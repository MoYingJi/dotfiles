# 语言服务器

本仓的 lsp 使用者有 neovim、kate，提供者有系统安装和 mason.nvim

mason-lspconfig.nvim 经过配置，可以自动选择系统 lsp 和 mason 安装，详见 `.config/nvim/lua/config/lsp.lua`；反之，系统也可以使用 mason 安装的 lsp，详见 `.local/bin/chezmoi/nvim-mason-path-exe`。mason 提供本地数据库 (位于 `.config/nvim/mason-local`) 以添加自定义 lsp，详见 `.config/nvim/lua/config/mason_registry.lua`

kate 的配置在 `.config/kate/lspclient/settings.json`，但我还没摸清格式
