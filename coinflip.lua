--// CoinFlip Auto Script
--// Auto Flip with 0.1s delay

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua"))()

local Window = Library.new("CoinFlip Auto")

local mainPage = Window:CreatePage("Main")
local settingsPage = Window:CreatePage("Settings")

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Variables
local IsRunning = true
local AutoFlip = false
local AutoUpgrade = false
local AutoRebirth = false

--// Upgrade list in order
local Upgrades = {
    "FlipSpeed",
    "CoinMultiplier",
    "HeadsChance",
    "CritChance",
    "LuckyFlip",
    "StreakPower"
}

--// Get RemoteEvents
local CoinFlipRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CoinFlipResult")
local PurchaseUpgradeRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PurchaseUpgrade")
local RebirthRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RebirthRequested")

--// Auto Flip Toggle
mainPage:CreateToggle("Auto Flip", false, function(value)
    AutoFlip = value
    Window:Notify("Auto Flip", value and "Enabled" or "Disabled", 2)
end)

--// Auto Upgrade Toggle
mainPage:CreateToggle("Auto Upgrade", false, function(value)
    AutoUpgrade = value
    Window:Notify("Auto Upgrade", value and "Enabled" or "Disabled", 2)
end)

--// Auto Rebirth Toggle
mainPage:CreateToggle("Auto Rebirth", false, function(value)
    AutoRebirth = value
    Window:Notify("Auto Rebirth", value and "Enabled" or "Disabled", 2)
end)

--// Auto Flip Loop (Heartbeat-based)
local FlipDelay = 0.1
local LastFlipTime = 0

task.spawn(function()
    RunService.Heartbeat:Connect(function(deltaTime)
        if IsRunning and AutoFlip then
            LastFlipTime = LastFlipTime + deltaTime
            if LastFlipTime >= FlipDelay then
                pcall(function()
                    CoinFlipRemote:FireServer()
                end)
                LastFlipTime = 0
            end
        end
    end)
end)

--// Auto Upgrade Loop
task.spawn(function()
    while IsRunning do
        if AutoUpgrade then
            for _, upgradeName in ipairs(Upgrades) do
                if not IsRunning or not AutoUpgrade then
                    break
                end
                pcall(function()
                    local args = {
                        upgradeName,
                        "max"
                    }
                    PurchaseUpgradeRemote:InvokeServer(unpack(args))
                end)
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

--// Auto Rebirth Loop (Heartbeat-based)
local RebirthDelay = 1
local LastRebirthTime = 0

task.spawn(function()
    RunService.Heartbeat:Connect(function(deltaTime)
        if IsRunning and AutoRebirth then
            LastRebirthTime = LastRebirthTime + deltaTime
            if LastRebirthTime >= RebirthDelay then
                pcall(function()
                    RebirthRemote:InvokeServer()
                end)
                LastRebirthTime = 0
            end
        end
    end)
end)

--// Settings Page - Destroy GUI Button
settingsPage:CreateButton("Destroy GUI", function()
    --// Stop all running features
    IsRunning = false
    AutoFlip = false
    AutoUpgrade = false
    AutoRebirth = false

    --// Destroy the GUI
    Window:Destroy()
end)
