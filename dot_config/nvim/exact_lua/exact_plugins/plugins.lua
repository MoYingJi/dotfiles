---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    {
        -- 主题
        "folke/tokyonight.nvim",
        lazy = false, -- 如果这是你的主配色方案 请确保我们在启动时加载它
        priority = 1000, -- 确保在所有其他启动插件之前加载此插件
        config = function() vim.cmd([[colorscheme tokyonight]]) end,
    },

    {
        -- 状态栏
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function() require("lualine").setup {} end,
    },

    {
        -- 高亮显示
        "nvim-treesitter/nvim-treesitter",
        branch = 'master',
        lazy = false,
        build = ":TSUpdate",
        config = function() require('nvim-treesitter.configs').setup {
            auto_install = true
        } end,
    },
}
