// Global Script

const processDirect = [
    "qbittorrent",
    // "sparkle",
    "SPlayer",
]

const processProxy = [
]

const domainDirect = [
    "archlinux.org",
    "archlinuxcn.org",
    "bgithub.xyz",
    "bikonoo.com",
    "bing.com",
    "codeberg.org",
    "d2learn.org",
    "firefox.com",
    "ghfast.top",
    "imsyy.top",
    "miyoushe.com",
    "modrinth.com",
    "moyingji.one",
    "mozilla.org",
    "naiveui.com",
    "natchecker.com",
    "npmmirror.com",
    "office365.com",
    // "open.spotify.com",
    "outlook.live.com",
    "outlook.live.net",
    "skillsmp.com",
    "stevexmh.net",
    "vuejs.org",
    "xllmapi.com",
]

const domainProxy = [
    "trae.cn",
    "trae.com.cn",
    "marscode.cn",
]


const prependRules = [
    //"DST-PORT,22,DIRECT", // SSH 端口 22
    ...processDirect.map(process => `PROCESS-NAME,${process},DIRECT`),
    ...domainDirect.map(domain => `DOMAIN-SUFFIX,${domain},DIRECT`),
    ...processProxy.map(process => `PROCESS-NAME,${process},PROXY`),
    ...domainProxy.map(domain => `DOMAIN-SUFFIX,${domain},PROXY`),
]

const appendRules = [
    "GEOIP,CN,DIRECT",
]


function main(config) {
    // 获取第一个类型为选择的代理组的名称（作为默认代理）
    const PROXY = config["proxy-groups"]
        .find((group) => group.type === "select")
        .name

    // 替换用户规则中的 PROXY
    const mapRule = (rules) => rules
        .map((rule) => rule.replace(/,PROXY$/, `,${PROXY}`))

    // 替换
    const prependRulesReplaced = mapRule(prependRules)
    const appendRulesReplaced = mapRule(appendRules)

    // 插入前置规则
    config.rules = prependRulesReplaced.concat(config.rules)
    // 插入后置规则
    const fallbackRuleIndex = config.rules.length - 1
    config.rules.splice(fallbackRuleIndex, 0, ...appendRulesReplaced)

    // 返回
    return config
}
