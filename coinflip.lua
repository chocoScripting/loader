--// CoinFlip Auto Script
--// Auto Flip with 0.1s delay

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua"))()

local Window = Library.new("CoinFlip Auto")

local mainPage = Window:CreatePage("Main")
local settingsPage = Window:CreatePage("Settings")

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local IsRunning = true
local AutoFlip = false
local AutoUpgrade = false

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

--// Auto Flip Loop
task.spawn(function()
    while IsRunning do
        if AutoFlip then
            pcall(function()
                CoinFlipRemote:FireServer()
            end)
        end
        task.wait(0.1)
    end
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

--// Settings Page - Destroy GUI Button
settingsPage:CreateButton("Destroy GUI", function()
    --// Stop all running features
    IsRunning = false
    AutoFlip = false
    AutoUpgrade = false

    --// Destroy the GUI
    Window:Destroy()
end)
