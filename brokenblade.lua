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
local currentPayload        = nil  -- active buffer, nil = not set yet
local autoChomusukeEnabled  = false
local chomusukeToggleCtrl   = nil  -- reference to toggle controller for auto-off

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
    if not currentPayload then return end
    local remoteEvent = ReplicatedStorage:FindFirstChild("Remote_Event")
    if not remoteEvent then return end
    pcall(function()
        remoteEvent:FireServer(currentPayload)
    end)
end

--================================================================
-- GUI SETUP
--================================================================

local Window = Library.new("Broken Blade")

local combatPage   = Window:CreatePage("Combat")
local payloadPage  = Window:CreatePage("Payload")
local settingsPage = Window:CreatePage("Settings")

local function notify(title, text, duration)
    if Window then Window:Notify(title, text, duration) end
end

-- COMBAT PAGE --------------------------------------------------

combatPage:CreateToggle("Kill Aura", false, function(value)
    if value and not currentPayload then
        notify("Kill Aura", "Set a payload in the Payload tab first!", 4)
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

local _, chomusukeCtrl = combatPage:CreateToggle("Auto Chomusuke", false, function(value)
    autoChomusukeEnabled = value
    notify("Auto Chomusuke", value and "Enabled" or "Disabled", 3)
end)
chomusukeToggleCtrl = chomusukeCtrl

-- PAYLOAD PAGE -------------------------------------------------

local payloadInput = ""
local _, payloadBoxCtrl = payloadPage:CreateTextBox("Paste Remote Spy Code", "local args = { buffer.fromstring(...) } ...", "", function(value)
    payloadInput = value
end)

payloadPage:CreateButton("Set Payload", function()
    if payloadInput == "" then
        notify("Error", "Textbox is empty!", 3)
        return
    end

    local buf, err = parsePayload(payloadInput)
    if not buf then
        notify("Parse Failed", err or "Unknown error", 5)
        return
    end

    currentPayload = buf
    if payloadStatus then
        payloadStatus:SetText("Payload active (" .. tostring(buffer.len(buf)) .. " bytes)")
    end
    notify("Payload Set", "Success! " .. tostring(buffer.len(buf)) .. " bytes", 3)
end)

payloadPage:CreateButton("Clear Payload", function()
    currentPayload  = nil
    killAuraEnabled = false
    payloadInput    = ""
    if payloadBoxCtrl then payloadBoxCtrl:SetText("") end
    if payloadStatus then payloadStatus:SetText("Payload not set") end
    notify("Cleared", "Payload cleared", 2)
end)

-- SETTINGS PAGE ------------------------------------------------

local _, fpsCtrl = settingsPage:CreateLabel("FPS", "60")

settingsPage:CreateButton("Destroy GUI", function()
    IsRunning       = false
    killAuraEnabled = false
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
        if killAuraEnabled and currentPayload then
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
                notify("Auto Chomusuke", "Chomusuke folder not found!", 4)
                autoChomusukeEnabled = false
                if chomusukeToggleCtrl then chomusukeToggleCtrl:SetState(false) end
                task.wait(0.2)
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

                -- After a full pass: if zero models had a highlight, auto-disable
                if autoChomusukeEnabled and not foundAny then
                    notify("Auto Chomusuke", "No targets left. Disabling.", 4)
                    autoChomusukeEnabled = false
                    if chomusukeToggleCtrl then chomusukeToggleCtrl:SetState(false) end
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

print("Broken Blade loaded!")
print("Press G to toggle UI | Set a payload in the Payload tab first!")
print("Kill Aura | Damage Multiplier")
