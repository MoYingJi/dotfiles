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
    taplo = "taplo", -- toml # extra/taplo-cli
    lemminx = "lemminx", -- xml # archlinuxcn/lemminx
    marksman = "marksman",
    systemd_lsp = "systemd-lsp",

    dae_lsp = { executable = "dae-lsp", local_registry = true },
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
    dae_lsp = {
        cmd = { "dae-lsp", "--stdio" },
        filetypes = { "dae" },
        root_markers = { ".git", "package.json" },
    },
}

M.shebang_filetype = {
    ["^#!.*ccrun"] = "c",
}

vim.filetype.add {
    extension = {
        dae = "dae",
    },
}

vim.diagnostic.config {
    virtual_text = true
}

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition | 转到定义" })
    end,
})

vim.filetype.add { pattern = { [".*"] = {
    ---@param _ string 文件路径
    ---@param bufnr number 缓冲区编号
    ---@return string | nil 文件类型
    function(_, bufnr)
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
        local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
        if not first_line or first_line:sub(1, 2) ~= '#!' then return nil end

        for pattern, filetype in pairs(M.shebang_filetype) do
            if first_line:match(pattern) then
                return filetype
            end
        end
    end,
} } }

local function get_executable(server)
    local entry = M.servers[server]
    if type(entry) == "table" then
        if entry.check_executable == false then return nil end
        return entry.executable
    end
    return entry
end

local function get_install_hint(server)
    local entry = M.servers[server]
    if type(entry) == "table" and entry.local_registry then
        local package = server:gsub("_", "-")
        if require("config.mason_registry").has_package(package) then
            return ":MasonInstall " .. package
        end
        return ("本地 Mason registry 不可用或缺少包定义（%s）"):format(package)
    end
    return ":LspInstall " .. server
end

function M.setup()
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local notified = {}
    local fallback_peers = {}
    local enabled_servers = {}

    for _, group in ipairs(M.fallback_groups) do
        local selected

        for _, server in ipairs(group) do
            fallback_peers[server] = group
            local executable = get_executable(server)
            if not selected and executable and vim.fn.executable(executable) == 1 then
                selected = server
            end
        end

        if selected then enabled_servers[selected] = true end
    end

    for server in pairs(M.servers) do
        local executable = get_executable(server)
        if not fallback_peers[server] and executable and vim.fn.executable(executable) == 1 then
            enabled_servers[server] = true
        end
    end

    local function notify_missing_for_buffer(buf)
        if not vim.api.nvim_buf_is_valid(buf) then return end

        local filetype = vim.bo[buf].filetype
        local missing = {}

        for server in pairs(M.servers) do
            local server_config = vim.lsp.config[server]
            local filetypes = server_config and server_config.filetypes or {}
            local executable = get_executable(server)
            local fallback_available = false

            for _, peer in ipairs(fallback_peers[server] or {}) do
                local peer_executable = get_executable(peer)
                if peer_executable and vim.fn.executable(peer_executable) == 1 then
                    fallback_available = true
                    break
                end
            end

            if vim.tbl_contains(filetypes, filetype)
                and executable
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
            local commands = {}
            for _, server in ipairs(missing) do
                table.insert(commands, get_install_hint(server))
            end
            vim.notify(
                ("当前文件类型 %q 缺少 LSP: %s\n按需安装：%s")
                    :format(filetype, table.concat(missing, ", "), table.concat(commands, " / ")),
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

    for server in pairs(M.servers) do
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
