-- 自定义命令

vim.api.nvim_create_user_command("S", function()
    vim.cmd("Lazy sync")
end, {})
