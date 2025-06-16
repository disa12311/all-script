local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local CFG = {
    VERSION = "6.0",
    URL = "https://raw.githubusercontent.com/YourUser/YourRepo/main/script.lua",
    AUTO = true,
    DEBUG = true
}

local function log(msg)
    if CFG.DEBUG then rconsoleprint("[Updater 6.0] "..tostring(msg).."\n") end
end

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Updater v"..CFG.VERSION,
            Text = msg,
            Duration = 5
        })
    end)
end

local function fetch(url)
    local ok, res = pcall(function()
        return HttpService:GetAsync(url .. "?t=" .. tick())
    end)
    return ok and res or nil
end

local function getRemoteVersion()
    local code = fetch(CFG.URL)
    return code and code:match('%-%-VERSION%s*:%s*([%d%.]+)') or nil
end

local function runUpdate()
    local code = fetch(CFG.URL)
    if code then
        local f = loadstring(code)
        if f then
            notify("Đang chạy script mới...")
            f()
            log("Script mới chạy thành công.")
        else
            notify("Loadstring lỗi!")
        end
    else
        notify("Không tải được script!")
    end
end

local function checkUpdate()
    local ver = getRemoteVersion()
    if ver then
        if ver ~= CFG.VERSION then
            notify("Có bản mới: "..ver)
            runUpdate()
        else
            notify("Đã là bản mới nhất!")
            log("Up-to-date.")
        end
    else
        notify("Không kiểm tra được version!")
    end
end

-- START
if CFG.AUTO then
    task.spawn(function()
        wait(1)
        checkUpdate()
    end)
else
    notify("Updater ready. Dùng hàm checkUpdate() để kiểm tra.")
end
