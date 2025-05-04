--[[
Script Name: studio
Version: beta v4.5
Author: Lua vip pro vn (Refinements - Logging and minor cleanup)
Description: Client-side script for Natural Disaster Survival
             to create and modify a block via GUI.
             Runs with an executor.
             Includes a simple logging system and minor code refinements.
--]]

-- Cache frequently used global functions, services, and constructors into local variables
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Instance_new = Instance.new
local math_clamp = math.clamp
local tonumber = tonumber
local tostring = tostring
local print_global = print -- Cache original print
local warn_global = warn   -- Cache original warn
local typeof = typeof
local pairs = pairs       -- Cache pairs for loops

local Vector3_new = Vector3.new
local UDim2_new = UDim2.new
local CFrame_new = CFrame.new
local Color3_new = Color3.new -- Cache Color3.new

-- === Simple Logging System ===
-- A basic local table to handle structured logging
local Log = {}
local LOG_PREFIX = "[Studio v4.5] " -- Prefix for all log messages

function Log.Info(message)
    print_global(LOG_PREFIX .. tostring(message)) -- Use cached print and tostring
end

function Log.Warn(message)
    warn_global(LOG_PREFIX .. tostring(message)) -- Use cached warn and tostring
end

function Log.Error(message)
    -- In a real scenario, you might want to add more robust error handling here
    error(LOG_PREFIX .. tostring(message)) -- Use global error for critical issues
end

-- Override global print and warn if desired (optional, generally better to use Log table explicitly)
-- print = Log.Info
-- warn = Log.Warn


-- Configuration (Easy to adjust values)
local GUI_WIDTH = 250
local GUI_START_POS_Y = 30 -- Starting Y position for GUI elements below title
local ELEMENT_HEIGHT = 25 -- Standard height for textboxes and buttons
local LABEL_HEIGHT = 20 -- Standard height for labels
local SPACING = 5 -- Vertical spacing between elements
local MOVE_INCREMENT = 1 -- How much to move the block per button click
local INITIAL_BLOCK_SIZE = Vector3_new(4, 4, 4)
local INITIAL_BLOCK_COLOR = Color3_new(1, 0, 0) -- Red
local TOGGLE_KEY_CODE = Enum.KeyCode.RightControl -- Key to toggle GUI visibility
local BLOCK_SIZE_LIMITS = {min = 0.1, max = 1000} -- Min/Max limits for block size input


-- Variables
local createdBlock = nil -- Holds the reference to our created block Part

-- === GUI Setup ===

-- Check for and destroy existing GUI to prevent duplicates if script is re-executed
local guiName = "StudioGUI_v4_5"
local existingGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(guiName) -- Use cached Players
if existingGui then
    Log.Warn("Found existing GUI '" .. guiName .. "', destroying it.") -- Use Log.Warn
    existingGui:Destroy()
end

local screenGui = Instance_new("ScreenGui") -- Use cached Instance_new
screenGui.Name = guiName
screenGui.Parent = Players.LocalPlayer.PlayerGui -- Use cached Players

local mainFrame = Instance_new("Frame") -- Use cached Instance_new
mainFrame.Size = UDim2_new(0, GUI_WIDTH, 0, 0) -- Use cached UDim2_new
mainFrame.Position = UDim2_new(0.5, -GUI_WIDTH/2, 0.5, -200) -- Use cached UDim2_new
mainFrame.BackgroundColor3 = Color3_new(0.15, 0.15, 0.15) -- Use cached Color3_new
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true -- Make the GUI draggable
mainFrame.Parent = screenGui -- Parent the mainFrame


-- === Dedicated GUI Helper Functions ===

-- Helper to create a basic TextLabel
local function createLabel(parent, text, positionY, config)
    local label = Instance_new("TextLabel") -- Use cached Instance_new
    label.Size = config and config.Size or UDim2_new(1, 0, 0, LABEL_HEIGHT) -- Use cached UDim2_new
    label.Position = config and config.Position or UDim2_new(0, 0, 0, positionY) -- Use cached UDim2_new
    label.Text = text
    label.TextColor3 = config and config.TextColor3 or Color3_new(0.8, 0.8, 0.8) -- Use cached Color3_new
    label.BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0, 0, 0, 0) -- Use cached Color3_new
    label.BorderSizePixel = 0
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = config and config.TextSize or 15
    label.TextXAlignment = config and config.TextXAlignment or Enum.TextXAlignment.Left
    label.TextInsets = config and config.TextInsets or UDimInsets.new(5, 0, 0, 0) -- UDimInsets.new doesn't need caching unless in a tight loop
    label.Parent = parent
    return label
end

-- Helper to create a basic TextBox
local function createTextBox(parent, placeholder, initialText, positionY, size, config)
    local textBox = Instance_new("TextBox") -- Use cached Instance_new
    textBox.Size = size or UDim2_new(1, -10, 0, ELEMENT_HEIGHT) -- Use cached UDim2_new
    textBox.Position = config and config.Position or UDim2_new(0, 5, 0, positionY) -- Use cached UDim2_new
    textBox.PlaceholderText = placeholder
    textBox.Text = initialText or ""
    textBox.BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0.3, 0.3, 0.3) -- Use cached Color3_new
    textBox.TextColor3 = config and config.TextColor3 or Color3_new(1, 1, 1) -- Use cached Color3_new
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = config and config.TextSize or 15
    textBox.Parent = parent
    return textBox
end

-- Helper to create a basic TextButton
local function createButton(parent, text, positionY, size, config)
    local button = Instance_new("TextButton") -- Use cached Instance_new
    button.Size = size or UDim2_new(1, -10, 0, ELEMENT_HEIGHT) -- Use cached UDim2_new
    button.Position = config and config.Position or UDim2_new(0, 5, 0, positionY) -- Use cached UDim2_new
    button.Text = text
    button.TextColor3 = config and config.TextColor3 or Color3_new(1, 1, 1) -- Use cached Color3_new
    button.BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0.2, 0.5, 0.8) -- Use cached Color3_new (Blueish)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = config and config.TextSize or 16
    button.Parent = parent
    return button
end


local currentY = GUI_START_POS_Y -- Track current Y position for element placement

-- === Refactored GUI Element Creation using Helpers ===

-- Title Label (created separately as it's at the top)
createLabel(mainFrame, "Studio Block Editor v4.5", 0, {
    Size = UDim2_new(1, 0, 0, 30), -- Use cached UDim2_new
    BackgroundColor3 = Color3_new(0.25, 0.25, 0.25), -- Use cached Color3_new
    TextColor3 = Color3_new(0.9, 0.9, 0.9), -- Use cached Color3_new
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextInsets = UDimInsets.new(0, 0, 0, 0) -- UDimInsets.new doesn't need caching
})


-- Size Controls
createLabel(mainFrame, "Size (X, Y, Z):", currentY)
currentY = currentY + LABEL_HEIGHT + SPACING

local sizeTextBoxes = {} -- Store textboxes for easier event connection

local sizeAxes = {"X", "Y", "Z"}
local initialSizes = {
    X = INITIAL_BLOCK_SIZE.X,
    Y = INITIAL_BLOCK_SIZE.Y,
    Z = INITIAL_BLOCK_SIZE.Z
}

for i, axis in pairs(sizeAxes) do -- Use cached pairs
    local textBox = createTextBox(mainFrame, "Size " .. axis, tostring(initialSizes[axis]), currentY) -- Use cached tostring
    sizeTextBoxes[axis] = textBox -- Store in table
    currentY = currentY + ELEMENT_HEIGHT + SPACING
end

-- Color Controls
createLabel(mainFrame, "Color (R, G, B 0-1):", currentY)
currentY = currentY + LABEL_HEIGHT + SPACING

local colorTextBoxes = {} -- Store textboxes for easier event connection

local colorChannels = {"R", "G", "B"}
local initialColors = {
    R = INITIAL_BLOCK_COLOR.R,
    G = INITIAL_BLOCK_COLOR.G,
    B = INITIAL_BLOCK_COLOR.B
}

local colorTextBoxWidth = (GUI_WIDTH - 10 - SPACING*2) / 3

for i, channel in pairs(colorChannels) do -- Use cached pairs
    local textBox = createTextBox(mainFrame, "Color " .. channel, tostring(initialColors[channel]), currentY, UDim2_new(0, colorTextBoxWidth, 0, ELEMENT_HEIGHT), { -- Use cached tostring, UDim2_new
        Position = UDim2_new(0, 5 + (i-1) * (colorTextBoxWidth + SPACING), 0, currentY) -- Use cached UDim2_new
    })
    colorTextBoxes[channel] = textBox -- Store in table
end
currentY = currentY + ELEMENT_HEIGHT + SPACING -- Move Y down after the row of color textboxes

-- Movement Controls
createLabel(mainFrame, "Move (Increment " .. MOVE_INCREMENT .. "):", currentY)
currentY = currentY + LABEL_HEIGHT + SPACING

local moveButtonWidth = (GUI_WIDTH - 10 - SPACING*2) / 3 -- 3 buttons per row

local moveButtonsData = {
    { text = "-Z (Fwd)", vector = Vector3_new(0, 0, -1), row = 0, col = 0 }, -- Use cached Vector3_new
    { text = "+Y (Up)", vector = Vector3_new(0, 1, 0), row = 0, col = 1 },    -- Use cached Vector3_new
    { text = "+Z (Back)", vector = Vector3_new(0, 0, 1), row = 0, col = 2 }, -- Use cached Vector3_new
    { text = "-X (Left)", vector = Vector3_new(-1, 0, 0), row = 1, col = 0 },-- Use cached Vector3_new
    { text = "-Y (Down)", vector = Vector3_new(0, -1, 0), row = 1, col = 1 },-- Use cached Vector3_new
    { text = "+X (Right)", vector = Vector3_new(1, 0, 0), row = 1, col = 2 },-- Use cached Vector3_new
}

local maxRows = 0
for _, data in pairs(moveButtonsData) do -- Use cached pairs
    local button = createButton(mainFrame, data.text, currentY + data.row * (ELEMENT_HEIGHT + SPACING), UDim2_new(0, moveButtonWidth, 0, ELEMENT_HEIGHT), { -- Use cached UDim2_new
        Position = UDim2_new(0, 5 + data.col * (moveButtonWidth + SPACING), 0, currentY + data.row * (ELEMENT_HEIGHT + SPACING)) -- Use cached UDim2_new
    })
    -- Store the vector data directly in the button for easy access in the event handler
    button.Tag = data.vector
    -- Track max row to update currentY after loop
    maxRows = math.max(maxRows, data.row) -- math.max is used only once, caching is minimal benefit but harmless
end
currentY = currentY + (maxRows + 1) * (ELEMENT_HEIGHT + SPACING)

-- Action Buttons
local createBlockButton = createButton(mainFrame, "Create Block", currentY, UDim2_new(1, -10, 0, 30), { -- Use cached UDim2_new
    BackgroundColor3 = Color3_new(0.3, 0.6, 0.3) -- Use cached Color3_new (Greenish)
})
currentY = currentY + 30 + SPACING

local removeBlockButton = createButton(mainFrame, "Remove Block", currentY, UDim2_new(1, -10, 0, 30), { -- Use cached UDim2_new
    BackgroundColor3 = Color3_new(0.6, 0.3, 0.3) -- Use cached Color3_new (Reddish)
})
currentY = currentY + 30 + SPACING


-- Adjust frame size dynamically based on element placement
mainFrame.Size = UDim2_new(0, GUI_WIDTH, 0, currentY) -- Use cached UDim2_new


-- === Block Functionality ===

-- Function to safely get a number from a textbox, with optional min/max clamp
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local num = tonumber(textBox.Text) -- Use cached tonumber
    if num == nil then
        Log.Warn("Invalid number input in textbox: '" .. (textBox.Name or textBox.PlaceholderText) .. "'. Using default value: " .. tostring(defaultValue)) -- Use Log.Warn and cached tostring
        return defaultValue
    end
    -- Apply clamp if min/max values are provided
    if minValue ~= nil and maxValue ~= nil then
        num = math_clamp(num, minValue, maxValue) -- Use cached math_clamp
    end
    return num
end

-- Function to create the block
local function createNewBlock()
    -- Remove existing block if any
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy() -- Destroy is a method call
        createdBlock = nil
        Log.Info("Removed existing block.") -- Use Log.Info
    end

    -- Create a new part
    createdBlock = Instance_new("Part") -- Use cached Instance_new
    createdBlock.Anchored = true         -- Keep it in place unless we move it
    createdBlock.CanCollide = false      -- Don't want it blocking players typically
    createdBlock.Parent = Workspace      -- Use cached Workspace service
    Log.Info("Created new block.") -- Use Log.Info

    -- Apply initial properties from text boxes using the refactored textboxes table
    local sizeX = getNumberFromTextBox(sizeTextBoxes.X, INITIAL_BLOCK_SIZE.X, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, INITIAL_BLOCK_SIZE.Y, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, INITIAL_BLOCK_SIZE.Z, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    createdBlock.Size = Vector3_new(sizeX, sizeY, sizeZ) -- Use cached Vector3_new

    local colorR = getNumberFromTextBox(colorTextBoxes.R, INITIAL_BLOCK_COLOR.R, 0, 1)
    local colorG = getNumberFromTextBox(colorTextBoxes.G, INITIAL_BLOCK_COLOR.G, 0, 1)
    local colorB = getNumberFromTextBox(colorTextBoxes.B, INITIAL_BLOCK_COLOR.B, 0, 1)
    createdBlock.Color = Color3_new(colorR, colorG, colorB) -- Use cached Color3_new

    -- Position the block slightly in front of the player's head
    -- Added wait for character and primary part for robustness
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() -- Use cached Players
    if character then
        local primaryPart = character:FindFirstChild("HumanoidRootPart")
        if primaryPart then
             -- Place relative to character's HumanoidRootPart
            createdBlock.CFrame = CFrame_new(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3_new(0, 5, 0)) -- Use cached CFrame_new, Vector3_new
            Log.Info("Placed block near player.") -- Use Log.Info
        else
            Log.Warn("HumanoidRootPart not found, placing block at origin.") -- Use Log.Warn
            createdBlock.CFrame = CFrame_new(0, 10, 0) -- Fallback position, use cached CFrame_new
        end
    else
        Log.Warn("Character not found, placing block at origin.") -- Use Log.Warn
        createdBlock.CFrame = CFrame_new(0, 10, 0) -- Fallback position, use cached CFrame_new
    end
end

-- Function to update block size from textboxes
local function updateBlockSize()
    if createdBlock and createdBlock.Parent then
        local sizeX = getNumberFromTextBox(sizeTextBoxes.X, createdBlock.Size.X, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, createdBlock.Size.Y, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, createdBlock.Size.Z, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        createdBlock.Size = Vector3_new(sizeX, sizeY, sizeZ) -- Use cached Vector3_new
        Log.Info("Updated block size.") -- Use Log.Info
    end
end

-- Function to update block color from textboxes
local function updateBlockColor()
    if createdBlock and createdBlock.Parent then
        local colorR = getNumberFromTextBox(colorTextBoxes.R, createdBlock.Color.R, 0, 1)
        local colorG = getNumberFromTextBox(colorTextBoxes.G, createdBlock.Color.G, 0, 1)
        local colorB = getNumberFromTextBox(colorTextBoxes.B, createdBlock.Color.B, 0, 1)
        createdBlock.Color = Color3_new(colorR, colorG, colorB) -- Use cached Color3_new
        Log.Info("Updated block color.") -- Use Log.Info
    end
end

-- Function to move the block by a vector (relative to block's local axes)
local function moveBlock(directionVector)
    if createdBlock and createdBlock.Parent then
        -- Move relative to the block's current CFrame, multiplied by the increment
        createdBlock.CFrame = createdBlock.CFrame * CFrame_new(directionVector * MOVE_INCREMENT) -- Use cached CFrame_new
        -- Log.Info("Moved block by " .. tostring(directionVector)) -- Optional: Log every move
    end
end

-- === Event Connections ===

-- Connect FocusLost for Size and Color TextBoxes using loops
for _, textBox in pairs(sizeTextBoxes) do -- Use cached pairs
    textBox.FocusLost:Connect(updateBlockSize) -- Connect is a method call
end

for _, textBox in pairs(colorTextBoxes) do -- Use cached pairs
     textBox.FocusLost:Connect(updateBlockColor)
end

-- Connect MouseButton1Click for Action Buttons
createBlockButton.MouseButton1Click:Connect(createNewBlock)
removeBlockButton.MouseButton1Click:Connect(function()
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
        Log.Info("Removed block via GUI.") -- Use Log.Info
    end
end)

-- Connect MouseButton1Click for Movement Buttons using a loop
local movementButtons = mainFrame:GetChildren() -- GetChildren is a method call
for _, button in pairs(movementButtons) do -- Use cached pairs
    -- Check if the child is a TextButton and has the Vector3 Tag we added
    if button:IsA("TextButton") and button.Tag and typeof(button.Tag) == "Vector3" then -- Use cached typeof, IsA is a method call
        button.MouseButton1Click:Connect(function()
            moveBlock(button.Tag) -- Use the stored vector from the button's Tag
        end)
    end
end


-- Optional: Add a keybind to toggle GUI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent) -- Use cached UserInputService
    -- Check if the input is the toggle key and it's not processed by the game
    if input.KeyCode == TOGGLE_KEY_CODE and not gameProcessedEvent then
        mainFrame.Visible = not mainFrame.Visible -- Visible is a property
        Log.Info("GUI visibility toggled.") -- Use Log.Info
    end
end)

-- Inform user that the script is loaded
Log.Info("Script beta v4.5 loaded. Press " .. TOGGLE_KEY_CODE.Name .. " to toggle GUI.") -- Use Log.Info
