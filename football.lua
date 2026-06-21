local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua"
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Variables
local IsRunning = true
local AutoKick = false
local AutoTrain = false
local AutoHatch = false
local AutoCraft = false
local DisablePopups = false
local GiftboxExploit = false
local AdminChest = false
local kickMultiplier = 1
local trainMultiplier = 50
local hatchMultiplier = 1
local hatchEggName = "Festival Egg"

--// Remotes Cache
local ThrowEvent = nil
local FinishEvent = nil
local TrainEvent = nil
local StopTrainEvent = nil
local ClaimPassEvent = nil
local HatchEggEvent = nil
local CraftEvent = nil
local ClaimGiftEvent = nil
local AdminChestEvent = nil

--// ProximityPrompt Helpers
local function findTrainingPrompt()
	local GameItems = workspace:FindFirstChild("GameItems")
	if not GameItems then return nil end
	local Maps = GameItems:FindFirstChild("Maps")
	if not Maps then return nil end
	
	for _, map in ipairs(Maps:GetChildren()) do
		local TrainingAreas = map:FindFirstChild("TrainingAreas")
		if TrainingAreas then
			local area = TrainingAreas:FindFirstChild("3|12")
			if area then
				local promptPart = area:FindFirstChild("PromptPart")
				if promptPart then
					local prompt = promptPart:FindFirstChild("Prompt") or promptPart:FindFirstChildWhichIsA("ProximityPrompt")
					if prompt then
						return prompt
					end
				end
			end
			
			for _, subArea in ipairs(TrainingAreas:GetChildren()) do
				local promptPart = subArea:FindFirstChild("PromptPart")
				if promptPart then
					local prompt = promptPart:FindFirstChild("Prompt") or promptPart:FindFirstChildWhichIsA("ProximityPrompt")
					if prompt then
						return prompt
					end
				end
			end
		end
	end
	return nil
end

local function triggerTrainingPrompt(prompt)
	if not prompt then return end
	local oldMaxDist = prompt.MaxActivationDistance
	pcall(function()
		prompt.MaxActivationDistance = math.huge
		fireproximityprompt(prompt)
	end)
	task.wait(0.1)
	pcall(function()
		prompt.MaxActivationDistance = oldMaxDist
	end)
end

--// Get Remotes Function
local function getRemotes()
	pcall(function()
		local Library = ReplicatedStorage:FindFirstChild("Library") or ReplicatedStorage:WaitForChild("Library", 2)
		if not Library then return end
		local Knit = Library:FindFirstChild("Knit") or Library:WaitForChild("Knit", 2)
		if not Knit then return end
		local Services = Knit:FindFirstChild("Services") or Knit:WaitForChild("Services", 2)
		if not Services then return end

		-- Throw Service Remotes
		local ThrowService = Services:FindFirstChild("ThrowService") or Services:WaitForChild("ThrowService", 2)
		if ThrowService then
			local RE = ThrowService:FindFirstChild("RE") or ThrowService:WaitForChild("RE", 2)
			if RE then
				ThrowEvent = RE:FindFirstChild("Throw") or RE:FindFirstChild("Throw", 2)
				FinishEvent = RE:FindFirstChild("Finish") or RE:FindFirstChild("Finish", 2)
			end
		end

		-- Training Service Remotes
		local TrainingService = Services:FindFirstChild("TrainingService") or Services:WaitForChild("TrainingService", 2)
		if TrainingService then
			local RE = TrainingService:FindFirstChild("RE") or TrainingService:WaitForChild("RE", 2)
			if RE then
				TrainEvent = RE:FindFirstChild("Train") or RE:FindFirstChild("Train", 2)
				StopTrainEvent = RE:FindFirstChild("Stop") or RE:FindFirstChild("Stop", 2)
			end
		end

		-- Seasonpass Service Remotes
		local SeasonpassService = Services:FindFirstChild("SeasonpassService") or Services:WaitForChild("SeasonpassService", 2)
		if SeasonpassService then
			local RE = SeasonpassService:FindFirstChild("RE") or SeasonpassService:WaitForChild("RE", 2)
			if RE then
				ClaimPassEvent = RE:FindFirstChild("Claim") or RE:WaitForChild("Claim", 2)
			end
		end

		-- Eggs Service Remotes
		local EggsService = Services:FindFirstChild("EggsService") or Services:WaitForChild("EggsService", 2)
		if EggsService then
			local RE = EggsService:FindFirstChild("RE") or EggsService:WaitForChild("RE", 2)
			if RE then
				HatchEggEvent = RE:FindFirstChild("HatchEgg") or RE:FindFirstChild("HatchEgg", 2)
			end
		end

		-- Pets Service Remotes
		local PetsService = Services:FindFirstChild("PetsService") or Services:WaitForChild("PetsService", 2)
		if PetsService then
			local RE = PetsService:FindFirstChild("RE") or PetsService:WaitForChild("RE", 2)
			if RE then
				CraftEvent = RE:FindFirstChild("Craft") or RE:WaitForChild("Craft", 2)
			end
		end

		-- AdminPanel Service Remotes (Giftbox Exploit)
		local AdminPanelService = Services:FindFirstChild("AdminPanelService") or Services:WaitForChild("AdminPanelService", 2)
		if AdminPanelService then
			local RE = AdminPanelService:FindFirstChild("RE") or AdminPanelService:WaitForChild("RE", 2)
			if RE then
				ClaimGiftEvent = RE:FindFirstChild("ClaimGift") or RE:FindFirstChild("ClaimGift", 2)
			end
		end

		-- AdminChest Service Remotes (Admin Chest)
		local AdminChestService = Services:FindFirstChild("AdminChestService") or Services:WaitForChild("AdminChestService", 2)
		if AdminChestService then
			local RE = AdminChestService:FindFirstChild("RE") or AdminChestService:WaitForChild("RE", 2)
			if RE then
				AdminChestEvent = RE:FindFirstChild("Claim") or RE:FindFirstChild("Claim", 2)
			end
		end
	end)
	return ThrowEvent ~= nil and FinishEvent ~= nil, TrainEvent ~= nil, ClaimPassEvent ~= nil, HatchEggEvent ~= nil, CraftEvent ~= nil, StopTrainEvent ~= nil, ClaimGiftEvent ~= nil, AdminChestEvent ~= nil
end

-- Initialize Window
local Window = Library.new("⚽ Football Training")

-- Helper notify function mapping to new library
local function notify(title, text, duration)
	Window:Notify(title, text, duration)
end

-- Create Pages
local trainPage = Window:CreatePage("Training")
local petsPage = Window:CreatePage("Pets & Eggs")
local miscPage = Window:CreatePage("Misc")

-- Build Training Page Controls
trainPage:CreateToggle("Auto Kick", false, function(value)
	AutoKick = value
	notify("Auto Kick", value and "Enabled" or "Disabled", 3)
end)

trainPage:CreateToggle("Auto Train", false, function(value)
	AutoTrain = value
	notify("Auto Train", value and "Enabled" or "Disabled", 3)
	
	if value then
		task.spawn(function()
			local prompt = findTrainingPrompt()
			if prompt then
				triggerTrainingPrompt(prompt)
			else
				notify("Auto Train", "Training prompt not found!", 3)
			end
		end)
	else
		if StopTrainEvent then
			pcall(function()
				StopTrainEvent:FireServer()
			end)
		else
			getRemotes()
			if StopTrainEvent then
				pcall(function()
					StopTrainEvent:FireServer()
				end)
			end
		end
	end
end)

trainPage:CreateTextBox("Kick Mult", "1-100", kickMultiplier, function(value)
	kickMultiplier = value
	notify("Kick Mult Set", "Kick multiplier set to " .. tostring(value), 2)
end)

trainPage:CreateTextBox("Train Mult", "1-100", trainMultiplier, function(value)
	trainMultiplier = value
	notify("Train Mult Set", "Train multiplier set to " .. tostring(value), 2)
end)

-- Build Pets Page Controls
petsPage:CreateToggle("Auto Hatch", false, function(value)
	AutoHatch = value
	notify("Auto Hatch", value and "Enabled" or "Disabled", 3)
end)

petsPage:CreateToggle("Auto Craft", false, function(value)
	AutoCraft = value
	notify("Auto Craft", value and "Enabled" or "Disabled", 3)
end)

petsPage:CreateTextBox("Egg Name", "Egg Name...", hatchEggName, function(value)
	hatchEggName = value
	notify("Egg Set", "Target egg set to: " .. tostring(value), 2)
end)

-- Build Misc Page Controls
miscPage:CreateToggle("Disable Popups", false, function(value)
	DisablePopups = value
	notify("Disable Popups", value and "Enabled" or "Disabled", 3)

	pcall(function()
		local popups = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PopUps")
		if popups then
			popups.Enabled = not value
		end
	end)

	pcall(function()
		local prompts = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Prompts")
		if prompts then
			local window = prompts:FindFirstChild("Window")
			if window then
				window.Visible = not value
			end
		end
	end)
end)

miscPage:CreateToggle("Giftbox Exploit", false, function(value)
	GiftboxExploit = value
	notify("Giftbox Exploit", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateToggle("Admin Chest", false, function(value)
	AdminChest = value
	notify("Admin Chest", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateButton("Claim Season Pass", function()
	task.spawn(function()
		notify("Claiming Pass", "Claiming levels 1 to 15...", 3)
		if ClaimPassEvent then
			for level = 1, 15 do
				if not IsRunning then break end
				pcall(function()
					ClaimPassEvent:FireServer("Free", level)
				end)
				pcall(function()
					ClaimPassEvent:FireServer("Premium", level)
				end)
				task.wait(0.1)
			end
			notify("Claim Complete", "Successfully claimed season pass levels 1-15!", 3)
		else
			getRemotes()
			if ClaimPassEvent then
				for level = 1, 15 do
					if not IsRunning then break end
					pcall(function()
						ClaimPassEvent:FireServer("Free", level)
					end)
					pcall(function()
						ClaimPassEvent:FireServer("Premium", level)
					end)
					task.wait(0.1)
				end
				notify("Claim Complete", "Successfully claimed season pass levels 1-15!", 3)
			else
				notify("Error", "Claim remote not found!", 3)
			end
		end
	end)
end)

miscPage:CreateButton("Destroy GUI", function()
	IsRunning = false
	AutoKick = false
	AutoTrain = false
	AutoHatch = false
	AutoCraft = false
	DisablePopups = false
	GiftboxExploit = false
	AdminChest = false
	
	-- Stop training if UI is destroyed
	if StopTrainEvent then
		pcall(function()
			StopTrainEvent:FireServer()
		end)
	end
	
	pcall(function()
		local popups = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PopUps")
		if popups then
			popups.Enabled = true
		end
	end)
	
	Window:Destroy()
end)

-- Notify loaded
notify("Loaded", "Football Training Script Loaded Successfully", 5)

-- Try to resolve Remotes initially
task.spawn(function()
	getRemotes()
end)

-- Auto Kick loop using Heartbeat for maximum fire rate (fires every frame ~60x/s)
local autoKickConnection
autoKickConnection = RunService.Heartbeat:Connect(function(dt)
	if not IsRunning then
		autoKickConnection:Disconnect()
		return
	end

	if AutoKick then
		if ThrowEvent and FinishEvent then
			for i = 1, kickMultiplier do
				pcall(function()
					ThrowEvent:FireServer()
				end)
			end

			for i = 1, kickMultiplier do
				pcall(function()
					FinishEvent:FireServer()
				end)
			end
		else
			getRemotes()
		end
	end
end)

-- Main loop running Train remote event with multiplier
task.spawn(function()
	while IsRunning do
		task.wait(0.01)
		
		if AutoTrain then
			if TrainEvent then
				for i = 1, trainMultiplier do
					pcall(function()
						TrainEvent:FireServer()
					end)
				end
				
				task.wait(0.05)
			else
				getRemotes()
				task.wait(1)
			end
		end
	end
end)

-- Main loop running Eggs Service HatchEgg
task.spawn(function()
	while IsRunning do
		-- reduced base delay for faster hatch cycles
		task.wait(0.01)
		if AutoHatch then
			if HatchEggEvent then
				for i = 1, hatchMultiplier do
					pcall(function()
						HatchEggEvent:FireServer(hatchEggName, "Triple")
					end)
					-- tiny safety pause between rapid fires
					task.wait(0.001)
				end
			else
				getRemotes()
				task.wait(1)
			end
		end
	end
end)

-- Function to scan current pet list and group matching pets by Name & Type attributes
local function getCraftableGroups()
	local groups = {}
	pcall(function()
		local mainFramePets = LocalPlayer:WaitForChild("PlayerGui", 5)
			:WaitForChild("Main", 2)
			:WaitForChild("Frames", 2)
			:WaitForChild("Pets", 2)
		local list = mainFramePets:WaitForChild("List", 2)
		
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" and child.Name ~= "UIGridLayout" then
				local pName = child:GetAttribute("Name")
				local pType = child:GetAttribute("Type")
				if pName and pType then
					local key = pName .. "_" .. pType
					if not groups[key] then
						groups[key] = {}
					end
					table.insert(groups[key], child.Name) -- child.Name is the ID of the pet
				end
			end
		end
	end)
	return groups
end

-- Main loop running Pets Service Auto Craft
task.spawn(function()
	while IsRunning do
		task.wait(0.1)
		
		if AutoCraft then
			if CraftEvent then
				local groups = getCraftableGroups()
				local craftedAny = false
				for key, ids in pairs(groups) do
					local count = #ids
					if count >= 5 then
						craftedAny = true
						for batch = 1, math.floor(count / 5) do
							if not AutoCraft or not IsRunning then break end
							local idx = (batch - 1) * 5
							local craftArgs = {
								{ ids[idx + 1], ids[idx + 2], ids[idx + 3], ids[idx + 4], ids[idx + 5] }
							}
							
							pcall(function()
								CraftEvent:FireServer(unpack(craftArgs))
							end)
							
							task.wait(0.01) -- Tiny safety delay between remote fires
						end
					end
				end
				if craftedAny then
					task.wait(0.2) -- Give client UI time to sync the updated inventory
				end
			else
				getRemotes()
				task.wait(1)
			end
		end
	end
end)

-- Loop to keep PopUps disabled if option is checked
task.spawn(function()
	while IsRunning do
		task.wait(0.2)
		if DisablePopups then
			pcall(function()
				local popups = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PopUps")
				if popups and popups.Enabled then
					popups.Enabled = false
				end
			end)
		end
	end
end)

-- Loop for Giftbox Exploit
task.spawn(function()
	local args = {
		"d7cf2ce8-fb5c-48f0-ab8c-568a0885b2cd"
	}
	while IsRunning do
		task.wait(0.0001)
		if GiftboxExploit then
			if ClaimGiftEvent then
				for i = 1, 10 do
					pcall(function()
						ClaimGiftEvent:FireServer(unpack(args))
					end)
				end
			else
				getRemotes()
				task.wait(1)
			end
		end
	end
end)

-- Loop for Admin Chest
task.spawn(function()
	while IsRunning do
		task.wait(0.0001)
		if AdminChest then
			if AdminChestEvent then
				pcall(function()
					AdminChestEvent:FireServer()
				end)
			else
				getRemotes()
				task.wait(1)
			end
		end
	end
end)
