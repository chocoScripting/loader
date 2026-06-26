local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua?t=" .. tostring(tick())
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

-- PLAYER & SERVICES
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- CHARACTER SETUP
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function getActiveCharacterInfo()
    local character = player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        return nil, nil, nil
    end
    return character, rootPart, humanoid
end

local function setupCharacter(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    task.spawn(setupCharacter, player.Character)
end

-- Keep updating global hrp/char in background for other references
task.spawn(function()
    while IsRunning do
        pcall(function()
            local activeChar, activeHRP = getActiveCharacterInfo()
            if activeChar and activeHRP then
                char = activeChar
                hrp = activeHRP
            end
        end)
        task.wait(0.2)
    end
end)

local ENEMY_FOLDER_NAME = "EnemyNpc"

local function getEnemyFolder()
    return workspace:FindFirstChild(ENEMY_FOLDER_NAME)
end

-- STATE CONTROLS
local IsRunning = true
local features = {
    KillAura    = false,
    AutoFarm    = false,
    EnemyESP    = false,
}

local damageMultiplier   = 1   -- How many times to fire per cycle
local attackArg          = 1   -- Custom attack remote argument
local farmOffsetX        = 0
local farmOffsetY        = 12
local farmOffsetZ        = 0
local currentTarget      = nil
local enemyHighlights    = {}

-- THEME COLOR
local ThemeColor     = Color3.fromRGB(100, 200, 255)
local ThemeColorDark = Color3.fromRGB(50, 120, 200)

--// =============================================================================
--// INITIALIZE GUI
--// =============================================================================
local Window = Library.new("🌀 Iron Soul")

local combatPage   = Window:CreatePage("Combat")
local espPage      = Window:CreatePage("ESP")
local configPage   = Window:CreatePage("Config")
local settingsPage = Window:CreatePage("Settings")

local function notify(title, text, duration)
    if Window then
        Window:Notify(title, text, duration)
    end
end

--// =============================================================================
--// GUI ELEMENTS
--// =============================================================================

-- Kill Aura toggle (we keep reference for AutoFarm to enable it)
local killAuraToggleCtrl
local _, kaCtrl = combatPage:CreateToggle("Kill Aura", false, function(value)
    features.KillAura = value
    notify("Kill Aura", value and "Enabled" or "Disabled", 3)
end)
killAuraToggleCtrl = kaCtrl

combatPage:CreateButton("Brutal Kill Aura", function()
    local enemies = getEnemies(math.huge)
    local count = 0
    for _, enemy in ipairs(enemies) do
        local hum = enemy:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            local isBoss = enemy:GetAttribute("LevelType") == "Boss"
            if not isBoss then
                pcall(function()
                    hum.Health = 0
                    count = count + 1
                end)
            end
        end
    end
    notify("Brutal Kill", "Eliminated " .. tostring(count) .. " enemies!", 2)
end)

combatPage:CreateTextBox("Multiplier", "1-100", damageMultiplier, function(value)
    damageMultiplier = math.clamp(math.floor(value), 1, 100)
    notify("Multiplier Set", "Damage multiplier: " .. tostring(damageMultiplier), 2)
end)

combatPage:CreateDropdown("Attack Type", "Heavy/Light Weapon", function()
    return {
        {Name = "Heavy/Light Weapon", Value = 1},
        {Name = "Staff", Value = 5}
    }
end, function(value)
    attackArg = value
    notify("Attack Type Set", "Value: " .. tostring(attackArg), 2)
end)

combatPage:CreateToggle("Auto Farm", false, function(value)
    features.AutoFarm = value
    notify("Auto Farm", value and "Enabled" or "Disabled", 3)
end)

-- Config Page Elements
configPage:CreateTextBox("Attack Argument", "Number", attackArg, function(value)
    attackArg = value
    notify("Attack Arg Set", "Value: " .. tostring(attackArg), 2)
end)

configPage:CreateTextBox("Offset X (Left/Right)", "Number", farmOffsetX, function(value)
    farmOffsetX = value
    notify("Offset X Set", "Left/Right: " .. tostring(farmOffsetX), 2)
end)

configPage:CreateTextBox("Offset Y (Height)", "Number", farmOffsetY, function(value)
    farmOffsetY = value
    notify("Offset Y Set", "Height: " .. tostring(farmOffsetY), 2)
end)

configPage:CreateTextBox("Offset Z (Front/Back)", "Number", farmOffsetZ, function(value)
    farmOffsetZ = value
    notify("Offset Z Set", "Front/Back: " .. tostring(farmOffsetZ), 2)
end)

-- ESP Page
espPage:CreateToggle("Enemy ESP", false, function(value)
    features.EnemyESP = value
    notify("Enemy ESP", value and "Enabled" or "Disabled", 3)
    if not value then
        -- Cleanup all highlights & billboards
        for _, hl in ipairs(enemyHighlights) do
            pcall(function() hl:Destroy() end)
        end
        enemyHighlights = {}
        local folder = getEnemyFolder()
        if folder then
            for _, v in ipairs(folder:GetDescendants()) do
                if v.Name == "_IronSoulEnemyBB" or v.Name == "IronSoulESPHL" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end)

-- Settings Page
local fpsLabel, fpsCtrl = settingsPage:CreateLabel("FPS", "60")

settingsPage:CreateButton("Destroy GUI", function()
    IsRunning = false
    features.KillAura     = false
    features.AutoFarm     = false
    features.EnemyESP     = false
    for _, hl in ipairs(enemyHighlights) do
        pcall(function() hl:Destroy() end)
    end
    enemyHighlights = {}
    local folder = getEnemyFolder()
    if folder then
        for _, v in ipairs(folder:GetDescendants()) do
            if v.Name == "_IronSoulEnemyBB" or v.Name == "IronSoulESPHL" then
                pcall(function() v:Destroy() end)
            end
        end
    end
    Window:Destroy()
end)

notify("Loaded", "Angels - Iron Soul Loaded Successfully!", 5)

--// =============================================================================
--// UTILITY: GET ENEMIES
--// =============================================================================

local function getEnemies(radius)
    local result = {}
    local folder = getEnemyFolder()
    local _, activeHRP = getActiveCharacterInfo()
    if not folder or not activeHRP then return result end

    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("Model") then
            local eHRP = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            local eHum = v:FindFirstChild("Humanoid")
            if eHRP and eHum and eHum.Health > 0 then
                local success, dist = pcall(function()
                    return (activeHRP.Position - eHRP.Position).Magnitude
                end)
                if success and (radius == math.huge or dist <= radius) then
                    table.insert(result, v)
                end
            end
        end
    end
    return result
end



--// =============================================================================
--// ENEMY ESP
--// =============================================================================

local function getOrCreateEnemyBillboard(enemy)
    local headPart = enemy:FindFirstChild("Head")
        or enemy:FindFirstChild("HumanoidRootPart")
        or enemy:FindFirstChildWhichIsA("BasePart")
    if not headPart then return end

    local bb = headPart:FindFirstChild("_IronSoulEnemyBB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "_IronSoulEnemyBB"
        bb.Size = UDim2.new(0, 130, 0, 48)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Parent = headPart

        local bg = Instance.new("Frame")
        bg.Name = "Frame"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
        bg.BackgroundTransparency = 0.25
        bg.BorderSizePixel = 0
        bg.Parent = bb
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = bg
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Color = ThemeColor
        bgStroke.Thickness = 1.2
        bgStroke.Parent = bg

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -8, 0.5, 0)
        titleLbl.Position = UDim2.new(0, 4, 0, 2)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "⚡ " .. enemy.Name
        titleLbl.TextColor3 = ThemeColor
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Center
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.Parent = bg

        local distLbl = Instance.new("TextLabel")
        distLbl.Name = "Distance"
        distLbl.Size = UDim2.new(1, -8, 0.5, -2)
        distLbl.Position = UDim2.new(0, 4, 0.5, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "... studs"
        distLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Center
        distLbl.Parent = bg
    end
    return bb
end

local function createEnemyHighlight(model)
    if not model:IsA("Model") then return nil end
    local hl = Instance.new("Highlight")
    hl.Name = "IronSoulESPHL"
    hl.Adornee = model
    hl.FillColor = ThemeColor
    hl.OutlineColor = ThemeColorDark
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    return hl
end

task.spawn(function()
    local cleanedUp = true
    while IsRunning do
        local success, err = pcall(function()
            if features.EnemyESP then
                cleanedUp = false
                local _, activeHRP = getActiveCharacterInfo()
                local enemies = getEnemies(math.huge)
                local activeHighlights = {}

                for _, enemy in ipairs(enemies) do
                    local existing = enemy:FindFirstChild("IronSoulESPHL")
                    if existing then
                        table.insert(activeHighlights, existing)
                    else
                        local newHL = createEnemyHighlight(enemy)
                        if newHL then
                            table.insert(activeHighlights, newHL)
                        end
                    end

                    -- Update billboard distance
                    local bb = getOrCreateEnemyBillboard(enemy)
                    if bb and activeHRP and activeHRP.Parent then
                        local headPart = bb.Parent
                        if headPart and headPart:IsA("BasePart") then
                            local dist = math.floor((activeHRP.Position - headPart.Position).Magnitude)
                            local frame = bb:FindFirstChild("Frame")
                            local distLbl = frame and frame:FindFirstChild("Distance")
                            if distLbl then
                                distLbl.Text = tostring(dist) .. " studs"
                            end
                        end
                    end
                end

                -- Prune stale highlights
                for i = #enemyHighlights, 1, -1 do
                    local hl = enemyHighlights[i]
                    if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
                        pcall(function() if hl then hl:Destroy() end end)
                        table.remove(enemyHighlights, i)
                    end
                end
                enemyHighlights = activeHighlights
            else
                if not cleanedUp then
                    cleanedUp = true
                    for _, hl in ipairs(enemyHighlights) do
                        pcall(function() if hl then hl:Destroy() end end)
                    end
                    enemyHighlights = {}
                    local folder = getEnemyFolder()
                    if folder then
                        for _, v in ipairs(folder:GetDescendants()) do
                            if v.Name == "_IronSoulEnemyBB" or v.Name == "IronSoulESPHL" then
                                pcall(function() v:Destroy() end)
                            end
                        end
                    end
                end
            end
        end)
        if not success then
            warn("Enemy ESP Loop Error: " .. tostring(err))
        end
        task.wait(features.EnemyESP and 0.5 or 0.2)
    end
end)

--// =============================================================================
--// KILL AURA
--// =============================================================================

local function fireKillAura()
    pcall(function()
        local args = {
            "SkillAction",
            "BaseAttack",
            attackArg
        }
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerActionRE"):FireServer(unpack(args))
    end)
end

task.spawn(function()
    while IsRunning do
        local delayTime = 0.2
        local success, err = pcall(function()
            if features.KillAura then
                for i = 1, damageMultiplier do
                    fireKillAura()
                end
                delayTime = 0.05
            end
        end)
        if not success then
            warn("Kill Aura Loop Error: " .. tostring(err))
            delayTime = 0.1
        end
        task.wait(delayTime)
    end
end)

--// =============================================================================
--// AUTO FARM
--// =============================================================================

task.spawn(function()
    while IsRunning do
        local delayTime = 0.2
        local success, err = pcall(function()
            if features.AutoFarm then
                local _, activeHRP, activeHum = getActiveCharacterInfo()
                if activeHRP and activeHum and activeHum.Health > 0 then
                    -- Target enemies
                    local enemies = getEnemies(math.huge)

                    if #enemies > 0 then
                        -- Sort enemies by distance
                        table.sort(enemies, function(a, b)
                            local aH = a:FindFirstChild("HumanoidRootPart")
                            local bH = b:FindFirstChild("HumanoidRootPart")
                            if aH and bH then
                                return (activeHRP.Position - aH.Position).Magnitude < (activeHRP.Position - bH.Position).Magnitude
                            end
                            return false
                        end)

                        local targetEnemy = enemies[1]
                        currentTarget = targetEnemy
                        local eHRP = targetEnemy:FindFirstChild("HumanoidRootPart")
                        if eHRP then
                            activeHRP.CFrame = eHRP.CFrame * CFrame.new(farmOffsetX, farmOffsetY, farmOffsetZ) * CFrame.Angles(-math.pi / 2, 0, 0)
                        end
                    else
                        currentTarget = nil
                    end
                    delayTime = 0.01
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        end)
        if not success then
            warn("Auto Farm Loop Error: " .. tostring(err))
            delayTime = 0.1
        end
        task.wait(delayTime)
    end
end)

--// =============================================================================
--// FPS COUNTER
--// =============================================================================

local frameTimer = tick()
local frameCounter = 0
local fpsConn
fpsConn = RunService.RenderStepped:Connect(function()
    if not IsRunning then
        if fpsConn then fpsConn:Disconnect() end
        return
    end
    frameCounter = frameCounter + 1
    if (tick() - frameTimer) >= 1 then
        local fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
        if fpsCtrl then
            fpsCtrl:SetText(tostring(fps))
        end
    end
end)

print("✅ Angels - Iron Soul LOADED!")
print("🎮 Press G to toggle UI | Drag from title bar")
print("⚔️ Kill Aura | 🚜 Auto Farm | 💡 Enemy ESP")
