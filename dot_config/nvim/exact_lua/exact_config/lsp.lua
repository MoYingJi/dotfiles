local M = {}

M.servers = {
    clangd = "clangd",
    rust_analyzer = "rust-analyzer",
    pyright = "pyright-langserver",
    pylsp = "pylsp",
    lua_ls = "lua-language-server",
    termux_language_server = "termux-language-server",
    bashls = "bash-language-server",
    fish_lsp = "fish-lsp",
    ts_ls = "typescript-language-server",
    eslint = "vscode-eslint-language-server",
    cssls = "vscode-css-language-server",
    jsonls = "vscode-json-language-server",
    yamlls = "yaml-language-server",
    marksman = "marksman",
}

M.fallback_groups = {
    { "pyright", "pylsp" },
}

M.server_configs = {
    rust_analyzer = {
        settings = {
            ["rust-analyzer"] = {
                check = { command = "clippy" },
            },
        },
    },
}

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition | 转到定义" })
    end,
})

vim.diagnostic.config {
    virtual_text = true
}

function M.setup()
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local notified = {}
    local fallback_peers = {}
    local enabled_servers = {}

    for _, group in ipairs(M.fallback_groups) do
        local selected

        for _, server in ipairs(group) do
            fallback_peers[server] = group
            if not selected and vim.fn.executable(M.servers[server]) == 1 then
                selected = server
            end
        end

        if selected then enabled_servers[selected] = true end
    end

    for server, executable in pairs(M.servers) do
        if not fallback_peers[server] and vim.fn.executable(executable) == 1 then
            enabled_servers[server] = true
        end
    end

    local function notify_missing_for_buffer(buf)
        if not vim.api.nvim_buf_is_valid(buf) then return end

        local filetype = vim.bo[buf].filetype
        local missing = {}

        for server, executable in pairs(M.servers) do
            local server_config = vim.lsp.config[server]
            local filetypes = server_config and server_config.filetypes or {}
            local fallback_available = false

            for _, peer in ipairs(fallback_peers[server] or {}) do
                if vim.fn.executable(M.servers[peer]) == 1 then
                    fallback_available = true
                    break
                end
            end

            if vim.tbl_contains(filetypes, filetype)
                and vim.fn.executable(executable) ~= 1
                and not fallback_available
                and not (notified[buf] and notified[buf][server])
            then
                notified[buf] = notified[buf] or {}
                notified[buf][server] = true
                table.insert(missing, server)
            end
        end

        if #missing > 0 then
            table.sort(missing)
            vim.notify(
                ("当前文件类型 %q 缺少 LSP: %s\n可运行 ':LspInstall <server>' 按需安装。")
                    :format(filetype, table.concat(missing, ", ")),
                vim.log.levels.WARN,
                { title = "LSP" }
            )
        end
    end

    local group = vim.api.nvim_create_augroup("UserLspMissingServerNotification", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args) notify_missing_for_buffer(args.buf) end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args) notified[args.buf] = nil end,
    })

    for server, _ in pairs(M.servers) do
        local config = vim.tbl_deep_extend("force", {
            capabilities = capabilities,
        }, M.server_configs[server] or {})
        vim.lsp.config(server, config)

        if enabled_servers[server] then vim.lsp.enable(server) end
    end

    local current_buf = vim.api.nvim_get_current_buf()
    vim.schedule(function() notify_missing_for_buffer(current_buf) end)
end

return M
