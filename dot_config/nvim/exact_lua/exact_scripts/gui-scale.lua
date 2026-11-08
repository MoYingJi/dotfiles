-- GUI 缩放

if vim.g.neovide then
    vim.g.neovide_scale_factor = 1.0

    local function change_scale(delta)
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
    end

    vim.keymap.set("n", "<C-=>", function() change_scale(1.1) end)
    vim.keymap.set("n", "<C-->", function() change_scale(1 / 1.1) end)
    vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end)
end
