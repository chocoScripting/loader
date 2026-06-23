-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- RESOLVE PARENT GUI (CoreGui or PlayerGui)
local parentGui = (function()
	local success, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if success and coreGui then
		return coreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end)()

--================================================================
-- RAINBOW CONTROLLER SYSTEM
--================================================================
local rainbowGradients = {}

local function makeRainbow(strokeOrGradient)
	local gradient
	if strokeOrGradient:IsA("UIStroke") then
		gradient = Instance.new("UIGradient")
		gradient.Parent = strokeOrGradient
	elseif strokeOrGradient:IsA("UIGradient") then
		gradient = strokeOrGradient
	end
	
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		table.insert(rainbowGradients, gradient)
	end
	return gradient
end

local rotConnection = RunService.RenderStepped:Connect(function()
	local rot = (tick() * 120) % 360
	for i = #rainbowGradients, 1, -1 do
		local g = rainbowGradients[i]
		if g and g.Parent then
			g.Rotation = rot
		else
			table.remove(rainbowGradients, i)
		end
	end
end)

--================================================================
-- CREATE NOTIFICATION GUI
--================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChocoLoaderUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "Notifications"
notificationContainer.Size = UDim2.new(0, 280, 1, -20)
notificationContainer.Position = UDim2.new(1, -290, 0, 10)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

local notifList = Instance.new("UIListLayout")
notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifList.Padding = UDim.new(0, 10)
notifList.Parent = notificationContainer

local function notify(title, text, duration)
	duration = duration or 3

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(1, 0, 0, 55)
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notificationContainer

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notifFrame

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = Color3.fromRGB(255, 255, 255)
	notifStroke.Thickness = 1.2
	notifStroke.Transparency = 0.2
	notifStroke.Parent = notifFrame
	
	makeRainbow(notifStroke)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notifFrame
	
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Parent = titleLabel
	makeRainbow(titleGradient)

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 25)
	descLabel.Position = UDim2.new(0, 10, 0, 23)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = text
	descLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	descLabel.Font = Enum.Font.GothamMedium
	descLabel.TextSize = 11
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = notifFrame

	-- Tween In
	notifFrame.Position = UDim2.new(1, 300, 0, 0)
	notifFrame:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)

	task.delay(duration, function()
		pcall(function()
			if not screenGui or not screenGui.Parent then return end
			notifFrame:TweenPosition(UDim2.new(1, 300, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.2, true, function()
				pcall(function()
					notifFrame:Destroy()
				end)
			end)
		end)
	end)
end

--================================================================
-- SCRIPT REGISTRY & LOADER LOGIC
--================================================================

local scriptList = {
	[135887679143452] = { -- Larping (Excuse me sir)
		Name = "Larping",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/larp.lua"
	},
	[112107733863518] = { -- Cursed Blade
		Name = "Cursed Blade",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/cblade.lua"
	},
	[76864623342260] = { -- Cursed Blade
		Name = "Cursed Blade",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/cblade.lua"
	},
	[79268393072444] = { -- Sell Lemons
		Name = "Sell Lemons",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/lemon.lua"
	},
	[11276071411] = { -- NPC or Die
		Name = "NPC or Die",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/nod.lua"
	},
	[119048529960596] = { -- Restaurant Tycoon 3
		Name = "Restaurant Tycoon 3",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/rt3.lua"
	},
	[15308782509] = { -- Football Training
		Name = "Football Training",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/football.lua"
	},
	[111896378748580] = { -- Shells
		Name = "Shells",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/shells.lua"
	},
	[73814003954154] = { -- Pickaxe Tycoon
		Name = "Pickaxe Tycoon",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/pick.lua"
	},
	[97387256206808] = { -- Broken Blade
		Name = "Broken Blade",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/brokenblade.lua"
	}
}

local placeId = game.PlaceId
local gameScript = scriptList[placeId]

if gameScript then
	print("🎮 [Choco Loader] Detected Game: " .. gameScript.Name .. " (PlaceId: " .. tostring(placeId) .. ")")
	notify("Choco Loader", "Detected Game: " .. gameScript.Name .. "\nLoading script...", 5)
	
	task.spawn(function()
		local success, err = pcall(function()
			loadstring(game:HttpGet(gameScript.Url))()
		end)
		
		if success then
			print("✅ [Choco Loader] " .. gameScript.Name .. " loaded successfully!")
			notify("Success", gameScript.Name .. " loaded successfully!", 5)
		else
			warn("❌ [Choco Loader] Failed to load " .. gameScript.Name .. ": " .. tostring(err))
			notify("Error", "Failed to load " .. gameScript.Name .. ". Check console.", 7)
		end
	end)
else
	local msg = "No script registered for PlaceId: " .. tostring(placeId)
	warn("⚠️ [Choco Loader] " .. msg)
	notify("Choco Loader", msg, 7)
end
