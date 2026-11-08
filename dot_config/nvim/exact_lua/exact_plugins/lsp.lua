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
        opts = {
            PATH = "prepend"
        },
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            automatic_enable = false
        },
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
            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        -- 让 lazydev 补全具有最高优先级 (见 `:h blink.cmp`)
                        score_offset = 100,
                    },
                }
            },
            fuzzy = { implementation = "rust" }
        },
    },

    {
        -- 为 Neovim 提供更快的 LuaLS 配置
        "folke/lazydev.nvim",
        ft = "lua",
    },
}
