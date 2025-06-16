--[[
Refactored Script: Studio Beta v5.0 Improved with Auto-Update
Key Enhancements:
1. Auto-layout via UIListLayout/UIGridLayout
2. ScrollingFrame ready for extension
3. ContextActionService shortcuts (W/S move, Ctrl toggle)
4. Modular StudioBlock & StudioGUI
5. Auto-update from GitHub (HttpService)
--]]

-- Services & Shortcuts
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Constructors
local new = Instance.new
local clamp = math.clamp
local tonumber = tonumber
local tostring = tostring
local warn = warn
local print = print
local loadstring = loadstring

-- Configuration
local Config = {
    GUI_NAME      = "StudioGUI_v5_0_Improved",
    WIDTH         = 280,
    PADDING       = 8,
    SPACING       = 4,
    TITLE_HEIGHT  = 30,
    BUTTON_HEIGHT = 28,
    MOVE_STEP     = 1,
    INIT_SIZE     = Vector3.new(4,4,4),
    INIT_COLOR    = Color3.new(1,0,0),
    KEY_TOGGLE    = Enum.KeyCode.RightControl,
    GITHUB_RAW    = "https://raw.githubusercontent.com/disa12311/studio/main/beta%20v1.0-v9.9/studio%20beta%20v5.0.lua",
    VERSION       = "5.0",
}

-- Logging
local function log(level, msg)
    print(("[%s] %s"):format(level, msg))
end

-- Auto-Update Module
local function checkForUpdate()
    local success, result = pcall(function()
        return HttpService:GetAsync(Config.GITHUB_RAW)
    end)
    if not success then
        warn("Auto-update failed: unable to fetch from GitHub.")
        return
    end
    -- find version in fetched script header
    local remoteVersion = result:match("Version%s*:%s*(%S+)")
    if remoteVersion and remoteVersion ~= Config.VERSION then
        log("INFO", "New version available: "..remoteVersion)
        -- auto-execute updated script
        local fn, err = loadstring(result)
        if fn then
            log("INFO", "Applying update...")
            fn()
        else
            warn("Auto-update load error: "..tostring(err))
        end
    else
        log("INFO", "Already on latest version: "..Config.VERSION)
    end
end

-- StudioBlock Module
local StudioBlock = {}
StudioBlock.__index = StudioBlock
function StudioBlock.new() return setmetatable({block=nil}, StudioBlock) end
function StudioBlock:create(size,color)
    if self.block then self.block:Destroy() end
    local p = new("Part"); p.Anchored=true; p.CanCollide=false; p.Size=size; p.Color=color
    local cf = (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or {CFrame=CFrame.new(0,10,0)}).CFrame
    p.CFrame = cf * CFrame.new(0,5,-10)
    p.Parent = Workspace; self.block=p; log("INFO","Block created.")
end
function StudioBlock:updateSize(size) if self.block then self.block.Size=size; log("INFO","Size updated") end end
function StudioBlock:updateColor(color) if self.block then self.block.Color=color; log("INFO","Color updated") end end
function StudioBlock:move(dir) if self.block then self.block.CFrame=self.block.CFrame*CFrame.new(dir*Config.MOVE_STEP) end end
function StudioBlock:remove() if self.block then self.block:Destroy(); self.block=nil; log("INFO","Block removed") end end

-- StudioGUI Module
local StudioGUI = {}
StudioGUI.__index = StudioGUI
function StudioGUI.new(blocker)
    local self = setmetatable({blocker=blocker}, StudioGUI)
    self:_createGui(); return self
end
function StudioGUI:_createGui()
    local pl = Players.LocalPlayer
    local gui = new("ScreenGui"); gui.Name=Config.GUI_NAME; gui.ResetOnSpawn=false; gui.Parent=pl:WaitForChild("PlayerGui")
    local frame = new("Frame"); frame.Size=UDim2.new(0,Config.WIDTH,0,0); frame.Position=UDim2.new(0.5,-Config.WIDTH/2,0.3,0)
    frame.BackgroundColor3=Color3.fromRGB(30,30,30); frame.BorderSizePixel=0; frame.Parent=gui
    local list = new("UIListLayout"); list.Padding=UDim.new(0,Config.SPACING); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=frame
    local title = new("TextLabel"); title.Text="Studio Block Editor v5.0"; title.Size=UDim2.new(1,0,0,Config.TITLE_HEIGHT)
    title.BackgroundColor3=Color3.fromRGB(50,50,50); title.Font=Enum.Font.SourceSansBold; title.TextSize=18; title.TextColor3=Color3.new(1,1,1); title.Parent=frame
    -- Inputs container
    local inputHolder=new("Frame"); inputHolder.Size=UDim2.new(1,0,0,Config.BUTTON_HEIGHT*2+Config.SPACING); inputHolder.Parent=frame
    local grid=new("UIGridLayout"); grid.CellSize=UDim2.new(1/3,-Config.SPACING,0,Config.BUTTON_HEIGHT); grid.CellPadding=UDim2.new(0,Config.SPACING,0,Config.SPACING); grid.Parent=inputHolder
    self.sizeInputs={self:_makeTextbox(inputHolder,"Size X",tostring(Config.INIT_SIZE.X)),self:_makeTextbox(inputHolder,"Size Y",tostring(Config.INIT_SIZE.Y)),self:_makeTextbox(inputHolder,"Size Z",tostring(Config.INIT_SIZE.Z))}
    self.colorInputs={self:_makeTextbox(inputHolder,"Color R",tostring(Config.INIT_COLOR.R)),self:_makeTextbox(inputHolder,"Color G",tostring(Config.INIT_COLOR.G)),self:_makeTextbox(inputHolder,"Color B",tostring(Config.INIT_COLOR.B))}
    -- Buttons
    self.createBtn=self:_makeButton(frame,"Create Block")
    self.removeBtn=self:_makeButton(frame,"Remove Block")
    self.updateBtn=self:_makeButton(frame,"Check & Apply Update")
    local moveHolder=new("Frame"); moveHolder.Size=UDim2.new(1,0,0,Config.BUTTON_HEIGHT*2); moveHolder.Parent=frame
    local moveGrid=new("UIGridLayout"); moveGrid.CellSize=UDim2.new(1/3,-Config.SPACING,0,Config.BUTTON_HEIGHT); moveGrid.CellPadding=UDim2.new(0,Config.SPACING,0,Config.SPACING); moveGrid.Parent=moveHolder
    self.moveButtons={self:_makeMoveBtn(moveHolder,'Fwd',Vector3.new(0,0,-1)),self:_makeMoveBtn(moveHolder,'Back',Vector3.new(0,0,1)),self:_makeMoveBtn(moveHolder,'Up',Vector3.new(0,1,0)),self:_makeMoveBtn(moveHolder,'Down',Vector3.new(0,-1,0)),self:_makeMoveBtn(moveHolder,'Left',Vector3.new(-1,0,0)),self:_makeMoveBtn(moveHolder,'Right',Vector3.new(1,0,0))}
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() frame.Size=UDim2.new(0,Config.WIDTH,0,list.AbsoluteContentSize+Config.PADDING) end)
    self.guiFrame=frame; self:_bindEvents()
end
function StudioGUI:_makeTextbox(parent,plc,txt)
    local tb=new("TextBox"); tb.PlaceholderText=plc; tb.Text=txt; tb.Font=Enum.Font.SourceSans; tb.TextSize=14; tb.BackgroundColor3=Color3.fromRGB(80,80,80); tb.TextColor3=Color3.new(1,1,1); tb.Parent=parent; return tb
end
function StudioGUI:_makeButton(parent,txt)
    local btn=new("TextButton"); btn.Text=txt; btn.Size=UDim2.new(1,0,0,Config.BUTTON_HEIGHT); btn.Font=Enum.Font.SourceSansBold; btn.TextSize=16; btn.BackgroundColor3=Color3.fromRGB(60,120,60); btn.TextColor3=Color3.new(1,1,1); btn.Parent=parent; return btn
end
function StudioGUI:_makeMoveBtn(parent,txt,vec)
    local b=self:_makeButton(parent,txt); b.Tag=vec; return b
end
function StudioGUI:_bindEvents()
    local sb=self.blocker
    self.createBtn.MouseButton1Click:Connect(function()
        local sx,sy,sz=unpack(self.sizeInputs)
        local cr,cg,cb=unpack(self.colorInputs)
        sb:create(Vector3.new(tonumber(sx.Text),tonumber(sy.Text),tonumber(sz.Text)),Color3.new(tonumber(cr.Text),tonumber(cg.Text),tonumber(cb.Text)))
    end)
    self.removeBtn.MouseButton1Click:Connect(function() sb:remove() end)
    self.updateBtn.MouseButton1Click:Connect(checkForUpdate)
    for _,b in ipairs(self.moveButtons) do b.MouseButton1Click:Connect(function() sb:move(b.Tag) end) end
    UserInputService.InputBegan:Connect(function(input,gp) if input.KeyCode==Config.KEY_TOGGLE and not gp then self.guiFrame.Visible=not self.guiFrame.Visible end end)
    ContextActionService:BindAction("MoveFwd",function() sb:move(Vector3.new(0,0,-1)) end,false,false,Enum.KeyCode.W)
    ContextActionService:BindAction("MoveBack",function() sb:move(Vector3.new(0,0,1)) end,false,false,Enum.KeyCode.S)
end

-- Main
local block=StudioBlock.new()
local gui=StudioGUI.new(block)
-- Initial auto-check without interrupting
spawn(function() checkForUpdate() end)
log("INFO","Studio Beta v5.0 Improved with Auto-Update initialized.")
