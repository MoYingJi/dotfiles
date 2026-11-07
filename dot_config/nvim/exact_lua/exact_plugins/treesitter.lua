---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    {
        -- 高亮显示
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local available_languages = {}
            for _, language in ipairs(require("nvim-treesitter").get_available()) do
                available_languages[language] = true
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "*",
                callback = function()
                    local filetype = vim.bo.filetype
                    local language = vim.treesitter.language.get_lang(filetype)
                    if not language or not available_languages[language] then return end

                    require("nvim-treesitter").install({ language })
                    pcall(vim.treesitter.start)
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function() require("treesitter-context").setup {} end,
    }
}
