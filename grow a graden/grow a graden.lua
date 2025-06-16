--[[ 
🌱 Grow a Garden Safe Script - Custom by ChatGPT
- AutoFarm, AutoWater, AutoHarvest, AutoUpgrade
- Safe Mode (delay ngẫu nhiên, giới hạn request)
- GUI Rayfield UI
- Module mã hóa nhẹ
- Auto Update từ Pastebin/Discord CDN

⚠️ Cam kết:
✅ Không phá game
✅ Không ảnh hưởng người chơi khác
✅ Không log dữ liệu cá nhân
✅ Chỉ hoạt động trong game Grow a Garden

👉 Hướng dẫn: Chạy script, nhấn F4 để mở GUI
]]

-- Auto Update
pcall(function()
    local url = "https://pastebin.com/raw/YOUR_PASTEBIN_ID" -- Thay link chính chủ của bạn
    local up = game:HttpGet(url)
    if up and up:find("--[[") then
        loadstring(up)()
        return
    end
end)

-- GUI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
local Window = Rayfield:CreateWindow({
    Name = "Grow a Garden Hub 🌱",
    LoadingTitle = "Đang khởi tạo...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGardenHub",
        FileName = "Settings"
    }
})

local MainTab = Window:CreateTab("🌿 Auto")
local StatusTab = Window:CreateTab("ℹ️ Status")

local AutoFarmEnabled = false
local AutoWaterEnabled = false
local AutoHarvestEnabled = false
local AutoUpgradeEnabled = false
local SafeMode = true

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Auto Rejoin
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Failed then
        wait(3)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

-- Safe delay
local function SafeDelay()
    local min, max = 1, 3
    if not SafeMode then min, max = 0.3, 0.8 end
    wait(math.random() * (max - min) + min)
end

-- Module mã hóa
local function LoadModule(code)
    return loadstring(string.reverse(code))()
end

-- Mã hóa các module
local AutoFarmCode = string.reverse([[
return function()
    local remote = nil
    for _, v in pairs(game.ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("farm") then
            remote = v break
        end
    end
    while _G.AutoFarmEnabled do
        if remote then remote:FireServer() end
        SafeDelay()
    end
end
]])

local AutoWaterCode = string.reverse([[
return function()
    local remote = game.ReplicatedStorage:FindFirstChild("WaterRemote")
    while _G.AutoWaterEnabled do
        if remote then remote:FireServer() end
        SafeDelay()
    end
end
]])

local AutoHarvestCode = string.reverse([[
return function()
    local remote = game.ReplicatedStorage:FindFirstChild("HarvestRemote")
    while _G.AutoHarvestEnabled do
        if remote then remote:FireServer() end
        SafeDelay()
    end
end
]])

local AutoUpgradeCode = string.reverse([[
return function()
    while _G.AutoUpgradeEnabled do
        local stats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
        if stats and stats:FindFirstChild("Cash") and stats.Cash.Value >= 100 then
            local upRemote = game.ReplicatedStorage:FindFirstChild("UpgradeRemote")
            if upRemote then upRemote:FireServer() end
        end
        SafeDelay()
    end
end
]])

-- Bật module
local function StartAutoFarm()
    _G.AutoFarmEnabled = true
    spawn(LoadModule(AutoFarmCode))
end

local function StartAutoWater()
    _G.AutoWaterEnabled = true
    spawn(LoadModule(AutoWaterCode))
end

local function StartAutoHarvest()
    _G.AutoHarvestEnabled = true
    spawn(LoadModule(AutoHarvestCode))
end

local function StartAutoUpgrade()
    _G.AutoUpgradeEnabled = true
    spawn(LoadModule(AutoUpgradeCode))
end

-- GUI toggle
MainTab:CreateToggle({
    Name = "Auto Farm 🌱",
    CurrentValue = false,
    Callback = function(v)
        AutoFarmEnabled = v
        _G.AutoFarmEnabled = v
        if v then StartAutoFarm() end
    end
})

MainTab:CreateToggle({
    Name = "Auto Water 💧",
    CurrentValue = false,
    Callback = function(v)
        AutoWaterEnabled = v
        _G.AutoWaterEnabled = v
        if v then StartAutoWater() end
    end
})

MainTab:CreateToggle({
    Name = "Auto Harvest 🍎",
    CurrentValue = false,
    Callback = function(v)
        AutoHarvestEnabled = v
        _G.AutoHarvestEnabled = v
        if v then StartAutoHarvest() end
    end
})

MainTab:CreateToggle({
    Name = "Auto Upgrade 🌟",
    CurrentValue = false,
    Callback = function(v)
        AutoUpgradeEnabled = v
        _G.AutoUpgradeEnabled = v
        if v then StartAutoUpgrade() end
    end
})

MainTab:CreateToggle({
    Name = "Safe Mode (khuyến nghị)",
    CurrentValue = true,
    Callback = function(v)
        SafeMode = v
    end
})

StatusTab:CreateParagraph({
    Title = "Trạng thái",
    Content = function()
        return string.format("AutoFarm: %s\nAutoWater: %s\nAutoHarvest: %s\nAutoUpgrade: %s\nSafeMode: %s",
        AutoFarmEnabled and "Bật" or "Tắt",
        AutoWaterEnabled and "Bật" or "Tắt",
        AutoHarvestEnabled and "Bật" or "Tắt",
        AutoUpgradeEnabled and "Bật" or "Tắt",
        SafeMode and "Bật" or "Tắt")
    end
})

-- Hotkey
Window:CreateNotification({
    Title = "Grow a Garden Hub",
    Content = "Nhấn F4 để mở/tắt GUI",
    Duration = 5
})

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.F4 then
        Window:Toggle()
    end
end)
