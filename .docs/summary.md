# 总览

这是一个由 chezmoi 管理的 dotfiles

本仓库提供模板，可将单配置文件到文件夹中方便管理，详见 `.docs/templates.md`

`.config/shell` 中是所有 shell 的共用配置，在每个 shell 的特定配置中 source，目前需要兼容 bash zsh fish

`.config/VSCode` 是 VSCode 的共用配置，三个符号链接 `.config/{Code,Code - Insiders,Code - OSS}` 指向它
