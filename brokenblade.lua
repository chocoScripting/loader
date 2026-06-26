local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua?t=" .. tostring(tick())
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

-- SERVICES
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- PLAYER
local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local hrp    = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp  = newChar:WaitForChild("HumanoidRootPart")
end)

-- STATE
local IsRunning             = true
local killAuraEnabled       = false
local damageMultiplier      = 1
local payload1              = nil
local payload2              = nil
local payload3              = nil
local lastFired             = 1
local autoChomusukeEnabled  = false
local chomusukeToggleCtrl   = nil  -- reference to toggle controller for auto-off
local autoFarmEnabled       = false
local selectedEnemies       = {}

--================================================================
-- PARSE PAYLOAD FROM REMOTE SPY
-- Supports pasting the ENTIRE Remote Spy code:
--   local args = { buffer.fromstring("...") }
--   game:GetService(...):FireServer(unpack(args))
-- Or just the raw string content: \147\020\204...
--================================================================

local function parsePayload(rawInput)
    -- Flatten newlines so the pattern can match multi-line input
    local flat = rawInput:gsub("\r\n", " "):gsub("\n", " "):gsub("\r", " ")

    -- Extract content inside buffer.fromstring("...") using [^"] pattern (safe)
    local extracted = flat:match('buffer%.fromstring%("([^"]*)"%)') 
                   or flat:match("buffer%.fromstring%('([^']*)'%)")

    local target = extracted or rawInput:match("^%s*(.-)%s*$")

    -- Evaluate escape sequences \147\020 etc. via loadstring
    local fn, err = loadstring('return "' .. target .. '"')
    if not fn then
        return nil, "Parse error: " .. tostring(err)
    end

    local ok, result = pcall(fn)
    if not ok or type(result) ~= "string" then
        return nil, "Eval error: " .. tostring(result)
    end

    return buffer.fromstring(result), nil
end

--================================================================
-- FIRE REMOTE
--================================================================

local function fireKillAura()
    local remoteEvent = ReplicatedStorage:FindFirstChild("Remote_Event")
    if not remoteEvent then return end

    -- Build list of active payloads
    local active = {}
    if payload1 then active[#active+1] = payload1 end
    if payload2 then active[#active+1] = payload2 end
    if payload3 then active[#active+1] = payload3 end

    if #active == 0 then return end

    -- Round-robin through available payloads
    if lastFired >= #active then lastFired = 1 else lastFired = lastFired + 1 end
    local targetPayload = active[lastFired]

    if not targetPayload then return end
    pcall(function()
        remoteEvent:FireServer(targetPayload)
    end)
end

--================================================================
-- GUI SETUP
--================================================================

local Window = Library.new("Broken Blade")

local combatPage   = Window:CreatePage("Combat")
local farmPage     = Window:CreatePage("Auto Farm")
local payloadPage  = Window:CreatePage("Payload")
local settingsPage = Window:CreatePage("Settings")

-- Dynamic runtime fallback patch for CreateMultiDropdown (used for Auto Farm)
local PageTable = getmetatable(combatPage)
if PageTable and not PageTable.CreateMultiDropdown then
    PageTable.CreateMultiDropdown = function(self, text, placeholderText, scanCallback, selectCallback)
        local parent = self.ScrollFrame

        local row = Instance.new("Frame")
        row.Name = text .. "Row"
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local button = Instance.new("TextButton")
        button.Name = "DropdownButton"
        button.Size = UDim2.new(0.58, 0, 0, 24)
        button.Position = UDim2.new(0.42, 0, 0.5, -12)
        button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.Text = placeholderText .. "  ▼"
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 11
        button.BorderSizePixel = 0
        button.Parent = row

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = button

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(50, 50, 50)
        btnStroke.Thickness = 1.0
        btnStroke.Parent = button

        -- List container (floating dropdown list)
        local listContainer = Instance.new("ScrollingFrame")
        listContainer.Name = "DropdownList"
        listContainer.Size = UDim2.new(0.58, 0, 0, 110)
        listContainer.Position = UDim2.new(0.42, 0, 1, 4)
        listContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        listContainer.BorderSizePixel = 0
        listContainer.ZIndex = 100
        listContainer.Visible = false
        listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        listContainer.ScrollBarThickness = 3
        listContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        listContainer.Parent = row

        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 6)
        listCorner.Parent = listContainer

        local listStroke = Instance.new("UIStroke")
        listStroke.Color = Color3.fromRGB(80, 80, 80)
        listStroke.Thickness = 1.0
        listStroke.Parent = listContainer

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = listContainer

        local listPadding = Instance.new("UIPadding")
        listPadding.PaddingTop = UDim.new(0, 4)
        listPadding.PaddingBottom = UDim.new(0, 4)
        listPadding.PaddingLeft = UDim.new(0, 4)
        listPadding.PaddingRight = UDim.new(0, 4)
        listPadding.Parent = listContainer

        local isOpen = false
        local selected = {} -- Dict of selected values: [value] = true/nil
        local optionLabels = {} -- Cache of value to label mapping

        local function getPageScroll()
            local curr = row
            while curr do
                if curr:IsA("ScrollingFrame") then
                    return curr
                end
                curr = curr.Parent
            end
            return nil
        end

        local function updateButtonText()
            local count = 0
            local displayLabels = {}
            for val, _ in pairs(selected) do
                count = count + 1
                local labelText = optionLabels[val] or tostring(val)
                table.insert(displayLabels, labelText)
            end
            
            if count == 0 then
                button.Text = placeholderText .. "  ▼"
            else
                local concatenated = table.concat(displayLabels, ", ")
                if #concatenated > 20 then
                    button.Text = tostring(count) .. " Selected  ▼"
                else
                    button.Text = concatenated .. "  ▼"
                end
            end
        end

        local function refreshList()
            -- Clear existing items
            for _, child in ipairs(listContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            -- Populate Options
            local options = scanCallback()
            optionLabels = {}
            if #options == 0 then
                local noItem = Instance.new("TextButton")
                noItem.Size = UDim2.new(1, 0, 0, 24)
                noItem.BackgroundTransparency = 1
                noItem.Text = "No Options"
                noItem.TextColor3 = Color3.fromRGB(150, 150, 150)
                noItem.Font = Enum.Font.GothamItalic
                noItem.TextSize = 11
                noItem.ZIndex = 12
                noItem.Parent = listContainer
            else
                for _, option in ipairs(options) do
                    local optLabel = type(option) == "table" and (option.Name or option.Value or tostring(option)) or tostring(option)
                    local optValue = type(option) == "table" and (option.Value or option.Name or tostring(option)) or option

                    optionLabels[optValue] = optLabel

                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 24)
                    optBtn.Font = Enum.Font.GothamMedium
                    optBtn.TextSize = 11
                    optBtn.ZIndex = 12
                    optBtn.Parent = listContainer

                    local isSel = selected[optValue] ~= nil
                    if isSel then
                        optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        optBtn.Text = "✓ " .. optLabel
                    else
                        optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                        optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                        optBtn.Text = optLabel
                    end

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn

                    optBtn.MouseButton1Click:Connect(function()
                        if selected[optValue] then
                            selected[optValue] = nil
                        else
                            selected[optValue] = true
                        end
                        
                        -- Update the current button visually without closing dropdown
                        local newSel = selected[optValue] ~= nil
                        if newSel then
                            optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                            optBtn.Text = "✓ " .. optLabel
                        else
                            optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                            optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                            optBtn.Text = optLabel
                        end

                        updateButtonText()
                        
                        -- Trigger callback
                        local selectedList = {}
                        for val, _ in pairs(selected) do
                            table.insert(selectedList, val)
                        end
                        selectCallback(selectedList, selected)
                    end)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end)

                    optBtn.MouseLeave:Connect(function()
                        local currentlySel = selected[optValue] ~= nil
                        if currentlySel then
                            optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        else
                            optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                            optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                        end
                    end)
                end
            end

            task.defer(function()
                listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
            end)
        end

        local function toggleDropdown()
            isOpen = not isOpen
            local pageScroll = getPageScroll()
            if pageScroll then
                pageScroll.ClipsDescendants = not isOpen
            end
            
            if isOpen then
                row.ZIndex = 10
                button.ZIndex = 10
                listContainer.ZIndex = 11

                refreshList()

                listContainer.Visible = true
                btnStroke.Color = Color3.fromRGB(255, 255, 255)
            else
                row.ZIndex = 1
                button.ZIndex = 1
                listContainer.ZIndex = 1
                listContainer.Visible = false
                btnStroke.Color = Color3.fromRGB(50, 50, 50)
            end
        end

        button.MouseButton1Click:Connect(toggleDropdown)

        button.MouseEnter:Connect(function()
            if not isOpen then
                button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                btnStroke.Color = Color3.fromRGB(100, 100, 100)
            end
        end)

        button.MouseLeave:Connect(function()
            if not isOpen then
                button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                btnStroke.Color = Color3.fromRGB(50, 50, 50)
            end
        end)

        local controller = {}
        function controller:SetSelected(newSelectedDict)
            selected = {}
            for val, state in pairs(newSelectedDict) do
                if state then
                    selected[val] = true
                end
            end
            updateButtonText()
            if isOpen then
                refreshList()
            end
        end
        
        function controller:GetSelected()
            local list = {}
            for val, _ in pairs(selected) do
                table.insert(list, val)
            end
            return list, selected
        end

        return row, controller
    end
end

-- AUTO FARM PAGE ------------------------------------------------

farmPage:CreateToggle("Auto Farm", false, function(value)
    autoFarmEnabled = value
    notify("Auto Farm", value and "Enabled" or "Disabled", 3)
end)

farmPage:CreateMultiDropdown("Select Enemies", "Choose Enemies", function()
    local names = {}
    local seen = {}
    local enemyService = workspace:FindFirstChild("EnemyService")
    if enemyService then
        for _, child in ipairs(enemyService:GetChildren()) do
            if child:IsA("Model") and not seen[child.Name] then
                seen[child.Name] = true
                table.insert(names, child.Name)
            end
        end
    end
    table.sort(names)
    return names
end, function(selectedList, selectedDict)
    selectedEnemies = selectedDict
end)

local function notify(title, text, duration)
    if Window then Window:Notify(title, text, duration) end
end

-- COMBAT PAGE --------------------------------------------------

combatPage:CreateToggle("Kill Aura", false, function(value)
    if value and not payload1 and not payload2 then
        notify("Kill Aura", "Set at least one payload first!", 4)
        killAuraEnabled = false
        return
    end
    killAuraEnabled = value
    notify("Kill Aura", value and "Enabled" or "Disabled", 3)
end)

combatPage:CreateTextBox("Multiplier", "1-100", damageMultiplier, function(value)
    damageMultiplier = math.max(1, math.floor(value))
    notify("Multiplier Set", "Damage multiplier: " .. tostring(damageMultiplier), 2)
end)

local _, payloadStatus = combatPage:CreateLabel("Status", "Payload not set")

local function updatePayloadStatus()
    if not payloadStatus then return end
    local parts = {}
    if payload1 then parts[#parts+1] = "P1(" .. tostring(buffer.len(payload1)) .. "B)" end
    if payload2 then parts[#parts+1] = "P2(" .. tostring(buffer.len(payload2)) .. "B)" end
    if payload3 then parts[#parts+1] = "P3(" .. tostring(buffer.len(payload3)) .. "B)" end
    if #parts > 0 then
        payloadStatus:SetText(table.concat(parts, " | ") .. " active")
    else
        payloadStatus:SetText("Payload not set")
    end
end

local _, chomusukeCtrl = combatPage:CreateToggle("Auto Chomusuke", false, function(value)
    autoChomusukeEnabled = value
    notify("Auto Chomusuke", value and "Enabled" or "Disabled", 3)
end)
chomusukeToggleCtrl = chomusukeCtrl

-- PAYLOAD PAGE -------------------------------------------------

local payloadInput1 = ""
local _, payloadBoxCtrl1 = payloadPage:CreateTextBox("Paste Payload 1", "local args = { buffer.fromstring(...) } ...", "", function(value)
    payloadInput1 = value
end)

payloadPage:CreateButton("Set Payload 1", function()
    if payloadInput1 == "" then
        notify("Error", "Textbox 1 is empty!", 3)
        return
    end

    local buf, err = parsePayload(payloadInput1)
    if not buf then
        notify("Parse Failed", err or "Unknown error", 5)
        return
    end

    payload1 = buf
    updatePayloadStatus()
    notify("Payload 1 Set", "Success! " .. tostring(buffer.len(buf)) .. " bytes", 3)
end)

payloadPage:CreateButton("Clear Payload 1", function()
    payload1 = nil
    payloadInput1 = ""
    if payloadBoxCtrl1 then payloadBoxCtrl1:SetText("") end
    if not payload1 and not payload2 and not payload3 then
        killAuraEnabled = false
    end
    updatePayloadStatus()
    notify("Cleared", "Payload 1 cleared", 2)
end)

local payloadInput2 = ""
local _, payloadBoxCtrl2 = payloadPage:CreateTextBox("Paste Payload 2", "local args = { buffer.fromstring(...) } ...", "", function(value)
    payloadInput2 = value
end)

payloadPage:CreateButton("Set Payload 2", function()
    if payloadInput2 == "" then
        notify("Error", "Textbox 2 is empty!", 3)
        return
    end

    local buf, err = parsePayload(payloadInput2)
    if not buf then
        notify("Parse Failed", err or "Unknown error", 5)
        return
    end

    payload2 = buf
    updatePayloadStatus()
    notify("Payload 2 Set", "Success! " .. tostring(buffer.len(buf)) .. " bytes", 3)
end)

payloadPage:CreateButton("Clear Payload 2", function()
    payload2 = nil
    payloadInput2 = ""
    if payloadBoxCtrl2 then payloadBoxCtrl2:SetText("") end
    if not payload1 and not payload2 and not payload3 then
        killAuraEnabled = false
    end
    updatePayloadStatus()
    notify("Cleared", "Payload 2 cleared", 2)
end)

local payloadInput3 = ""
local _, payloadBoxCtrl3 = payloadPage:CreateTextBox("Paste Payload 3", "local args = { buffer.fromstring(...) } ...", "", function(value)
    payloadInput3 = value
end)

payloadPage:CreateButton("Set Payload 3", function()
    if payloadInput3 == "" then
        notify("Error", "Textbox 3 is empty!", 3)
        return
    end

    local buf, err = parsePayload(payloadInput3)
    if not buf then
        notify("Parse Failed", err or "Unknown error", 5)
        return
    end

    payload3 = buf
    updatePayloadStatus()
    notify("Payload 3 Set", "Success! " .. tostring(buffer.len(buf)) .. " bytes", 3)
end)

payloadPage:CreateButton("Clear Payload 3", function()
    payload3 = nil
    payloadInput3 = ""
    if payloadBoxCtrl3 then payloadBoxCtrl3:SetText("") end
    if not payload1 and not payload2 and not payload3 then
        killAuraEnabled = false
    end
    updatePayloadStatus()
    notify("Cleared", "Payload 3 cleared", 2)
end)

payloadPage:CreateButton("Clear All Payloads", function()
    payload1        = nil
    payload2        = nil
    payload3        = nil
    killAuraEnabled = false
    payloadInput1   = ""
    payloadInput2   = ""
    payloadInput3   = ""
    if payloadBoxCtrl1 then payloadBoxCtrl1:SetText("") end
    if payloadBoxCtrl2 then payloadBoxCtrl2:SetText("") end
    if payloadBoxCtrl3 then payloadBoxCtrl3:SetText("") end
    updatePayloadStatus()
    notify("Cleared", "All payloads cleared", 2)
end)

-- SETTINGS PAGE ------------------------------------------------

local _, fpsCtrl = settingsPage:CreateLabel("FPS", "60")

settingsPage:CreateButton("Destroy GUI", function()
    IsRunning       = false
    killAuraEnabled = false
    autoFarmEnabled = false
    Window:Destroy()
end)

notify("Loaded", "Broken Blade loaded! Set a payload first.", 5)

--================================================================
-- FPS COUNTER
--================================================================

local frameTimer   = tick()
local frameCounter = 0

local fpsConnection
fpsConnection = RunService.RenderStepped:Connect(function()
    if not IsRunning then
        fpsConnection:Disconnect()
        return
    end
    frameCounter = frameCounter + 1
    if (tick() - frameTimer) >= 1 then
        if fpsCtrl then fpsCtrl:SetText(tostring(frameCounter)) end
        frameCounter = 0
        frameTimer   = tick()
    end
end)

--================================================================
-- KILL AURA LOOP
--================================================================

task.spawn(function()
    while IsRunning do
        if killAuraEnabled and (payload1 or payload2 or payload3) then
            for i = 1, damageMultiplier do
                fireKillAura()
            end
            task.wait(0.0001)
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- AUTO CHOMUSUKE LOOP
--================================================================

task.spawn(function()
    while IsRunning do
        if not autoChomusukeEnabled then
            task.wait(0.2)
        else
            -- Locate the Chomusuke NPC folder
            local chomusukeFolder = workspace:FindFirstChild("World")
                and workspace.World:FindFirstChild("NPC")
                and workspace.World.NPC:FindFirstChild("Chomusuke")

            if not chomusukeFolder then
                task.wait(1)
            else
                -- Iterate ALL models: teleport first, THEN check highlight (it only appears when nearby)
                local models = chomusukeFolder:GetChildren()
                local foundAny = false -- tracks if any model had a highlight this full pass

                for _, model in ipairs(models) do
                    if not autoChomusukeEnabled or not IsRunning then break end
                    if not model:IsA("Model") then continue end

                    -- 1. Teleport to the model's Talk part
                    local talkPart = model:FindFirstChild("Talk")
                    local teleportPos = talkPart and talkPart.Position
                        or (model.PrimaryPart and model.PrimaryPart.Position)
                        or Vector3.new(0, 0, 0)

                    pcall(function()
                        hrp.CFrame = CFrame.new(teleportPos + Vector3.new(0, 0, 3))
                    end)

                    -- 2. Wait 0.6s so PromptFlashHighlight can appear (proximity-dependent)
                    task.wait(0.6)

                    -- 3. Check if this model has PromptFlashHighlight now that we are near
                    if not model:FindFirstChild("PromptFlashHighlight", true) then
                        -- No highlight here, skip to next model
                        continue
                    end

                    -- 4. This model has a highlight — fire the ProximityPrompt
                    foundAny = true
                    local pp = talkPart and talkPart:FindFirstChildWhichIsA("ProximityPrompt")
                    if pp then
                        pcall(function()
                            fireproximityprompt(pp)
                        end)
                    end

                    -- 5. Wait until PromptFlashHighlight disappears (interaction done), max 3s
                    local timeout = tick() + 3
                    repeat
                        task.wait(0.2)
                        if not autoChomusukeEnabled or not IsRunning then break end
                    until not model:FindFirstChild("PromptFlashHighlight", true)
                        or tick() > timeout
                end

                -- If no targets had highlight, wait a bit before starting the next pass
                if not foundAny then
                    task.wait(1)
                end
            end
        end
    end
end)

--================================================================
-- E SPAM LOOP FOR CHOMUSUKE
--================================================================

task.spawn(function()
    while IsRunning do
        if autoChomusukeEnabled then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
            task.wait(0.1)
        else
            task.wait(0.3)
        end
    end
end)

--================================================================
-- AUTO FARM LOOP
--================================================================

task.spawn(function()
    while IsRunning do
        if not autoFarmEnabled then
            task.wait(0.2)
        else
            local enemyService = workspace:FindFirstChild("EnemyService")
            if not enemyService then
                task.wait(1)
            else
                -- Gather all matching alive enemies
                local targets = {}
                for _, child in ipairs(enemyService:GetChildren()) do
                    if child:IsA("Model") then
                        -- Check if child's name matches any selected enemy
                        local nameMatch = false
                        if selectedEnemies[child.Name] then
                            nameMatch = true
                        else
                            -- Fallback to substring matching just in case
                            for selName, enabled in pairs(selectedEnemies) do
                                if enabled and (string.find(child.Name, selName, 1, true) or string.find(selName, child.Name, 1, true)) then
                                    nameMatch = true
                                    break
                                end
                            end
                        end

                        if nameMatch then
                            local humanoid = child:FindFirstChildWhichIsA("Humanoid")
                            local hrpPart = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                            if humanoid and humanoid.Health > 0.1 and hrpPart then
                                table.insert(targets, {
                                    Model = child,
                                    Humanoid = humanoid,
                                    RootPart = hrpPart
                                })
                            end
                        end
                    end
                end

                if #targets == 0 then
                    -- No targets found/alive, wait for respawn
                    task.wait(1)
                else
                    -- Teleport to enemies one by one
                    for _, target in ipairs(targets) do
                        if not autoFarmEnabled or not IsRunning then break end

                        -- Verify target is still valid and alive
                        if target.Model.Parent and target.Humanoid.Health > 0.1 and target.RootPart.Parent then
                            -- Teleport once to the target
                            pcall(function()
                                hrp.CFrame = target.RootPart.CFrame
                            end)

                            -- Wait until target is dead or no longer exists
                            while autoFarmEnabled and IsRunning and target.Model.Parent and target.Humanoid.Health > 0.1 and target.RootPart.Parent do
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

print("Broken Blade loaded!")
print("Press G to toggle UI | Set a payload in the Payload tab first!")
print("Kill Aura | Damage Multiplier")
