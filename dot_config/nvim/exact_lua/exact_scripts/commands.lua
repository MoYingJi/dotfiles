---@diagnostic disable-next-line: undefined-global
local vim = vim

vim.api.nvim_create_user_command("S", function()
    vim.cmd("Lazy sync")
end, {})
