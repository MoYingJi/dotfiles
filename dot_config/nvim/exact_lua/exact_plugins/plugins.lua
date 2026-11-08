return {
    {
        -- 状态栏
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
    },

    {
        -- 模糊查找
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
    },

    {
        -- 哪个键来着？
        "folke/which-key.nvim",
        event = "VeryLazy",
    },

    {
        -- 文件树
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,
    },

    {
        -- 标签页
        "romgrk/barbar.nvim",
        dependencies = { "lewis6991/gitsigns.nvim", "nvim-tree/nvim-web-devicons" },
        init = function() vim.g.barbar_auto_setup = false end,
        opts = {
            animation = false,
            auto_hide = 1,
            sidebar_filetypes = {
                ["neo-tree"] = {
                    event = "BufWipeout",
                    text = " 文件",
                    align = "left",
                }
            },
            exclude_ft = { "neo-tree", "neo-tree-popup" }
        },
        config = function(_, opts)
            require("barbar").setup(opts)

            vim.api.nvim_create_autocmd("BufWinLeave", {
                callback = function(ev)
                    local buf = ev.buf
                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(buf)
                            and vim.api.nvim_buf_get_name(buf) == ""
                            and not vim.bo[buf].modified
                            and vim.api.nvim_buf_line_count(buf) == 1
                            and (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
                        then
                            pcall(vim.api.nvim_buf_delete, buf, { force = false })
                        end
                    end)
                end,
            })
        end,
    },

    {
        -- Git 集成
        "lewis6991/gitsigns.nvim",
    },
}
