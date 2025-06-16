local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local CFG = {
    VERSION = "6.0",
    URL = "https://raw.githubusercontent.com/disa12311/studio/refs/heads/main/beta%20v1.0-v9.9/studio%20beta%20v6.0.lua",
    AUTO = true,
    DEBUG = true
}

local function log(msg)
    if CFG.DEBUG then warn("[Updater 6.0] " .. tostring(msg)) end
end

local function notify(t, m, d)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = t or "Updater",
            Text = m or "",
            Duration = d or 5
        })
    end)
end

local function fetch(url)
    local ok, res = pcall(function() return HttpService:GetAsync(url .. "?t=" .. tick()) end)
    return ok and res or nil
end

local function getRemoteVersion()
    local code = fetch(CFG.URL)
    if code then
        return code:match('%-%-VERSION%s*:%s*([%d%.]+)')
    end
end

local function runUpdate()
    local code = fetch(CFG.URL)
    if code then
        local f = loadstring(code)
        if f then
            notify("Updater", "Đang chạy script mới...", 3)
            log("Script mới chạy thành công.")
            f()
        else
            notify("Updater", "Loadstring thất bại!", 5)
        end
    else
        notify("Updater", "Không tải được script!", 5)
    end
end

local function checkUpdate(auto)
    local remoteVer = getRemoteVersion()
    if remoteVer then
        if remoteVer ~= CFG.VERSION then
            notify("Updater", "Có bản mới: " .. remoteVer, 4)
            runUpdate()
        else
            if not auto then notify("Updater", "Đã là bản mới nhất!", 3) end
            log("Up-to-date.")
        end
    else
        notify("Updater", "Không kiểm tra được version!", 4)
        log("Check version fail.")
    end
end

local function createGUI()
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "UpdaterGui"
    gui.ResetOnSpawn = false

    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0, 250, 0, 110)
    f.Position = UDim2.new(0.5, -125, 0.5, -55)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, 0, 0.3, 0)
    t.Text = "Updater v" .. CFG.VERSION
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1,1,1)
    t.TextScaled = true

    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(1, -20, 0.3, 0)
    b.Position = UDim2.new(0, 10, 0.35, 0)
    b.Text = "Check Update"
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true

    local c = Instance.new("TextButton", f)
    c.Size = UDim2.new(1, -20, 0.25, 0)
    c.Position = UDim2.new(0, 10, 0.7, 0)
    c.Text = "Close"
    c.BackgroundColor3 = Color3.fromRGB(80,30,30)
    c.TextColor3 = Color3.new(1,1,1)
    c.TextScaled = true

    b.MouseButton1Click:Connect(function() checkUpdate(false) end)
    c.MouseButton1Click:Connect(function() gui:Destroy() end)
end

-- Start
if CFG.AUTO then task.spawn(function() wait(1); checkUpdate(true) end) end
createGUI()
notify("Updater", "Đã tải v" .. CFG.VERSION, 3)
log("Đã chạy v" .. CFG.VERSION)
