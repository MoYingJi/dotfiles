---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    -- LSP 配置

    {
        "neovim/nvim-lspconfig",
        dependencies = { "saghen/blink.cmp", "williamboman/mason.nvim" },
        config = function() require("config.lsp").setup() end,
    },

    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function() require("mason").setup({
            PATH = "prepend"
        }) end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "mason.nvim", "neovim/nvim-lspconfig" },
        config = function()
            require("mason-lspconfig").setup({
                automatic_enable = false,
            })
        end,
    },

    -- 代码补全

    {
        "saghen/blink.cmp",
        dependencies = { "saghen/blink.lib", "rafamadriz/friendly-snippets" },
        build = function() require("blink.cmp").build():pwait() end,
        opts = {
            keymap = {
                preset = "enter"
            },
            completion = { documentation = { auto_show = true } },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            fuzzy = { implementation = "rust" }
        },
    }
}
