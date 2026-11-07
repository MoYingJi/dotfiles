---@diagnostic disable-next-line: undefined-global
local vim = vim

-- 主题配置

local default_repo = "folke/tokyonight.nvim"

local themes = {
    ["folke/tokyonight.nvim"] = {
        colorscheme = "tokyonight",
    },
    ["tiesen243/vercel.nvim"] = {
        colorscheme = "vercel",
        config = function()
            require("vercel").setup({
                theme = "dark"
            })
        end
    },
}

-- 计算

local plugins = {}

local default_colorscheme = assert(assert(themes[default_repo]).colorscheme)

for repo, opts in pairs(themes) do
    local is_default = (repo == default_repo)

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
            vim.cmd.colorscheme(default_colorscheme)
        end
    elseif user_config then
        plugin.config = user_config
    end

    table.insert(plugins, plugin)
end

return plugins
