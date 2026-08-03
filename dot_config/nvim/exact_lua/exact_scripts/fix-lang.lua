---@diagnostic disable: undefined-global
local vim = vim

if vim.env.LANG and vim.env.LANG:match("zh_CN") then
    vim.cmd("language zh_CN.UTF-8")
end
