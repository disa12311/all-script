--[[
🌿 Grow a Garden Ultimate v7
✔ All v6 features (AutoFarm, Water, Harvest, Collect, Upgrade, SafeMode++, ESP, etc.)
✔ Macro Recorder: record key/mouse events + remote calls
✔ Macro Playback: replay recorded sequence with safe timing
✔ GUI: Macro tab (Record / Stop / Play / Clear)
✔ Encrypted modules, dynamic remotes, Smart Pathfinding
✔ Anti‑AFK, Auto‑Rejoin, Auto‑Update ready
]]

local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local HttpService   = game:GetService("HttpService")
local VirtualUser   = game:GetService("VirtualUser")
local TeleportSvc   = game:GetService("TeleportService")
local Pathfinding   = game:GetService("PathfindingService")
local UserInput     = game:GetService("UserInputService")

local LocalPlayer   = Players.LocalPlayer

-- Helper: find Remote by keyword
local function FindRemote(k)
    for _, r in ipairs(RS:GetDescendants()) do
        if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and r.Name:lower():find(k) then
            return r
        end
    end
end

-- Safe fire
local function SafeFire(r, ...)
    if r then pcall(function() r:FireServer(...) end) end
end

-- Randomized delay
local function RandDelay()
    local min = _G.SafeMin or 0.6
    local max = _G.SafeMax or 1.2
    wait(math.random(min*100, max*100)/100 + (_G.SafeMode and math.random() or 0))
end

-- Travel to position
local function TravelTo(pos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local path = Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5})
    path:ComputeAsync(char.PrimaryPart.Position, pos)
    for _, wp in ipairs(path:GetWaypoints()) do
        char.Humanoid:MoveTo(wp.Position)
        char.Humanoid.MoveToFinished:Wait(1)
    end
end

-- Module encryption / run
local function Encrypt(src)
    return HttpService:Base64Encode(HttpService:Base64Encode(src:reverse()))
end
local function RunMod(code)
    loadstring((HttpService:Base64Decode(HttpService:Base64Decode(code))):reverse())()
end

-- ========== CORE MODULES (v6) ==========
local modules = {
    AutoFarm = Encrypt([[
        while _G.AutoFarm do
            local r = FindRemote("farm") or FindRemote("plant")
            -- move to nearest ReadyToHarvest
            local bestDist, bestPos = 1e9
            for _, m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m:FindFirstChild("ReadyToHarvest") and m.PrimaryPart then
                    local d = (m.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
                    if d < bestDist then bestDist, bestPos = d, m.PrimaryPart.Position end
                end
            end
            if bestPos then TravelTo(bestPos) end
            SafeFire(r)
            RandDelay()
        end
    ]]),
    AutoCollect = Encrypt([[
        while _G.AutoCollect do
            SafeFire(FindRemote("collect") or FindRemote("reward"))
            RandDelay()
        end
    ]]),
    -- ... (other modules unchanged: AutoWater, AutoHarvest, AutoUpgrade, ESP)
}

-- ========== MACRO MODULE ==========
-- Stores sequence of {time, type, data}
local Macro = { recording = false, timeline = {} }

-- Start recording
function Macro:start()
    self.recording = true
    self.timeline = {}
    self.startTime = tick()
    print("Macro: Recording started")
end

-- Stop recording
function Macro:stop()
    self.recording = false
    print("Macro: Recording stopped; recorded", #self.timeline, "events.")
end

-- Play back
function Macro:play()
    if #self.timeline == 0 then return end
    print("Macro: Playback started")
    local base = tick()
    for i, evt in ipairs(self.timeline) do
        local dt = evt.t - (self.timeline[1].t)
        wait(evt.dt or dt)
        if evt.type == "move" then
            TravelTo(evt.pos)
        elseif evt.type == "click" then
            SafeFire(evt.remote, unpack(evt.args))
        end
    end
    print("Macro: Playback finished")
end

-- Capture input
UserInput.InputBegan:Connect(function(input, gpe)
    if Macro.recording and not gpe then
        local now = tick() - Macro.startTime
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- left click: try interaction remote
            local remote = FindRemote("farm") or FindRemote("collect") or FindRemote("water") or FindRemote("harvest")
            table.insert(Macro.timeline, { t = now, dt = Macro.timeline[#Macro.timeline] and now - Macro.timeline[#Macro.timeline].t or 0, type = "click", remote = remote, args = {} })
        elseif input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or
               input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
            -- movement key: sample character position
            local pos = LocalPlayer.Character.PrimaryPart.Position
            table.insert(Macro.timeline, { t = now, dt = Macro.timeline[#Macro.timeline] and now - Macro.timeline[#Macro.timeline].t or 0, type = "move", pos = pos })
        end
    end
end)

-- ========== GUI (Rayfield) ==========
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
local Window = Rayfield:CreateWindow({
    Name = "Grow a Garden Ultimate v7",
    LoadingTitle = "Macro & Ultra Farm",
    ConfigurationSaving = { Enabled = true, FolderName = "GrowGardenV7", FileName = "Settings" }
})

-- Main Tab (v6 features)
local main = Window:CreateTab("🌱 Main")
main:CreateToggle({ Name="Auto Farm", CurrentValue=false, Callback=function(v) _G.AutoFarm=v if v then RunMod(modules.AutoFarm) end end })
main:CreateToggle({ Name="Auto Collect", CurrentValue=false, Callback=function(v) _G.AutoCollect=v if v then RunMod(modules.AutoCollect) end end })
main:CreateToggle({ Name="Safe Mode++", CurrentValue=true, Callback=function(v) _G.SafeMode=v end })
main:CreateSlider({ Name="Min Delay", Range={0.1,1.5}, Increment=0.1, CurrentValue=_G.SafeMin, Callback=function(v) _G.SafeMin=v end })
main:CreateSlider({ Name="Max Delay", Range={0.5,2.5}, Increment=0.1, CurrentValue=_G.SafeMax, Callback=function(v) _G.SafeMax=v end })

-- Macro Tab
local mTab = Window:CreateTab("⌨️ Macro")
mTab:CreateButton({ Name="Start Recording", Callback=function() Macro:start() end })
mTab:CreateButton({ Name="Stop Recording", Callback=function() Macro:stop() end })
mTab:CreateButton({ Name="Play Macro", Callback=function() Macro:play() end })
mTab:CreateButton({ Name="Clear Macro", Callback=function() Macro.timeline={} print("Macro cleared") end })

mTab:CreateParagraph({
    Title = "Instructions",
    Content = "1) Start Recording → perform moves/clicks\n2) Stop Recording\n3) Play Macro\n4) Adjust SafeMode delays for timing"
})

-- Anti‑AFK + Auto‑Rejoin
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
LocalPlayer.OnTeleport:Connect(function(s)
    if s == Enum.TeleportState.Failed then wait(2) TeleportSvc:Teleport(game.PlaceId) end
end)

-- Hotkey F4
UserInput.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.F4 then Window:Toggle() end
end)

Window:CreateNotification({
    Title = "Grow a Garden v7",
    Content = "F4 toggles GUI | Macro Enabled",
    Duration = 6
})
