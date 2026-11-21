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

    mcppls = { executable = "mcppls", local_registry = true },
    dae_lsp = { executable = "dae-lsp", local_registry = true },
}

M.fallback_groups = {
    { filetypes = { "python" }, servers = { "pyright", "pylsp" } },
    { filetypes = { "c" }, servers = { "clangd" } },
    { filetypes = { "cpp" }, servers = { "mcppls", "clangd" } },
}

M.server_configs = {
    rust_analyzer = {
        settings = {
            ["rust-analyzer"] = {
                check = { command = "clippy" },
            },
        },
    },
    mcppls = {
        cmd = { "mcppls", "serve" },
        filetypes = { "c", "cpp" },
        root_markers = { "mcpp.toml", "CMakeLists.txt", "compile_commands.json", ".git" },
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
        h = "c", -- .h 有歧义，交给 clangd；.hpp/.hh 等仍按 C++ 处理
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
    local fallback_by_filetype = {}
    local fallback_servers = {}

    for _, group in ipairs(M.fallback_groups) do
        for _, filetype in ipairs(group.filetypes) do
            fallback_by_filetype[filetype] = group.servers
        end
        for _, server in ipairs(group.servers) do
            fallback_servers[server] = true
        end
    end

    local function select_fallback_server(filetype)
        for _, server in ipairs(fallback_by_filetype[filetype] or {}) do
            local executable = get_executable(server)
            if executable and vim.fn.executable(executable) == 1 then
                return server
            end
        end
    end

    local selected_by_filetype = {}
    local selected_filetypes = {}
    for _, group in ipairs(M.fallback_groups) do
        for _, filetype in ipairs(group.filetypes) do
            local server = select_fallback_server(filetype)
            if server then
                selected_by_filetype[filetype] = server
                selected_filetypes[server] = selected_filetypes[server] or {}
                table.insert(selected_filetypes[server], filetype)
            end
        end
    end

    for server in pairs(M.servers) do
        local config = vim.tbl_deep_extend("force", {
            capabilities = capabilities,
        }, M.server_configs[server] or {})
        vim.lsp.config(server, config)
    end

    for server in pairs(fallback_servers) do
        local resolved_config = vim.deepcopy(vim.lsp.config[server])
        local original_root_dir = resolved_config.root_dir
        local filetypes = {}
        for _, filetype in ipairs(resolved_config.filetypes or {}) do
            if not fallback_by_filetype[filetype] then
                table.insert(filetypes, filetype)
            end
        end
        vim.list_extend(filetypes, selected_filetypes[server] or {})
        resolved_config.filetypes = filetypes
        resolved_config.root_dir = function(bufnr, on_dir)
            local filetype = vim.bo[bufnr].filetype
            if fallback_by_filetype[filetype] and selected_by_filetype[filetype] ~= server then return end

            if type(original_root_dir) == "function" then
                original_root_dir(bufnr, on_dir)
            elseif type(original_root_dir) == "string" then
                on_dir(original_root_dir)
            else
                on_dir(nil)
            end
        end
        vim.lsp.config[server] = resolved_config
    end

    local function notify_missing_for_buffer(buf)
        if not vim.api.nvim_buf_is_valid(buf) then return end

        local filetype = vim.bo[buf].filetype
        local missing = {}

        local fallback_group = fallback_by_filetype[filetype]
        if fallback_group then
            if not selected_by_filetype[filetype] then
                notified[buf] = notified[buf] or {}
                for _, server in ipairs(fallback_group) do
                    if not notified[buf][server] then
                        notified[buf][server] = true
                        table.insert(missing, server)
                    end
                end
            end
        end

        for server in pairs(M.servers) do
            local server_config = vim.lsp.config[server]
            local filetypes = server_config and server_config.filetypes or {}
            local executable = get_executable(server)

            if vim.tbl_contains(filetypes, filetype)
                and not fallback_servers[server]
                and executable
                and vim.fn.executable(executable) ~= 1
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
        local executable = get_executable(server)
        if executable and vim.fn.executable(executable) == 1 then
            vim.lsp.enable(server)
        end
    end

    local current_buf = vim.api.nvim_get_current_buf()
    vim.schedule(function() notify_missing_for_buffer(current_buf) end)
end

return M
