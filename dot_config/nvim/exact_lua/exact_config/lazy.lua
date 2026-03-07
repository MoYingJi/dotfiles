---@diagnostic disable-next-line: undefined-global
local vim = vim

local config = require("config.nvim_chezmoi")

local url_format = "https://github.com/%s.git"
if config.ssh_github then url_format = "git@github.com:%s.git" end

-- 初始化 lazy.nvim
--               ~/.local/share/nvim/
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = url_format:format("folke/lazy.nvim")
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "克隆 lazy.nvim 失败:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\n按任意键退出..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- 请确保在加载 lazy.nvim 之前设置 `mapleader` 和 `maplocalleader` 以便映射正确
-- 这里也可以放其他设置 (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 加载 lazy.nvim
require("lazy").setup({
    spec = {
        -- 添加插件
        { import = "plugins" },
    },
    -- 在此处配置任何其他设置 有关更多详细信息 请参阅文档
    -- https://lazy.folke.io/configuration
    git = {
        -- 用于克隆插件的 URL 格式
        url_format = url_format,
    },
    -- 安装插件时将使用的配色方案
    install = { colorscheme = { "habamax" } },
    -- 自动检查插件更新
    checker = { enabled = false },
})
