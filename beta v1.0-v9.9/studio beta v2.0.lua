--[[
Script Name: studio
Version: beta v2.0
Author: Lua vip pro vn (Refactored based on analysis)
Description: Client-side script for Natural Disaster Survival
             to create and modify a block via GUI.
             Runs with an executor.
             Features refactored GUI creation and event handling.
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

-- Variables
local createdBlock = nil -- Holds the reference to our created block Part

-- === GUI Setup ===

-- Check for and destroy existing GUI to prevent duplicates if script is re-executed
local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("StudioGUI_v2_0")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StudioGUI_v2_0" -- Unique GUI name for this version
screenGui.Parent = LocalPlayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, 0) -- Initial height will be calculated later
mainFrame.Position = UDim2.new(0.5, -GUI_WIDTH/2, 0.5, -200) -- Center horizontally
mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true -- Make the GUI draggable
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Text = "Studio Block Editor v2.0"
titleLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
titleLabel.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
titleLabel.BorderSizePixel = 0
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

-- Helper function to create GUI elements with properties
local function createElement(elementType, properties)
    local element = Instance.new(elementType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = mainFrame
    return element
end

local currentY = GUI_START_POS_Y -- Track current Y position for element placement

-- === Refactored GUI Element Creation ===

-- Create Size TextBoxes using a loop
createElement("TextLabel", {
    Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
    Position = UDim2.new(0, 0, 0, currentY),
    Text = "Size (X, Y, Z):",
    TextColor3 = Color3.new(0.8, 0.8, 0.8),
    BackgroundColor3 = Color3.new(0, 0, 0, 0),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextInsets = UDimInsets.new(5, 0, 0, 0)
})
currentY = currentY + LABEL_HEIGHT + SPACING

local sizeTextBoxes = {} -- Store textboxes for easier event connection

local sizeAxes = {"X", "Y", "Z"}
local initialSizes = {
    X = INITIAL_BLOCK_SIZE.X,
    Y = INITIAL_BLOCK_SIZE.Y,
    Z = INITIAL_BLOCK_SIZE.Z
}

for i, axis in ipairs(sizeAxes) do
    local textBox = createElement("TextBox", {
        Size = UDim2.new(1, -10, 0, ELEMENT_HEIGHT),
        Position = UDim2.new(0, 5, 0, currentY),
        PlaceholderText = "Size " .. axis,
        Text = tostring(initialSizes[axis]),
        BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15
    })
    sizeTextBoxes[axis] = textBox -- Store in table
    currentY = currentY + ELEMENT_HEIGHT + SPACING
end

-- Create Color TextBoxes using a loop
createElement("TextLabel", {
    Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
    Position = UDim2.new(0, 0, 0, currentY),
    Text = "Color (R, G, B 0-1):",
    TextColor3 = Color3.new(0.8, 0.8, 0.8),
    BackgroundColor3 = Color3.new(0, 0, 0, 0),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextInsets = UDimInsets.new(5, 0, 0, 0)
})
currentY = currentY + LABEL_HEIGHT + SPACING

local colorTextBoxes = {} -- Store textboxes for easier event connection

local colorChannels = {"R", "G", "B"}
local initialColors = {
    R = INITIAL_BLOCK_COLOR.R,
    G = INITIAL_BLOCK_COLOR.G,
    B = INITIAL_BLOCK_COLOR.B
}

for i, channel in ipairs(colorChannels) do
    local textBox = createElement("TextBox", {
        Size = UDim2.new(1/3, -10, 0, ELEMENT_HEIGHT), -- Distribute horizontally
        Position = UDim2.new((i-1)/3, 5, 0, currentY),
        PlaceholderText = "Color " .. channel,
        Text = tostring(initialColors[channel]),
        BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15
    })
    colorTextBoxes[channel] = textBox -- Store in table
    -- Adjust position for subsequent textboxes
    if i < #colorChannels then
         -- Move position for the next textbox in the same row, doesn't affect currentY for the next section
    end
end
currentY = currentY + ELEMENT_HEIGHT + SPACING -- Move Y down after the row of color textboxes

-- Create Movement Buttons using a loop and table
createElement("TextLabel", {
    Size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
    Position = UDim2.new(0, 0, 0, currentY),
    Text = "Move (Increment " .. MOVE_INCREMENT .. "):",
    TextColor3 = Color3.new(0.8, 0.8, 0.8),
    BackgroundColor3 = Color3.new(0, 0, 0, 0),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextInsets = UDimInsets.new(5, 0, 0, 0)
})
currentY = currentY + LABEL_HEIGHT + SPACING

local moveButtonWidth = (GUI_WIDTH - 10 - SPACING*2) / 3 -- 3 buttons per row

local moveButtonsData = {
    { text = "-Z (Fwd)", vector = Vector3.new(0, 0, -1), row = 0, col = 0 },
    { text = "+Y (Up)", vector = Vector3.new(0, 1, 0), row = 0, col = 1 },
    { text = "+Z (Back)", vector = Vector3.new(0, 0, 1), row = 0, col = 2 },
    { text = "-X (Left)", vector = Vector3.new(-1, 0, 0), row = 1, col = 0 },
    { text = "-Y (Down)", vector = Vector3.new(0, -1, 0), row = 1, col = 1 },
    { text = "+X (Right)", vector = Vector3.new(1, 0, 0), row = 1, col = 2 },
}

local maxRows = 0
for _, data in ipairs(moveButtonsData) do
    local button = createElement("TextButton", {
        Size = UDim2.new(0, moveButtonWidth, 0, ELEMENT_HEIGHT),
        Position = UDim2.new(0, 5 + data.col * (moveButtonWidth + SPACING), 0, currentY + data.row * (ELEMENT_HEIGHT + SPACING)),
        Text = data.text,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
        TextSize = 16
    })
    -- Store the vector data directly in the button for easy access in the event handler
    button.Tag = data.vector
    -- Track max row to update currentY after loop
    maxRows = math.max(maxRows, data.row)
end
currentY = currentY + (maxRows + 1) * (ELEMENT_HEIGHT + SPACING)

-- Create Action Buttons (Create, Remove)
local createBlockButton = createElement("TextButton", {
    Size = UDim2.new(1, -10, 0, 30),
    Position = UDim2.new(0, 5, 0, currentY),
    Text = "Create Block",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.3, 0.6, 0.3),
    TextSize = 16
})
currentY = currentY + 30 + SPACING

local removeBlockButton = createElement("TextButton", {
    Size = UDim2.new(1, -10, 0, 30),
    Position = UDim2.new(0, 5, 0, currentY),
    Text = "Remove Block",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.6, 0.3, 0.3),
    TextSize = 16
})
currentY = currentY + 30 + SPACING

-- Adjust frame size dynamically based on element placement
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, currentY)


-- === Block Functionality ===

-- Function to safely get a number from a textbox, with optional min/max clamp
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local num = tonumber(textBox.Text)
    if num == nil then
        -- Optionally reset text to default visually
        -- textBox.Text = tostring(defaultValue) -- Can add this line if desired
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
    local sizeX = getNumberFromTextBox(sizeTextBoxes.X, INITIAL_BLOCK_SIZE.X, 0.1, 1000) -- Added a large max size limit as per analysis
    local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, INITIAL_BLOCK_SIZE.Y, 0.1, 1000)
    local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, INITIAL_BLOCK_SIZE.Z, 0.1, 1000)
    createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)

    local colorR = getNumberFromTextBox(colorTextBoxes.R, INITIAL_BLOCK_COLOR.R, 0, 1) -- Clamped 0-1 as per analysis
    local colorG = getNumberFromTextBox(colorTextBoxes.G, INITIAL_BLOCK_COLOR.G, 0, 1)
    local colorB = getNumberFromTextBox(colorTextBoxes.B, INITIAL_BLOCK_COLOR.B, 0, 1)
    createdBlock.Color = Color3.new(colorR, colorG, colorB)

    -- Position the block slightly in front of the player's head
    -- Added wait for character and primary part for robustness
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if character and character:FindFirstChild("HumanoidRootPart") then
         -- Place relative to character's HumanoidRootPart (most common PrimaryPart)
        local primaryPart = character.HumanoidRootPart
        createdBlock.CFrame = CFrame.new(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3.new(0, 5, 0)) -- 10 studs in front, 5 studs up
    else
         -- Fallback position if character/primaryPart not found
         print("Could not find character/PrimaryPart, placing block at origin.")
        createdBlock.CFrame = CFrame.new(0, 10, 0) -- Place at origin, slightly up
    end
end

-- Function to update block size from textboxes
local function updateBlockSize()
    if createdBlock and createdBlock.Parent then
        local sizeX = getNumberFromTextBox(sizeTextBoxes.X, createdBlock.Size.X, 0.1, 1000) -- Apply limits
        local sizeY = getNumberFromTextBox(sizeTextBoxes.Y, createdBlock.Size.Y, 0.1, 1000)
        local sizeZ = getNumberFromTextBox(sizeTextBoxes.Z, createdBlock.Size.Z, 0.1, 1000)
        createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)
    end
end

-- Function to update block color from textboxes
local function updateBlockColor()
    if createdBlock and createdBlock.Parent then
        local colorR = getNumberFromTextBox(colorTextBoxes.R, createdBlock.Color.R, 0, 1) -- Apply limits
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

-- === Refactored Event Connections ===

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
print("Studio script beta v2.0 loaded. Press " .. TOGGLE_KEY_CODE.Name .. " to toggle GUI.")
