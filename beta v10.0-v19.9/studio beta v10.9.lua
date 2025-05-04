--[[
Script Name: Studio Beta v10.9
Version: beta v10.9
Author: Lua vip pro vn (Hole Tool Enhancements, Terrain Storage Optimization, Basic 3D UI)
Description: Client-side script for Natural Disaster Survival
             with significantly enhanced terrain editing tools (customizable hole shape/size,
             compressed multi-region save/load, basic 3D material preview), item creation/transformation,
             alignment, distribution, shape drawing (circle), improved persistence (common children, limited terrain),
             pivot control, and basic undo/redo for multiple action types.
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
local ErrorGlobal = error -- Redefined later to use GUI label
local TypeOfGlobal = typeof
local PairsGlobal = pairs
local IpairsGlobal = ipairs
local TableInsert = table.insert
local TableRemove = table.remove
local TableSort = table.sort
local TaskWait = task.wait
local MathHuge = math.huge
local MathMax = math.max
local MathMin = math.min
local MathPi = math.pi
local MathCos = math.cos
local MathSin = math.sin
local MathSqrt = math.sqrt
local MathAbs = math.abs -- Cache math.abs
local MathExp = math.exp -- Cache math.exp
local MathMax = math.max -- Re-cache math.max just in case


local Vector3New = Vector3.new
local UDim2New = UDim2.new
local CFrameNew = CFrame.new
local Color3New = Color3.New
local UDimInsetsNew = UDimInsets.new
local EnumMaterial = Enum.Material
local EnumAutomaticSize = Enum.AutomaticSize
local EnumSortOrder = Enum.SortOrder
local EnumHorizontalAlignment = Enum.TextXAlignment.Left -- Used for TextLabels
local UDimNew = UDim.new
local InstanceIsA = InstanceNew("Part").IsA
local EnumKeyCode = Enum.KeyCode
local EnumFillDirectionHorizontal = Enum.FillDirection.Horizontal
local EnumPartType = EnumPartType
local EnumUserInputType = EnumUserInputType
local EnumRaycastFilterTypeBlacklist = EnumRaycastFilterType.Blacklist
local RaycastParamsNew = RaycastParams.new
local MathRad = math.rad
local EnumFont = Enum.Font


local Terrain = Workspace.Terrain


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
    GUI_NAME = "StudioGUI_v10_9",
    LOG_PREFIX = "[Studio v10.9] ",
     GUI_MESSAGE_DISPLAY_TIME = 5,

    -- DataStore Config
    DATASTORE_NAME = "StudioBlockConfig_v10_9",
    DATASTORE_KEY = "BlockConfigs",
    DATASTORE_TERRAIN_KEY = "TerrainConfig",
     DATASTORE_VERSION = 6, -- Incremented version for compressed multi-region terrain save/load
    DATASTORE_RETRY_ATTEMPTS = 3,
    DATASTORE_RETRY_DELAY = 1,

    -- Mobile Virtual Button Config
    VIRTUAL_BUTTON_SIZE = UDim2New(0, 60, 0, 60),
    VIRTUAL_BUTTON_SPACING = 10,
    VIRTUAL_BUTTON_BASE_X = 20,
    VIRTUAL_BUTTON_BASE_Y_OFFSET_BOTTOM = 100,
    VIRTUAL_BUTTON_UP_DOWN_OFFSET_RIGHT = 80,
     VIRTUAL_BUTTON_PAINT_OFFSET_RIGHT = 150, -- Offset for the paint button

    -- Particle Effect Config
    PARTICLE_LIFETIME = 0.5,
    PARTICLE_RATE = 20,
    PARTICLE_COLOR = Color3New(0, 1, 1), -- Cyan default
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
     MODEL_HIGHLIGHT_TRANSPARENCY = 0.8,
     MODEL_HIGHLIGHT_COLOR = Color3New(0, 0.5, 1),

    -- Transformation Config
    INITIAL_ROTATION_ANGLE = 90,
    SCALE_INCREMENT_FACTOR = 1.1,
    DUPLICATE_OFFSET = Vector3New(5, 5, 5),

    -- Undo/Redo Config
    UNDO_STACK_SIZE = 20, -- Max number of item/action states
     TERRAIN_UNDO_STACK_SIZE = 5, -- Max number of terrain voxel states (kept smaller due to data size)

    -- Shape Drawing Config
    CIRCLE_DEFAULT_RADIUS = 10,
    CIRCLE_DEFAULT_PARTS = 12,
    CIRCLE_PART_THICKNESS = 1,
    CIRCLE_PART_HEIGHT = 5,

    -- Terrain Tool Config
    TERRAIN_BRUSH_SIZE_DEFAULT = 5,
    TERRAIN_BRUSH_SIZE_MIN = 1,
    TERRAIN_BRUSH_SIZE_MAX = 50,
    TERRAIN_BRUSH_STRENGTH_DEFAULT = 0.5,
    TERRAIN_BRUSH_STRENGTH_MIN = 0.1,
    TERRAIN_BRUSH_STRENGTH_MAX = 2,
    TERRAIN_MATERIAL_DEFAULT = Enum.Material.Grass,
    TERRAIN_VOXEL_RESOLUTION = 4,
    TERRAIN_MAX_REGION_SIZE = 50, -- Max region size (studs) for saving/loading/undo. Brush size influences actual region size.
    TERRAIN_SHAPE_HEIGHT_DEFAULT = 10,
    TERRAIN_SHAPE_RADIUS_DEFAULT = 20,
     PAINT_COOLDOWN = 0.05, -- Seconds between terrain paint calls

     -- Hole Tool Config (using TERRAIN_SHAPE_ constants as defaults)
     HOLE_RADIUS_DEFAULT = TERRAIN_SHAPE_RADIUS_DEFAULT,
     HOLE_DEPTH_DEFAULT = TERRAIN_SHAPE_HEIGHT_DEFAULT,
     HOLE_SHAPE_DEFAULT = "Circular", -- "Circular", "Square", "SoftCone"

     -- 3D UI Config
     VIEWPORT_FRAME_MATERIAL_SIZE = UDim2New(0.5, -5, 0, 50), -- Size for the material preview viewport
     VIEWPORT_FRAME_MATERIAL_OFFSET_Y = 3 * ELEMENT_HEIGHT + 2 * SPACING, -- Position below material dropdown
     PANEL_3D_SIZE = Vector3New(10, 5, 0.5), -- Size of the floating 3D panel
     PANEL_3D_BUTTON_SIZE = Vector3New(2, 2, 0.2), -- Size of buttons within the 3D panel

}

-- === Service Check and Fallback (Basic) ===
if not DataStoreService then
    Log.Error("DataStoreService not available. Script may not work correctly.")
    StudioBlock = StudioBlock or {}
     StudioBlock.saveItemConfig = function() Log.Warn("Save disabled: DataStoreService not available.") end
     StudioBlock.loadItemConfig = function() Log.Warn("Load disabled: DataStoreService not available.") end
      StudioBlock.saveTerrainConfig = function() Log.Warn("Terrain save disabled: DataStoreService not available.") end
     StudioBlock.loadTerrainConfig = function() Log.Warn("Terrain load disabled: DataStoreService not available.") end
end

local networkClient = game:GetService("NetworkClient")
if not game:IsLoaded() or (networkClient and not networkClient.IsConnected) then
     Log.Warn("Network connection may be unstable. DataStore operations might fail.")
end

if not Terrain then
     Log.Error("Terrain service not available. Terrain tools disabled.")
     StudioBlock = StudioBlock or {}
      StudioBlock.paintTerrain = function() Log.Warn("Terrain tools disabled.") end
      StudioBlock.createTerrainHill = function() Log.Warn("Terrain tools disabled.") end
      StudioBlock.createTerrainHole = function() Log.Warn("Terrain tools disabled.") end
      StudioBlock.saveTerrainConfig = function() Log.Warn("Terrain save disabled.") end
      StudioBlock.loadTerrainConfig = function() Log.Warn("Terrain load disabled.") end
       StudioBlock.updateHolePreview = function() end -- Disable preview update
      StudioBlock.show3DPanel = function() Log.Warn("Terrain tools disabled.") return nil end
     -- Disable GUI elements for terrain - Deferring full GUI disable logic for now.
end


-- === Simple Logging System (Modified for GUI Display) ===
local guiMessageLabel = nil

local Log = {}
function Log.Info(message) PrintGlobal(Config.LOG_PREFIX .. TostringGlobal(message)) end
function Log.Warn(message) WarnGlobal(Config.LOG_PREFIX .. TostringGlobal(message)) end
function Log.Error(message)
    local errorMessage = TostringGlobal(message)
    WarnGlobal(Config.LOG_PREFIX .. "ERROR: " .. errorMessage)
    if guiMessageLabel then
         guiMessageLabel.Text = "Error: " .. errorMessage
         guiMessageLabel.TextColor3 = Color3New(1, 0, 0)
         guiMessageLabel.Visible = true
         task.spawn(function()
             TaskWait(Config.GUI_MESSAGE_DISPLAY_TIME)
             if guiMessageLabel.Text == "Error: " .. errorMessage then
                 guiMessageLabel.Visible = false
                 guiMessageLabel.Text = ""
             end
         end)
    end
    ErrorGlobal(errorMessage)
end
function Log.DisplayMessage(message, color)
    local displayColor = color or Color3New(1, 1, 1)
    Log.Info(message)
    if guiMessageLabel then
        guiMessageLabel.Text = TostringGlobal(message)
        guiMessageLabel.TextColor3 = displayColor
        guiMessageLabel.Visible = true
        task.spawn(function()
            TaskWait(Config.GUI_MESSAGE_DISPLAY_TIME)
             if guiMessageLabel.Text == TostringGlobal(message) and guiMessageLabel.TextColor3 == displayColor then
                 guiMessageLabel.Visible = false
                 guiMessageLabel.Text = ""
             end
         })
    end
end


-- === General Utility Functions ===
local function getNumberFromTextBox(textBox, defaultValue, minValue, maxValue)
    local numberValue = Tonumber(textBox.Text)
    if numberValue == nil then
        Log.Warn("Invalid number input in textbox: '" .. (textBox and (textBox.Name or textBox.PlaceholderText) or "Unnamed TextBox") .. "'. Using default value: " .. TostringGlobal(defaultValue))
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

-- Camera Vector Caching
local lastCameraCFrame = Camera and Camera.CFrame or CFrameNew()
local cachedCameraLookVector = Vector3New(0, 0, -1)
local cachedCameraRightVector = Vector3New(1, 0, 0)
local function updateCameraVectors()
    if Camera and Camera.CFrame and Camera.CFrame ~= lastCameraCFrame then
        lastCameraCFrame = Camera.CFrame
        cachedCameraLookVector = Vector3New(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
        cachedCameraRightVector = Vector3New(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z).Unit
    end
end
local function mapDirectionToCamera(directionVector)
    if directionVector.Y ~= 0 then
        return directionVector
    end
    updateCameraVectors()
    return directionVector.X * cachedCameraRightVector + directionVector.Z * cachedCameraLookVector
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

local function createButton(parent, text, size, config)
    local button = createElement("TextButton", {
        Size = size,
        Text = text,
        TextColor3 = Color3New(1, 1, 1),
        BackgroundColor3 = config.BackgroundColor3 or Color3New(0.4, 0.4, 0.4),
        Font = EnumFont.SourceSans,
        TextSize = config.TextSize or 16,
        BorderSizePixel = 0,
        Parent = parent,
        LayoutOrder = config.LayoutOrder or 0,
        Active = config.Active ~= nil and config.Active or true,
        ZIndex = config.ZIndex or 1,
        Position = config.Position or UDim2New(0,0,0,0),
    })
     if config.Tooltip then
         -- Basic tooltip simulation (requires more GUI elements)
     end
    return button
end

local function createLabel(parent, text, config)
    local label = createElement("TextLabel", {
        Size = config.Size or UDim2New(1, -10, 0, Config.LABEL_HEIGHT),
        Text = text,
        TextColor3 = config.TextColor3 or Color3New(0.8, 0.8, 0.8),
        BackgroundColor3 = config.BackgroundColor3 or Color3New(1, 1, 1, 0),
        Font = config.Font or EnumFont.SourceSans,
        TextSize = config.TextSize or 14,
        TextWrapped = config.TextWrapped or false,
        TextXAlignment = config.TextXAlignment or EnumHorizontalAlignment,
        TextYAlignment = config.TextYAlignment or Enum.TextYAlignment.Center,
        TextInsets = config.TextInsets or UDimInsetsNew(5, 5, 0, 0),
        BorderSizePixel = 0,
        Parent = parent,
        LayoutOrder = config.LayoutOrder or 0,
        ZIndex = config.ZIndex or 1,
        Visible = config.Visible ~= nil and config.Visible or true,
    })
    return label
end

local function createTextBox(parent, placeholder, initialText, size, config)
    local textBox = createElement("TextBox", {
        Size = size,
        PlaceholderText = placeholder,
        Text = initialText or "",
        TextColor3 = Color3New(1, 1, 1),
        BackgroundColor3 = config.BackgroundColor3 or Color3New(0.3, 0.3, 0.3),
        Font = EnumFont.SourceSans,
        TextSize = config.TextSize or 16,
        BorderSizePixel = 0,
        Parent = parent,
        LayoutOrder = config.LayoutOrder or 0,
        Active = config.Active ~= nil and config.Active or true,
        ClearTextOnFocus = config.ClearTextOnFocus ~= nil and config.ClearTextOnFocus or false,
        ZIndex = config.ZIndex or 1,
    })
    return textBox
end


-- === Item Management and Functionality ===
local managedItems = {}
local activeItem = nil
local selectedItems = {}
local itemHighlights = {}
local isPerformingBooleanOp = false
local itemDataStore = DataStoreService:GetDataStore(Config.DATASTORE_NAME)

-- Basic Pivot System
local currentPivotCFrame = nil
local pivotHighlightPart = nil
local moveDirection = Vector3New(0, 0, 0)
local isMoving = false
local lockPivot = false


-- Undo/Redo System
local undoStack = {}
local redoStack = {}

-- Separate stacks for large voxel data from terrain edits
local terrainUndoStates = {} -- Stores {Region = region, Materials = materials, Occupancies = occupancies} BEFORE edit
local terrainRedoStates = {} -- Stores {Region = region, Materials = materials, Occupancies = occupancies} AFTER edit


-- Note: saveItemRecursive and loadItemRecursive are defined later, but used in Undo/Redo logic.

local function pushUndo(action, data)
    TableInsert(undoStack, {action = action, data = data})
    while #undoStack > Config.UNDO_STACK_SIZE do
        -- When removing from the main stack, also remove corresponding terrain data if the action is terrain
        local oldestAction = TableRemove(undoStack, 1)
        if oldestAction.action == "terrain" and #terrainUndoStates > 0 then
            -- Assuming terrain states are pushed in order corresponding to terrain actions on main stack
            -- This is a simplified assumption; complex interactions need more robust state mapping.
            TableRemove(terrainUndoStates, 1)
             Log.Warn("Removed oldest terrain undo state due to stack limit.")
        end
    end
    redoStack = {} -- Clear redo stack on new action
     -- When clearing main redo stack, also clear terrain redo stack
     terrainRedoStates = {}
     Log.DisplayMessage("Undo state saved.", Color3New(0.8, 0.8, 0.8))
end

local function undo()
    if #undoStack > 0 then
        local lastAction = TableRemove(undoStack)
        Log.Info("Performing Undo action: " .. lastAction.action)
        Log.DisplayMessage("Undoing: " .. lastAction.action .. "...", Color3New(1, 1, 0.5))

        local success = safeCall(function()
            if lastAction.action == "create" then
                 -- Undo Create: Destroy the created item
                local itemToDestroy = lastAction.data.item
                -- Need to capture current state before destroying for redo...
                 local itemConfigForRedo = saveItemRecursive(itemToDestroy)
                 local itemParentForRedo = itemToDestroy.Parent
                 local wasSelectedForRedo = table.find(selectedItems, itemToDestroy) ~= nil
                 local wasActiveForRedo = activeItem == itemToDestroy

                if itemToDestroy and itemToDestroy.Parent then
                     local indexInManaged = table.find(managedItems, itemToDestroy)
                     if indexInManaged then TableRemove(managedItems, indexInManaged) end
                     if activeItem == itemToDestroy then StudioBlock.setActiveBlockByIndex(nil) end
                     local indexInSelected = table.find(selectedItems, itemToDestroy)
                     if indexInSelected then TableRemove(selectedItems, indexInSelected) end
                    itemToDestroy:Destroy()
                     Log.Info("Undid Create: Destroyed '" .. (itemToDestroy.Name or "Unnamed") .. "'")
                end
                -- Store data for Redo
                 TableInsert(redoStack, {action = "create_undo", data = {itemConfig = itemConfigForRedo, parentItem = itemParentForRedo, wasSelected = wasSelectedForRedo, wasActive = wasActiveForRedo}})


             elseif lastAction.action == "create_multiple" then
                 -- Undo Create Multiple: Destroy the created items (and potentially their parent model)
                 local itemsData = lastAction.data.items -- Contains {item = item, itemConfig = config, parentItem = parent} for each item created
                  local redoItemsData = {} -- To store current state before destroying for redo

                  for _, itemData in IpairsGlobal(itemsData) do
                      local itemToDestroy = itemData.item
                       -- Capture current state for redo (this might be different from original config if modified)
                        local itemConfigForRedo = saveItemRecursive(itemToDestroy)
                        local itemParentForRedo = itemToDestroy.Parent

                       if itemToDestroy and itemToDestroy.Parent then
                           local indexInManaged = table.find(managedItems, itemToDestroy)
                           if indexInManaged then TableRemove(managedItems, indexInManaged) end
                           itemToDestroy:Destroy()
                           Log.Info("Undid Create Multiple: Destroyed '" .. (itemToDestroy.Name or "Unnamed") .. "'")
                       end
                       -- Store data for Redo (using captured current state)
                        TableInsert(redoItemsData, {itemConfig = itemConfigForRedo, parentItem = itemParentForRedo})
                  end
                   -- Complex logic to restore selection/active item state is deferred.
                   StudioBlock.clearSelection()
                   StudioBlock.setActiveBlockByIndex(nil)

                    -- Store data for Redo
                   TableInsert(redoStack, {action = "create_multiple_undo", data = {items = redoItemsData}})


            elseif lastAction.action == "delete" then
                 -- Undo Delete: Restore the deleted item
                 local itemConfig = lastAction.data.itemConfig
                 local parentItem = lastAction.data.parentItem
                 local wasSelected = lastAction.data.wasSelected
                 local wasActive = lastAction.data.wasActive

                 local loadedItem = loadItemRecursive(itemConfig, parentItem or Workspace)
                 if loadedItem then
                      TableInsert(managedItems, loadedItem)
                       -- Restore selection/active state
                        if wasSelected then TableInsert(selectedItems, loadedItem) end
                       if wasActive then StudioBlock.setActiveBlockByIndex(table.find(managedItems, loadedItem)) else updateGUIForActiveItem() end

                      Log.Info("Undid Delete: Restored '" .. (loadedItem.Name or "Unnamed") .. "'")
                      -- Store data for Redo (Delete the restored item)
                       -- Need to save *current* state before deleting for redo... recursive save.
                       local itemConfigForRedo = saveItemRecursive(loadedItem)
                        local itemParentForRedo = loadedItem.Parent
                        local wasSelectedForRedo = table.find(selectedItems, loadedItem) ~= nil
                        local wasActiveForRedo = activeItem == loadedItem

                       TableInsert(redoStack, {action = "delete_undo", data = {item = loadedItem, itemConfig = itemConfigForRedo, parentItem = itemParentForRedo, wasSelected = wasSelectedForRedo, wasActive = wasActiveForRedo}})
                 else
                      Log.Warn("Undid Delete: Failed to restore item.")
                 end


             elseif lastAction.action == "move" then
                 -- Undo Move: Revert CFrames to before the move
                 local itemsData = lastAction.data.items
                  local redoData = {action = "move_undo", data = {}}
                  local itemsToRestoreSelection = {}
                  local restoreActiveItem = nil

                  for _, itemData in IpairsGlobal(itemsData) do
                      local item = itemData.item
                      local oldCFrame = itemData.oldCFrame
                       if item and item.Parent then
                           local currentCFrame = item:GetPivot() -- Capture current pivot for redo
                           item:PivotTo(oldCFrame)
                           Log.Info("Undid Move: Reverted '" .. (item.Name or "Unnamed") .. "' CFrame.")
                           TableInsert(redoData.data, {item = item, oldCFrame = currentCFrame})
                            TableInsert(itemsToRestoreSelection, item)
                            if activeItem == item then restoreActiveItem = item end
                       else
                            Log.Warn("Undid Move: Item no longer exists.")
                       end
                  end
                   StudioBlock.clearSelection()
                   for _, item in IpairsGlobal(itemsToRestoreSelection) do TableInsert(selectedItems, item) end -- Restore selection
                   if restoreActiveItem then activeItem = restoreActiveItem end -- Set active item reference
                    updateGUIForActiveItem() -- Refresh GUI for selection/active item

                  TableInsert(redoStack, redoData)

             elseif lastAction.action == "align" then
                  -- Undo Align: Revert CFrames to before the align
                  local itemsData = lastAction.data.items
                   local redoData = {action = "align_undo", data = {}}
                    local itemsToRestoreSelection = {}
                     local restoreActiveItem = nil

                  for _, itemData in IpairsGlobal(itemsData) do
                      local item = itemData.item
                      local oldCFrame = itemData.oldCFrame
                       if item and item.Parent then
                           local currentCFrame = item:GetPivot() -- Capture current pivot for redo
                           item:PivotTo(oldCFrame)
                           Log.Info("Undid Align: Reverted '" .. (item.Name or "Unnamed") .. "' CFrame.")
                            TableInsert(redoData.data, {item = item, oldCFrame = currentCFrame})
                             TableInsert(itemsToRestoreSelection, item)
                             if activeItem == item then restoreActiveItem = item end
                       else
                           Log.Warn("Undid Align: Item no longer exists.")
                       end
                  end
                    StudioBlock.clearSelection()
                   for _, item in IpairsGlobal(itemsToRestoreSelection) do TableInsert(selectedItems, item) end
                    if restoreActiveItem then activeItem = restoreActiveItem end
                    updateGUIForActiveItem()

                   TableInsert(redoStack, redoData)

              elseif lastAction.action == "distribute" then
                   -- Undo Distribute: Revert CFrames to before the distribution
                   local itemsData = lastAction.data.items
                    local redoData = {action = "distribute_undo", data = {}}
                     local itemsToRestoreSelection = {}
                     local restoreActiveItem = nil

                   for _, itemData in IpairsGlobal(itemsData) do
                       local item = itemData.item
                       local oldCFrame = itemData.oldCFrame
                        if item and item.Parent then
                            local currentCFrame = item:GetPivot() -- Capture current pivot for redo
                            item:PivotTo(oldCFrame)
                            Log.Info("Undid Distribute: Reverted '" .. (item.Name or "Unnamed") .. "' CFrame.")
                             TableInsert(redoData.data, {item = item, oldCFrame = currentCFrame})
                              TableInsert(itemsToRestoreSelection, item)
                              if activeItem == item then restoreActiveItem = item end
                        else
                            Log.Warn("Undid Distribute: Item no longer exists.")
                        end
                   end
                    StudioBlock.clearSelection()
                    for _, item in IpairsGlobal(itemsToRestoreSelection) do TableInsert(selectedItems, item) end
                     if restoreActiveItem then activeItem = restoreActiveItem end
                     updateGUIForActiveItem()

                    TableInsert(redoStack, redoData)


             elseif lastAction.action == "rotate" then
                  -- Undo Rotate: Revert CFrames
                 local itemsData = lastAction.data.items
                  local redoData = {action = "rotate_undo", data = {}}
                  local itemsToRestoreSelection = {}
                  local restoreActiveItem = nil

                  for _, itemData in IpairsGlobal(itemsData) do
                      local item = itemData.item
                      local oldCFrame = itemData.oldCFrame
                       if item and item.Parent then
                           local currentCFrame = item:GetPivot() -- Capture current pivot for redo
                           item:PivotTo(oldCFrame)
                           Log.Info("Undid Rotate: Reverted '" .. (item.Name or "Unnamed") .. "' CFrame.")
                           TableInsert(redoData.data, {item = item, oldCFrame = currentCFrame})
                            TableInsert(itemsToRestoreSelection, item)
                             if activeItem == item then restoreActiveItem = item end
                       else
                           Log.Warn("Undid Rotate: Item no longer exists.")
                       end
                  end
                    StudioBlock.clearSelection()
                   for _, item in IpairsGlobal(itemsToRestoreSelection) do TableInsert(selectedItems, item) end
                    if restoreActiveItem then activeItem = restoreActiveItem end
                    updateGUIForActiveItem()

                   TableInsert(redoStack, redoData)

             elseif lastAction.action == "scale" then
                  -- Undo Scale: Revert Sizes
                 local itemsData = lastAction.data.items
                  local redoData = {action = "scale_undo", data = {}}
                  local itemsToRestoreSelection = {}
                  local restoreActiveItem = nil

                  for _, itemData in IpairsGlobal(itemsData) do
                      local item = itemData.item
                      local oldSize = itemData.oldSize
                       if item and item.Parent and InstanceIsA(item, "BasePart") then
                           local currentSize = item.Size -- Capture current size for redo
                           item.Size = oldSize
                           Log.Info("Undid Scale: Reverted '" .. (item.Name or "Unnamed") .. "' Size.")
                           TableInsert(redoData.data, {item = item, oldSize = currentSize})
                            TableInsert(itemsToRestoreSelection, item)
                             if activeItem == item then restoreActiveItem = item end
                       else
                           Log.Warn("Undid Scale: Item no longer exists or is not BasePart.")
                       end
                  end
                    StudioBlock.clearSelection()
                   for _, item in IpairsGlobal(itemsToRestoreSelection) do TableInsert(selectedItems, item) end
                    if restoreActiveItem then activeItem = restoreActiveItem end
                    updateGUIForActiveItem()

                   TableInsert(redoStack, redoData)

              elseif lastAction.action == "apply_properties" then
                   -- Undo Apply Properties: Revert properties
                   local item = lastAction.data.item
                   local oldProperties = lastAction.data.oldProperties
                    local redoProperties = {}

                   if item and item.Parent and InstanceIsA(item, "BasePart") then
                       -- Store current state for redo
                       redoProperties.Size = item.Size
                       redoProperties.Color = item.Color
                       redoProperties.Transparency = item.Transparency
                       redoProperties.Reflectance = item.Reflectance
                       redoProperties.CanCollide = item.CanCollide
                       redoProperties.Anchored = item.Anchored
                       redoProperties.Shape = InstanceIsA(item, "Part") and item.Shape.Name or nil
                       redoProperties.Material = InstanceIsA(item, "Part") and item.Material.Name or nil
                        redoProperties.Attributes = InstanceIsA(item, "Part") and item:GetAttributes() or nil

                       -- Apply old properties
                       item.Size = oldProperties.Size
                       item.Color = oldProperties.Color
                       item.Transparency = oldProperties.Transparency
                       item.Reflectance = oldProperties.Reflectance
                       item.CanCollide = oldProperties.CanCollide
                       item.Anchored = oldProperties.Anchored
                        if InstanceIsA(item, "Part") then
                             -- Recreating part for shape/material change via undo is complex.
                             -- Log.Warn("Undo Apply Properties: Shape/Material change cannot be undone directly. Only basic properties reverted.")
                             -- item.Shape = EnumPartType[oldProperties.Shape] or item.Shape -- Requires recreation
                             -- item.Material = EnumMaterial[oldProperties.Material] or item.Material -- Requires recreation
                        end
                        -- Restore Attributes
                        if oldProperties.Attributes then
                             for attr, value in PairsGlobal(oldProperties.Attributes) do
                                  safeCall(function() item:SetAttribute(attr, value) end)
                             end
                        end
                         if redoProperties.Attributes then
                              for attr, value in PairsGlobal(redoProperties.Attributes) do
                                   if not oldProperties.Attributes or oldProperties.Attributes[attr] == nil then
                                        safeCall(function() item:SetAttribute(attr, nil) end)
                                   end
                              end
                         end

                       Log.Info("Undid Apply Properties: Reverted properties for '" .. (item.Name or "Unnamed") .. "'")
                   else
                       Log.Warn("Undid Apply Properties: Item no longer exists or is not BasePart.")
                   end
                   -- Push Redo state
                    TableInsert(redoStack, {action = "apply_properties_undo", data = {item = item, oldProperties = redoProperties}})

              elseif lastAction.action == "set_pivot" then
                  -- Undo Set Pivot: Restore old pivot state
                  local oldPivotCFrame = lastAction.data.oldPivotCFrame
                  -- oldPivotPart reference is likely invalid, but we can recreate the highlight if needed
                   local currentPivotCFrameForRedo = currentPivotCFrame -- Capture current state for redo
                   local currentPivotPartForRedo = pivotHighlightPart -- Capture current part for redo

                  currentPivotCFrame = oldPivotCFrame
                   if pivotHighlightPart then pivotHighlightPart:Destroy() pivotHighlightPart = nil end

                  if oldPivotCFrame then
                        pivotHighlightPart = InstanceNew("Part")
                        pivotHighlightPart.Shape = EnumPartType.Ball
                        pivotHighlightPart.Size = Vector3New(1, 1, 1)
                        pivotHighlightPart.Anchored = true
                        pivotHighlightPart.CanCollide = false
                        pivotHighlightPart.Transparency = 0.5
                        pivotHighlightPart.Color = Color3New(1, 1, 0)
                        pivotHighlightPart.CFrame = currentPivotCFrame
                        pivotHighlightPart.Parent = Workspace
                        Log.Info("Undid Set Pivot: Reverted to old pivot (re-created highlight).")
                   else
                        Log.Info("Undid Set Pivot: Cleared pivot.")
                   end
                    -- Push Redo state
                   TableInsert(redoStack, {action = "set_pivot_undo", data = {oldPivotCFrame = currentPivotCFrameForRedo, oldPivotPart = currentPivotPartForRedo}})

              elseif lastAction.action == "terrain" then
                  -- Undo Terrain: Revert terrain to the state before the edit
                   local region = lastAction.data.region
                   if #terrainUndoStates > 0 then
                        local oldTerrainState = TableRemove(terrainUndoStates, #terrainUndoStates) -- Get the most recent terrain state

                        -- Read current state of the region for redo
                         local currentTerrainStateForRedo = nil
                         local successRead, materialsRead, occupanciesRead = safeCall(function() return Terrain:ReadVoxels(region, Config.TERRAIN_VOXEL_RESOLUTION) end)
                         if successRead then
                             currentTerrainStateForRedo = {Region = region, Materials = materialsRead, Occupancies = occupanciesRead}
                         else
                              Log.Warn("Failed to read current terrain state for Redo during Undo Terrain.")
                         end

                        -- Write the old state back
                         local successWrite = safeCall(function() Terrain:WriteVoxels(region, Config.TERRAIN_VOXEL_RESOLUTION, oldTerrainState.Materials, oldTerrainState.Occupancies) end)
                         if successWrite then
                             safeCall(function() Terrain:AutowedgeCells(region) end)
                             Log.DisplayMessage("Undid terrain edit.", Color3New(1, 1, 0.5))
                             -- Push current state to terrainRedoStates
                              if currentTerrainStateForRedo then
                                  TableInsert(terrainRedoStates, currentTerrainStateForRedo)
                                  -- Push redo action to main redoStack
                                   TableInsert(redoStack, {action = "terrain_undo", data = {region = region}})
                               else
                                   Log.Warn("Skipping Redo push for Terrain Undo due to failed state capture.")
                               end
                         else
                              Log.Error("Failed to write old terrain state during Undo Terrain.")
                         end

                   else
                       Log.Warn("No terrain state found in terrainUndoStates for Undo Terrain.")
                        Log.DisplayMessage("No terrain state to Undo.", Color3New(0.8, 0.8, 0.8))
                   end

            -- Add other action types here (group, ungroup, boolean results) - Complex Undo/Redo

            else
                Log.Warn("Unknown Undo action type: " .. lastAction.action)
                 TableInsert(redoStack, lastAction)
            end
        end)

         updateGUIForActiveItem()
          updateItemSelectionDropdown_GUI()
    else
        Log.Info("Undo stack is empty.")
         Log.DisplayMessage("Nothing to Undo.", Color3New(0.8, 0.8, 0.8))
    end
end

local function redo()
    if #redoStack > 0 then
        local lastUndoneAction = TableRemove(redoStack)
        Log.Info("Performing Redo action: " .. lastUndoneAction.action)
        Log.DisplayMessage("Redoing: " .. lastUndoneAction.action .. "...", Color3New(0.5, 1, 1))

        local success = safeCall(function()
             if lastUndoneAction.action == "create_undo" then
                  -- Redo Create (after Undo Create): Re-create the item
                  local itemConfig = lastUndoneAction.data.itemConfig
                  local parentItem = lastUndoneAction.data.parentItem
                  local wasSelected = lastUndoneAction.data.wasSelected
                  local wasActive = lastUndoneAction.data.wasActive

                  local loadedItem = loadItemRecursive(itemConfig, parentItem or Workspace)
                   if loadedItem then
                      TableInsert(managedItems, loadedItem)
                       if wasSelected then TableInsert(selectedItems, loadedItem) end
                       if wasActive then StudioBlock.setActiveBlockByIndex(table.find(managedItems, loadedItem)) else updateGUIForActiveItem() end

                      Log.Info("Redid Create: Restored '" .. (loadedItem.Name or "Unnamed") .. "'")
                       -- Store data for Undo (Delete the restored item) - recursive save
                       local itemConfigForUndo = saveItemRecursive(loadedItem)
                       local itemParentForUndo = loadedItem.Parent
                       local wasSelectedForUndo = table.find(selectedItems, loadedItem) ~= nil
                       local wasActiveForUndo = activeItem == loadedItem

                      TableInsert(undoStack, {action = "delete", data = {item = loadedItem, itemConfig = itemConfigForUndo, parentItem = itemParentForUndo, wasSelected = wasSelectedForUndo, wasActive = wasActiveForUndo}})
                   else
                       Log.Warn("Redid Create: Failed to restore item.")
                   end


             elseif lastUndoneAction.action == "create_multiple_undo" then
                  -- Redo Create Multiple (after Undo Create Multiple): Re-create the items
                  local itemsData = lastUndoneAction.data.items -- Contains itemConfigs and parentItems
                  local undoItemsData = {} -- To store references for undo

                   for _, itemData in IpairsGlobal(itemsData) do
                       local itemConfig = itemData.itemConfig
                       local parentItem = itemData.parentItem
                       local loadedItem = loadItemRecursive(itemConfig, parentItem or Workspace)
                       if loadedItem then
                           TableInsert(managedItems, loadedItem)
                           Log.Info("Redid Create Multiple: Restored '" .. (loadedItem.Name or "Unnamed") .. "'")
                            TableInsert(undoItemsData, {item = loadedItem})
                       else
                           Log.Warn("Redid Create Multiple: Failed to restore item from config.")
