---@diagnostic disable-next-line: undefined-global
local vim = vim

-- 作者: DeepSeek 大人 (有修改)

-- 辅助函数：执行命令并返回修剪后的输出（移除首尾空白和换行）
local function get_system_output(cmd)
    local handle = io.popen(cmd)
    if not handle then return 0 end
    local result = handle:read("*a")
    handle:close()
    -- 去除尾部换行，并转换为数字
    result = result:gsub("%s+$", "")
    return math.floor(tonumber(result) or 0)
end

-- 辅助函数：执行命令（不关心输出）
local function exec_system(cmd)
    os.execute(cmd .. " > /dev/null 2>&1")
end

-- 输入法状态相关函数

local function im_status() return get_system_output("fcitx5-remote") end
local function im_close() exec_system("fcitx5-remote -c") end
local function im_open() exec_system("fcitx5-remote -o") end


-- 保存状态
-- 0: 未知; 1: 关闭; 2: 开启
local fcitx5_prev_state = 0

local function im_save_and_close()
    fcitx5_prev_state = im_status()
    im_close()
end

local function im_restore()
    if fcitx5_prev_state == 2 then
        im_open()
    end
end

-- 定义自动命令组（便于管理）
local fcitx5_group = vim.api.nvim_create_augroup("Fcitx5AutoCmd", { clear = true })

-- 退出插入模式时：保存状态并关闭输入法
vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = fcitx5_group,
    callback = im_save_and_close
})

-- 进入插入模式时：如果之前状态是开启，则重新打开
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = fcitx5_group,
    callback = im_restore
})

-- 在启动时先关闭输入法并保存状态，因为此时是 NORMOR MODE
im_save_and_close()
