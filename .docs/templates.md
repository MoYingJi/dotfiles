# 模板

本仓提供模板 `merge-*` 以拆分单配置文件到文件夹中方便管理
 - 要在 `.chezmoiignore` 中忽略这些辅助目录
 - 可在 `<name>.json.tmpl` 中写入 `{{- template "merge-json-object" . -}}` (或 `merge-json-array`)，这会自动读取 `<name>.json.d/` 下的 `**/*.json{,c}` 合并
 - 可在 `modify_<name>.json` 中调用 `merge-json-object`，并传入要保留的 path (这些 path 会原样保留外部的值，不由 chezmoi 管理和修改)，样例有 `.config/VSCode/User/settings.json`
