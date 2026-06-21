local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua?t=" .. tostring(tick())
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

-- PLAYER & GUI SERVICES
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- GAME SERVICES
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local entityfolder = workspace:FindFirstChild("Entity")
local cachedArg1 = nil
local currentTarget = nil
local loot = workspace:FindFirstChild("FX")

-- Dynamic Event Locator (Resolves issues where the Event changes on weapon swap/death)
local function getEvent()
    if not char then return nil end
    local netMessage = char:FindFirstChild("NetMessage")
    if netMessage then
        return netMessage:FindFirstChild("TrigerSkill")
    end
    return nil
end

-- Handle Character Respawn and Weapon Switching
local function setupCharacter(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    
    newChar.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            -- Reset weapon code cache on tool swap so it recalculates
            cachedArg1 = nil
        end
    end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    task.spawn(setupCharacter, player.Character)
end

-- STATE CONTROLS
local IsRunning = true
local features = {
    KillAura = false,
    AutoFarm = false,
    AutoPickup = false,
    InfiniteRange = false,
    Cover = false,
    MerchantESP = false,
    EntityESP = false,
    SellAll = false
}
local sellList = {}
for i = 1, 200 do
    table.insert(sellList, i)
end
local farmOffset = CFrame.new(0, 7, 0) -- Jarak teleport AutoFarm (Di atas musuh agar tidak terkena hit)
local killAuraRange = 100 -- Jarak deteksi maksimal Kill Aura (Ubah angka ini jika ingin memperpendek/memperpanjang jarak serang)
local damageMultiplier = 1 -- Jumlah hit per serang (Damage Multiplier)
local merchantHighlights = {} -- Store Highlight instances for merchants
local entityHighlights = {} -- Store Highlight instances for entities

-- THEME CONFIGURATION (Crimson Red for Cursed Blade ESP & Highlights)
local ThemeColor = Color3.fromRGB(255, 75, 75)
local ThemeColorDark = Color3.fromRGB(200, 40, 40)

--// =============================================================================
--// INITIALIZE GUI WINDOW & PAGES
--// =============================================================================
local Window = Library.new("⚔️ Angels - Cursed Blade")

local combatPage = Window:CreatePage("Combat")
local espPage = Window:CreatePage("ESP & Teleport")
local miscPage = Window:CreatePage("Utility")
local settingsPage = Window:CreatePage("Settings")

-- Global notify wrapper mapping to the active Window instance
local function notify(title, text, duration)
    if Window then
        Window:Notify(title, text, duration)
    end
end

--// =============================================================================
--// CREATE WINDOW ELEMENTS
--// =============================================================================

-- Global Kill Aura Toggle variable for programmatic access in Auto Farm loop
local killAuraToggle

-- 1. COMBAT PAGE
local _, killAuraToggleObj = combatPage:CreateToggle("Kill Aura", false, function(value)
    features.KillAura = value
    notify("Kill Aura", value and "Enabled" or "Disabled", 3)
end)
killAuraToggle = killAuraToggleObj

combatPage:CreateToggle("Auto Farm", false, function(value)
    features.AutoFarm = value
    notify("Auto Farm", value and "Enabled" or "Disabled", 3)
end)

combatPage:CreateToggle("Infinite Range", false, function(value)
    features.InfiniteRange = value
    notify("Infinite Range", value and "Enabled" or "Disabled", 3)
end)

combatPage:CreateTextBox("Multiplier", "1-100", damageMultiplier, function(value)
    damageMultiplier = value
    notify("Multiplier Set", "Damage multiplier set to " .. tostring(value), 2)
end)

-- 2. ESP & TELEPORT PAGE
espPage:CreateToggle("Merchant ESP", false, function(value)
    features.MerchantESP = value
    notify("Merchant ESP", value and "Enabled" or "Disabled", 3)
    if not value then
        for _, highlight in ipairs(merchantHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        merchantHighlights = {}
        -- Cleanup billboards
        local eitem = workspace:FindFirstChild("EItem")
        if eitem then
            for _, v in ipairs(eitem:GetDescendants()) do
                if v.Name == "_MerchantBB" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end)

espPage:CreateToggle("Entity ESP", false, function(value)
    features.EntityESP = value
    notify("Entity ESP", value and "Enabled" or "Disabled", 3)
    if not value then
        for _, highlight in ipairs(entityHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        entityHighlights = {}
        -- Cleanup billboards
        if entityfolder then
            for _, v in ipairs(entityfolder:GetDescendants()) do
                if v.Name == "_EntityBB" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end)

local selectedMerchant = nil

espPage:CreateDropdown("Select Merchant", "Choose Merchant", function()
    local options = {}
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        local count = 0
        for _, v in ipairs(eitem:GetChildren()) do
            if v.Name == "Merchant" then
                count = count + 1
                local displayName = "Merchant " .. count
                local hrpPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                if hrpPart and hrp then
                    local dist = math.floor((hrp.Position - hrpPart.Position).Magnitude)
                    displayName = string.format("Merchant %d [%d studs]", count, dist)
                end
                table.insert(options, { Name = displayName, Value = v })
            end
        end
        local merchantFolder = eitem:FindFirstChild("Merchant")
        if merchantFolder and merchantFolder:IsA("Folder") then
            for _, v in ipairs(merchantFolder:GetChildren()) do
                count = count + 1
                local hrpPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart") or v
                local displayName = v.Name
                if hrpPart and hrpPart:IsA("BasePart") and hrp then
                    local dist = math.floor((hrp.Position - hrpPart.Position).Magnitude)
                    displayName = string.format("%s [%d studs]", v.Name, dist)
                end
                table.insert(options, { Name = displayName, Value = v })
            end
        end
    end
    return options
end, function(val)
    selectedMerchant = val
end)

espPage:CreateButton("Teleport to Merchant", function()
    if not selectedMerchant or not selectedMerchant.Parent then
        notify("Teleport", "Pilih Merchant terlebih dahulu!", 3)
        return
    end
    local targetCF = nil
    if selectedMerchant:IsA("Model") then
        if selectedMerchant.PrimaryPart then
            targetCF = selectedMerchant.PrimaryPart.CFrame
        else
            local part = selectedMerchant:FindFirstChildWhichIsA("BasePart")
            if part then targetCF = part.CFrame end
        end
    elseif selectedMerchant:IsA("BasePart") then
        targetCF = selectedMerchant.CFrame
    end
    if targetCF and hrp then
        hrp.CFrame = targetCF * CFrame.new(0, 3, 0)
        notify("Teleport", "Berhasil teleport ke " .. selectedMerchant.Name, 3)
    else
        notify("Teleport", "Gagal mendapatkan posisi Merchant!", 3)
    end
end)

-- 3. UTILITY PAGE
miscPage:CreateToggle("Auto Pickup", false, function(value)
    features.AutoPickup = value
    notify("Auto Pickup", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateToggle("Cover Player", false, function(value)
    features.Cover = value
    notify("Cover Player", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateToggle("Sell All", false, function(value)
    features.SellAll = value
    notify("Sell All", value and "Enabled" or "Disabled", 3)
end)

local selectedPlayerName = nil

miscPage:CreateDropdown("Select Player", "Choose Player", function()
    local options = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            table.insert(options, {
                Name = p.DisplayName .. " (@" .. p.Name .. ")",
                Value = p.Name
            })
        end
    end
    return options
end, function(val)
    selectedPlayerName = val
end)

-- 4. SETTINGS PAGE
local fpsLabel, fpsCtrl = settingsPage:CreateLabel("FPS", "60")

settingsPage:CreateButton("Destroy GUI", function()
    IsRunning = false
    features.KillAura = false
    features.AutoFarm = false
    features.AutoPickup = false
    features.InfiniteRange = false
    features.Cover = false
    features.MerchantESP = false
    features.EntityESP = false
    features.SellAll = false
    for _, highlight in ipairs(merchantHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    merchantHighlights = {}
    for _, highlight in ipairs(entityHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    entityHighlights = {}
    
    -- Cleanup billboards when UI is destroyed
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        for _, v in ipairs(eitem:GetDescendants()) do
            if v.Name == "_MerchantBB" then
                pcall(function() v:Destroy() end)
            end
        end
    end
    if entityfolder then
        for _, v in ipairs(entityfolder:GetDescendants()) do
            if v.Name == "_EntityBB" then
                pcall(function() v:Destroy() end)
            end
        end
    end

    Window:Destroy()
end)

-- Notify loaded
notify("Loaded", "Angels - Cursed Blade Loaded Successfully", 5)

--================================================================
-- UTILITY FUNCTIONS
--================================================================

local function Entity(radius)
    local entity = {}
    if not entityfolder or not hrp then return entity end
    for _, v in ipairs(entityfolder:GetChildren()) do
        local Entityhrp = v:FindFirstChild("HumanoidRootPart")
        local EntityHumanoid = v:FindFirstChild("Humanoid")

        if Entityhrp and EntityHumanoid and EntityHumanoid.Health > 0 then
            if radius == math.huge or (hrp.Position - Entityhrp.Position).Magnitude <= radius then
                entity[#entity+1] = v
            end
        end
    end
    return entity
end

--================================================================
-- HOOK SKILL
--================================================================

local oldnamecall
oldnamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "FireServer" and string.lower(self.Name) == "trigerskill" then
        cachedArg1 = args[1]
    end
    return oldnamecall(self, ...)
end)

--================================================================
-- MERCHANT ESP
--================================================================

local function getMerchants()
    local merchants = {}
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        for _, v in ipairs(eitem:GetChildren()) do
            if v.Name == "Merchant" and v:IsA("Model") then
                table.insert(merchants, v)
            end
        end
        local merchantFolder = eitem:FindFirstChild("Merchant")
        if merchantFolder and merchantFolder:IsA("Folder") then
            for _, v in ipairs(merchantFolder:GetChildren()) do
                if v:IsA("Model") then
                    table.insert(merchants, v)
                end
            end
        end
    end
    return merchants
end

local function getOrCreateBillboard(merchant)
    local headPart = merchant:FindFirstChild("Head")
        or merchant:FindFirstChild("HumanoidRootPart")
        or merchant:FindFirstChildWhichIsA("BasePart")
    if not headPart then return end

    local bb = headPart:FindFirstChild("_MerchantBB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "_MerchantBB"
        bb.Size = UDim2.new(0, 120, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Parent = headPart

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = bb
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = bg
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Color = Color3.fromRGB(255, 215, 0)
        bgStroke.Thickness = 1.2
        bgStroke.Parent = bg

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -8, 0.5, 0)
        titleLbl.Position = UDim2.new(0, 4, 0, 2)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "🛒 Merchant"
        titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Center
        titleLbl.Parent = bg

        local distLbl = Instance.new("TextLabel")
        distLbl.Name = "Distance"
        distLbl.Size = UDim2.new(1, -8, 0.5, -2)
        distLbl.Position = UDim2.new(0, 4, 0.5, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "... studs"
        distLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Center
        distLbl.Parent = bg
    end
    return bb
end

local function createHighlight(model)
    if not model:IsA("Model") then return nil end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    return highlight
end

-- Merchant ESP + Billboard label update loop
task.spawn(function()
    local cleanedUp = true
    while IsRunning do
        if features.MerchantESP then
            cleanedUp = false
            local merchants = getMerchants()
            local activeHighlights = {}

            for _, merchant in ipairs(merchants) do
                local existingHighlight = merchant:FindFirstChild("Highlight")
                if existingHighlight then
                    table.insert(activeHighlights, existingHighlight)
                else
                    local newHighlight = createHighlight(merchant)
                    if newHighlight then
                        table.insert(activeHighlights, newHighlight)
                    end
                end

                -- Update billboard distance label
                local bb = getOrCreateBillboard(merchant)
                if bb and hrp then
                    local headPart = bb.Parent
                    if headPart and headPart:IsA("BasePart") then
                        local dist = math.floor((hrp.Position - headPart.Position).Magnitude)
                        local distLbl = bb:FindFirstChild("Frame") and bb.Frame:FindFirstChild("Distance")
                        if distLbl then
                            distLbl.Text = tostring(dist) .. " studs"
                        end
                    end
                end
            end

            -- Remove stale highlights
            for i = #merchantHighlights, 1, -1 do
                local hl = merchantHighlights[i]
                if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
                    pcall(function() if hl then hl:Destroy() end end)
                    table.remove(merchantHighlights, i)
                end
            end
            merchantHighlights = activeHighlights
            task.wait(0.5)
        else
            if not cleanedUp then
                cleanedUp = true
                -- Cleanup highlights
                if #merchantHighlights > 0 then
                    for _, hl in ipairs(merchantHighlights) do
                        pcall(function() if hl then hl:Destroy() end end)
                    end
                    merchantHighlights = {}
                end
                -- Cleanup billboards
                local eitem = workspace:FindFirstChild("EItem")
                if eitem then
                    for _, v in ipairs(eitem:GetDescendants()) do
                        if v.Name == "_MerchantBB" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
end)

--================================================================
-- ENTITY ESP
--================================================================

local function getOrCreateEntityBillboard(entity)
    local headPart = entity:FindFirstChild("Head")
        or entity:FindFirstChild("HumanoidRootPart")
        or entity:FindFirstChildWhichIsA("BasePart")
    if not headPart then return end

    local bb = headPart:FindFirstChild("_EntityBB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "_EntityBB"
        bb.Size = UDim2.new(0, 120, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Parent = headPart

        local bg = Instance.new("Frame")
        bg.Name = "Frame"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
        bg.BackgroundTransparency = 0.3
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
        titleLbl.Text = "💀 " .. entity.Name
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
        distLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Center
        distLbl.Parent = bg
    end
    return bb
end

local function createEntityHighlight(model)
    if not model:IsA("Model") then return nil end
    local highlight = Instance.new("Highlight")
    highlight.Name = "EntityHighlight"
    highlight.Adornee = model
    highlight.FillColor = ThemeColor
    highlight.OutlineColor = ThemeColorDark
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    return highlight
end

task.spawn(function()
    local cleanedUp = true
    while IsRunning do
        if features.EntityESP then
            cleanedUp = false
            local currentEntityFolder = workspace:FindFirstChild("Entity")
            local entities = {}
            if currentEntityFolder then
                for _, v in ipairs(currentEntityFolder:GetChildren()) do
                    if v:IsA("Model") then
                        table.insert(entities, v)
                    end
                end
            end
            local activeEntityHighlights = {}

            for _, entity in ipairs(entities) do
                local existingHighlight = entity:FindFirstChild("EntityHighlight")
                if existingHighlight then
                    table.insert(activeEntityHighlights, existingHighlight)
                else
                    local newHighlight = createEntityHighlight(entity)
                    if newHighlight then
                        table.insert(activeEntityHighlights, newHighlight)
                    end
                end

                -- Update billboard distance label
                local bb = getOrCreateEntityBillboard(entity)
                if bb and hrp and hrp.Parent then
                    local headPart = bb.Parent
                    if headPart and headPart:IsA("BasePart") then
                        local dist = math.floor((hrp.Position - headPart.Position).Magnitude)
                        local frame = bb:FindFirstChild("Frame")
                        local distLbl = frame and frame:FindFirstChild("Distance")
                        if distLbl then
                            distLbl.Text = tostring(dist) .. " studs"
                        end
                    end
                end
            end

            -- Remove stale highlights
            for i = #entityHighlights, 1, -1 do
                local hl = entityHighlights[i]
                if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
                    pcall(function() if hl then hl:Destroy() end end)
                    table.remove(entityHighlights, i)
                end
            end
            entityHighlights = activeEntityHighlights
            task.wait(0.5)
        else
            if not cleanedUp then
                cleanedUp = true
                -- Cleanup highlights
                if #entityHighlights > 0 then
                    for _, hl in ipairs(entityHighlights) do
                        pcall(function() if hl then hl:Destroy() end end)
                    end
                    entityHighlights = {}
                end
                -- Cleanup billboards
                local currentEntityFolder = workspace:FindFirstChild("Entity")
                if currentEntityFolder then
                    for _, v in ipairs(currentEntityFolder:GetDescendants()) do
                        if v.Name == "_EntityBB" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
end)

--================================================================
-- AUTO SELL
--================================================================

task.spawn(function()
    while IsRunning do
        if features.SellAll then
            local args = {
                539767613,
                sellList
            }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
            end)
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

--================================================================
-- AUTO PICKUP
--================================================================

task.spawn(function()
    while IsRunning do
        if features.AutoPickup and hrp then
            local currentLoot = workspace:FindFirstChild("FX") or loot
            if currentLoot then
                for _, touch in ipairs(currentLoot:GetDescendants()) do
                    if not IsRunning or not features.AutoPickup or not hrp then break end
                    if touch:IsA("TouchTransmitter") then
                        local part = touch.Parent
                        if part and part:IsA("BasePart") and hrp and hrp.Parent then
                            pcall(function()
                                firetouchinterest(hrp, part, 0)
                                firetouchinterest(hrp, part, 1)
                            end)
                        end
                    end
                end
            end
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- AUTO FARM + KILL AURA
--================================================================

task.spawn(function()
    while IsRunning do
        if features.AutoFarm and hrp then
            if killAuraToggle then
                killAuraToggle.Set(true)
            end

            if currentTarget then
                local hum = currentTarget:FindFirstChild("Humanoid")
                local hrp2 = currentTarget:FindFirstChild("HumanoidRootPart")

                if not hum or hum.Health <= 0 or not hrp2 then
                    currentTarget = nil
                end
            end

            if not currentTarget then
                local entities = Entity(math.huge) -- No limit for Auto Farm range!

                local closest = nil
                local shortest = math.huge

                for _, v in ipairs(entities) do
                    local targetHRP = v:FindFirstChild("HumanoidRootPart")
                    local targetHum = v:FindFirstChild("Humanoid")

                    if targetHRP and targetHum and targetHum.Health > 0 then
                        local dist = (hrp.Position - targetHRP.Position).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = v
                        end
                    end
                end

                currentTarget = closest
            end

            if currentTarget then
                local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    hrp.CFrame = targetHRP.CFrame * farmOffset
                end
            end
            task.wait()
        else
            currentTarget = nil
            task.wait(0.2)
        end
    end
end)

--================================================================
-- COVER PLAYER
--================================================================

task.spawn(function()
    while IsRunning do
        if features.Cover and hrp and selectedPlayerName then
            local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character then
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    hrp.CFrame = targetHRP.CFrame * farmOffset
                end
            end
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- KILL AURA EXECUTION
--================================================================

local function fireKillAuraEvent(target)
    local currentEvent = getEvent()
    if not currentEvent or not target then return end
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    -- Option A: Serangan di antara player dan target (2 stud lebih dekat ke player) menghadap ke target
    local cf = targetHRP.CFrame
    if hrp then
        local diff = targetHRP.Position - hrp.Position
        local direction = diff.Magnitude > 0.1 and diff.Unit or Vector3.new(0, 0, -1)
        cf = CFrame.lookAt(targetHRP.Position - direction * 2, targetHRP.Position)
    end

    if cachedArg1 then
        if cachedArg1 == 102 then
            -- Bow (102) targets the "Collision" part inside the enemy model
            local hitTarget = target:FindFirstChild("Collision") or targetHRP or target
            currentEvent:FireServer(102, "Atk", hitTarget, {})
        else
            -- Sword (101) & Staff (103) require CFrame
            currentEvent:FireServer(cachedArg1, "Enter", cf, 1)
        end
    else
        -- If cachedArg1 is nil, fire default skills for all known weapons
        local hitTarget = target:FindFirstChild("Collision") or targetHRP or target
        currentEvent:FireServer(101, "Enter", cf, 1)
        currentEvent:FireServer(103, "Enter", cf, 1)
        currentEvent:FireServer(102, "Atk", hitTarget, {})
    end
end

task.spawn(function()
    while IsRunning do
        if features.KillAura and hrp then
            if currentTarget then
                local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                local targetHum = currentTarget:FindFirstChild("Humanoid")

                if targetHRP and targetHum and targetHum.Health > 0 then
                    for i = 1, damageMultiplier do
                        fireKillAuraEvent(currentTarget)
                    end
                end
            else
                local currentRange = killAuraRange
                if features.InfiniteRange then
                    currentRange = math.huge
                end
                local entities = Entity(currentRange)
                
                -- Sort entities by distance to player (closest first)
                table.sort(entities, function(a, b)
                    local aHRP = a:FindFirstChild("HumanoidRootPart")
                    local bHRP = b:FindFirstChild("HumanoidRootPart")
                    if aHRP and bHRP then
                        return (hrp.Position - aHRP.Position).Magnitude < (hrp.Position - bHRP.Position).Magnitude
                    end
                    return false
                end)

                -- Attack up to 10 closest entities
                local attackCount = 0
                for _, v in ipairs(entities) do
                    if attackCount >= 10 then break end
                    local targetHRP = v:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        attackCount = attackCount + 1
                        for i = 1, damageMultiplier do
                            fireKillAuraEvent(v)
                        end
                    end
                end
            end
            task.wait(0.05)
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- STATS UPDATE
--================================================================

local frameTimer = tick()
local frameCounter = 0
local fps = 60

local fpsConnection
fpsConnection = RunService.RenderStepped:Connect(function()
    if not IsRunning then
        if fpsConnection then
            fpsConnection:Disconnect()
        end
        return
    end
    frameCounter = frameCounter + 1
    if (tick() - frameTimer) >= 1 then
        fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
        if fpsCtrl then
            fpsCtrl:SetText(tostring(fps))
        end
    end
end)

print("✅ Angels - Cursed Blade LOADED!")
print("🎮 Press G to toggle UI | Drag from title bar")
print("⚔️ Kill Aura | 🚜 Auto Farm | 🛡️ Cover Player | 💰 Auto Pickup")
