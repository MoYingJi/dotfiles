-- 主题配置

local default_repo = "folke/tokyonight.nvim"
local default_colorscheme = ""

local themes = {
    ["folke/tokyonight.nvim"] = {
        colorscheme = "tokyonight",
    },
    ["tiesen243/vercel.nvim"] = {
        colorscheme = "vercel",
        config = function()
            require("vercel") {
                theme = "dark"
            }
        end
    },
}

-- 计算

if default_colorscheme and default_colorscheme ~= "" then
    if default_repo and default_repo ~= "" then
        error("不能同时指定 default_colorscheme 和 default_repo")
    end

    vim.cmd.colorscheme(default_colorscheme)
elseif default_repo and default_repo ~= "" then
    local theme_opts = themes[default_repo]
    if not theme_opts then
        error("未找到默认主题的配置")
    end
    if not theme_opts.colorscheme or theme_opts.colorscheme == "" then
        error("默认主题必须指定 colorscheme")
    end
else
    error("必须指定 default_repo 或 default_colorscheme")
end

local plugins = {}

for repo, opts in pairs(themes) do
    local is_default = (repo == default_repo)
    local this_colorscheme = opts and opts.colorscheme

    if (is_default) then
        assert(this_colorscheme ~= nil and this_colorscheme ~= "", "默认主题必须指定 colorscheme")
    end

    ---@type table<string, any>
    local plugin = {
        repo,
        lazy = not is_default,                   -- 默认主题启动即加载，其余按需加载
        priority = is_default and 1000 or nil,   -- 默认主题优先加载，避免闪烁
    }

    -- 合并插件选项，排除仅供本文件使用的元数据
    if opts then
        for k, v in pairs(opts) do
            if k ~= "config" and k ~= "colorscheme" then
                plugin[k] = v
            end
        end
    end

    -- 处理 config: 默认主题要在用户 config 之后设置 colorscheme
    local user_config = opts and opts.config
    if is_default then
        plugin.config = function()
            if user_config then user_config() end
            vim.cmd.colorscheme(this_colorscheme)
        end
    elseif user_config then
        plugin.config = user_config
    end

    table.insert(plugins, plugin)
end

return plugins
