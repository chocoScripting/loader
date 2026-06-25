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
local payloadPage  = Window:CreatePage("Payload")
local settingsPage = Window:CreatePage("Settings")

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
