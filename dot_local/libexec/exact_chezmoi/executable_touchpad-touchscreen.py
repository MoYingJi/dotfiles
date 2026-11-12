#!/usr/bin/env python3
"""Touchpad-to-touchscreen trial and favorites-key toggle daemon."""

import argparse
import os
import os
import selectors
import signal
import subprocess
import sys
import time
from contextlib import ExitStack

from evdev import InputDevice, UInput, ecodes, list_devices


TOUCHPAD_NAME = os.environ.get("TOUCHPAD_NAME", "FTCS0038:00 2808:0106 Touchpad")
MOUSE_NAME = os.environ.get("TOUCHPAD_MOUSE_NAME", "FTCS0038:00 2808:0106 Mouse")
DURATION_SECONDS = 30
KEYD_MONITOR = os.environ.get("KEYD_MONITOR", "/usr/bin/keyd")
ABS_CODES = (
    ecodes.ABS_X,
    ecodes.ABS_Y,
    ecodes.ABS_MT_SLOT,
    ecodes.ABS_MT_POSITION_X,
    ecodes.ABS_MT_POSITION_Y,
    ecodes.ABS_MT_TRACKING_ID,
)


def find_devices(stack):
    found = {}
    for path in list_devices():
        device = InputDevice(path)
        if device.name in (TOUCHPAD_NAME, MOUSE_NAME):
            stack.callback(device.close)
            if device.name in found:
                raise RuntimeError(f"设备名称不唯一: {device.name}")
            found[device.name] = device
        else:
            device.close()

    if set(found) != {TOUCHPAD_NAME, MOUSE_NAME}:
        raise RuntimeError(f"找不到触控板或其鼠标节点，已找到: {list(found)}")
    touchpad, mouse = found[TOUCHPAD_NAME], found[MOUSE_NAME]
    if not touchpad.phys or touchpad.phys != mouse.phys or touchpad.info != mouse.info:
        raise RuntimeError("触控板和鼠标节点的硬件身份不匹配")
    return touchpad, mouse


def create_touchscreen(touchpad):
    capabilities = touchpad.capabilities(absinfo=True)
    if ecodes.BTN_TOUCH not in capabilities.get(ecodes.EV_KEY, []):
        raise RuntimeError("触控板缺少 BTN_TOUCH")
    axes = dict(capabilities.get(ecodes.EV_ABS, []))
    missing = set(ABS_CODES) - axes.keys()
    if missing:
        raise RuntimeError(f"触控板缺少必要的绝对坐标轴: {sorted(missing)}")
    if axes[ecodes.ABS_MT_SLOT].min != 0:
        raise RuntimeError("不支持起点非零的触点槽")
    return UInput(
        events={
            ecodes.EV_KEY: [ecodes.BTN_TOUCH],
            ecodes.EV_ABS: [(code, axes[code]) for code in ABS_CODES],
        },
        name="Touchpad touchscreen trial",
        bustype=ecodes.BUS_VIRTUAL,
        input_props=[ecodes.INPUT_PROP_DIRECT],
    )


def discard_pending_events(device):
    while device.read_one() is not None:
        pass


def wait_for_udev(touchscreen):
    if touchscreen.device is None:
        raise RuntimeError("无法访问创建的虚拟输入设备")
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        result = subprocess.run(
            ["udevadm", "info", "--query=property", f"--name={touchscreen.device.path}"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0 and "ID_INPUT_TOUCHSCREEN=1" in result.stdout.splitlines():
            return
        time.sleep(0.1)
    raise RuntimeError(
        "虚拟设备未被 udev 识别为触摸屏: "
        f"{touchscreen.device.path}; {result.stderr.strip()}"
    )


class TouchForwarder:
    def __init__(self, touchscreen):
        self.touchscreen = touchscreen
        self.slot = 0
        self.active_slots = set()
        self.dirty = False

    def process(self, event):
        if event.type == ecodes.EV_SYN:
            if event.code == ecodes.SYN_DROPPED:
                raise RuntimeError("触控板事件队列溢出，终止试验")
            if event.code == ecodes.SYN_REPORT and self.dirty:
                self.touchscreen.syn()
                self.dirty = False
        elif event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
            self.touchscreen.write(event.type, event.code, event.value)
            self.dirty = True
        elif event.type == ecodes.EV_ABS and event.code in ABS_CODES:
            if event.code == ecodes.ABS_MT_SLOT:
                self.slot = event.value
            elif event.code == ecodes.ABS_MT_TRACKING_ID:
                if event.value == -1:
                    self.active_slots.discard(self.slot)
                else:
                    self.active_slots.add(self.slot)
            self.touchscreen.write(event.type, event.code, event.value)
            self.dirty = True

    def release(self):
        for slot in sorted(self.active_slots):
            self.touchscreen.write(ecodes.EV_ABS, ecodes.ABS_MT_SLOT, slot)
            self.touchscreen.write(ecodes.EV_ABS, ecodes.ABS_MT_TRACKING_ID, -1)
        self.touchscreen.write(ecodes.EV_KEY, ecodes.BTN_TOUCH, 0)
        self.touchscreen.syn()
        self.active_slots.clear()


class TouchscreenMode:
    def __init__(self, touchpad, mouse):
        self.touchpad = touchpad
        self.mouse = mouse
        self.touchscreen = None
        self.forwarder = None
        self.grabbed = []

    @property
    def active(self):
        return self.touchscreen is not None

    def enable(self):
        if self.active:
            return

        touchscreen = create_touchscreen(self.touchpad)
        try:
            wait_for_udev(touchscreen)
            for device in (self.touchpad, self.mouse):
                discard_pending_events(device)
            for device in (self.touchpad, self.mouse):
                device.grab()
                self.grabbed.append(device)
            for device in (self.touchpad, self.mouse):
                discard_pending_events(device)
            if ecodes.BTN_TOUCH in self.touchpad.active_keys():
                raise RuntimeError("触控板上已有手指；请抬起手指后再切换")
            self.touchscreen = touchscreen
            self.forwarder = TouchForwarder(touchscreen)
        except BaseException:
            for device in reversed(self.grabbed):
                device.ungrab()
            self.grabbed.clear()
            touchscreen.close()
            raise

    def disable(self):
        if not self.active:
            return
        try:
            self.forwarder.release()
        finally:
            self.touchscreen.close()
            self.touchscreen = None
            self.forwarder = None
            for device in reversed(self.grabbed):
                device.ungrab()
            self.grabbed.clear()

    def close(self):
        self.disable()

    def __enter__(self):
        return self

    def __exit__(self, _exc_type, _exc_value, _traceback):
        self.close()


def keyd_favorites_transition(line, was_down):
    """Return whether a line is a new favorites press and its resulting state."""
    fields = line.split()
    if len(fields) < 5 or " ".join(fields[:3]) != "keyd virtual keyboard":
        return False, was_down
    if fields[-2] != "favorites":
        return False, was_down
    if fields[-1] == "up":
        return False, False
    if fields[-1] == "down":
        return not was_down, True
    return False, was_down


def start_keyd_monitor():
    return subprocess.Popen(
        ["stdbuf", "-oL", KEYD_MONITOR, "monitor"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0,
    )


def stop_keyd_monitor(monitor):
    if monitor.poll() is None:
        monitor.terminate()
        try:
            monitor.wait(timeout=1)
        except subprocess.TimeoutExpired:
            monitor.kill()
            monitor.wait()


def run_toggle_daemon():
    stopping = False

    def stop(_signum, _frame):
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    with ExitStack() as stack:
        touchpad, mouse = find_devices(stack)
        mode = stack.enter_context(TouchscreenMode(touchpad, mouse))
        monitor = stack.enter_context(start_keyd_monitor())
        stack.callback(stop_keyd_monitor, monitor)
        if monitor.stdout is None:
            raise RuntimeError("无法读取 keyd monitor 输出")
        selector = stack.enter_context(selectors.DefaultSelector())
        selector.register(monitor.stdout, selectors.EVENT_READ)
        favorites_down = False
        pending_output = b""
        print("触控板模式；按 favorites 切换触摸屏模式。", flush=True)
        try:
            while not stopping:
                if monitor.poll() is not None:
                    raise RuntimeError(f"keyd monitor 已退出，状态码 {monitor.returncode}")
                for key, _ in selector.select(0.5):
                    if key.fileobj is monitor.stdout:
                        chunk = os.read(monitor.stdout.fileno(), 4096)
                        if not chunk:
                            if stopping:
                                break
                            raise RuntimeError("keyd monitor 输出已关闭")
                        pending_output += chunk
                        while b"\n" in pending_output:
                            line, pending_output = pending_output.split(b"\n", 1)
                            toggle, favorites_down = keyd_favorites_transition(
                                line.decode("utf-8"), favorites_down
                            )
                            if toggle:
                                if mode.active:
                                    selector.unregister(touchpad)
                                    selector.unregister(mouse)
                                    mode.disable()
                                    print("已切回触控板模式。", flush=True)
                                else:
                                    try:
                                        mode.enable()
                                        try:
                                            selector.register(touchpad, selectors.EVENT_READ)
                                            selector.register(mouse, selectors.EVENT_READ)
                                        except OSError:
                                            for device in (touchpad, mouse):
                                                try:
                                                    selector.unregister(device)
                                                except KeyError:
                                                    pass
                                            mode.disable()
                                            raise
                                        print("已切换到触摸屏模式；再按 favorites 可退出。", flush=True)
                                    except (OSError, RuntimeError) as error:
                                        print(f"切换到触摸屏模式失败：{error}", file=sys.stderr, flush=True)
                    elif mode.active and key.fileobj is touchpad:
                        for event in touchpad.read():
                            mode.forwarder.process(event)
                    elif mode.active and key.fileobj is mouse:
                        mouse.read()
        finally:
            selector.unregister(monitor.stdout)
            mode.disable()
        print("触控屏切换服务已停止，触控板已恢复。", flush=True)


def run_trial():
    stopping = False

    def stop(_signum, _frame):
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    with ExitStack() as stack:
        touchpad, mouse = find_devices(stack)
        mode = stack.enter_context(TouchscreenMode(touchpad, mouse))
        mode.enable()
        if stopping:
            return
        selector = stack.enter_context(selectors.DefaultSelector())
        selector.register(touchpad, selectors.EVENT_READ)
        selector.register(mouse, selectors.EVENT_READ)
        deadline = time.monotonic() + DURATION_SECONDS
        print("READY: 触摸屏试验已启动，最多持续 30 秒。", flush=True)
        try:
            while not stopping:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                for key, _ in selector.select(min(remaining, 0.2)):
                    if key.fileobj is touchpad:
                        for event in touchpad.read():
                            mode.forwarder.process(event)
                    else:
                        mouse.read()
            print("试验结束，正在释放触点并恢复触控板。", flush=True)
        finally:
            mode.disable()


def run():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--toggle-daemon",
        action="store_true",
        help="listen for favorites via keyd and toggle the virtual touchscreen",
    )
    args = parser.parse_args()
    if args.toggle_daemon:
        run_toggle_daemon()
    else:
        run_trial()


if __name__ == "__main__":
    try:
        run()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"触控板映射程序退出: {error}", file=sys.stderr, flush=True)
        sys.exit(1)
