-- 修改自 fastforward.js
-- https://github.com/n1nja88888/mpv-fastfoward/raw/refs/heads/main/fastfoward.js
-- LICENSE: ARR

local mp = require "mp"
local msg = require "mp.msg"
local options = require "mp.options"

-- 配置
local opts = {
    key = "RIGHT",                  -- 绑定的按键
    speed_multiplier = 3,           -- 按住时的倍速
    seek_amount = nil,              -- 点按时的快进秒数 (默认使用 mpv 的 seek-forward 设置)
    osd_duration = 0.1,             -- OSD 显示时长
    osd_message = "Speed: ->> %S",  -- OSD 提示文字 (支持 %S 占位符显示当前倍速)
}

options.read_options(opts)

-- 如果 seek_amount 没有设置，则使用 mpv 的默认 seek-forward 设置
if opts.seek_amount == nil then
    local mpv_seek = mp.get_property_native("seek-forward")

    if type(mpv_seek) == "number" then
        opts.seek_amount = mpv_seek
    else
        opts.seek_amount = 5
    end
end

-- 内部状态变量
local original_speed = 1.0
local speed_changed = false

-- 处理按键事件的函数
function on_key(event)
    local event_type = event.event -- "down", "repeat", "up"

    if event_type == "down" then
        -- 按下时：保存当前速度
        original_speed = mp.get_property_native("speed")
        speed_changed = false

    elseif event_type == "repeat" then
        -- 重复触发（按住不放）：设置加速
        local fast_speed = original_speed * opts.speed_multiplier
        mp.set_property_native("speed", fast_speed)
        speed_changed = true

        -- 处理 OSD 消息，将 %S 替换为实际倍速
        local osd_text = opts.osd_message:gsub("%%S", string.format("%g", fast_speed))
        mp.osd_message(osd_text, opts.osd_duration)

    elseif event_type == "up" then
        -- 松开时：判断是恢复速度还是快进
        if speed_changed then
            -- 如果触发过加速，恢复原速
            mp.set_property_native("speed", original_speed)
        else
            -- 如果没有触发加速（只是点按），则快进
            mp.commandv("seek", opts.seek_amount, "relative")
        end
    end
end

-- 注册按键绑定
-- 注意：complex=true 是获取 down/repeat/up 事件的关键 (需要 mpv 0.33.0+)
mp.add_key_binding(opts.key, "speed_hold_toggle", on_key, {
    repeatable = true,
    complex = true
})
