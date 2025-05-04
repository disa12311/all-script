--[[
Script Name: Studio Beta v5.0
Version: beta v5.0
Author: Lua vip pro vn (Single File Version)
Description: Client-side script for Natural Disaster Survival
             to create and modify a block via GUI.
             Runs as a single file script.
             Merged code from v5.0 modules into one file.
--]]

-- === Cached Global Functions, Services, and Constructors ===
-- Cache frequently used global functions, services, and constructors into local variables
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Instance_new = Instance.new
local math_clamp = math.clamp
local tonumber = tonumber
local tostring_global = tostring
local print_global = print
local warn_global = warn
local error_global = error
local typeof_global = typeof
local pairs_global = pairs
local ipairs_global = ipairs -- Cache ipairs

local Vector3_new = Vector3.new
local UDim2_new = UDim2.new
local CFrame_new = CFrame.new
local Color3_new = Color3.new
local UDimInsets_new = UDimInsets.new

-- === Configuration ===
-- Centralized configuration values for the script

local Config = {
    GUI_WIDTH = 250,
    GUI_START_POS_Y = 30, -- Starting Y position for GUI elements below title
    ELEMENT_HEIGHT = 25,  -- Standard height for textboxes and buttons
    LABEL_HEIGHT = 20,    -- Standard height for labels
    SPACING = 5,          -- Vertical spacing between elements
    MOVE_INCREMENT = 1,   -- How much to move the block per button click
    INITIAL_BLOCK_SIZE = Vector3_new(4, 4, 4),
    INITIAL_BLOCK_COLOR = Color3_new(1, 0, 0), -- Red
    TOGGLE_KEY_CODE = Enum.KeyCode.RightControl, -- Key to toggle GUI visibility
    BLOCK_SIZE_LIMITS = {min = 0.1, max = 1000}, -- Min/Max limits for block size input
    GUI_NAME = "StudioGUI_v5_0_SingleFile", -- Unique GUI name for this version
    LOG_PREFIX = "[Studio v5.0 Single File] " -- Prefix for all log messages
}


-- === Simple Logging System ===
-- A basic local table to handle structured logging
-- Merged from StudioUtils
local Log = {}

function Log.Info(message)
    print_global(Config.LOG_PREFIX .. tostring_global(message))
end

function Log.Warn(message)
    warn_global(Config.LOG_PREFIX .. tostring_global(message))
end

function Log.Error(message)
    -- Use global error to stop execution on critical errors
    error_global(Config.LOG_PREFIX .. tostring_global(message))
end


-- === General Utility Functions ===
-- Merged from StudioUtils

-- Function to safely get a number from a textbox, with optional min/max clamp
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local num = tonumber_global(textBox.Text)
    if num == nil then
        Log.Warn("Invalid number input in textbox: '" .. (textBox.Name or textBox.PlaceholderText or "Unnamed TextBox") .. "'. Using default value: " .. tostring_global(defaultValue))
        return defaultValue
    end
    -- Apply clamp if min/max values are provided
    if minValue ~= nil and maxValue ~= nil then
        num = math_clamp(num, minValue, maxValue)
    end
    return num
end

-- Helper function to create a generic GUI element (used by specific helpers)
local function createElement(elementType, properties)
    local element = Instance_new(elementType)
    for prop, value in pairs_global(properties) do
        element[prop] = value
    end
    return element
end


-- === Block Functionality ===
-- Merged from StudioBlock

local createdBlock = nil -- Holds the reference to our created block Part

local StudioBlock = {} -- Using a local table to group block functions conceptually

function StudioBlock.createNewBlock(sizeTextBoxes, colorTextBoxes) -- Accepts textbox references from GUI logic
    -- Remove existing block if any
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
        Log.Info("Removed existing block.")
    end

    -- Create a new part
    createdBlock = Instance_new("Part")
    createdBlock.Anchored = true
    createdBlock.CanCollide = false
    createdBlock.Parent = Workspace
    Log.Info("Created new block.")

    -- Apply initial properties from text boxes
    local sizeX = getNumberFromTextBox(sizeTextBoxes.X, Config.INITIAL_BLOCK_SIZE.X, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
    local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, Config.INITIAL_BLOCK_SIZE.Y, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
    local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, Config.INITIAL_BLOCK_SIZE.Z, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
    createdBlock.Size = Vector3_new(sizeX, sizeY, sizeZ)

    local colorR = getNumberFromTextBox(colorTextBoxes.R, Config.INITIAL_BLOCK_COLOR.R, 0, 1)
    local colorG = getNumberFromTextBox(colorTextBoxes.G, Config.INITIAL_BLOCK_COLOR.G, 0, 1)
    local colorB = getNumberFromTextBox(colorTextBoxes.B, Config.INITIAL_BLOCK_COLOR.B, 0, 1)
    createdBlock.Color = Color3_new(colorR, colorG, colorB)

    -- Position the block slightly in front of the player's head
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if character then
        local primaryPart = character:FindFirstChild("HumanoidRootPart")
        if primaryPart then
            createdBlock.CFrame = CFrame_new(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3_new(0, 5, 0))
            Log.Info("Placed block near player.")
        else
            Log.Warn("HumanoidRootPart not found, placing block at origin.")
            createdBlock.CFrame = CFrame_new(0, 10, 0) -- Fallback position
        end
    else
        Log.Warn("Character not found, placing block at origin.")
        createdBlock.CFrame = CFrame_new(0, 10, 0) -- Fallback position
    end
end

function StudioBlock.updateBlockSize(sizeTextBoxes) -- Accepts textbox references
    if createdBlock and createdBlock.Parent then
        local sizeX = getNumberFromTextBox(sizeTextBoxes.X, createdBlock.Size.X, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, createdBlock.Size.Y, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, createdBlock.Size.Z, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        createdBlock.Size = Vector3_new(sizeX, sizeY, sizeZ)
        Log.Info("Updated block size.")
    end
end

function StudioBlock.updateBlockColor(colorTextBoxes) -- Accepts textbox references
    if createdBlock and createdBlock.Parent then
        local colorR = getNumberFromTextBox(colorTextBoxes.R, createdBlock.Color.R, 0, 1)
        local colorG = getNumberFromTextBox(colorTextBoxes.G, createdBlock.Color.G, 0, 1)
        local colorB = getNumberFromTextBox(colorTextBoxes.B, createdBlock.Color.B, 0, 1)
        createdBlock.Color = Color3_new(colorR, colorG, colorB)
        Log.Info("Updated block color.")
    end
end

function StudioBlock.moveBlock(directionVector)
    if createdBlock and createdBlock.Parent then
        createdBlock.CFrame = createdBlock.CFrame * CFrame_new(directionVector * Config.MOVE_INCREMENT)
        -- Log.Info("Moved block by " .. tostring_global(directionVector)) -- Optional: Log every move
    end
end

function StudioBlock.removeBlock()
     if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
        Log.Info("Removed block.")
    end
end


-- === GUI Creation and Event Handling ===
-- Merged from StudioGUI

local screenGui = nil
local mainFrame = nil
local sizeTextBoxes = {}
local colorTextBoxes = {}

-- === GUI Helper Functions (More specific helpers) ===
-- Refined helpers using the generic createElement

local function createLabel(parent, text, positionY, config)
    local label = createElement("TextLabel", {
        Size = config and config.Size or UDim2_new(1, 0, 0, Config.LABEL_HEIGHT),
        Position = config and config.Position or UDim2_new(0, 0, 0, positionY),
        Text = text,
        TextColor3 = config and config.TextColor3 or Color3_new(0.8, 0.8, 0.8),
        BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0, 0, 0, 0), -- Transparent
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSansSemibold,
        TextSize = config and config.TextSize or 15,
        TextXAlignment = config and config.TextXAlignment or Enum.TextXAlignment.Left,
        TextInsets = config and config.TextInsets or UDimInsets.new(5, 0, 0, 0),
        Parent = parent
    })
    return label
end

local function createTextBox(parent, placeholder, initialText, positionY, size, config)
    local textBox = createElement("TextBox", {
        Size = size or UDim2_new(1, -10, 0, Config.ELEMENT_HEIGHT),
        Position = config and config.Position or UDim2_new(0, 5, 0, positionY),
        PlaceholderText = placeholder,
        Text = initialText or "",
        BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0.3, 0.3, 0.3),
        TextColor3 = config and config.TextColor3 or Color3_new(1, 1, 1),
        Font = Enum.Font.SourceSans,
        TextSize = config and config.TextSize or 15,
        Parent = parent
    })
    return textBox
end

local function createButton(parent, text, positionY, size, config)
    local button = createElement("TextButton", {
        Size = size or UDim2_new(1, -10, 0, Config.ELEMENT_HEIGHT),
        Position = config and config.Position or UDim2_new(0, 5, 0, positionY),
        Text = text,
        TextColor3 = config and config.TextColor3 or Color3_new(1, 1, 1),
        BackgroundColor3 = config and config.BackgroundColor3 or Color3_new(0.2, 0.5, 0.8), -- Blueish
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSansBold,
        TextSize = config and config.TextSize or 16,
        Parent = parent
    })
    return button
end


-- Function to build the entire GUI and connect events
local function createGUI()
    local LocalPlayer = Players.LocalPlayer

    -- Check for and destroy existing GUI
    local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(Config.GUI_NAME)
    if existingGui then
        Log.Warn("Found existing GUI '" .. Config.GUI_NAME .. "', destroying it.")
        existingGui:Destroy()
    end

    screenGui = Instance_new("ScreenGui")
    screenGui.Name = Config.GUI_NAME
    screenGui.Parent = LocalPlayer.PlayerGui

    mainFrame = Instance_new("Frame")
    mainFrame.Size = UDim2_new(0, Config.GUI_WIDTH, 0, 0) -- Initial height will be calculated later
    mainFrame.Position = UDim2_new(0.5, -Config.GUI_WIDTH/2, 0.5, -200) -- Center horizontally
    mainFrame.BackgroundColor3 = Color3_new(0.15, 0.15, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui


    local currentY = Config.GUI_START_POS_Y -- Track current Y position

    -- Title Label (created separately as it's at the top)
    createLabel(mainFrame, "Studio Block Editor v5.0", 0, {
        Size = UDim2_new(1, 0, 0, 30),
        BackgroundColor3 = Color3_new(0.25, 0.25, 0.25),
        TextColor3 = Color3_new(0.9, 0.9, 0.9),
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextInsets = UDimInsets_new(0, 0, 0, 0)
    })


    -- Size Controls
    createLabel(mainFrame, "Size (X, Y, Z):", currentY)
    currentY = currentY + Config.LABEL_HEIGHT + Config.SPACING

    local sizeAxes = {"X", "Y", "Z"}
    local initialSizes = {
        X = Config.INITIAL_BLOCK_SIZE.X,
        Y = Config.INITIAL_BLOCK_SIZE.Y,
        Z = Config.INITIAL_BLOCK_SIZE.Z
    }

    for i, axis in ipairs_global(sizeAxes) do
        local textBox = createTextBox(mainFrame, "Size " .. axis, tostring_global(initialSizes[axis]), currentY)
        sizeTextBoxes[axis] = textBox -- Store in table
        currentY = currentY + ELEMENT_HEIGHT + Config.SPACING
    end

    -- Color Controls
    createLabel(mainFrame, "Color (R, G, B 0-1):", currentY)
    currentY = currentY + Config.LABEL_HEIGHT + Config.SPACING

    local colorChannels = {"R", "G", "B"}
    local initialColors = {
        R = Config.INITIAL_BLOCK_COLOR.R,
        G = Config.INITIAL_BLOCK_COLOR.G,
        B = Config.INITIAL_BLOCK_COLOR.B
    }

    local colorTextBoxWidth = (Config.GUI_WIDTH - 10 - Config.SPACING*2) / 3

    for i, channel in ipairs_global(colorChannels) do
        local textBox = createTextBox(mainFrame, "Color " .. channel, tostring_global(initialColors[channel]), currentY, UDim2_new(0, colorTextBoxWidth, 0, Config.ELEMENT_HEIGHT), {
            Position = UDim2_new(0, 5 + (i-1) * (colorTextBoxWidth + Config.SPACING), 0, currentY)
        })
        colorTextBoxes[channel] = textBox -- Store in table
    end
    currentY = currentY + ELEMENT_HEIGHT + Config.SPACING -- Move Y down after the row

    -- Movement Controls
    createLabel(mainFrame, "Move (Increment " .. Config.MOVE_INCREMENT .. "):", currentY)
    currentY = currentY + LABEL_HEIGHT + Config.SPACING

    local moveButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING*2) / 3

    local moveButtonsData = {
        { text = "-Z (Fwd)", vector = Vector3_new(0, 0, -1), row = 0, col = 0 },
        { text = "+Y (Up)", vector = Vector3_new(0, 1, 0), row = 0, col = 1 },
        { text = "+Z (Back)", vector = Vector3_new(0, 0, 1), row = 0, col = 2 },
        { text = "-X (Left)", vector = Vector3_new(-1, 0, 0), row = 1, col = 0 },
        { text = "-Y (Down)", vector = Vector3_new(0, -1, 0), row = 1, col = 1 },
        { text = "+X (Right)", vector = Vector3_new(1, 0, 0), row = 1, col = 2 },
    }

    local maxRows = 0
    for _, data in ipairs_global(moveButtonsData) do
        local button = createButton(mainFrame, data.text, currentY + data.row * (Config.ELEMENT_HEIGHT + Config.SPACING), UDim2_new(0, moveButtonWidth, 0, Config.ELEMENT_HEIGHT), {
            Position = UDim2_new(0, 5 + data.col * (moveButtonWidth + Config.SPACING), 0, currentY + data.row * (Config.ELEMENT_HEIGHT + Config.SPACING))
        })
        button.Tag = data.vector -- Store vector in Tag
        maxRows = math.max(maxRows, data.row)
    end
    currentY = currentY + (maxRows + 1) * (Config.ELEMENT_HEIGHT + Config.SPACING)

    -- Action Buttons
    local createBlockButton = createButton(mainFrame, "Create Block", currentY, UDim2_new(1, -10, 0, 30), {
        BackgroundColor3 = Color3_new(0.3, 0.6, 0.3) -- Greenish
    })
    currentY = currentY + 30 + Config.SPACING

    local removeBlockButton = createButton(mainFrame, "Remove Block", currentY, UDim2_new(1, -10, 0, 30), {
        BackgroundColor3 = Color3_new(0.6, 0.3, 0.3) -- Reddish
    })
    currentY = currentY + 30 + Config.SPACING

    -- Adjust frame size dynamically
    mainFrame.Size = UDim2_new(0, Config.GUI_WIDTH, 0, currentY)

    Log.Info("GUI created.")

    -- === Event Connections ===
    -- Connect events AFTER GUI is created
    -- Now call functions on the local StudioBlock table directly

    -- Connect FocusLost for Size and Color TextBoxes
    for _, textBox in pairs_global(sizeTextBoxes) do
        textBox.FocusLost:Connect(function() StudioBlock.updateBlockSize(sizeTextBoxes) end) -- Call StudioBlock directly
    end

    for _, textBox in pairs_global(colorTextBoxes) do
         textBox.FocusLost:Connect(function() StudioBlock.updateBlockColor(colorTextBoxes) end) -- Call StudioBlock directly
    end

    -- Connect MouseButton1Click for Action Buttons
    createBlockButton.MouseButton1Click:Connect(function() StudioBlock.createNewBlock(sizeTextBoxes, colorTextBoxes) end) -- Call StudioBlock directly
    removeBlockButton.MouseButton1Click:Connect(StudioBlock.removeBlock) -- Call StudioBlock directly

    -- Connect MouseButton1Click for Movement Buttons
    local movementButtons = mainFrame:GetChildren()
    for _, button in pairs_global(movementButtons) do
        if button:IsA("TextButton") and button.Tag and typeof_global(button.Tag) == "Vector3" then
            local directionVector = button.Tag -- Cache vector
            button.MouseButton1Click:Connect(function()
                StudioBlock.moveBlock(directionVector) -- Use cached vector and call StudioBlock function
            end)
        end
    end

    -- Return mainFrame reference for MainScript logic
    return mainFrame
end


-- === Main Execution Logic ===
-- Merged from StudioMain

-- Note: Services and Config are already cached at the top

-- Create the GUI and get the main frame reference
local mainFrameReference = createGUI()

-- Handle GUI visibility toggle using UserInputService
local TOGGLE_KEY_CODE = Config.TOGGLE_KEY_CODE -- Get from Config
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == TOGGLE_KEY_CODE and not gameProcessedEvent then
        if mainFrameReference then -- Use the returned frame reference
             mainFrameReference.Visible = not mainFrameReference.Visible
             Log.Info("GUI visibility toggled.")
        end
    end
end)

Log.Info("Studio Beta v5.0 Single File initialized.")
Log.Info("Press " .. TOGGLE_KEY_CODE.Name .. " to toggle GUI.")

-- The script finishes execution here after setting up events and GUI.
-- The GUI and event connections keep the script alive and functional.
