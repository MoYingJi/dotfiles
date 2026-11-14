local M = {}

local registry_path = vim.fn.stdpath("config") .. "/mason-local"
local registry_status

local function check_registry()
    if registry_status then return registry_status end

    if vim.fn.isdirectory(registry_path .. "/packages") ~= 1 then
        registry_status = {
            available = false,
            reason = "本地 Mason registry 缺少 packages/ 目录",
        }
        return registry_status
    end

    if vim.fn.executable("yq") ~= 1 then
        registry_status = {
            available = false,
            reason = "未找到 yq",
        }
        return registry_status
    end

    local output = vim.fn.system({ "yq", "-I0", "-o", "json" }, "name: mason-yq-probe\n")
    local ok, result = pcall(vim.json.decode, output)
    if vim.v.shell_error ~= 0 or not ok or type(result) ~= "table" or result.name ~= "mason-yq-probe" then
        registry_status = {
            available = false,
            reason = "yq 与 Mason 不兼容（需要 Mike Farah 版）",
        }
        return registry_status
    end

    registry_status = { available = true }
    return registry_status
end

function M.get_options()
    local status = check_registry()
    local registries = { "github:mason-org/mason-registry" }

    if status.available then
        table.insert(registries, 1, "file:" .. registry_path)
    else
        vim.notify(
            ("本地 Mason registry 已禁用：%s"):format(status.reason),
            vim.log.levels.WARN,
            { title = "Mason" }
        )
    end

    return {
        PATH = "prepend",
        registries = registries,
    }
end

function M.has_package(package)
    return check_registry().available
        and vim.fn.filereadable(registry_path .. "/packages/" .. package .. "/package.yaml") == 1
end

return M
