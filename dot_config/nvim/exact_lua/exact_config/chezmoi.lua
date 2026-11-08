local ok, mod = pcall(require, "config.chezmoi-tmpl")

if ok then
    return mod
else
    error("加载 config.chezmoi-tmpl 失败")
    return {}
end
