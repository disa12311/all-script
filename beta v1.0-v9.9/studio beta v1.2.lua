--[[
Script Name: studio
Version: beta v1.2
Author: Lua vip pro vn (Refactored)
Description: Client-side script for Natural Disaster Survival
             to create and modify a block via GUI.
             Runs with an executor.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace") -- Use Workspace service

-- Variables
local createdBlock = nil -- Holds the reference to our created block Part

-- Configuration (Easy to adjust values)
local GUI_WIDTH = 250
local GUI_START_POS_Y = 30 -- Starting Y position for GUI elements below title
local ELEMENT_HEIGHT = 25 -- Standard height for textboxes and buttons
local LABEL_HEIGHT = 20 -- Standard height for labels
local SPACING = 5 -- Vertical spacing between elements
local MOVE_INCREMENT = 1 -- How much to move the block per button click
local INITIAL_BLOCK_SIZE = Vector3.new(4, 4, 4)
local INITIAL_BLOCK_COLOR = Color3.new(1, 0, 0) -- Red

-- === GUI Creation ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StudioGUI_v1_2" -- Unique GUI name
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") -- Use WaitForChild

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, 0) -- Initial height will be calculated
mainFrame.Position = UDim2.new(0.5, -GUI_WIDTH/2, 0.5, -200) -- Center horizontally
mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15) -- Slightly lighter dark
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true -- Make the GUI draggable
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Text = "Studio Block Editor v1.2"
titleLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9) -- Lighter text
titleLabel.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
titleLabel.BorderSizePixel = 0
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

-- Helper function to create GUI elements
local function createElement(elementType, properties)
    local element = Instance.new(elementType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = mainFrame
    return element
end

local currentY = GUI_START_POS_Y -- Track current Y position for element placement

-- Size Controls
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

local sizeXTextBox = createElement("TextBox", {
    Size = UDim2.new(1, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(0, 5, 0, currentY),
    PlaceholderText = "Size X",
    Text = tostring(INITIAL_BLOCK_SIZE.X),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})
currentY = currentY + ELEMENT_HEIGHT + SPACING

local sizeYTextBox = createElement("TextBox", {
    Size = UDim2.new(1, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(0, 5, 0, currentY),
    PlaceholderText = "Size Y",
    Text = tostring(INITIAL_BLOCK_SIZE.Y),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})
currentY = currentY + ELEMENT_HEIGHT + SPACING

local sizeZTextBox = createElement("TextBox", {
    Size = UDim2.new(1, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(0, 5, 0, currentY),
    PlaceholderText = "Size Z",
    Text = tostring(INITIAL_BLOCK_SIZE.Z),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})
currentY = currentY + ELEMENT_HEIGHT + SPACING

-- Color Controls
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

local colorRTextBox = createElement("TextBox", {
    Size = UDim2.new(1/3, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(0, 5, 0, currentY),
    PlaceholderText = "Color R",
    Text = tostring(INITIAL_BLOCK_COLOR.R),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})

local colorGTextBox = createElement("TextBox", {
    Size = UDim2.new(1/3, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(1/3, 5, 0, currentY),
    PlaceholderText = "Color G",
    Text = tostring(INITIAL_BLOCK_COLOR.G),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})

local colorBTextBox = createElement("TextBox", {
    Size = UDim2.new(1/3, -10, 0, ELEMENT_HEIGHT),
    Position = UDim2.new(2/3, 5, 0, currentY),
    PlaceholderText = "Color B",
    Text = tostring(INITIAL_BLOCK_COLOR.B),
    BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15
})
currentY = currentY + ELEMENT_HEIGHT + SPACING

-- Movement Controls
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

-- Arrange movement buttons in a grid/more organized layout
local moveButtonWidth = (GUI_WIDTH - 10 - SPACING*2) / 3 -- 3 buttons per row, with spacing
local moveButtonHeight = 25

local moveUpButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5 + moveButtonWidth + SPACING, 0, currentY), -- Middle button
    Text = "+Y (Up)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
local moveForwardButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5, 0, currentY), -- Left button
    Text = "-Z (Fwd)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
local moveBackwardButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5 + (moveButtonWidth + SPACING)*2, 0, currentY), -- Right button
    Text = "+Z (Back)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
currentY = currentY + moveButtonHeight + SPACING

local moveLeftButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5, 0, currentY),
    Text = "-X (Left)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
local moveDownButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5 + moveButtonWidth + SPACING, 0, currentY), -- Middle button
    Text = "-Y (Down)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
local moveRightButton = createElement("TextButton", {
    Size = UDim2.new(0, moveButtonWidth, 0, moveButtonHeight),
    Position = UDim2.new(0, 5 + (moveButtonWidth + SPACING)*2, 0, currentY), -- Right button
    Text = "+X (Right)",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.2, 0.5, 0.8),
    TextSize = 16
})
currentY = currentY + moveButtonHeight + SPACING

-- Action Buttons
local createBlockButton = createElement("TextButton", {
    Size = UDim2.new(1, -10, 0, 30),
    Position = UDim2.new(0, 5, 0, currentY),
    Text = "Create Block",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.3, 0.6, 0.3), -- Greenish
    TextSize = 16
})
currentY = currentY + 30 + SPACING

local removeBlockButton = createElement("TextButton", {
    Size = UDim2.new(1, -10, 0, 30),
    Position = UDim2.new(0, 5, 0, currentY),
    Text = "Remove Block",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.new(0.6, 0.3, 0.3), -- Reddish
    TextSize = 16
})
currentY = currentY + 30 + SPACING

-- Adjust frame size dynamically based on element placement
mainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, currentY)


-- === Block Functionality ===

-- Function to safely get a number from a textbox
local function getNumberFromTextBox(textBox, defaultValue)
    local num = tonumber(textBox.Text)
    if num == nil then
        -- Optional: Reset text to default or visually indicate error
        -- For this version, we'll just use the default value
        return defaultValue
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

    -- Apply initial properties from text boxes
    -- Using getNumberFromTextBox for robustness
    local sizeX = getNumberFromTextBox(sizeXTextBox, INITIAL_BLOCK_SIZE.X)
    local sizeY = getNumberFromTextBox(sizeYTextBox, INITIAL_BLOCK_SIZE.Y)
    local sizeZ = getNumberFromTextBox(sizeZTextBox, INITIAL_BLOCK_SIZE.Z)
    createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)

    local colorR = math.clamp(getNumberFromTextBox(colorRTextBox, INITIAL_BLOCK_COLOR.R), 0, 1)
    local colorG = math.clamp(getNumberFromTextBox(colorGTextBox, INITIAL_BLOCK_COLOR.G), 0, 1)
    local colorB = math.clamp(getNumberFromTextBox(colorBTextBox, INITIAL_BLOCK_COLOR.B), 0, 1)
    createdBlock.Color = Color3.new(colorR, colorG, colorB)

    -- Position the block slightly in front of the player's head
    local character = LocalPlayer.Character
    if character and character.PrimaryPart then
         -- Place relative to character's PrimaryPart (often HumanoidRootPart)
        local playerPos = character.PrimaryPart.Position
        createdBlock.CFrame = CFrame.new(playerPos + character.PrimaryPart.CFrame.LookVector * 10 + Vector3.new(0, 5, 0)) -- 10 studs in front, 5 studs up
    else
         -- Fallback position if character not found
        createdBlock.CFrame = CFrame.new(0, 10, 0) -- Place at origin, slightly up
    end
end

-- Function to update block size
local function updateBlockSize()
    if createdBlock and createdBlock.Parent then
        local sizeX = getNumberFromTextBox(sizeXTextBox, createdBlock.Size.X)
        local sizeY = getNumberFromTextBox(sizeYTextBox, createdBlock.Size.Y)
        local sizeZ = getNumberFromTextBox(sizeZTextBox, createdBlock.Size.Z)
        createdBlock.Size = Vector3.new(sizeX, sizeY, sizeZ)
    end
end

-- Function to update block color
local function updateBlockColor()
    if createdBlock and createdBlock.Parent then
        local colorR = math.clamp(getNumberFromTextBox(colorRTextBox, createdBlock.Color.R), 0, 1)
        local colorG = math.clamp(getNumberFromTextBox(colorGTextBox, createdBlock.Color.G), 0, 1)
        local colorB = math.clamp(getNumberFromTextBox(colorBTextBox, createdBlock.Color.B), 0, 1)
        createdBlock.Color = Color3.new(colorR, colorG, colorB)
    end
end

-- Function to move the block by a vector (relative to world axes)
local function moveBlock(directionVector)
    if createdBlock and createdBlock.Parent then
        -- Move relative to the block's current CFrame, multiplied by the increment
        -- This uses the block's own orientation for movement directions
        createdBlock.CFrame = createdBlock.CFrame * CFrame.new(directionVector * MOVE_INCREMENT)
    end
end

-- === Event Connections ===

-- Connect textbox updates
sizeXTextBox.FocusLost:Connect(updateBlockSize)
sizeYTextBox.FocusLost:Connect(updateBlockSize)
sizeZTextBox.FocusLost:Connect(updateBlockSize)

colorRTextBox.FocusLost:Connect(updateBlockColor)
colorGTextBox.FocusLost:Connect(updateBlockColor)
colorBTextBox.FocusLost:Connect(updateBlockColor)

-- Connect button clicks
createBlockButton.MouseButton1Click:Connect(createNewBlock)
removeBlockButton.MouseButton1Click:Connect(function()
    if createdBlock and createdBlock.Parent then
        createdBlock:Destroy()
        createdBlock = nil
    end
end)

-- Connect movement buttons
moveUpButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(0, 1, 0)) end)
moveDownButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(0, -1, 0)) end)
moveLeftButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(-1, 0, 0)) end) -- Using block's local X-axis
moveRightButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(1, 0, 0)) end) -- Using block's local X-axis
moveForwardButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(0, 0, -1)) end) -- Using block's local Z-axis (forward)
moveBackwardButton.MouseButton1Click:Connect(function() moveBlock(Vector3.new(0, 0, 1)) end)  -- Using block's local Z-axis (backward)


-- Optional: Add a keybind to toggle GUI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Check if the input is RightControl and it's not processed by the game (like typing in chat)
    if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
        mainFrame.Visible = not mainFrame.Visible -- Toggle visibility
    end
end)

-- Inform user that the script is loaded
print("Studio script beta v1.2 loaded. Press RightControl to toggle GUI.")
