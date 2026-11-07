---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    {
        -- 状态栏
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function() require("lualine").setup {} end,
    },

    {
        -- 模糊查找
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function() require("fzf-lua").setup {} end,
    },

    {
        -- 哪个键来着？
        "folke/which-key.nvim",
        event = "VeryLazy",
    },
}
