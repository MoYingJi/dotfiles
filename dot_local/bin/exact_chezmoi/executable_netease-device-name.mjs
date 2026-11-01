#!/usr/bin/env node

import { createCipheriv, createHash, randomBytes } from "node:crypto";
import { readFile } from "node:fs/promises";
import { hostname, release, type, userInfo } from "node:os";

const API_PATH = "/api/deviceinfo/center/upload";
const API_URL = "https://interfacepc.music.163.com/eapi/deviceinfo/center/upload";
const EAPI_KEY = "e82ckenh8dichen8";

const HOST_OS_KEY =
    process.platform === "darwin"
        ? "osx"
        : process.platform === "linux"
          ? "linux"
          : "pc";

const OS = {
    pc: {
        os: "pc",
        appver: "3.1.29.205117",
        channel: "netease",
    },
    linux: {
        os: "linux",
        appver: "1.2.1.0428",
        channel: "netease",
    },
    osx: {
        os: "osx",
        appver: "3.1.10.5100",
        channel: "netease",
    },
}[HOST_OS_KEY];

const USER_AGENT =
    HOST_OS_KEY === "osx"
        ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        : "NeteaseMusic/9.0.90/5038 (iPhone; iOS 16.2; zh_CN)";

const HELP = `用法：node netease-device-name.mjs <cookie.json|-> [设备名称]

从 JSON Cookie 文件读取 MUSIC_U 并上报登录设备名称。省略设备名称时使用「用户名 的 计算机名」。
文件参数为 - 时从 stdin 读取。

示例：
  node netease-device-name.mjs netease-cookies.json
  cat netease-cookies.json | node netease-device-name.mjs - "我的电脑"`;

/** 与项目相同，优先使用「用户名 的 计算机名」作为默认设备名 */
const defaultDeviceName = () => {
    const username = userInfo().username.trim();
    return username ? `${username} 的 ${hostname()}` : hostname();
};

/** 从 JSON 内容中提取请求所需的 Cookie 字段 */
const parseCookie = (content) => {
    const value = JSON.parse(content);
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error("Cookie 文件内容必须是 JSON 对象");
    }
    if (typeof value.MUSIC_U !== "string" || !value.MUSIC_U.trim()) {
        throw new Error("Cookie 文件中缺少有效的 MUSIC_U");
    }

    const cookie = { MUSIC_U: value.MUSIC_U };
    for (const key of ["__csrf", "NMTID", "deviceId"]) {
        if (value[key] !== undefined && typeof value[key] !== "string") {
            throw new Error(`Cookie 字段 ${key} 必须是字符串`);
        }
        if (value[key]) cookie[key] = value[key];
    }
    return cookie;
};

/** 读取文件或标准输入中的 Cookie JSON */
const readCookie = async (path) => {
    let content;
    if (path === "-") {
        process.stdin.setEncoding("utf8");
        content = "";
        for await (const chunk of process.stdin) content += chunk;
    } else {
        content = await readFile(path, "utf8");
    }
    return parseCookie(content);
};

/** 按网易云 eapi 协议加密请求参数 */
const encryptEapi = (path, data) => {
    const text = JSON.stringify(data);
    const message = `nobody${path}use${text}md5forencrypt`;
    const digest = createHash("md5").update(message).digest("hex");
    const plaintext = `${path}-36cd479b6b5-${text}-36cd479b6b5-${digest}`;
    const cipher = createCipheriv("aes-128-ecb", Buffer.from(EAPI_KEY), null);
    return Buffer.concat([
        cipher.update(plaintext, "utf8"),
        cipher.final(),
    ]).toString("hex");
};

/** 生成设备名称上报所需的请求头 */
const buildRequestHeader = (cookie) => {
    const deviceId =
        cookie.deviceId || randomBytes(26).toString("hex").toUpperCase();
    const header = {
        osver: `${type()} ${release()}`,
        deviceId,
        os: OS.os,
        appver: OS.appver,
        versioncode: "140",
        mobilename: "",
        buildver: Date.now().toString().slice(0, 10),
        resolution: "1920x1080",
        __csrf: cookie.__csrf || "",
        channel: OS.channel,
        requestId: `${Date.now()}_${Math.floor(Math.random() * 1000)
            .toString()
            .padStart(4, "0")}`,
        MUSIC_U: cookie.MUSIC_U,
    };
    if (cookie.NMTID) header.NMTID = cookie.NMTID;
    return header;
};

/** 编码请求 Cookie 字段 */
const serializeCookie = (cookie) =>
    Object.entries(cookie)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join("; ");

/** 使用当前设备信息构建并发送设备名称上报 */
const reportDeviceName = async (cookie, deviceName) => {
    const header = buildRequestHeader(cookie);
    const encrypted = encryptEapi(API_PATH, { deviceName, e_r: false, header });
    const body = new URLSearchParams({ params: encrypted });
    const response = await fetch(API_URL, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            Cookie: serializeCookie(header),
            "User-Agent": USER_AGENT,
        },
        body,
        signal: AbortSignal.timeout(8000),
    });

    let result;
    try {
        result = await response.json();
    } catch {
        throw new Error(
            `网易云返回了无法解析的响应（HTTP ${response.status}）`,
        );
    }
    if (!result || typeof result !== "object" || Array.isArray(result)) {
        throw new Error(`网易云返回了无效响应（HTTP ${response.status}）`);
    }
    if (!response.ok || Number(result.code) !== 200) {
        throw new Error(
            `设备名称上报失败：${result.msg || result.message || `HTTP ${response.status}`}`,
        );
    }
    console.log(`设备名称「${deviceName}」上报成功`);
};

/** 解析命令行参数并启动上报 */
const main = async () => {
    const args = process.argv.slice(2);
    if (args.length === 1 && (args[0] === "--help" || args[0] === "-h")) {
        console.log(HELP);
        return;
    }
    if (args.length < 1 || args.length > 2) throw new Error(HELP);

    const cookie = await readCookie(args[0]);
    await reportDeviceName(cookie, args[1]?.trim() || defaultDeviceName());
};

main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
});
