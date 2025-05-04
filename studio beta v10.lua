--[[
Script Name: Studio Beta v10.0
Version: beta v10.0
Author: Lua vip pro vn (Custom Rotate Angle, Basic Pivot, Model Highlight, Basic Model Save/Load)
Description: Client-side script for Natural Disaster Survival
             to create, modify, transform, group, and basic save/load items.
             Includes Union/Negate, particle effects, and mobile virtual button toggle.
--]]

-- === Cached Global Functions, Services, and Constructors ===
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local DataStoreService = game:GetService("DataStoreService")

local InstanceNew = Instance.new
local MathClamp = math.clamp
local Tonumber = tonumber
local TostringGlobal = tostring
local PrintGlobal = print
local WarnGlobal = warn
local ErrorGlobal = error
local TypeOfGlobal = typeof
local PairsGlobal = pairs
local IpairsGlobal = ipairs
local TaskWait = task.wait

local Vector3New = Vector3.new
local UDim2New = UDim2.new
local CFrameNew = CFrame.new
local Color3New = Color3.New
local UDimInsetsNew = UDimInsets.new
local EnumMaterial = Enum.Material
local EnumAutomaticSize = Enum.AutomaticSize
local EnumSortOrder = Enum.SortOrder
local EnumHorizontalAlignment = Enum.HorizontalAlignment
local UDimNew = UDim.new
local InstanceIsA = InstanceNew("Part").IsA
local EnumKeyCode = Enum.KeyCode
local EnumFillDirection = Enum.FillDirection
local EnumPartType = Enum.PartType
local EnumUserInputType = Enum.UserInputType
local EnumRaycastFilterType = Enum.RaycastFilterType
local RaycastParamsNew = RaycastParams.new
local MathRad = math.rad


-- === Configuration ===
local Config = {
    GUI_WIDTH = 250,
    GUI_START_POS_Y = 30,
    ELEMENT_HEIGHT = 25,
    LABEL_HEIGHT = 20,
    SPACING = 5,
    MOVE_INCREMENT = 1,
    INITIAL_BLOCK_SIZE = Vector3New(4, 4, 4),
    INITIAL_BLOCK_COLOR = Color3New(1, 0, 0),
    TOGGLE_KEY_CODE = EnumKeyCode.RightControl,
    BLOCK_SIZE_LIMITS = {min = 0.1, max = 1000},
    GUI_NAME = "StudioGUI_v10_0",
    LOG_PREFIX = "[Studio v10.0] ",

    -- DataStore Config
    DATASTORE_NAME = "StudioBlockConfig_v10_0",
    DATASTORE_KEY = "BlockConfigs",
    DATASTORE_RETRY_ATTEMPTS = 3,
    DATASTORE_RETRY_DELAY = 1,

    -- Mobile Virtual Button Config
    VIRTUAL_BUTTON_SIZE = UDim2New(0, 60, 0, 60),
    VIRTUAL_BUTTON_SPACING = 10,
    VIRTUAL_BUTTON_BASE_X = 20,
    VIRTUAL_BUTTON_BASE_Y_OFFSET_BOTTOM = 100,
    VIRTUAL_BUTTON_UP_DOWN_OFFSET_RIGHT = 80,

    -- Particle Effect Config
    PARTICLE_LIFETIME = 0.5,
    PARTICLE_RATE = 20,
    PARTICLE_COLOR = Color3New(0, 1, 1), -- Cyan
    PARTICLE_SIZE = NumberSequence.new(0.5, 0),
    PARTICLE_SPEED = 5,

    -- Initial Property Defaults (for new items)
    INITIAL_PART_TYPE = EnumPartType.Block,
    INITIAL_MATERIAL = EnumMaterial.Plastic,
    INITIAL_TRANSPARENCY = 0,
    INITIAL_REFLECTANCE = 0,
    INITIAL_CAN_COLLIDE = true,
    INITIAL_ANCHORED = true,

    -- Selection Config
    SELECTION_HIGHLIGHT_COLOR = Color3New(0, 1, 0.5),
    SELECTION_HIGHLIGHT_TRANSPARENCY = 0.5,
    RAYCAST_MAX_DISTANCE = 1000,
     MODEL_HIGHLIGHT_TRANSPARENCY = 0.8, -- Transparency for the model highlight part
     MODEL_HIGHLIGHT_COLOR = Color3New(0, 0.5, 1), -- Blueish color for model highlight

    -- Transformation Config
    INITIAL_ROTATION_ANGLE = 90, -- Initial degrees for rotation input
    SCALE_INCREMENT_FACTOR = 1.1, -- Factor for scale buttons (e.g., 1.1 = 10% increase)
    DUPLICATE_OFFSET = Vector3New(5, 5, 5), -- Offset for duplicated items
}

-- === Basic Service Check ===
if not DataStoreService then
    Log.Error("DataStoreService not available. Script may not work on this Roblox version or environment.")
    return
end

local networkClient = game:GetService("NetworkClient")
if not game:IsLoaded() or (networkClient and not networkClient.IsConnected) then
     Log.Warn("Network connection may be unstable. DataStore operations might fail.")
end


-- === Simple Logging System ===
local Log = {}
function Log.Info(message) PrintGlobal(Config.LOG_PREFIX .. TostringGlobal(message)) end
function Log.Warn(message) WarnGlobal(Config.LOG_PREFIX .. TostringGlobal(message)) end
function Log.Error(message)
    WarnGlobal(Config.LOG_PREFIX .. "ERROR: " .. TostringGlobal(message))
    ErrorGlobal(TostringGlobal(message))
end


-- === General Utility Functions ===
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local numberValue = Tonumber(textBox.Text)
    if numberValue == nil then
        Log.Warn("Invalid number input in textbox: '" .. (textBox.Name or textBox.PlaceholderText or "Unnamed TextBox") .. "'. Using default value: " .. TostringGlobal(defaultValue))
        return defaultValue
    end
    if minValue ~= nil and maxValue ~= nil then
        numberValue = MathClamp(numberValue, minValue, maxValue)
    end
    return numberValue
end

local function createElement(elementType, properties)
    local element = InstanceNew(elementType)
    for prop, value in PairsGlobal(properties) do
        element[prop] = value
    end
    return element
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Log.Error("Protected call failed: " .. TostringGlobal(result))
    end
    return success, result
end

local function handleTextBoxFocusLost(textBox, updateFunction)
    textBox.FocusLost:Connect(function() updateFunction() end)
end

local function mapDirectionToCamera(directionVector)
    if directionVector.Y ~= 0 then
        return directionVector
    end
    local cameraVectors = getCameraRelativeVector()
    if not cameraVectors then
        return directionVector
    end
    local cameraLookVector = Camera.CFrame.LookVector
    local cameraRightVector = Camera.CFrame.RightVector
    cameraLookVector = Vector3New(cameraLookVector.X, 0, cameraLookVector.Z).Unit
    cameraRightVector = Vector3New(cameraRightVector.X, 0, cameraRightVector.Z).Unit
    return cameraLookVector, cameraRightVector
end

local function handleMoveButton(button, directionVector)
    button.MouseButton1Down:Connect(function()
        local moveVector = mapDirectionToCamera(directionVector)
        moveDirection = moveDirection + moveVector
        if moveDirection.Magnitude > 1e-4 then isMoving = true end
    end)
    button.MouseButton1Up:Connect(function()
        local moveVector = mapDirectionToCamera(directionVector)
        moveDirection = moveDirection - moveVector
        if moveDirection.Magnitude < 1e-4 then isMoving = false; moveDirection = Vector3New(0, 0, 0) end
    end)
end

local function createCheckbox(parent, text, initialState, config)
    local button = createButton(parent, text .. (initialState and " [X]" or " [ ]"), config.Size or UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), config)
    button.Tag = initialState

    button.MouseButton1Click:Connect(function()
        local currentState = button.Tag
        local newState = not currentState
        button.Tag = newState
        button.Text = text .. (newState and " [X]" or " [ ]")
        if config.OnToggled then
            config.OnToggled(newState)
        end
    end)
    return button
end


-- === Item Management and Functionality ===
local managedItems = {}
local activeItem = nil
local selectedItems = {}
local itemHighlights = {} -- Table to hold highlight parts for selected Models
local isPerformingBooleanOp = false
local itemDataStore = DataStoreService:GetDataStore(Config.DATASTORE_NAME)

-- Basic Pivot System
local currentPivotCFrame = nil -- The CFrame defining the current pivot
local pivotHighlightPart = nil -- Optional: visual representation of the pivot


-- GUI references (assigned in createGUI)
local sizeTextBoxes_GUI
local colorTextBoxes_GUI
local shapeDropdown_GUI
local materialDropdown_GUI
local transparencyTextBox_GUI
local reflectanceTextBox_GUI
local canCollideCheckbox_GUI
local anchoredCheckbox_GUI
local itemSelectionDropdown_GUI
local toggleMobileButtonsCheckbox_GUI
local unionButton_GUI
local negateButton_GUI
local duplicateButton_GUI
local groupButton_GUI
local ungroupButton_GUI
local rotateAngleTextBox_GUI -- New GUI reference
local setPivotButton_GUI -- New GUI reference


-- Helper to update GUI elements when the active item changes
local function updateGUIForActiveItem()
    -- Reset property controls state
    local propertyControls = {
         sizeTextBoxes_GUI.X, sizeTextBoxes_GUI.Y, sizeTextBoxes_GUI.Z,
         colorTextBoxes_GUI.R, colorTextBoxes_GUI.G, colorTextBoxes_GUI.B,
         shapeDropdown_GUI, materialDropdown_GUI,
         transparencyTextBox_GUI, reflectanceTextBox_GUI,
         canCollideCheckbox_GUI, anchoredCheckbox_GUI,
    }
    for _, control in IpairsGlobal(propertyControls) do
         if control and InstanceIsA(control, "GuiObject") then
             control.TextEditable = false
             control.Active = false
             control.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) -- Grey out
             if InstanceIsA(control, "TextBox") then control.Text = "" end -- Clear textboxes
             if InstanceIsA(control, "TextButton") and control.Tag ~= nil then control.Tag = false end -- Reset checkbox state tag
              if control == canCollideCheckbox_GUI then control.Text = "CanCollide [ ]" end
              if control == anchoredCheckbox_GUI then control.Text = "Anchored [ ]" end
               if control == shapeDropdown_GUI then control.Text = "Shape: N/A" end
               if control == materialDropdown_GUI then control.Text = "Material: N/A" end
         end
    end


    if activeItem then
        -- Enable controls based on item type
        if InstanceIsA(activeItem, "BasePart") then
             sizeTextBoxes_GUI.X.Text = TostringGlobal(activeItem.Size.X)
             sizeTextBoxes_GUI.Y.Text = TostringGlobal(activeItem.Size.Y)
             sizeTextBoxes_GUI.Z.Text = TostringGlobal(activeItem.Size.Z)
             colorTextBoxes_GUI.R.Text = TostringGlobal(activeItem.Color.R)
             colorTextBoxes_GUI.G.Text = TostringGlobal(activeItem.Color.G)
             colorTextBoxes_GUI.B.Text = TostringGlobal(activeItem.Color.B)
             transparencyTextBox_GUI.Text = TostringGlobal(activeItem.Transparency)
             reflectanceTextBox_GUI.Text = TostringGlobal(activeItem.Reflectance)
             canCollideCheckbox_GUI.Tag = activeItem.CanCollide
             anchoredCheckbox_GUI.Tag = activeItem.Anchored

              local basePartControls = {
                 sizeTextBoxes_GUI.X, sizeTextBoxes_GUI.Y, sizeTextBoxes_GUI.Z,
                 colorTextBoxes_GUI.R, colorTextBoxes_GUI.G, colorTextBoxes_GUI.B,
                 transparencyTextBox_GUI, reflectanceTextBox_GUI,
                 canCollideCheckbox_GUI, anchoredCheckbox_GUI,
            }
            for _, control in IpairsGlobal(basePartControls) do
                 if control and InstanceIsA(control, "GuiObject") then
                     control.TextEditable = InstanceIsA(control, "TextBox")
                     control.Active = true
                      control.BackgroundColor3 = InstanceIsA(control, "TextBox") and Color3New(0.3, 0.3, 0.3) or (InstanceIsA(control, "TextButton") and (control == canCollideCheckbox_GUI or control == anchoredCheckbox_GUI) and Color3New(0.3, 0.3, 0.3) or Color3New(0.4, 0.4, 0.4))
                 end
            end

             canCollideCheckbox_GUI.Text = "CanCollide" .. (activeItem.CanCollide and " [X]" or " [ ]")
             anchoredCheckbox_GUI.Text = "Anchored" .. (activeItem.Anchored and " [X]" or " [ ]")


            if InstanceIsA(activeItem, "Part") then
                 shapeDropdown_GUI.Text = "Shape: " .. (activeItem.Shape and activeItem.Shape.Name or "Unknown")
                 materialDropdown_GUI.Text = "Material: " .. (activeItem.Material and activeItem.Material.Name or "Unknown")
                 shapeDropdown_GUI.Active = true
                 materialDropdown_GUI.Active = true
                 shapeDropdown_GUI.BackgroundColor3 = Color3New(0.4, 0.4, 0.4)
                 materialDropdown_GUI.BackgroundColor3 = Color3New(0.4, 0.4, 0.4)
            elseif InstanceIsA(activeItem, "PartOperation") then
                 shapeDropdown_GUI.Text = "Shape: " .. (activeItem.Type and activeItem.Type.Name or "PartOperation")
                 materialDropdown_GUI.Text = "Material: N/A (CSG)"
                 shapeDropdown_GUI.Active = false
                 materialDropdown_GUI.Active = false
                 shapeDropdown_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
                 materialDropdown_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
            end

        elseif InstanceIsA(activeItem, "Model") then
             -- Models can be moved and rotated (via PivotTo), but properties like Size, Color, Transparency are on children
             -- Grey out property controls not applicable to the Model itself
             sizeTextBoxes_GUI.X.Text = "N/A (Model)"
             sizeTextBoxes_GUI.Y.Text = "N/A (Model)"
             sizeTextBoxes_GUI.Z.Text = "N/A (Model)"
             colorTextBoxes_GUI.R.Text = "N/A (Model)"
             colorTextBoxes_GUI.G.Text = "N/A (Model)"
             colorTextBoxes_GUI.B.Text = "N/A (Model)"
             transparencyTextBox_GUI.Text = "N/A (Model)"
             reflectanceTextBox_GUI.Text = "N/A (Model)"
             shapeDropdown_GUI.Text = "Shape: Model"
             materialDropdown_GUI.Text = "Material: N/A"

              local greyOutControls = {
                 sizeTextBoxes_GUI.X, sizeTextBoxes_GUI.Y, sizeTextBoxes_GUI.Z,
                 colorTextBoxes_GUI.R, colorTextBoxes_GUI.G, colorTextBoxes_GUI.B,
                 transparencyTextBox_GUI, reflectanceTextBox_GUI,
                 shapeDropdown_GUI, materialDropdown_GUI,
            }
            for _, control in IpairsGlobal(greyOutControls) do
                 if control and InstanceIsA(control, "GuiObject") then
                     control.TextEditable = false
                     control.Active = false
                     control.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
                 end
            end

             -- CanCollide/Anchored on Model if PrimaryPart is set (complex), let's grey them out
             canCollideCheckbox_GUI.Tag = false
             canCollideCheckbox_GUI.Text = "CanCollide [ ] (Model)"
             canCollideCheckbox_GUI.Active = false
             canCollideCheckbox_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)

             anchoredCheckbox_GUI.Tag = false
             anchoredCheckbox_GUI.Text = "Anchored [ ] (Model)"
             anchoredCheckbox_GUI.Active = false
             anchoredCheckbox_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)

        else -- Other unsupported Instance types
             sizeTextBoxes_GUI.X.Text = "N/A"
             sizeTextBoxes_GUI.Y.Text = "N/A"
             sizeTextBoxes_GUI.Z.Text = "N/A"
             colorTextBoxes_GUI.R.Text = "N/A"
             colorTextBoxes_GUI.G.Text = "N/A"
             colorTextBoxes_GUI.B.Text = "N/A"
             transparencyTextBox_GUI.Text = "N/A"
             reflectanceTextBox_GUI.Text = "N/A"
             shapeDropdown_GUI.Text = "Shape: " .. activeItem.ClassName
             materialDropdown_GUI.Text = "Material: N/A"

              local greyOutControls = {
                 sizeTextBoxes_GUI.X, sizeTextBoxes_GUI.Y, sizeTextBoxes_GUI.Z,
                 colorTextBoxes_GUI.R, colorTextBoxes_GUI.G, colorTextBoxes_GUI.B,
                 transparencyTextBox_GUI, reflectanceTextBox_GUI,
                 shapeDropdown_GUI, materialDropdown_GUI,
                 canCollideCheckbox_GUI, anchoredCheckbox_GUI,
            }
            for _, control in IpairsGlobal(greyOutControls) do
                 if control and InstanceIsA(control, "GuiObject") then
                     control.TextEditable = false
                     control.Active = false
                     control.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
                 end
            end
        end


        Log.Info("GUI updated for active item (" .. (activeItem.Name or "Unnamed") .. ").")
    else
        Log.Info("GUI cleared (no active item).")
    end
    updateItemSelectionDropdown_GUI()
    -- Update Group/Ungroup button states (Ungroup depends on activeItem type)
     if groupButton_GUI and ungroupButton_GUI then
           -- Group state depends on selectedItems, updateItemSelection handles that
            ungroupButton_GUI.Active = activeItem ~= nil and InstanceIsA(activeItem, "Model") and not isPerformingBooleanOp
           ungroupButton_GUI.BackgroundColor3 = ungroupButton_GUI.Active and Color3New(0.6, 0.3, 0.3) or Color3New(0.5, 0.5, 0.5)
      end
    -- Update Pivot button state
     if setPivotButton_GUI then
          setPivotButton_GUI.Active = activeItem ~= nil and (InstanceIsA(activeItem, "BasePart") or InstanceIsA(activeItem, "Model"))
          setPivotButton_GUI.BackgroundColor3 = setPivotButton_GUI.Active and Color3New(0.4, 0.4, 0.8) or Color3New(0.5, 0.5, 0.5) -- Blueish
     end
end

-- Helper to update the item selection dropdown text
local function updateItemSelectionDropdown_GUI()
    if activeItem and activeItem.Parent then
         local activeIndex = -1
         for i, item in IpairsGlobal(managedItems) do
             if item == activeItem then
                 activeIndex = i
                 break
             end
         end
        itemSelectionDropdown_GUI.Text = "Item " .. activeIndex .. ": " .. (activeItem.Name or "Unnamed") .. " (" .. (activeItem.Shape and activeItem.Shape.Name or (activeItem.Type and activeItem.Type.Name) or activeItem.ClassName) .. ")"
    else
        itemSelectionDropdown_GUI.Text = "No Item Selected (" .. #managedItems .. " total)"
    end
end

-- Function to apply properties from GUI to the active item
function StudioBlock.applyPropertiesFromGUI()
    if activeItem and activeItem.Parent and InstanceIsA(activeItem, "BasePart") then -- Can only apply these properties to BaseParts
        safeCall(function()
            local currentShapeText = shapeDropdown_GUI.Text:match("Shape: (.+)") or (activeItem.Shape and activeItem.Shape.Name) or "Block"
            local currentMaterialText = materialDropdown_GUI.Text:match("Material: (.+)") or (activeItem.Material and activeItem.Material.Name) or "Plastic"

            local newShapeEnum = EnumPartType[currentShapeText] or EnumPartType.Block
            local newMaterialEnum = EnumMaterial[currentMaterialText] or EnumMaterial.Plastic

            local needsRecreation = InstanceIsA(activeItem, "Part") and (newShapeEnum ~= activeItem.Shape or newMaterialEnum ~= activeItem.Material)

            if needsRecreation then
                Log.Info("Changing Shape or Material, recreating Part.")
                local oldItem = activeItem
                local oldIndexInManaged = table.find(managedItems, oldItem) -- Get index before destroying

                local newPart = InstanceNew("Part")
                newPart.Shape = newShapeEnum
                newPart.Material = newMaterialEnum

                newPart.CFrame = oldItem.CFrame
                newPart.Size = oldItem.Size
                newPart.Color = oldItem.Color
                newPart.Transparency = oldItem.Transparency
                newPart.Reflectance = oldItem.Reflectance
                newPart.CanCollide = oldItem.CanCollide
                newPart.Anchored = oldItem.Anchored
                newPart.Name = oldItem.Name

                for _, child in IpairsGlobal(oldItem:GetChildren()) do
                    safeCall(function() child.Parent = newPart end)
                end

                if oldIndexInManaged then
                    managedItems[oldIndexInManaged] = newPart
                else
                     -- Fallback if item not found in managed list (shouldn't happen)
                     table.insert(managedItems, newPart)
                end

                oldItem:Destroy()

                activeItem = newPart
                newPart.Parent = Workspace

                Log.Info("Item recreated with new Shape/Material.")
            end

            if activeItem and activeItem.Parent and InstanceIsA(activeItem, "BasePart") then
                 StudioBlock.updateActiveItemSize()

                 activeItem.Transparency = getNumberFromTextBox(transparencyTextBox_GUI, activeItem.Transparency, 0, 1)
                 activeItem.Reflectance = getNumberFromTextBox(reflectanceTextBox_GUI, activeItem.Reflectance, 0, 1)
                 activeItem.CanCollide = canCollideCheckbox_GUI.Tag
                 activeItem.Anchored = anchoredCheckbox_GUI.Tag
                 Log.Info("Applied other properties to active item.")
            end

        end)
    elseif activeItem then
        Log.Warn("Cannot apply properties: Active item is not a BasePart.")
    else
        Log.Warn("No active item to apply properties to.")
    end
    updateGUIForActiveItem()
end

-- Set the current pivot to the active item's CFrame
function StudioBlock.setPivotToActiveItem()
     if activeItem and (InstanceIsA(activeItem, "BasePart") or InstanceIsA(activeItem, "Model")) then
          currentPivotCFrame = activeItem.CFrame -- Set pivot to the item's CFrame
          Log.Info("Pivot set to active item's location: " .. TostringGlobal(currentPivotCFrame.Position))
          -- Optional: Create a visual indicator for the pivot
           if pivotHighlightPart then pivotHighlightPart:Destroy() end
           pivotHighlightPart = InstanceNew("Part")
           pivotHighlightPart.Shape = EnumPartType.Ball
           pivotHighlightPart.Size = Vector3New(1, 1, 1)
           pivotHighlightPart.Anchored = true
           pivotHighlightPart.CanCollide = false
           pivotHighlightPart.Transparency = 0.5
           pivotHighlightPart.Color = Color3New(1, 1, 0) -- Yellow
           pivotHighlightPart.CFrame = currentPivotCFrame
           pivotHighlightPart.Parent = Workspace
     else
          currentPivotCFrame = nil
          Log.Warn("No active BasePart or Model to set pivot from. Pivot cleared.")
          if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end
     end
end

-- Add/Remove items from the selection list
function StudioBlock.toggleItemSelection(item)
    if item and item.Parent == Workspace then
        local indexInSelection = -1
        for i, selectedItem in IpairsGlobal(selectedItems) do
            if selectedItem == item then
                indexInSelection = i
                break
            end
        end

        if indexInSelection == -1 then
            -- Add to selection
            table.insert(selectedItems, item)
            -- Add visual highlight
            if InstanceIsA(item, "BasePart") then
                 item.LocalTransparencyModifier = Config.SELECTION_HIGHLIGHT_TRANSPARENCY
                 -- Remove Model highlight if it exists (e.g., selected a Part inside a Model)
                 if itemHighlights[item] then itemHighlights[item]:Destroy() itemHighlights[item] = nil end
            elseif InstanceIsA(item, "Model") then
                 -- Add Model highlight (bounding box Part)
                 if not itemHighlights[item] then
                      local boundingBox = item:GetBoundingBox()
                      local highlightPart = InstanceNew("Part")
                      highlightPart.Shape = EnumPartType.Block
                      highlightPart.Anchored = true
                      highlightPart.CanCollide = false
                      highlightPart.Transparency = Config.MODEL_HIGHLIGHT_TRANSPARENCY
                      highlightPart.Color = Config.MODEL_HIGHLIGHT_COLOR
                      highlightPart.CFrame = boundingBox -- Set CFrame and Size based on bounding box
                      highlightPart.Size = boundingBox.Size
                      highlightPart.Parent = Workspace -- Parent to workspace for consistent cleanup
                      itemHighlights[item] = highlightPart
                 end
            -- Add highlight for other types if needed later
            end
            Log.Info("Added item to selection: " .. (item.Name or "Unnamed"))
        else
            -- Remove from selection
            table.remove(selectedItems, indexInSelection)
            -- Remove visual highlight
             if InstanceIsA(item, "BasePart") then
                item.LocalTransparencyModifier = 0
             elseif InstanceIsA(item, "Model") then
                  if itemHighlights[item] then itemHighlights[item]:Destroy() itemHighlights[item] = nil end
             end
            Log.Info("Removed item from selection: " .. (item.Name or "Unnamed"))
        end
        Log.Info("Current selection count: " .. #selectedItems)
         -- Update button states
         if unionButton_GUI and negateButton_GUI then
              local basePartsInSelection = 0
              for _, item in IpairsGlobal(selectedItems) do if InstanceIsA(item, "BasePart") then basePartsInSelection += 1 end end

              local canPerformUnion = basePartsInSelection >= 2 and not isPerformingBooleanOp
              unionButton_GUI.Active = canPerformUnion
              unionButton_GUI.BackgroundColor3 = canPerformUnion and Color3New(0.2, 0.5, 0.8) or Color3New(0.5, 0.5, 0.5)

              local canPerformNegate = (basePartsInSelection == 2) and not isPerformingBooleanOp
              negateButton_GUI.Active = canPerformNegate
              negateButton_GUI.BackgroundColor3 = canPerformNegate and Color3New(0.2, 0.5, 0.8) or Color3New(0.5, 0.5, 0.5)
         end
          if groupButton_GUI and ungroupButton_GUI then
               groupButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
               groupButton_GUI.BackgroundColor3 = groupButton_GUI.Active and Color3New(0.3, 0.6, 0.3) or Color3New(0.5, 0.5, 0.5)
                ungroupButton_GUI.Active = activeItem ~= nil and InstanceIsA(activeItem, "Model") and not isPerformingBooleanOp
               ungroupButton_GUI.BackgroundColor3 = ungroupButton_GUI.Active and Color3New(0.6, 0.3, 0.3) or Color3New(0.5, 0.5, 0.5)
          end
           if duplicateButton_GUI then
              duplicateButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
               duplicateButton_GUI.BackgroundColor3 = duplicateButton_GUI.Active and Color3New(0.3, 0.6, 0.6) or Color3New(0.5, 0.5, 0.5)
           end
    else
         Log.Warn("Cannot toggle selection for invalid instance.")
    end
end

-- Clear the selection list
function StudioBlock.clearSelection()
    for _, item in IpairsGlobal(selectedItems) do
        if item and item.Parent then
             if InstanceIsA(item, "BasePart") then
                 item.LocalTransparencyModifier = 0
             elseif InstanceIsA(item, "Model") then
                  if itemHighlights[item] then itemHighlights[item]:Destroy() itemHighlights[item] = nil end
             end
        end
    end
    selectedItems = {}
    Log.Info("Selection cleared.")
     if unionButton_GUI and negateButton_GUI then
        unionButton_GUI.Active = false
         unionButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
        negateButton_GUI.Active = false
         negateButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5)
     end
      if groupButton_GUI and ungroupButton_GUI then
           groupButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
           groupButton_GUI.BackgroundColor3 = groupButton_GUI.Active and Color3New(0.3, 0.6, 0.3) or Color3New(0.5, 0.5, 0.5)
           -- Ungroup state depends on activeItem, updateGUIForActiveItem handles that
      end
       if duplicateButton_GUI then
           duplicateButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
            duplicateButton_GUI.BackgroundColor3 = duplicateButton_GUI.Active and Color3New(0.3, 0.6, 0.6) or Color3New(0.5, 0.5, 0.5)
       end
    -- Clear pivot when selection is cleared (optional, but often desired)
     -- StudioBlock.setPivotToActiveItem() -- Setting to nil will clear it
     -- Or just destroy the visual part if pivot is not tied to selection
     if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end
     currentPivotCFrame = nil -- Clear the pivot CFrame
end

-- Helper to handle boolean operation completion
local function handleBooleanOpComplete(success, resultPartOp, originalItems, operationType)
    isPerformingBooleanOp = false

     -- Update button states
     if unionButton_GUI and negateButton_GUI then
          local basePartsInSelection = 0
          for _, item in IpairsGlobal(selectedItems) do if InstanceIsA(item, "BasePart") then basePartsInSelection += 1 end end

          local canPerformUnion = basePartsInSelection >= 2 and not isPerformingBooleanOp
          unionButton_GUI.Active = canPerformUnion
          unionButton_GUI.BackgroundColor3 = canPerformUnion and Color3New(0.2, 0.5, 0.8) or Color3New(0.5, 0.5, 0.5)

          local canPerformNegate = (basePartsInSelection == 2) and not isPerformingBooleanOp
          negateButton_GUI.Active = canPerformNegate
          negateButton_GUI.BackgroundColor3 = canPerformNegate and Color3New(0.2, 0.5, 0.8) or Color3New(0.5, 0.5, 0.5)
     end
      if groupButton_GUI and ungroupButton_GUI then
           groupButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
           groupButton_GUI.BackgroundColor3 = groupButton_GUI.Active and Color3New(0.3, 0.6, 0.3) or Color3New(0.5, 0.5, 0.5)
            ungroupButton_GUI.Active = activeItem ~= nil and InstanceIsA(activeItem, "Model") and not isPerformingBooleanOp
           ungroupButton_GUI.BackgroundColor3 = ungroupButton_GUI.Active and Color3New(0.6, 0.3, 0.3) or Color3New(0.5, 0.5, 0.5)
      end
       if duplicateButton_GUI then
           duplicateButton_GUI.Active = #selectedItems > 0 and not isPerformingBooleanOp
            duplicateButton_GUI.BackgroundColor3 = duplicateButton_GUI.Active and Color3New(0.3, 0.6, 0.6) or Color3New(0.5, 0.5, 0.5)
       end


    if success and resultPartOp and InstanceIsA(resultPartOp, "PartOperation") then
        resultPartOp.Parent = Workspace
        resultPartOp.Name = operationType .. "_" .. #managedItems + 1

        local remainingManagedItems = {}
        for _, item in IpairsGlobal(managedItems) do
            local isOriginal = false
            for _, original in IpairsGlobal(originalItems) do
                if item == original then
                    isOriginal = true
                    if original and original.Parent then safeCall(function() original:Destroy() end) end
                    break
                end
            end
            if not isOriginal then
                table.insert(remainingManagedItems, item)
            end
        end
        managedItems = remainingManagedItems

        table.insert(managedItems, resultPartOp)

        Log.Info(operationType .. " operation successful. Created: " .. resultPartOp.Name)

        StudioBlock.setActiveBlockByIndex(#managedItems)

        StudioBlock.clearSelection()

    else
        Log.Error(operationType .. " operation failed: " .. TostringGlobal(resultPartOp))
    end
end

-- Perform a Union operation on selected BaseParts
function StudioBlock.performUnion()
    local basePartsInSelection = 0
    local itemsToUnion = {}
     local originalItems = {}
    for _, item in IpairsGlobal(selectedItems) do
        if item and item.Parent == Workspace and InstanceIsA(item, "BasePart") then
             table.insert(itemsToUnion, item:Clone())
             table.insert(originalItems, item)
             basePartsInSelection += 1
        else
            Log.Warn("Skipping non-BasePart item in selection for Union.")
        end
    end

    if basePartsInSelection < 2 then
        Log.Warn("Select at least two BaseParts to perform a Union operation.")
        return
    end
    if isPerformingBooleanOp then
         Log.Warn("Already performing a boolean operation. Please wait.")
         return
    end

    isPerformingBooleanOp = true

     Log.Info("Performing Union operation on " .. basePartsInSelection .. " items...")

    -- Disable boolean/group/duplicate buttons while processing
     if unionButton_GUI and negateButton_GUI then unionButton_GUI.Active = false; negateButton_GUI.Active = false; unionButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5); negateButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end
      if groupButton_GUI then groupButton_GUI.Active = false; groupButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end
      if duplicateButton_GUI then duplicateButton_GUI.Active = false; duplicateButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end


    local basePart = table.remove(itemsToUnion, 1)
    local unionAsyncResult = basePart:UnionAsync(itemsToUnion)

    unionAsyncResult.Then(function(resultPartOp)
        handleBooleanOpComplete(true, resultPartOp, originalItems, "Union")
    end, function(errorReason)
        handleBooleanOpComplete(false, TostringGlobal(errorReason), originalItems, "Union")
    end)
end

-- Perform a Negate operation on selected BaseParts
function StudioBlock.performNegate()
    local basePartsInSelection = 0
    local basePart = nil
    local partsToSubtract = {}
     local originalItems = {}

     for _, item in IpairsGlobal(selectedItems) do
         if item and item.Parent == Workspace and InstanceIsA(item, "BasePart") then
             local clonedPart = item:Clone()
             if basePartsInSelection == 0 then
                  basePart = clonedPart
             else
                 table.insert(partsToSubtract, clonedPart)
             end
             table.insert(originalItems, item)
             basePartsInSelection += 1
         else
             Log.Warn("Skipping non-BasePart item in selection for Negate.")
         end
     end


     if basePartsInSelection ~= 2 then
        Log.Warn("Negate operation requires exactly two selected BaseParts. The first selected is the base, the second is subtracted.")
         StudioBlock.clearSelection()
        return
    end
    if isPerformingBooleanOp then
         Log.Warn("Already performing a boolean operation. Please wait.")
         return
    end

     isPerformingBooleanOp = true

     Log.Info("Performing Negate operation: Subtracting the second selected item from the first.")

     -- Disable boolean/group/duplicate buttons while processing
     if unionButton_GUI and negateButton_GUI then unionButton_GUI.Active = false; negateButton_GUI.Active = false; unionButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5); negateButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end
      if groupButton_GUI then groupButton_GUI.Active = false; groupButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end
      if duplicateButton_GUI then duplicateButton_GUI.Active = false; duplicateButton_GUI.BackgroundColor3 = Color3New(0.5, 0.5, 0.5) end


    local negatingPart = partsToSubtract[1]
    negatingPart.Operation = Enum.PartOperationMode.Subtract

    local subtractAsyncResult = basePart:SubtractAsync({negatingPart})

    subtractAsyncResult.Then(function(resultPartOp)
        handleBooleanOpComplete(true, resultPartOp, originalItems, "Negate")
    end, function(errorReason)
        handleBooleanOpComplete(false, TostringGlobal(errorReason), originalItems, "Negate")
    end)
end

-- Duplicate selected items
function StudioBlock.duplicateSelectedItems()
     if #selectedItems == 0 then
         Log.Warn("No items selected to duplicate.")
         return
     end
      if isPerformingBooleanOp then
           Log.Warn("Cannot duplicate while performing boolean operation.")
           return
      end

     Log.Info("Duplicating " .. #selectedItems .. " selected items.")

     local duplicatedItems = {}
     for _, item in IpairsGlobal(selectedItems) do
          if item and item.Parent == Workspace then
              local clonedItem = safeCall(function() return item:Clone() end)
              if clonedItem then
                   if InstanceIsA(clonedItem, "BasePart") or InstanceIsA(clonedItem, "Model") then
                        clonedItem.CFrame = clonedItem.CFrame * CFrameNew(Config.DUPLICATE_OFFSET)
                   else
                         Log.Warn("Duplicated non-BasePart/Model item, positioning might be off.")
                   end

                    clonedItem.Parent = Workspace

                   table.insert(managedItems, clonedItem)
                   table.insert(duplicatedItems, clonedItem)
                   Log.Info("Duplicated item: " .. (clonedItem.Name or "Unnamed"))
              else
                   Log.Error("Failed to clone item: " .. (item.Name or "Unnamed"))
              end
          else
               Log.Warn("Skipping invalid item in selection for duplication.")
          end
     end

     StudioBlock.clearSelection()
     for _, duplicatedItem in IpairsGlobal(duplicatedItems) do
          StudioBlock.toggleItemSelection(duplicatedItem)
     end

     if #duplicatedItems > 0 then
          StudioBlock.setActiveBlockByIndex(table.find(managedItems, duplicatedItems[1]))
     end

     updateItemSelectionDropdown_GUI()
end

-- Rotate selected items around the current pivot
function StudioBlock.rotateSelectedItems(axis) -- Only takes axis now, angle from textbox
    if #selectedItems == 0 then
        Log.Warn("No items selected to rotate.")
        return
    end
     if isPerformingBooleanOp then
           Log.Warn("Cannot rotate while performing boolean operation.")
           return
      end
     if not currentPivotCFrame then
         Log.Warn("Pivot is not set. Use 'Set Pivot to Active Item' button first.")
         return
     end

     local angleDegrees = getNumberFromTextBox(rotateAngleTextBox_GUI, Config.INITIAL_ROTATION_ANGLE, -360, 360) -- Get angle from textbox
     local radians = MathRad(angleDegrees)
     local rotationCFrame = CFrameNew()

     if axis == "X" then rotationCFrame = CFrame.Angles(radians, 0, 0)
     elseif axis == "Y" then rotationCFrame = CFrame.Angles(0, radians, 0)
     elseif axis == "Z" then rotationCFrame = CFrame.Angles(0, 0, radians) end

     Log.Info("Rotating " .. #selectedItems .. " selected items around pivot (" .. TostringGlobal(currentPivotCFrame.Position) .. ") along " .. axis .. " axis by " .. angleDegrees .. " degrees.")

    safeCall(function()
        for _, item in IpairsGlobal(selectedItems) do
             if item and item.Parent == Workspace and (InstanceIsA(item, "BasePart") or InstanceIsA(item, "Model")) then
                 -- Rotate relative to the pivot using PivotTo
                 local currentCFrame = item.CFrame
                 -- Move the item to the pivot's origin, apply rotation, then move it back
                 item:PivotTo(currentPivotCFrame * CFrameNew:ToObjectSpace(currentPivotCFrame:Inverse() * currentCFrame) * rotationCFrame)

             else
                  Log.Warn("Skipping non-BasePart/Model item in selection for rotation.")
             end
        end
    end)
     updateGUIForActiveItem()
end

-- Scale selected BaseParts non-uniformly
function StudioBlock.scaleSelectedItems(axis, factor)
    if #selectedItems == 0 then
        Log.Warn("No BaseParts selected to scale.")
        return
    end
     if isPerformingBooleanOp then
           Log.Warn("Cannot scale while performing boolean operation.")
           return
      end

     if factor <= 0 then
         Log.Warn("Scale factor must be positive.")
         return
     end

    Log.Info("Scaling selected items along " .. axis .. " axis by factor " .. factor .. ".")

    safeCall(function()
        for _, item in IpairsGlobal(selectedItems) do
             if item and item.Parent == Workspace and InstanceIsA(item, "BasePart") then
                 local currentSize = item.Size
                 local newSize = currentSize

                 if axis == "X" then newSize = Vector3New(currentSize.X * factor, currentSize.Y, currentSize.Z)
                 elseif axis == "Y" then newSize = Vector3New(currentSize.X, currentSize.Y * factor, currentSize.Z)
                 elseif axis == "Z" then newSize = Vector3New(currentSize.X, currentSize.Y, currentSize.Z * factor) end

                 newSize = Vector3New(
                     MathClamp(newSize.X, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max),
                     MathClamp(newSize.Y, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max),
                     MathClamp(newSize.Z, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
                 )

                 item.Size = newSize
             else
                  Log.Warn("Skipping non-BasePart item in selection for scaling.")
             end
        end
    end)
     updateGUIForActiveItem()
end


-- Group selected items into a Model
function StudioBlock.groupSelectedItems()
     if #selectedItems == 0 then
         Log.Warn("Select items to group.")
         return
     end
      if isPerformingBooleanOp then
           Log.Warn("Cannot group while performing boolean operation.")
           return
      end

     local validItemsToGroup = {}
      for _, item in IpairsGlobal(selectedItems) do
           if item and item.Parent and item.Parent ~= Workspace and not InstanceIsA(item.Parent, "Service") then
                table.insert(validItemsToGroup, item)
           elseif item and item.Parent == Workspace then
                 table.insert(validItemsToGroup, item)
           else
                 Log.Warn("Skipping invalid item for grouping.")
           end
      end

     if #validItemsToGroup == 0 then
          Log.Warn("No valid items selected to group.")
          return
     end

     Log.Info("Grouping " .. #validItemsToGroup .. " selected items.")

     local newModel = InstanceNew("Model")
     newModel.Name = "StudioModel_" .. #managedItems + 1
     newModel.Parent = Workspace

     -- Calculate the center CFrame of the selected items for the model's CFrame/Pivot
      local centerPos = Vector3New(0,0,0)
      local totalWeight = 0
      for _, item in IpairsGlobal(validItemsToGroup) do
          local pos = item.Position
          local weight = 1 -- Can use size/volume for weighted average if needed
          centerPos = centerPos + pos * weight
          totalWeight = totalWeight + weight
      end
      if totalWeight > 0 then centerPos = centerPos / totalWeight end

      newModel.CFrame = CFrameNew(centerPos) -- Set the model's CFrame to the center of selected items

     safeCall(function()
          for _, item in IpairsGlobal(validItemsToGroup) do
               if item and item.Parent ~= newModel then
                    item.Parent = newModel
               end
          end
     end)

     table.insert(managedItems, newModel)
     StudioBlock.setActiveBlockByIndex(#managedItems)
     StudioBlock.clearSelection()

      updateItemSelectionDropdown_GUI()
end

-- Ungroup the active Model
function StudioBlock.ungroupActiveModel()
     if not activeItem or not InstanceIsA(activeItem, "Model") then
          Log.Warn("Active item is not a Model to ungroup.")
          return
     end
      if isPerformingBooleanOp then
           Log.Warn("Cannot ungroup while performing boolean operation.")
           return
      end

     local modelToUngroup = activeItem
     local originalParent = modelToUngroup.Parent

     Log.Info("Ungrouping model: " .. (modelToUngroup.Name or "Unnamed"))

     local childrenToManage = {}

     safeCall(function()
          for _, child in IpairsGlobal(modelToUngroup:GetChildren()) do
               if child and child.Parent == modelToUngroup then
                    child.Parent = originalParent
                    table.insert(childrenToManage, child)
               end
          end
     end)

     local indexInManaged = -1
      for i, item in IpairsGlobal(managedItems) do
          if item == modelToUngroup then
              indexInManaged = i
              table.remove(managedItems, i)
              break
          end
      end

      for _, child in IpairsGlobal(childrenToManage) do
          table.insert(managedItems, child)
      end


     modelToUngroup:Destroy()
     activeItem = nil

     if #childrenToManage > 0 then
          StudioBlock.setActiveBlockByIndex(table.find(managedItems, childrenToManage[1]))
     else
           StudioBlock.setActiveBlockByIndex(nil)
     end

     StudioBlock.clearSelection()
     updateItemSelectionDropdown_GUI()

end


function StudioBlock.createNewBlock()
    local newPart = InstanceNew("Part")
    newPart.Anchored = anchoredCheckbox_GUI.Tag
    newPart.CanCollide = canCollideCheckbox_GUI.Tag
    newPart.Parent = Workspace
    local currentShapeText = shapeDropdown_GUI.Text:match("Shape: (.+)") or Config.INITIAL_PART_TYPE.Name
    local currentMaterialText = materialDropdown_GUI.Text:match("Material: (.+)") or Config.INITIAL_MATERIAL.Name
    newPart.Material = EnumMaterial[currentMaterialText] or Config.INITIAL_MATERIAL
    newPart.Shape = EnumPartType[currentShapeText] or Config.INITIAL_PART_TYPE
    newPart.Transparency = getNumberFromTextBox(transparencyTextBox_GUI, Config.INITIAL_TRANSPARENCY, 0, 1)
    newPart.Reflectance = getNumberFromTextBox(reflectanceTextBox_GUI, Config.INITIAL_REFLECTANCE, 0, 1)

    newPart.Name = "StudioItem_" .. #managedItems + 1

    local particleEmitter = InstanceNew("ParticleEmitter")
    particleEmitter.Lifetime = NumberRange.new(Config.PARTICLE_LIFETIME)
    particleEmitter.Rate = Config.PARTICLE_RATE
    particleEmitter.Color = ColorSequence.new(Config.PARTICLE_COLOR)
    particleEmitter.Size = Config.PARTICLE_SIZE
    particleEmitter.Speed = NumberRange.new(Config.PARTICLE_SPEED)
    particleEmitter.EmissionDirection = Enum.ParticleEmissionDirection.Any
    particleEmitter.Enabled = false
    particleEmitter.Parent = newPart

     newPart.Size = Vector3New(
         getNumberFromTextBox(sizeTextBoxes_GUI.X, Config.INITIAL_BLOCK_SIZE.X, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max),
         getNumberFromTextBox(sizeTextBoxes_GUI.Y, Config.INITIAL_BLOCK_SIZE.Y, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max),
         getNumberFromTextBox(sizeTextBoxes_GUI.Z, Config.INITIAL_BLOCK_SIZE.Z, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
     )
      newPart.Color = Color3New(
         getNumberFromTextBox(colorTextBoxes_GUI.R, Config.INITIAL_BLOCK_COLOR.R, 0, 1),
         getNumberFromTextBox(colorTextBoxes_GUI.G, Config.INITIAL_BLOCK_COLOR.G, 0, 1),
         getNumberFromTextBox(colorTextBoxes_GUI.B, Config.INITIAL_BLOCK_COLOR.B, 0, 1)
     )


    safeCall(function()
        local localPlayer = Players.LocalPlayer
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        if character then
            local primaryPart = character:WaitForChild("HumanoidRootPart", 5)
            if primaryPart then
                newPart.CFrame = CFrameNew(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3New(0, 5, 0))
                Log.Info("Placed new item near player.")
            else
                Log.Warn("HumanoidRootPart not found on character after waiting, placing item at origin.")
                newPart.CFrame = CFrameNew(0, 10, 0)
            end
        else
            Log.Warn("Character not found, placing item at origin.")
            newPart.CFrame = CFrameNew(0, 10, 0)
        end
    end)

    table.insert(managedItems, newPart)
    StudioBlock.setActiveBlockByIndex(#managedItems)
     updateItemSelectionDropdown_GUI()
end

function StudioBlock.removeActiveBlock()
     if activeItem and activeItem.Parent then
        local itemName = activeItem.Name
        local indexToRemove = -1
        for i, item in IpairsGlobal(managedItems) do
            if item == activeItem then
                indexToRemove = i
                break
            end
        end
        if indexToRemove ~= -1 then
            table.remove(managedItems, indexToRemove)
        end

        activeItem:Destroy()
        activeItem = nil
        Log.Info("Removed item: " .. itemName)
        if #managedItems > 0 then
             StudioBlock.setActiveBlockByIndex(MathClamp(indexToRemove, 1, #managedItems))
        else
             StudioBlock.setActiveBlockByIndex(nil)
        end
    else
        Log.Warn("No active item to remove.")
    end
     updateItemSelectionDropdown_GUI()
    StudioBlock.clearSelection()
end

function StudioBlock.setActiveBlockByIndex(index)
    if index and index >= 1 and index <= #managedItems and managedItems[index] then
        activeItem = managedItems[index]
        Log.Info("Active item set to index: " .. index .. " (" .. activeItem.Name .. ").")
        updateGUIForActiveItem()
    elseif index == nil or #managedItems == 0 then
        activeItem = nil
         Log.Info("No active item selected.")
         updateGUIForActiveItem()
    else
        Log.Warn("Invalid item index: " .. TostringGlobal(index))
    end
     updateItemSelectionDropdown_GUI()
     StudioBlock.clearSelection() -- Clear selection when active item changes
     -- Clear pivot when active item changes (optional)
      if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end
      currentPivotCFrame = nil
end


function StudioBlock.updateActiveItemSize()
    if activeItem and activeItem.Parent and InstanceIsA(activeItem, "BasePart") then
        local sizeX = getNumberFromTextBox(sizeTextBoxes_GUI.X, activeItem.Size.X, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        local sizeY = getNumberFromTextBox(sizeTextBoxes_GUI.Y, activeItem.Size.Y, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        local sizeZ = getNumberFromTextBox(sizeTextBoxes_GUI.Z, activeItem.Size.Z, Config.BLOCK_SIZE_LIMITS.min, Config.BLOCK_SIZE_LIMITS.max)
        activeItem.Size = Vector3New(sizeX, sizeY, sizeZ)
        Log.Info("Updated active item size.")
    else
         Log.Warn("No active BasePart to update size.")
    end
     updateGUIForActiveItem()
end

function StudioBlock.updateActiveItemColor()
    if activeItem and activeItem.Parent and InstanceIsA(activeItem, "BasePart") then
        local colorR = getNumberFromTextBox(colorTextBoxes_GUI.R, activeItem.Color.R, 0, 1)
        local colorG = getNumberFromTextBox(colorTextBoxes_GUI.G, activeItem.Color.G, 0, 1)
        local colorB = getNumberFromTextBox(colorTextBoxes_GUI.B, activeItem.Color.B, 0, 1)
        activeItem.Color = Color3New(colorR, colorG, colorB)
        Log.Info("Updated active item color.")
    else
         Log.Warn("No active BasePart to update color.")
    end
     updateGUIForActiveItem()
end

function StudioBlock.moveActiveItem(directionVector)
    if activeItem and activeItem.Parent and (InstanceIsA(activeItem, "BasePart") or InstanceIsA(activeItem, "Model")) then
         if currentPivotCFrame then
              -- Move relative to the pivot
              local currentCFrame = activeItem.CFrame
              local newCFrame = currentCFrame * CFrameNew(directionVector)
              activeItem:PivotTo(newCFrame) -- Move relative to the pivot
         else
              -- Move relative to the item's own CFrame
              activeItem.CFrame = activeItem.CFrame * CFrameNew(directionVector)
         end
    end
end

function StudioBlock.repositionActiveItemAfterRespawn(character)
    if activeItem and activeItem.Parent and (InstanceIsA(activeItem, "BasePart") or InstanceIsA(activeItem, "Model")) and character then
        local primaryPart = character:WaitForChild("HumanoidRootPart", 5)
        if primaryPart then
            safeCall(function()
                 -- Reposition relative to the item's own CFrame (repositioning doesn't usually use pivot)
                 activeItem.CFrame = CFrameNew(primaryPart.Position + primaryPart.CFrame.LookVector * 10 + Vector3New(0, 5, 0))
                 Log.Info("Repositioned active item after respawn.")
                 -- Reset pivot after repositioning (optional)
                 if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end
                 currentPivotCFrame = nil
            end)
        else
            Log.Warn("HumanoidRootPart not found on new character after waiting, cannot reposition active item.")
        end
    end
end

-- Function to save ALL item configurations (Basic Model Save/Load)
function StudioBlock.saveItemConfig()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
         Log.Warn("LocalPlayer not available, cannot save configuration.")
         return
    end

    local configsToSave = {}

    -- Helper function to recursively save item properties
    local function saveItemRecursive(item)
        if not item or not item.Parent or item == game or InstanceIsA(item.Parent, "Service") then
             return nil -- Skip invalid or service-related items
        end

        local itemConfig = {
            Name = item.Name,
            Type = item.ClassName,
            Position = {X = item.Position.X, Y = item.Position.Y, Z = item.Position.Z}, -- Position for BaseParts/Models
            Transparency = item.Transparency, -- Common on BaseParts
            Reflectance = item.Reflectance, -- Common on BaseParts
            CanCollide = item.CanCollide, -- Common on BaseParts/Models
            Anchored = item.Anchored, -- Common on BaseParts/Models
        }

        if InstanceIsA(item, "BasePart") then
             itemConfig.Size = {X = item.Size.X, Y = item.Size.Y, Z = item.Size.Z}
             itemConfig.Color = {R = item.Color.R, G = item.Color.G, B = item.Color.B}
        end

        if InstanceIsA(item, "Part") then
             itemConfig.Shape = item.Shape.Name
             itemConfig.Material = item.Material.Name
        elseif InstanceIsA(item, "PartOperation") then
             if item.Name:match("^Union") then itemConfig.CSGOperation = "Union"
             elseif item.Name:match("^Negate") then itemConfig.CSGOperation = "Negate"
             end
        elseif InstanceIsA(item, "Model") then
             itemConfig.Children = {}
             -- Recursively save children of the model
             for _, child in IpairsGlobal(item:GetChildren()) do
                  local childConfig = saveItemRecursive(child) -- Save the child
                  if childConfig then
                       table.insert(itemConfig.Children, childConfig)
                  end
             end
             -- Need to handle PrimaryPart CFrame relative to Model CFrame if saving PrimaryPart
             -- For simplicity, only saving children properties directly for now.
        -- Skip other types for simplicity (e.g., MeshParts, Accessories, etc.)
        else
             Log.Warn("Skipping saving unsupported item type '" .. item.ClassName .. "' Name: " .. (item.Name or "Unnamed"))
             return nil -- Skip saving this item
        end

         return itemConfig
    end -- End saveItemRecursive

    -- Save all top-level items managed by the script
    for _, item in IpairsGlobal(managedItems) do
        if item and item.Parent == Workspace then -- Only save top-level items directly in Workspace
             local itemConfig = saveItemRecursive(item)
             if itemConfig then
                 table.insert(configsToSave, itemConfig)
             end
        else
             Log.Warn("Skipping saving managed item not in Workspace or already a child: " .. (item and item.Name or "Unnamed"))
        end
    end


    if #configsToSave == 0 then
         Log.Warn("No savable top-level items (Parts/PartOperations/Models) found in Workspace.")
         return
    end

    local retries = Config.DATASTORE_RETRY_ATTEMPTS
    local success = false
    local errorMessage = "Unknown error"

    for i = 1, retries do
        success, errorMessage = pcall(function()
            itemDataStore:SetAsync(TostringGlobal(localPlayer.UserId), configsToSave)
        end)
        if success then
            Log.Info("Item configurations saved successfully (" .. #configsToSave .. " top-level items).")
            return
        else
            Log.Warn("Failed to save item configurations (Attempt " .. i .. "/" .. retries .. "): " .. TostringGlobal(errorMessage))
            if i < retries then TaskWait(Config.DATASTORE_RETRY_DELAY) end
        end
    end
    Log.Error("Failed to save item configurations after " .. retries .. " attempts: " .. TostringGlobal(errorMessage))
end

-- Function to load ALL item configurations (Basic Model Save/Load)
function StudioBlock.loadItemConfig()
     local localPlayer = Players.LocalPlayer
     if not localPlayer then
         Log.Warn("LocalPlayer not available, cannot load configuration.")
         return
     end

    for _, item in IpairsGlobal(managedItems) do
        if item and item.Parent then safeCall(function() item:Destroy() end) end
    end
    managedItems = {}
    activeItem = nil
    StudioBlock.clearSelection()
     if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end
     currentPivotCFrame = nil

    local success, savedConfigs = pcall(function()
        return itemDataStore:GetAsync(TostringGlobal(localPlayer.UserId))
    end)

    -- Helper function to recursively load item properties
    local function loadItemRecursive(itemConfig, parentItem)
        if not itemConfig or not itemConfig.Type then
             Log.Warn("Skipping loading item due to missing or invalid configuration.")
             return nil
        end

        local loadedItem = nil
        local parentInstance = parentItem or Workspace -- Default parent is Workspace if no parentItem provided (top level)

        if itemConfig.Type == "Part" then
             loadedItem = InstanceNew("Part")
             if itemConfig.Shape then loadedItem.Shape = EnumPartType[itemConfig.Shape] or Config.INITIAL_PART_TYPE end
             if itemConfig.Material then loadedItem.Material = EnumMaterial[itemConfig.Material] or Config.INITIAL_MATERIAL end
             if itemConfig.Size then loadedItem.Size = Vector3New(itemConfig.Size.X, itemConfig.Size.Y, itemConfig.Size.Z) else loadedItem.Size = Config.INITIAL_BLOCK_SIZE end

        elseif itemConfig.Type == "UnionOperation" or itemConfig.Type == "NegateOperation" then
             loadedItem = InstanceNew("Part") -- Load PartOperation as a basic Part
             Log.Warn("Loaded PartOperation (" .. itemConfig.Type .. ") as a basic Part; complex geometry is lost.")
             if itemConfig.Size then loadedItem.Size = Vector3New(itemConfig.Size.X, itemConfig.Size.Y, itemConfig.Size.Z) else loadedItem.Size = Config.INITIAL_BLOCK_SIZE end
             loadedItem.Shape = Config.INITIAL_PART_TYPE -- Set default shape
             loadedItem.Material = Config.INITIAL_MATERIAL -- Set default material

        elseif itemConfig.Type == "Model" then
             loadedItem = InstanceNew("Model")
             if itemConfig.Children and TypeOfGlobal(itemConfig.Children) == "table" then
                  -- Recursively load children
                  for _, childConfig in IpairsGlobal(itemConfig.Children) do
                       local loadedChild = loadItemRecursive(childConfig, loadedItem) -- Pass the new model as parent
                       -- loadedChild.Parent is set inside recursive call
                  end
             end
             -- Handle PrimaryPart loading if saved (complex), skipping for now
        -- Skip other types for simplicity (e.g., MeshParts, Accessories, etc.)
        else
             Log.Warn("Skipping loading unsupported item type '" .. TostringGlobal(itemConfig.Type) .. "' Name: " .. (itemConfig.Name or "Unnamed"))
             return nil
        end

        if loadedItem then
             loadedItem.Parent = parentInstance -- Set parent after creation

             loadedItem.Name = itemConfig.Name or ("LoadedItem_" .. #managedItems + 1) -- Assign a name during load
             loadedItem.Transparency = itemConfig.Transparency ~= nil and itemConfig.Transparency or (InstanceIsA(loadedItem, "BasePart") and Config.INITIAL_TRANSPARENCY or 0) -- Apply transparency if BasePart
             loadedItem.Reflectance = itemConfig.Reflectance ~= nil and itemConfig.Reflectance or (InstanceIsA(loadedItem, "BasePart") and Config.INITIAL_REFLECTANCE or 0) -- Apply reflectance if BasePart
             loadedItem.CanCollide = itemConfig.CanCollide ~= nil and itemConfig.CanCollide or Config.INITIAL_CAN_COLLIDE
             loadedItem.Anchored = itemConfig.Anchored ~= nil and itemConfig.Anchored or Config.INITIAL_ANCHORED
             if itemConfig.Color and InstanceIsA(loadedItem, "BasePart") then loadedItem.Color = Color3New(itemConfig.Color.R, itemConfig.Color.G, itemConfig.Color.B) end -- Apply color if BasePart
             if itemConfig.Position then loadedItem.Position = Vector3New(itemConfig.Position.X, itemConfig.Position.Y, itemConfig.Position.Z) end


             -- Add particle emitter if it's a BasePart and doesn't have one already (e.g. if PartOperation became Part)
             if InstanceIsA(loadedItem, "BasePart") and not loadedItem:FindFirstChildOfClass("ParticleEmitter") then
                 local particleEmitter = InstanceNew("ParticleEmitter")
                 particleEmitter.Lifetime = NumberRange.new(Config.PARTICLE_LIFETIME)
                 particleEmitter.Rate = Config.PARTICLE_RATE
                 particleEmitter.Color = ColorSequence.new(Config.PARTICLE_COLOR)
                 particleEmitter.Size = Config.PARTICLE_SIZE
                 particleEmitter.Speed = NumberRange.new(Config.PARTICLE_SPEED)
                 particleEmitter.EmissionDirection = Enum.ParticleEmissionDirection.Any
                 particleEmitter.Enabled = false
                 particleEmitter.Parent = loadedItem
             end

             -- Add to managedItems ONLY if it's a top-level item being loaded
             if parentItem == nil then
                  table.insert(managedItems, loadedItem)
             end

             Log.Info("Loaded item: " .. loadedItem.Name .. " (" .. loadedItem.ClassName .. "). Parent: " .. (parentInstance and parentInstance.Name or "None (Workspace)"))
         end

         return loadedItem
    end -- End loadItemRecursive


    if success and savedConfigs and TypeOfGlobal(savedConfigs) == "table" then
        if #savedConfigs > 0 then
             Log.Info("Loading " .. #savedConfigs .. " top-level item configurations.")
             for i, itemConfig in IpairsGlobal(savedConfigs) do
                 safeCall(function()
                      loadItemRecursive(itemConfig, nil) -- Load top-level items with no parent
                 end)
             end

             StudioBlock.setActiveBlockByIndex(1)
        else
            Log.Info("Saved data found, but it contains no savable items.")
        end
    elseif success and not savedConfigs then
        Log.Info("No saved item configuration found.")
    else
        Log.Error("Failed to load item configurations: " .. TostringGlobal(savedConfigs))
    end
    updateGUIForActiveItem()
    updateItemSelectionDropdown_GUI()
end


-- === GUI Creation and Event Handling ===
local screenGui = nil
local mainFrame = nil
local toggleButton = nil
sizeTextBoxes_GUI = {}
colorTextBoxes_GUI = {}
local guiMoveButtons = {}
itemSelectionDropdown_GUI = nil
toggleMobileButtonsCheckbox_GUI = nil
unionButton_GUI = nil
negateButton_GUI = nil
duplicateButton_GUI = nil
groupButton_GUI = nil
ungroupButton_GUI = nil
rotateAngleTextBox_GUI = nil -- New GUI reference
local rotateButtonWidth -- Store calculated width
local setPivotButton_GUI = nil
local mobileVirtualButtonsFrame = nil


local function createGUI()
    local localPlayer = Players.LocalPlayer

    local existingGui = localPlayer:WaitForChild("PlayerGui"):FindFirstChild(Config.GUI_NAME)
    if existingGui then
        Log.Warn("Found existing GUI '" .. Config.GUI_NAME .. "', destroying it.")
        existingGui:Destroy()
    end

    screenGui = InstanceNew("ScreenGui")
    screenGui.Name = Config.GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer.PlayerGui

    toggleButton = createButton(screenGui, "Toggle UI", UDim2New(0, 100, 0, 30), {
        Position = UDim2New(0, 10, 1, -40),
        BackgroundColor3 = Color3New(0.7, 0.7, 0.3),
        TextSize = 14,
        ZIndex = 10
    })

    mainFrame = InstanceNew("Frame")
    mainFrame.Size = UDim2New(0, Config.GUI_WIDTH, 0, 0)
    mainFrame.Position = UDim2New(0.5, -Config.GUI_WIDTH/2, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3New(0.15, 0.15, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    mainFrame.Visible = true

    local listLayout = InstanceNew("UIListLayout")
    listLayout.Padding = UDimNew(0, Config.SPACING)
    listLayout.SortOrder = EnumSortOrder.LayoutOrder
    listLayout.HorizontalAlignment = EnumHorizontalAlignment.Center
    listLayout.Parent = mainFrame

    mainFrame.AutomaticSize = EnumAutomaticSize.Y

    local uiScale = InstanceNew("UIScale")
    uiScale.Parent = mainFrame
    uiScale.Scale = MathClamp(Camera.ViewportSize.X / 1000, 0.5, 1.5)


    local titleLabel = createLabel(mainFrame, "Studio Item Editor v10.0", {
        Size = UDim2New(1, 0, 0, 30),
        BackgroundColor3 = Color3New(0.25, 0.25, 0.25),
        TextColor3 = Color3New(0.9, 0.9, 0.9),
        Font = Enum.Font.SourceSansBold, TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextInsets = UDimInsetsNew(0, 0, 0, 0),
        LayoutOrder = 1
    })

    -- Item Selection Control
    local selectItemLabel = createLabel(mainFrame, "Select Item:", {LayoutOrder = 2})
    itemSelectionDropdown_GUI = createButton(mainFrame, "No Item Selected (" .. #managedItems .. " total)", UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 3})
    itemSelectionDropdown_GUI.MouseButton1Click:Connect(function()
        if #managedItems > 0 then
            local currentIndex = -1
            for i, item in IpairsGlobal(managedItems) do
                if item == activeItem then
                    currentIndex = i
                    break
                end
            end
            local nextIndex = (currentIndex % #managedItems) + 1
            StudioBlock.setActiveBlockByIndex(nextIndex)
        else
             StudioBlock.setActiveBlockByIndex(nil)
        end
    end)
    StudioBlock.updateItemSelectionDropdown = updateItemSelectionDropdown_GUI


    -- Size Controls
    local sizeLabel = createLabel(mainFrame, "Size (X, Y, Z):", {LayoutOrder = 4})
    sizeTextBoxes_GUI.X = createTextBox(mainFrame, "Size X", "", UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 5})
    sizeTextBoxes_GUI.Y = createTextBox(mainFrame, "Size Y", "", UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 6})
    sizeTextBoxes_GUI.Z = createTextBox(mainFrame, "Size Z", "", UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 7})

    handleTextBoxFocusLost(sizeTextBoxes_GUI.X, function() StudioBlock.applyPropertiesFromGUI() end)
    handleTextBoxFocusLost(sizeTextBoxes_GUI.Y, function() StudioBlock.applyPropertiesFromGUI() end)
    handleTextBoxFocusLost(sizeTextBoxes_GUI.Z, function() StudioBlock.applyPropertiesFromGUI() end)


    -- Color Controls
    local colorLabel = createLabel(mainFrame, "Color (R, G, B 0-1):", {LayoutOrder = 8})
    local colorTextBoxWidth = (Config.GUI_WIDTH - 10 - Config.SPACING*2) / 3
    local colorLayoutOrder = 9
    local colorFrame = InstanceNew("Frame")
    colorFrame.Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
    colorFrame.BackgroundColor3 = Color3New(1, 1, 1, 0)
    colorFrame.BorderSizePixel = 0
    colorFrame.Parent = mainFrame
    colorFrame.LayoutOrder = colorLayoutOrder
    local colorListLayout = InstanceNew("UIListLayout")
    colorListLayout.FillDirection = EnumFillDirection.Horizontal
    colorListLayout.Padding = UDimNew(0, Config.SPACING)
    colorListLayout.SortOrder = EnumSortOrder.LayoutOrder
    colorListLayout.Parent = colorFrame

    colorTextBoxes_GUI.R = createTextBox(colorFrame, "Color R", "", UDim2New(0, colorTextBoxWidth, 1, 0), {LayoutOrder = 1})
    colorTextBoxes_GUI.G = createTextBox(colorFrame, "Color G", "", UDim2New(0, colorTextBoxWidth, 1, 0), {LayoutOrder = 2})
    colorTextBoxes_GUI.B = createTextBox(colorFrame, "Color B", "", UDim2New(0, colorTextBoxWidth, 1, 0), {LayoutOrder = 3})

    handleTextBoxFocusLost(colorTextBoxes_GUI.R, function() StudioBlock.applyPropertiesFromGUI() end)
    handleTextBoxFocusLost(colorTextBoxes_GUI.G, function() StudioBlock.applyPropertiesFromGUI() end)
    handleTextBoxFocusLost(colorTextBoxes_GUI.B, function() StudioBlock.applyPropertiesFromGUI() end)


    -- Add New Property Controls
    -- Shape (Simple TextButton dropdown)
    local shapeLabel = createLabel(mainFrame, "Shape:", {LayoutOrder = 10})
    shapeDropdown_GUI = createButton(mainFrame, "Shape: " .. Config.INITIAL_PART_TYPE.Name, UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 11})
    local partTypes = {EnumPartType.Block, EnumPartType.Ball, EnumPartType.Cylinder, EnumPartType.Wedge, EnumPartType.CornerWedge}
    local currentShapeIndex = 1
    for i, shape in IpairsGlobal(partTypes) do if shape == Config.INITIAL_PART_TYPE then currentShapeIndex = i; break end end
    shapeDropdown_GUI.MouseButton1Click:Connect(function()
        if shapeDropdown_GUI.Active then -- Only allow clicking if active
            currentShapeIndex = (currentShapeIndex % #partTypes) + 1
            local selectedShape = partTypes[currentShapeIndex]
            shapeDropdown_GUI.Text = "Shape: " .. selectedShape.Name
            Log.Info("Selected shape: " .. selectedShape.Name)
        end
    end)


    -- Material (Simple TextButton dropdown)
    local materialLabel = createLabel(mainFrame, "Material:", {LayoutOrder = 12})
    materialDropdown_GUI = createButton(mainFrame, "Material: " .. Config.INITIAL_MATERIAL.Name, UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 13})
    local commonMaterials = {EnumMaterial.Plastic, EnumMaterial.Wood, EnumMaterial.Slate, EnumMaterial.Concrete, EnumMaterial.Fabric, EnumMaterial.Sand, EnumMaterial.Grass, EnumMaterial.Mud, EnumMaterial.Brick, EnumMaterial.Pebble, EnumMaterial.Rock, EnumMaterial.Ice, EnumMaterial.Snow, EnumMaterial.Glass, EnumMaterial.SmoothPlastic, EnumMaterial.Metal, EnumMaterial.DiamondPlate, EnumMaterial.Foil, EnumMaterial.Granite, EnumMaterial.Marble, EnumMaterial.Basalt, EnumMaterial.Ground, EnumMaterial.Asphalt, EnumMaterial.Cobblestone, EnumMaterial.CorrodedMetal, EnumMaterial.CrackedLava, EnumMaterial.GlassSmooth, EnumMaterial.LeafyGrass, EnumMaterial.Limestone, EnumMaterial.MuddyRock, EnumMaterial.PlaidFabric, EnumMaterial.Salt, EnumMaterial.Sandstone, EnumMaterial.SnowSmooth, EnumMaterial.WoodGrain, EnumMaterial.Neon, EnumMaterial.ForceField}
    local currentMaterialIndex = 1
    for i, mat in IpairsGlobal(commonMaterials) do if mat == Config.INITIAL_MATERIAL then currentMaterialIndex = i; break end end
    materialDropdown_GUI.MouseButton1Click:Connect(function()
        if materialDropdown_GUI.Active then -- Only allow clicking if active
            currentMaterialIndex = (currentMaterialIndex % #commonMaterials) + 1
            local selectedMaterial = commonMaterials[currentMaterialIndex]
            materialDropdown_GUI.Text = "Material: " .. selectedMaterial.Name
            Log.Info("Selected material: " .. selectedMaterial.Name)
        end
    end)

    -- Transparency and Reflectance TextBoxes
    local transparencyLabel = createLabel(mainFrame, "Transparency (0-1):", {LayoutOrder = 14})
    transparencyTextBox_GUI = createTextBox(mainFrame, "0", TostringGlobal(Config.INITIAL_TRANSPARENCY), UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 15})
    handleTextBoxFocusLost(transparencyTextBox_GUI, function() StudioBlock.applyPropertiesFromGUI() end)

    local reflectanceLabel = createLabel(mainFrame, "Reflectance (0-1):", {LayoutOrder = 16})
    reflectanceTextBox_GUI = createTextBox(mainFrame, "0", TostringGlobal(Config.INITIAL_REFLECTANCE), UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT), {LayoutOrder = 17})
    handleTextBoxFocusLost(reflectanceTextBox_GUI, function() StudioBlock.applyPropertiesFromGUI() end)

    -- CanCollide and Anchored Checkboxes
    canCollideCheckbox_GUI = createCheckbox(mainFrame, "CanCollide", Config.INITIAL_CAN_COLLIDE, {
        LayoutOrder = 18,
        Size = UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT),
        OnToggled = function(newState)
            StudioBlock.applyPropertiesFromGUI()
        end
    })
    anchoredCheckbox_GUI = createCheckbox(mainFrame, "Anchored", Config.INITIAL_ANCHORED, {
        LayoutOrder = 19,
        Size = UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT),
         OnToggled = function(newState)
            StudioBlock.applyPropertiesFromGUI()
        end
    })

    -- Add Apply Properties Button
    local applyPropertiesButton = createButton(mainFrame, "Apply Properties", UDim2New(1, -10, 0, 30), {
        BackgroundColor3 = Color3New(0.3, 0.6, 0.3),
        LayoutOrder = 20
    })
    applyPropertiesButton.MouseButton1Click:Connect(function() StudioBlock.applyPropertiesFromGUI() end)


    -- Movement Controls (GUI Buttons)
    local moveLabel = createLabel(mainFrame, "Move (Increment " .. Config.MOVE_INCREMENT .. "):", {LayoutOrder = 21})
    local moveButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING*2) / 3
    local guiMoveButtonsData = {
        { text = "-Z (Fwd)", vector = Vector3New(0, 0, -1), row = 0, col = 0 },
        { text = "+Y (Up)", vector = Vector3New(0, 1, 0), row = 0, col = 1 },
        { text = "+Z (Back)", vector = Vector3New(0, 0, 1), row = 0, col = 2 },
        { text = "-X (Left)", vector = Vector3New(-1, 0, 0), row = 1, col = 0 },
        { text = "-Y (Down)", vector = Vector3New(0, -1, 0), row = 1, col = 1 },
        { text = "+X (Right)", vector = Vector3New(1, 0, 0), row = 1, col = 2 },
    }
    local maxRows = 0
    guiMoveButtons = {}
    local guiMoveLayoutOrder = 22
    local moveRowFrames = {}
    for row = 0, 1 do
        moveRowFrames[row] = InstanceNew("Frame")
        moveRowFrames[row].Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
        moveRowFrames[row].BackgroundColor3 = Color3New(1, 1, 1, 0)
        moveRowFrames[row].BorderSizePixel = 0
        moveRowFrames[row].Parent = mainFrame
        moveRowFrames[row].LayoutOrder = guiMoveLayoutOrder + row
        local rowListLayout = InstanceNew("UIListLayout")
        rowListLayout.FillDirection = EnumFillDirection.Horizontal
        rowListLayout.Padding = UDimNew(0, Config.SPACING)
        rowListLayout.SortOrder = EnumSortOrder.LayoutOrder
        rowListLayout.Parent = moveRowFrames[row]
    end
    for _, data in IpairsGlobal(guiMoveButtonsData) do
        local button = createButton(moveRowFrames[data.row], data.text,
            UDim2New(0, moveButtonWidth, 1, 0),
            { LayoutOrder = data.col + 1 }
        )
        button.Tag = data.vector
        table.insert(guiMoveButtons, button)
        handleMoveButton(button, data.vector)
        maxRows = math.max(maxRows, data.row)
    end

    -- Transformation Controls (Rotate, Scale)
    local transformLabel = createLabel(mainFrame, "Transform:", {LayoutOrder = 24})
    local transformButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING * 2) / 3
    local transformLayoutOrder = 25
    local transformRowFrames = {}
    for row = 0, 2 do -- Added a row for Angle/Pivot
        transformRowFrames[row] = InstanceNew("Frame")
        transformRowFrames[row].Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
        transformRowFrames[row].BackgroundColor3 = Color3New(1, 1, 1, 0)
        transformRowFrames[row].BorderSizePixel = 0
        transformRowFrames[row].Parent = mainFrame
        transformRowFrames[row].LayoutOrder = transformLayoutOrder + row
         local rowListLayout = InstanceNew("UIListLayout")
        rowListLayout.FillDirection = EnumFillDirection.Horizontal
        rowListLayout.Padding = UDimNew(0, Config.SPACING)
        rowListLayout.SortOrder = EnumSortOrder.LayoutOrder
        rowListLayout.Parent = transformRowFrames[row]
    end

     -- Angle Input and Set Pivot
     local rotateAngleLabel = createLabel(transformRowFrames[0], "Angle (°):", {Size = UDim2New(0, 80, 1, 0), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left, TextInsets = UDimInsetsNew(5,0,0,0)})
     rotateAngleTextBox_GUI = createTextBox(transformRowFrames[0], "Angle", TostringGlobal(Config.INITIAL_ROTATION_ANGLE), UDim2New(0, transformButtonWidth * 2 - 10, 1, 0), {LayoutOrder = 2}) -- Wider textbox
      setPivotButton_GUI = createButton(transformRowFrames[0], "Set Pivot", UDim2New(0, transformButtonWidth - 10, 1, 0), { -- Button size
          BackgroundColor3 = Color3New(0.5, 0.5, 0.5), -- Start inactive
          LayoutOrder = 3,
           Active = false,
     })
     setPivotButton_GUI.MouseButton1Click:Connect(function() StudioBlock.setPivotToActiveItem() end)


    -- Rotate Buttons
    local rotateLabel = createLabel(transformRowFrames[1], "Rotate:", {Size = UDim2New(0, 80, 1, 0), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left, TextInsets = UDimInsetsNew(5,0,0,0)})
    local rotateXButton = createButton(transformRowFrames[1], "X", UDim2New(0, transformButtonWidth - 20, 1, 0), {LayoutOrder = 2})
    local rotateYButton = createButton(transformRowFrames[1], "Y", UDim2New(0, transformButtonWidth - 20, 1, 0), {LayoutOrder = 3})
    local rotateZButton = createButton(transformRowFrames[1], "Z", UDim2New(0, transformButtonWidth - 20, 1, 0), {LayoutOrder = 4})

    rotateXButton.MouseButton1Click:Connect(function() StudioBlock.rotateSelectedItems("X") end)
    rotateYButton.MouseButton1Click:Connect(function() StudioBlock.rotateSelectedItems("Y") end)
    rotateZButton.MouseButton1Click:Connect(function() StudioBlock.rotateSelectedItems("Z") end)

    -- Scale Buttons
    local scaleLabel = createLabel(transformRowFrames[2], "Scale (" .. Config.SCALE_INCREMENT_FACTOR .. "x):", {Size = UDim2New(0, 80, 1, 0), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left, TextInsets = UDimInsetsNew(5,0,0,0)})
    local scaleButtonSize = UDim2New(0, (transformButtonWidth - 20)/2, 1, 0)
    local scaleXUpButton = createButton(transformRowFrames[2], "+X", scaleButtonSize, {LayoutOrder = 2})
    local scaleXDownButton = createButton(transformRowFrames[2], "-X", scaleButtonSize, {LayoutOrder = 3})
    local scaleYUpButton = createButton(transformRowFrames[2], "+Y", scaleButtonSize, {LayoutOrder = 4})
    local scaleYDownButton = createButton(transformRowFrames[2], "-Y", scaleButtonSize, {LayoutOrder = 5})
    local scaleZUpButton = createButton(transformRowFrames[2], "+Z", scaleButtonSize, {LayoutOrder = 6})
    local scaleZDownButton = createButton(transformRowFrames[2], "-Z", scaleButtonSize, {LayoutOrder = 7})

    scaleXUpButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("X", Config.SCALE_INCREMENT_FACTOR) end)
    scaleXDownButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("X", 1 / Config.SCALE_INCREMENT_FACTOR) end)
    scaleYUpButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("Y", Config.SCALE_INCREMENT_FACTOR) end)
    scaleYDownButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("Y", 1 / Config.SCALE_INCREMENT_FACTOR) end)
    scaleZUpButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("Z", Config.SCALE_INCREMENT_FACTOR) end)
    scaleZDownButton.MouseButton1Click:Connect(function() StudioBlock.scaleSelectedItems("Z", 1 / Config.SCALE_INCREMENT_FACTOR) end)


    -- Boolean Operation Buttons
    local booleanOpsLabel = createLabel(mainFrame, "Boolean Operations:", {LayoutOrder = 28})
    local booleanButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING) / 2
    local booleanLayoutOrder = 29
    local booleanOpsFrame = InstanceNew("Frame")
    booleanOpsFrame.Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
    booleanOpsFrame.BackgroundColor3 = Color3New(1, 1, 1, 0)
    booleanOpsFrame.BorderSizePixel = 0
    booleanOpsFrame.Parent = mainFrame
    booleanOpsFrame.LayoutOrder = booleanLayoutOrder
    local booleanListLayout = InstanceNew("UIListLayout")
    booleanListLayout.FillDirection = EnumFillDirection.Horizontal
    booleanListLayout.Padding = UDimNew(0, Config.SPACING)
    booleanListLayout.SortOrder = EnumSortOrder.LayoutOrder
    booleanListLayout.Parent = booleanOpsFrame

    unionButton_GUI = createButton(booleanOpsFrame, "Union", UDim2New(0, booleanButtonWidth, 1, 0), {
         BackgroundColor3 = Color3New(0.5, 0.5, 0.5),
         LayoutOrder = 1,
         Active = false,
     })
     negateButton_GUI = createButton(booleanOpsFrame, "Negate", UDim2New(0, booleanButtonWidth, 1, 0), {
         BackgroundColor3 = Color3New(0.5, 0.5, 0.5),
         LayoutOrder = 2,
          Active = false,
     })

    unionButton_GUI.MouseButton1Click:Connect(function() StudioBlock.performUnion() end)
    negateButton_GUI.MouseButton1Click:Connect(function() StudioBlock.performNegate() end)

    -- Duplicate and Group/Ungroup Buttons
     local action2Label = createLabel(mainFrame, "Actions:", {LayoutOrder = 30})
     local action2ButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING * 2) / 3
     local action2LayoutOrder = 31
      local action2Frame = InstanceNew("Frame")
      action2Frame.Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
      action2Frame.BackgroundColor3 = Color3New(1, 1, 1, 0)
      action2Frame.BorderSizePixel = 0
      action2Frame.Parent = mainFrame
      action2Frame.LayoutOrder = action2LayoutOrder
      local action2ListLayout = InstanceNew("UIListLayout")
      action2ListLayout.FillDirection = EnumFillDirection.Horizontal
      action2ListLayout.Padding = UDimNew(0, Config.SPACING)
      action2ListLayout.SortOrder = EnumSortOrder.LayoutOrder
      action2ListLayout.Parent = action2Frame

     duplicateButton_GUI = createButton(action2Frame, "Duplicate", UDim2New(0, action2ButtonWidth, 1, 0), {
         BackgroundColor3 = Color3New(0.3, 0.6, 0.6),
         LayoutOrder = 1,
          Active = true,
     })
      groupButton_GUI = createButton(action2Frame, "Group", UDim2New(0, action2ButtonWidth, 1, 0), {
          BackgroundColor3 = Color3New(0.5, 0.5, 0.5),
          LayoutOrder = 2,
          Active = false,
      })
      ungroupButton_GUI = createButton(action2Frame, "Ungroup", UDim2New(0, action2ButtonWidth, 1, 0), {
          BackgroundColor3 = Color3New(0.5, 0.5, 0.5),
          LayoutOrder = 3,
          Active = false,
      })

     duplicateButton_GUI.MouseButton1Click:Connect(function() StudioBlock.duplicateSelectedItems() end)
     groupButton_GUI.MouseButton1Click:Connect(function() StudioBlock.groupSelectedItems() end)
     ungroupButton_GUI.MouseButton1Click:Connect(function() StudioBlock.ungroupActiveModel() end)


    -- Creation and Removal Buttons
    local creationRemovalLabel = createLabel(mainFrame, "Creation / Removal:", {LayoutOrder = 32})
     local creationRemovalButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING) / 2
     local creationRemovalLayoutOrder = 33
      local creationRemovalFrame = InstanceNew("Frame")
      creationRemovalFrame.Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
      creationRemovalFrame.BackgroundColor3 = Color3New(1, 1, 1, 0)
      creationRemovalFrame.BorderSizePixel = 0
      creationRemovalFrame.Parent = mainFrame
      creationRemovalFrame.LayoutOrder = creationRemovalLayoutOrder
      local creationRemovalListLayout = InstanceNew("UIListLayout")
      creationRemovalListLayout.FillDirection = EnumFillDirection.Horizontal
      creationRemovalListLayout.Padding = UDimNew(0, Config.SPACING)
      creationRemovalListLayout.SortOrder = EnumSortOrder.LayoutOrder
      creationRemovalListLayout.Parent = creationRemovalFrame

    local createBlockButton = createButton(creationRemovalFrame, "Create Item", UDim2New(0, creationRemovalButtonWidth, 1, 0), {
        BackgroundColor3 = Color3New(0.3, 0.6, 0.3),
        LayoutOrder = 1
    })
    local removeBlockButton = createButton(creationRemovalFrame, "Remove Active Item", UDim2New(0, creationRemovalButtonWidth, 1, 0), {
        BackgroundColor3 = Color3New(0.6, 0.3, 0.3),
        LayoutOrder = 2
    })
    createBlockButton.MouseButton1Click:Connect(function() StudioBlock.createNewBlock() end)
    removeBlockButton.MouseButton1Click:Connect(function() StudioBlock.removeActiveBlock() end)


    -- Save/Load Buttons
    local saveDataLabel = createLabel(mainFrame, "Save / Load:", {LayoutOrder = 34})
     local saveDataButtonWidth = (Config.GUI_WIDTH - 10 - Config.SPACING) / 2
     local saveDataLayoutOrder = 35
      local saveDataFrame = InstanceNew("Frame")
      saveDataFrame.Size = UDim2New(1, 0, 0, Config.ELEMENT_HEIGHT)
      saveDataFrame.BackgroundColor3 = Color3New(1, 1, 1, 0)
      saveDataFrame.BorderSizePixel = 0
      saveDataFrame.Parent = mainFrame
      saveDataFrame.LayoutOrder = saveDataLayoutOrder
      local saveDataListLayout = InstanceNew("UIListLayout")
      saveDataListLayout.FillDirection = EnumFillDirection.Horizontal
      saveDataListLayout.Padding = UDimNew(0, Config.SPACING)
      saveDataListLayout.SortOrder = EnumSortOrder.LayoutOrder
      saveDataListLayout.Parent = saveDataFrame

    local saveBlockButton = createButton(saveDataFrame, "Save All Configs", UDim2New(0, saveDataButtonWidth, 1, 0), {
        BackgroundColor3 = Color3New(0.2, 0.5, 0.8),
        LayoutOrder = 1
    })
    local loadBlockButton = createButton(saveDataFrame, "Load All Configs", UDim2New(0, saveDataButtonWidth, 1, 0), {
        BackgroundColor3 = Color3New(0.2, 0.5, 0.8),
        LayoutOrder = 2
    })
    saveBlockButton.MouseButton1Click:Connect(function() StudioBlock.saveItemConfig() end)
    loadBlockButton.MouseButton1Click:Connect(function() StudioBlock.loadItemConfig() end)


    -- Add Mobile Button Toggle (Only show on touch devices)
    if UserInputService.TouchEnabled then
        toggleMobileButtonsCheckbox_GUI = createCheckbox(mainFrame, "Show Mobile Buttons", true, {
            LayoutOrder = 36,
            Size = UDim2New(1, -10, 0, Config.ELEMENT_HEIGHT),
            OnToggled = function(newState)
                 if mobileVirtualButtonsFrame then
                      mobileVirtualButtonsFrame.Visible = newState
                      Log.Info("Mobile virtual buttons " .. (newState and "shown" or "hidden"))
                 end
            end
        })
    end


    Log.Info("GUI created using UIListLayout and UIScale.")

    -- === Mobile Virtual Movement Buttons Frame ===
    mobileVirtualButtonsFrame = InstanceNew("Frame")
    mobileVirtualButtonsFrame.Name = "MobileVirtualButtonsFrame"
    mobileVirtualButtonsFrame.Size = UDim2New(1, 0, 1, 0)
    mobileVirtualButtonsFrame.BackgroundColor3 = Color3New(1, 1, 1, 0)
    mobileVirtualButtonsFrame.BorderSizePixel = 0
    mobileVirtualButtonsFrame.Parent = screenGui


    if UserInputService.TouchEnabled then
        local buttonSize = Config.VIRTUAL_BUTTON_SIZE
        local buttonSpacing = Config.VIRTUAL_BUTTON_SPACING
        local baseX = Config.VIRTUAL_BUTTON_BASE_X
        local baseY_BottomOffset = Config.VIRTUAL_BUTTON_BASE_Y_OFFSET_BOTTOM
        local upDownOffsetRight = Config.VIRTUAL_BUTTON_UP_DOWN_OFFSET_RIGHT

        local virtualButtonsData = {
            { text = "Fwd", vector = Vector3New(0, 0, -1), align = "bottomLeft" },
            { text = "Back", vector = Vector3New(0, 0, 1), align = "bottomLeft" },
            { text = "-Left", vector = Vector3New(-1, 0, 0), align = "bottomLeft" },
            { text = "-Right", vector = Vector3New(1, 0, 0), align = "bottomLeft" },
            { text = "Up", vector = Vector3New(0, 1, 0), align = "bottomRight" },
            { text = "Down", vector = Vector3New(0, -1, 0), align = "bottomRight" },
        }

        for _, data in IpairsGlobal(virtualButtonsData) do
            local button = createButton(mobileVirtualButtonsFrame, data.text, buttonSize, {
                BackgroundColor3 = Color3New(0.2, 0.5, 0.8),
                TextSize = 14,
                ZIndex = 5,
            })
            button.Tag = data.vector
            handleMoveButton(button, data.vector)

            if data.align == "bottomLeft" then
                 local col = (data.vector.X < 0 and 0) or (data.vector.X > 0 and 2) or 1
                 local row = (data.vector.Z < 0 and 0) or (data.vector.Z > 0 and 1) or 0
                 local xPos = baseX + col * (buttonSize.X.Offset + buttonSpacing)
                 local yPos = Camera.ViewportSize.Y - baseY_BottomOffset - (row == 0 and buttonSize.Y.Offset + buttonSpacing or 0)
                 button.Position = UDim2New(0, xPos, 0, yPos)

            elseif data.align == "bottomRight" then
                 local xPos = Camera.ViewportSize.X - upDownOffsetRight - buttonSize.X.Offset
                 local yPos = Camera.ViewportSize.Y - baseY_BottomOffset - (data.vector.Y > 0 and buttonSize.Y.Offset + buttonSpacing or 0)
                 button.Position = UDim2New(0, xPos, 0, yPos)
            end
        end
    end
     if UserInputService.TouchEnabled and toggleMobileButtonsCheckbox_GUI then
          mobileVirtualButtonsFrame.Visible = toggleMobileButtonsCheckbox_GUI.Tag
     elseif mobileVirtualButtonsFrame then
          mobileVirtualButtonsFrame.Visible = false
     end


    return mainFrame
end


-- === Main Execution Logic ===

local localPlayer = Players.LocalPlayer
local PlayerMouse = localPlayer:GetMouse() -- Cache PlayerMouse


local mainFrameReference = createGUI()


if toggleButton then
     toggleButton.MouseButton1Click:Connect(function()
        if mainFrameReference then
            mainFrameReference.Visible = not mainFrameReference.Visible
            Log.Info("GUI visibility toggled via button.")
        end
    end)
else
    Log.Error("Toggle UI button failed to create!")
end


local TOGGLE_KEY_CODE = Config.TOGGLE_KEY_CODE
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if mainFrameReference and input.KeyCode == TOGGLE_KEY_CODE and not gameProcessedEvent then
        local focusedTextBox = UserInputService:GetFocusedTextBox()
        if not focusedTextBox or not mainFrameReference.Visible then
             mainFrameReference.Visible = not mainFrameReference.Visible
             Log.Info("GUI visibility toggled via keybind.")
        end
    end
    -- Handle item selection click
    if mainFrameReference and mainFrameReference.Visible and not gameProcessedEvent and (input.UserInputType == EnumUserInputType.MouseButton1 or input.UserInputType == EnumUserInputType.Touch) then
        local guiObjectUnderCursor = PlayerMouse.Target
        if guiObjectUnderCursor and (guiObjectUnderCursor:IsDescendantOf(mainFrameReference) or guiObjectUnderCursor == toggleButton) then
             return
        end
         if UserInputService.TouchEnabled and mobileVirtualButtonsFrame and guiObjectUnderCursor and guiObjectUnderCursor:IsDescendantOf(mobileVirtualButtonsFrame) then
              return
         end


        local isShiftHeld = UserInputService:IsKeyDown(EnumKeyCode.LeftShift) or UserInputService:IsKeyDown(EnumKeyCode.RightShift)

        if not isShiftHeld then
             StudioBlock.clearSelection()
        end

        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local raycastParams = RaycastParamsNew()
        raycastParams.FilterType = EnumRaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {screenGui, localPlayer.Character}

        local hitResult = Workspace:Raycast(ray.Origin, ray.Direction * Config.RAYCAST_MAX_DISTANCE, raycastParams)

        if hitResult and hitResult.Instance then
            local clickedItem = hitResult.Instance
            local managedItem = nil
            local currentItem = clickedItem
             while currentItem and currentItem.Parent ~= Workspace and currentItem.Parent ~= game do
                  currentItem = currentItem.Parent
             end
            for _, item in IpairsGlobal(managedItems) do
                 if item == currentItem then
                     managedItem = item
                     break
                 end
            end

            if managedItem then
                StudioBlock.toggleItemSelection(managedItem)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == EnumUserInputType.Keyboard then
        local directionVector = nil
        if input.KeyCode == EnumKeyCode.W then directionVector = Vector3New(0, 0, -1)
        elseif input.KeyCode == EnumKeyCode.S then directionVector = Vector3New(0, 0, 1)
        elseif input.KeyCode == EnumKeyCode.A then directionVector = Vector3New(-1, 0, 0)
        elseif input.KeyCode == EnumKeyCode.D then directionVector = Vector3New(1, 0, 0)
        elseif input.KeyCode == EnumKeyCode.E then directionVector = Vector3New(0, 1, 0)
        elseif input.KeyCode == EnumKeyCode.Q then directionVector = Vector3New(0, -1, 0)
        end
        if directionVector then
            local moveVector = mapDirectionToCamera(directionVector)
            moveDirection = moveDirection - moveVector
            if moveDirection.Magnitude < 1e-4 then
                isMoving = false
                moveDirection = Vector3New(0, 0, 0)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if activeItem and activeItem.Parent and (InstanceIsA(activeItem, "BasePart") or InstanceIsA(activeItem, "Model")) and isMoving and mainFrameReference and mainFrameReference.Visible then
        local moveVector = moveDirection.Unit * Config.MOVE_INCREMENT * deltaTime * 60

         -- Move relative to the pivot if set, otherwise relative to item's CFrame
         if currentPivotCFrame then
              local currentCFrame = activeItem.CFrame
              local newCFrame = currentCFrame * CFrameNew(moveVector)
              activeItem:PivotTo(newCFrame)
         else
              activeItem.CFrame = activeItem.CFrame * CFrameNew(moveVector)
         end


        if InstanceIsA(activeItem, "BasePart") then
            local particleEmitter = activeItem:FindFirstChildOfClass("ParticleEmitter")
            if particleEmitter and not particleEmitter.Enabled then
                 particleEmitter.Enabled = true
            end
        end
    else
         if activeItem and InstanceIsA(activeItem, "BasePart") then
             local particleEmitter = activeItem:FindFirstChildOfClass("ParticleEmitter")
             if particleEmitter and particleEmitter.Enabled then
                  particleEmitter.Enabled = false
             end
         end
    end
     -- Keep pivot highlight updated with pivot CFrame
     if pivotHighlightPart and currentPivotCFrame then
          pivotHighlightPart.CFrame = currentPivotCFrame
     end
end


Log.Info("Studio Beta v10.0 initialized.")
Log.Info("GUI is visible by default. Use the 'Toggle UI' button (bottom left) or press " .. TOGGLE_KEY_CODE.Name .. " (PC only) to show/hide the panel.")
Log.Info("Use WASD/EQ (PC) or virtual buttons (Mobile) to move the ACTIVE item based on camera direction when GUI is visible.")
Log.Info("Click items in the workspace to SELECT them. Hold SHIFT and click to add/remove from selection. Selected Models have a blue bounding box.")
Log.Info("Use the 'Select Item' button to cycle through managed items. Use 'Apply Properties' to update properties (Size, Color, Transparency, Reflectance, CanCollide, Anchored) for BaseParts.")
Log.Info("Use 'Set Pivot' to set the transformation pivot to the Active Item's CFrame. Rotate and Move operations will use the pivot if set.")
Log.Info("Use Rotate/Scale buttons on SELECTED BaseParts or Models. Rotate uses the Angle input.")
Log.Info("Use 'Union' or 'Negate' buttons on SELECTED BaseParts. Negate requires exactly two selected BaseParts.")
Log.Info("Use 'Duplicate' to clone selected items.")
Log.Info("Use 'Group' on SELECTED items. Use 'Ungroup Active Item' on a Model.")
Log.Info("Loading PartOperations as basic Parts (geometry is lost). Basic Model structure (direct BasePart children) is saved/loaded, but complex nesting may not be perfect.")
