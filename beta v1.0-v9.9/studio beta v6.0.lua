local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    VERSION = "6.0",
    GITHUB_RAW = "https://raw.githubusercontent.com/YourUser/YourRepo/main/script.lua",
    AUTO_CHECK = true,
    DEBUG = true
}

local function debugLog(msg)
    if Config.DEBUG then
        warn("[Updater V6.0] " .. tostring(msg))
    end
end

local function notify(title, message, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title or "Updater",
            Text = message or "",
            Duration = duration or 5
        })
    end)
end

local function fetchRemoteVersion()
    local url = Config.GITHUB_RAW .. "?vcheck=" .. tick()
    debugLog("Fetching remote version: " .. url)
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if success and response then
        local ver = response:match('%-%-VERSION%s*:%s*([%d%.]+)')
        if ver then
            debugLog("Remote version: " .. ver)
            return ver
        else
            debugLog("Không tìm thấy VERSION tag trong file.")
        end
    else
        debugLog("Lỗi khi lấy version: " .. tostring(response))
    end
    return nil
end

local function fetchAndRunUpdate()
    local url = Config.GITHUB_RAW .. "?update=" .. tick()
    debugLog("Fetching script update: " .. url)
    local success, code = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if success and code then
        local func = loadstring(code)
        if func then
            notify("Updater", "Đang chạy script mới...", 3)
            debugLog("Script mới được tải và chạy.")
            func()
        else
            notify("Updater", "Loadstring thất bại!", 5)
            debugLog("Loadstring thất bại.")
        end
    else
        notify("Updater", "Không thể tải script mới!", 5)
        debugLog("Không tải được script mới: " .. tostring(code))
    end
end

local function checkUpdate(auto)
    local remoteVer = fetchRemoteVersion()
    if remoteVer then
        if remoteVer ~= Config.VERSION then
            notify("Updater", "Có phiên bản mới: " .. remoteVer, 5)
            fetchAndRunUpdate()
        else
            if not auto then
                notify("Updater", "Bạn đang dùng phiên bản mới nhất!", 5)
            end
            debugLog("Đã up-to-date.")
        end
    else
        notify("Updater", "Không kiểm tra được phiên bản!", 5)
        debugLog("Version check failed.")
    end
end

local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UpdaterGui"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 250, 0, 120)
    frame.Position = UDim2.new(0.5, -125, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0

    local uiCorner = Instance.new("UICorner", frame)
    uiCorner.CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Script Updater v" .. Config.VERSION
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -20, 0.3, 0)
    button.Position = UDim2.new(0, 10, 0.4, 0)
    button.Text = "Check Update"
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.TextScaled = true

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(1, -20, 0.2, 0)
    closeBtn.Position = UDim2.new(0, 10, 0.75, 0)
    closeBtn.Text = "Close"
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.TextScaled = true

    button.MouseButton1Click:Connect(function()
        checkUpdate(false)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

-- Khởi động
if Config.AUTO_CHECK then
    spawn(function()
        wait(1)
        checkUpdate(true)
    end)
end

createGUI()
notify("Updater", "Script v" .. Config.VERSION .. " đã tải!", 3)
debugLog("Script v" .. Config.VERSION .. " đã chạy.")
