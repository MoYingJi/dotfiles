return {
    {
        -- 高亮显示
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function(_, opts)
            local ts = require("nvim-treesitter")
            ts.setup(opts)

            local available_languages = {}
            for _, language in ipairs(ts.get_available()) do
                available_languages[language] = true
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "*",
                callback = function(args)
                    local buf = args.buf
                    local filetype = vim.bo[buf].filetype
                    local language = vim.treesitter.language.get_lang(filetype)
                    if not language or not available_languages[language] then return end

                    ts.install({ language }):await(function(err, installed)
                        if err then
                            vim.notify(tostring(err), vim.log.levels.ERROR)
                            return
                        end
                        if not installed then
                            vim.notify("Failed to install Treesitter parser for " .. language, vim.log.levels.ERROR)
                            return
                        end
                        if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].filetype ~= filetype then return end

                        local ok, start_err = pcall(vim.treesitter.start, buf, language)
                        if not ok then
                            vim.notify(tostring(start_err), vim.log.levels.ERROR)
                            return
                        end
                        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end)
                end,
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function() require("treesitter-context").setup {} end,
    }
}
