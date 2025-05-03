--[[
Script Name: studio
Version: beta v3.0
Author: Lua vip pro vn (Applying advanced refactoring)
Description: Client-side script for Natural Disaster Survival
             to create and modify a block via GUI.
             Runs with an executor.
             Features highly refactored GUI creation using dedicated helpers.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Configuration (Easy to adjust values)
local GUI_WIDTH = 250
local GUI_START_POS_Y = 30 -- Starting Y position for GUI elements below title
local ELEMENT_HEIGHT = 25 -- Standard height for textboxes and buttons
local LABEL_HEIGHT = 20 -- Standard height for labels
local SPACING = 5 -- Vertical spacing between elements
local MOVE_INCREMENT = 1 -- How much to move the block per button click
local INITIAL_BLOCK_SIZE = Vector3.new(4, 4, 4)
local INITIAL_BLOCK_COLOR = Color3.new(1, 0, 0) -- Red
local TOGGLE_KEY_CODE = Enum.KeyCode.RightControl -- Key to toggle GUI visibility
local BLOCK_SIZE_LIMITS = {min = 0.1, max = 1000} -- Min/Max limits for block size input

-- Variables
local createdBlock = nil -- Holds the reference to our created block Part

-- === GUI Setup ===

-- Check for and destroy existing GUI to prevent duplicates if script is re-executed
local guiName = "StudioGUI_v3_0"
local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(guiName)
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName -- Unique GUI name for this version
screenGui.Parent = LocalPlayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, 0) -- Initial height will be calculated later
mainFrame.Position = UDim2.new(0.5, -GUI_WIDTH/2, 0.5, -200) -- Center horizontally
mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true -- Make the GUI draggable
mainFrame.Parent = screenGui

-- === Dedicated GUI Helper Functions ===

-- Helper to create a basic TextLabel
local function createLabel(parent, text, positionY, config)
    local label = Instance.new("TextLabel")
    label.Size = config and config.Size or UDim2.new(1, 0, 0, LABEL_HEIGHT)
    label.Position = config and config.Position or UDim2.new(0, 0, 0, positionY)
    label.Text = text
    label.TextColor3 = config and config.TextColor3 or Color3.new(0.8, 0.8, 0.8)
    label.BackgroundColor3 = config and config.BackgroundColor3 or Color3.new(0, 0, 0, 0) -- Transparent
    label.BorderSizePixel = 0
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = config and config.TextSize or 15
    label.TextXAlignment = config and config.TextXAlignment or Enum.TextXAlignment.Left
    label.TextInsets = config and config.TextInsets or UDimInsets.new(5, 0, 0, 0)
    label.Parent = parent
    return label
end

-- Helper to create a basic TextBox
local function createTextBox(parent, placeholder, initialText, positionY, size, config)
    local textBox = Instance.new("TextBox")
    textBox.Size = size or UDim2.new(1, -10, 0, ELEMENT_HEIGHT)
    textBox.Position = config and config.Position or UDim2.new(0, 5, 0, positionY)
    textBox.PlaceholderText = placeholder
    textBox.Text = initialText or ""
    textBox.BackgroundColor3 = config and config.BackgroundColor3 or Color3.new(0.3, 0.3, 0.3)
    textBox.TextColor3 = config and config.TextColor3 or Color3.new(1, 1, 1)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = config and config.TextSize or 15
    textBox.Parent = parent
    return textBox
end

-- Helper to create a basic TextButton
local function createButton(parent, text, positionY, size, config)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(1, -10, 0, ELEMENT_HEIGHT)
    button.Position = config and config.Position or UDim2.new(0, 5, 0, positionY)
    button.Text = text
    button.TextColor3 = config and config.TextColor3 or Color3.new(1, 1, 1)
    button.BackgroundColor3 = config and config.BackgroundColor3 or Color3.new(0.2, 0.5, 0.8) -- Blueish
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = config and config.TextSize or 16
    button.Parent = parent
    return button
end


local currentY = GUI_START_POS_Y -- Track current Y position for element placement

-- === Refactored GUI Element Creation using Helpers ===

-- Title Label (created separately as it's at the top)
createLabel(mainFrame, "Studio Block Editor v3.0", 0, {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.new(0.25, 0.25, 0.25),
    TextColor3 = Color3.new(0.9, 0.9, 0.9),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextInsets = UDimInsets.new(0, 0, 0, 0) -- Center alignment doesn't need left inset
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

for i, axis in ipairs(sizeAxes) do
    local textBox = createTextBox(mainFrame, "Size " .. axis, tostring(initialSizes[axis]), currentY)
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

for i, channel in ipairs(colorChannels) do
    local textBox = createTextBox(mainFrame, "Color " .. channel, tostring(initialColors[channel]), currentY, UDim2.new(0, colorTextBoxWidth, 0, ELEMENT_HEIGHT), {
        Position = UDim2.new(0, 5 + (i-1) * (colorTextBoxWidth + SPACING), 0, currentY)
    })
    colorTextBoxes[channel] = textBox -- Store in table
end
currentY = currentY + ELEMENT_HEIGHT + SPACING -- Move Y down after the row of color textboxes

-- Movement Controls
createLabel(mainFrame, "Move (Increment " .. MOVE_INCREMENT .. "):", currentY)
currentY = currentY + LABEL_HEIGHT + SPACING

local moveButtonWidth = (GUI_WIDTH - 10 - SPACING*2) / 3 -- 3 buttons per row

local moveButtonsData = {
    { text = "-Z (Fwd)", vector = Vector3.new(0, 0, -1), row = 0, col = 0 },
    { text = "+Y (Up)", vector = Vector3.new(0, 1, 0), row = 0, col = 1 }, -- Placed in middle column for Up
    { text = "+Z (Back)", vector = Vector3.new(0, 0, 1), row = 0, col = 2 },
    { text = "-X (Left)", vector = Vector3.new(-1, 0, 0), row = 1, col = 0 },
    { text = "-Y (Down)", vector = Vector3.new(0, -1, 0), row = 1, col = 1 }, -- Placed in middle column for Down
    { text = "+X (Right)", vector = Vector3.new(1, 0, 0), row = 1, col = 2 },
}

local maxRows = 0
for _, data in ipairs(moveButtonsData) do
    local button = createButton(mainFrame, data.text, currentY + data.row * (ELEMENT_HEIGHT + SPACING), UDim2.new(0, moveButtonWidth, 0, ELEMENT_HEIGHT), {
        Position = UDim2.new(0, 5 + data.col * (moveButtonWidth + SPACING), 0, currentY + data.row * (ELEMENT_HEIGHT + SPACING))
    })
    -- Store the vector data directly in the button for easy access in the event handler
    button.Tag = data.vector
    -- Track max row to update currentY after loop
    maxRows = math.max(maxRows, data.row)
end
currentY = currentY + (maxRows + 1) * (ELEMENT_HEIGHT + SPACING)

-- Action Buttons
local createBlockButton = createButton(mainFrame, "Create Block", currentY, UDim2.new(1, -10, 0, 30), {
    BackgroundColor3 = Color3.new(0.3, 0.6, 0.3) -- Greenish
})
currentY = currentY + 30 + SPACING

local removeBlockButton = createButton(mainFrame, "Remove Block", currentY, UDim2.new(1, -10, 0, 30), {
    BackgroundColor3 = Color3.new(0.6, 0.3, 0.3) -- Reddish
})
currentY = currentY + 30 + SPACING


-- Adjust frame size dynamically based on element placement
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, currentY)


-- === Block Functionality ===

-- Function to safely get a number from a textbox, with optional min/max clamp
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local num = tonumber(textBox.Text)
    if num == nil then
        -- Optional: Reset text to default visually or indicate error
        -- textBox.Text = tostring(defaultValue) -- Can add this line if desired
        warn("Invalid number input in textbox: ", textBox.Name or textBox.PlaceholderText, ". Using default value: ", defaultValue) -- Warning for developer/user
        return defaultValue
    end
    -- Apply clamp if min/max values are provided
    if minValue ~= nil and maxValue ~= nil then
        num = math.clamp(num, minValue, maxValue)
    end
    return num
end

-- Function to create the block
local function createNewBlock()
    -- Remove existing block if any
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
    end

    -- Create a new part
    createdBlock = Instance.new("Part")
    createdBlock.Anchored = true         -- Keep it in place unless we move it
    createdBlock.CanCollide = false      -- Don't want it blocking players typically
    createdBlock.Parent = Workspace      -- Parent to Workspace

    -- Apply initial properties from text boxes using the refactored textboxes table
    local sizeX = getNumberFromTextBox(sizeTextBoxes.X, INITIAL_BLOCK_SIZE.X, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, INITIAL_BLOCK_SIZE.Y, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, INITIAL_BLOCK_SIZE.Z, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
    createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)

    local colorR = getNumberFromTextBox(colorTextBoxes.R, INITIAL_BLOCK_COLOR.R, 0, 1)
    local colorG = getNumberFromTextBox(colorTextBoxes.G, INITIAL_BLOCK_COLOR.G, 0, 1)
    local colorB = getNumberFromTextBox(colorTextBoxes.B, INITIAL_BLOCK_COLOR.B, 0, 1)
    createdBlock.Color = Color3.new(colorR, colorG, colorB)

    -- Position the block slightly in front of the player's head
    -- Added wait for character and primary part for robustness
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if character then
        local primaryPart = character:FindFirstChild("HumanoidRootPart")
        if primaryPart then
             -- Place relative to character's HumanoidRootPart
            createdBlock.CFrame = CFrame.new(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3.new(0, 5, 0)) -- 10 studs in front, 5 studs up
        else
            warn("HumanoidRootPart not found, placing block at origin.")
            createdBlock.CFrame = CFrame.new(0, 10, 0) -- Fallback position
        end
    else
        warn("Character not found, placing block at origin.")
        createdBlock.CFrame = CFrame.new(0, 10, 0) -- Fallback position
    end
end

-- Function to update block size from textboxes
local function updateBlockSize()
    if createdBlock and createdBlock.Parent then
        local sizeX = getNumberFromTextBox(sizeTextBoxes.X, createdBlock.Size.X, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, createdBlock.Size.Y, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, createdBlock.Size.Z, BLOCK_SIZE_LIMITS.min, BLOCK_SIZE_LIMITS.max)
        createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)
    end
end

-- Function to update block color from textboxes
local function updateBlockColor()
    if createdBlock and createdBlock.Parent then
        local colorR = getNumberFromTextBox(colorTextBoxes.R, createdBlock.Color.R, 0, 1)
        local colorG = getNumberFromTextBox(colorTextBoxes.G, createdBlock.Color.G, 0, 1)
        local colorB = getNumberFromTextBox(colorTextBoxes.B, createdBlock.Color.B, 0, 1)
        createdBlock.Color = Color3.new(colorR, colorG, colorB)
    end
end

-- Function to move the block by a vector (relative to block's local axes)
local function moveBlock(directionVector)
    if createdBlock and createdBlock.Parent then
        -- Move relative to the block's current CFrame, multiplied by the increment
        createdBlock.CFrame = createdBlock.CFrame * CFrame.new(directionVector * MOVE_INCREMENT)
    end
end

-- === Event Connections ===

-- Connect FocusLost for Size and Color TextBoxes using loops
for _, textBox in pairs(sizeTextBoxes) do
    textBox.FocusLost:Connect(updateBlockSize)
end

for _, textBox in pairs(colorTextBoxes) do
     textBox.FocusLost:Connect(updateBlockColor)
end

-- Connect MouseButton1Click for Action Buttons
createBlockButton.MouseButton1Click:Connect(createNewBlock)
removeBlockButton.MouseButton1Click:Connect(function()
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
    end
end)

-- Connect MouseButton1Click for Movement Buttons using a loop
-- We stored the vector data in the button's .Tag property during creation
local movementButtons = mainFrame:GetChildren() -- Get all children of the frame
for _, button in pairs(movementButtons) do
    -- Check if the child is a TextButton and has the Vector3 Tag we added
    if button:IsA("TextButton") and button.Tag and typeof(button.Tag) == "Vector3" then
        button.MouseButton1Click:Connect(function()
            moveBlock(button.Tag) -- Use the stored vector from the button's Tag
        end)
    end
end


-- Optional: Add a keybind to toggle GUI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Check if the input is the toggle key and it's not processed by the game
    if input.KeyCode == TOGGLE_KEY_CODE and not gameProcessedEvent then
        mainFrame.Visible = not mainFrame.Visible -- Toggle visibility
    end
end)

-- Inform user that the script is loaded
print("Studio script beta v3.0 loaded. Press " .. TOGGLE_KEY_CODE.Name .. " to toggle GUI.")
