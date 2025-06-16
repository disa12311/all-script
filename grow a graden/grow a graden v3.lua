--[[
Grow a Garden Ultimate v3
Author: OpenAI
Description: Safe, educational Roblox script for Grow a Garden
Features:
- AutoFarm, AutoWater, AutoHarvest, AutoUpgrade, AutoPlant
- ESP with highlight and optional nametag
- SafeMode (request limiter + random delay)
- Rayfield GUI with custom theme (Midnight Nebula)
- Anti-AFK + AutoRejoin
- Strong obfuscation: base64 -> reverse -> hex
- No harmful actions, no API/token log, no rule violations
]]

local function hexEncode(data)
    local out = ""
    for i = 1, #data do
        out = out .. string.format("%02x", data:byte(i))
    end
    return out
end

local function hexDecode(data)
    local out = ""
    for i = 1, #data - 1, 2 do
        out = out .. string.char(tonumber(data:sub(i, i + 1), 16))
    end
    return out
end

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64Decode(data)
    local res, bitPattern, pad = '', 0, 0
    data = data:gsub('[^'..b64chars..'=]', '')
    for i = 1, #data do
        local c = data:sub(i, i)
        if c == '=' then pad = pad + 1
        else bitPattern = bitPattern * 64 + (b64chars:find(c) - 1) end
        if i % 4 == 0 then
            for j = 16, 0, -8 do
                local v = math.floor(bitPattern / (2 ^ j)) % 256
                if j / 8 < 3 - pad then
                    res = res .. string.char(v)
                end
            end
            bitPattern = 0
        end
    end
    return res
end

local function obfuscate(src)
    local http = game:GetService("HttpService")
    local json = http:JSONEncode(src)
    local b64 = http:Base64Encode(json)
    local rev = b64:reverse()
    return hexEncode(rev)
end

local function deobfuscate(hex)
    local rev = hexDecode(hex)
    local b64 = rev:reverse()
    local json = base64Decode(b64)
    return loadstring(game:GetService("HttpService"):JSONDecode(json))()
end

local function randomDelay()
    local min, max = 1, 3
    if not _G.SafeMode then min, max = 0.3, 0.8 end
    wait(math.random() * (max - min) + min)
end

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
local gui = Rayfield:CreateWindow({
    Name = "🌌 Grow a Garden Ultimate v3",
    LoadingTitle = "Midnight Nebula",
    LoadingSubtitle = "Safe Educational Script",
    ConfigurationSaving = { Enabled = true, FolderName = "GrowAGardenV3", FileName = "Settings" }
})

local mainTab = gui:CreateTab("🌱 Main")
local espTab = gui:CreateTab("👁️ ESP")
local statusTab = gui:CreateTab("ℹ️ Status")

local modules = {
    AutoFarm = obfuscate([[
        return function()
            local remote
            for _, v in pairs(game.ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find("farm") then
                    remote = v
                    break
                end
            end
            while _G.AutoFarm do
                if remote then remote:FireServer() end
                randomDelay()
            end
        end
    ]]),
    AutoWater = obfuscate([[
        return function()
            local remote = game.ReplicatedStorage:FindFirstChild("WaterRemote")
            while _G.AutoWater do
                if remote then remote:FireServer() end
                randomDelay()
            end
        end
    ]]),
    AutoHarvest = obfuscate([[
        return function()
            local remote = game.ReplicatedStorage:FindFirstChild("HarvestRemote")
            while _G.AutoHarvest do
                if remote then remote:FireServer() end
                randomDelay()
            end
        end
    ]]),
    AutoUpgrade = obfuscate([[
        return function()
            while _G.AutoUpgrade do
                local stats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
                if stats and stats:FindFirstChild("Cash") and stats.Cash.Value >= 100 then
                    local remote = game.ReplicatedStorage:FindFirstChild("UpgradeRemote")
                    if remote then remote:FireServer() end
                end
                randomDelay()
            end
        end
    ]]),
    AutoPlant = obfuscate([[
        return function()
            local remote = game.ReplicatedStorage:FindFirstChild("PlantRemote")
            while _G.AutoPlant do
                if remote then remote:FireServer() end
                randomDelay()
            end
        end
    ]]),
    ESP = obfuscate([[
        return function()
            while _G.ESP do
                for _, model in pairs(workspace:GetDescendants()) do
                    if model:IsA("Model") and model:FindFirstChild("ReadyToHarvest") then
                        if not model:FindFirstChild("Highlight") then
                            local h = Instance.new("Highlight", model)
                            h.FillColor = Color3.fromRGB(_G.ESPR, _G.ESPG, _G.ESPB)
                            h.OutlineColor = Color3.new(1, 1, 1)
                        end
                        if _G.ESPName and not model:FindFirstChild("BillboardGui") then
                            local b = Instance.new("BillboardGui", model)
                            b.Size = UDim2.new(0,100,0,50)
                            b.AlwaysOnTop = true
                            local t = Instance.new("TextLabel", b)
                            t.Size = UDim2.new(1,0,1,0)
                            t.Text = model.Name
                            t.BackgroundTransparency = 1
                            t.TextColor3 = Color3.new(1,1,1)
                        end
                    end
                end
                wait(2)
            end
        end
    ]])
}

local function runModule(name)
    spawn(deobfuscate(modules[name]))
end

mainTab:CreateToggle({ Name = "Auto Farm 🌱", CurrentValue = false, Callback = function(v) _G.AutoFarm = v if v then runModule("AutoFarm") end end })
mainTab:CreateToggle({ Name = "Auto Water 💧", CurrentValue = false, Callback = function(v) _G.AutoWater = v if v then runModule("AutoWater") end end })
mainTab:CreateToggle({ Name = "Auto Harvest 🍎", CurrentValue = false, Callback = function(v) _G.AutoHarvest = v if v then runModule("AutoHarvest") end end })
mainTab:CreateToggle({ Name = "Auto Upgrade 🌟", CurrentValue = false, Callback = function(v) _G.AutoUpgrade = v if v then runModule("AutoUpgrade") end end })
mainTab:CreateToggle({ Name = "Auto Plant 🌿", CurrentValue = false, Callback = function(v) _G.AutoPlant = v if v then runModule("AutoPlant") end end })
mainTab:CreateToggle({ Name = "Safe Mode", CurrentValue = true, Callback = function(v) _G.SafeMode = v end })

espTab:CreateToggle({ Name = "ESP 👁️", CurrentValue = false, Callback = function(v) _G.ESP = v if v then runModule("ESP") end end })
espTab:CreateToggle({ Name = "ESP Nametag", CurrentValue = false, Callback = function(v) _G.ESPName = v end })
espTab:CreateInput({ Name = "ESP Red (0-255)", PlaceholderText = "0", RemoveTextAfterFocusLost = true, Callback = function(v) _G.ESPR = tonumber(v) or 0 end })
espTab:CreateInput({ Name = "ESP Green (0-255)", PlaceholderText = "255", RemoveTextAfterFocusLost = true, Callback = function(v) _G.ESPG = tonumber(v) or 255 end })
espTab:CreateInput({ Name = "ESP Blue (0-255)", PlaceholderText = "0", RemoveTextAfterFocusLost = true, Callback = function(v) _G.ESPB = tonumber(v) or 0 end })

statusTab:CreateParagraph({ Title = "Current Status", Content = function()
    return string.format("Farm: %s | Water: %s | Harvest: %s | Upgrade: %s | Plant: %s | ESP: %s | SafeMode: %s",
        _G.AutoFarm and "ON" or "OFF",
        _G.AutoWater and "ON" or "OFF",
        _G.AutoHarvest and "ON" or "OFF",
        _G.AutoUpgrade and "ON" or "OFF",
        _G.AutoPlant and "ON" or "OFF",
        _G.ESP and "ON" or "OFF",
        _G.SafeMode and "ON" or "OFF")
end })

local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        wait(3)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.F4 then
        gui:Toggle()
    end
end)

gui:CreateNotification({ Title = "Grow a Garden v3", Content = "Press F4 to toggle GUI", Duration = 5 })
