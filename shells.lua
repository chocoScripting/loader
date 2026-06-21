local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua"
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

--// =============================================================================
--// AUTO DIG FEATURE LOGIC & UI INITIALIZATION
--// =============================================================================

-- Global Settings Variables
local autoDigEnabled = false
local autoTriggerDig = true -- automatically click screen to start digging when idle
local digTriggerInterval = 0.5 -- spam click delay (seconds) when QTE is not visible
local clickTolerance = 7.0 -- base tolerance in degrees for matching
local clickMethod = "Virtual Click" -- default: Virtual Click (VIM)
local clickCooldown = 0.1 -- default cooldown in seconds
local pauseWhileChatting = true -- default: pause click simulation while typing
local debugEnabled = false
local playerDetectionEnabled = false
local playerDetectionDistance = 30
local perfectChance = 100
local imperfectOffset = 25

-- Runtime States
local Window = nil
local savedCFrame = nil
local selectedMerchant = nil
local loopConnection = nil
local childAddedConnection = nil
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local notificationsMain = nil
local autoFarmCtrl = nil

task.spawn(function()
	pcall(function()
		local notifications = playerGui:WaitForChild("Notifications", 5)
		if notifications then
			notificationsMain = notifications:WaitForChild("Main", 5)
		end
	end)
end)

-- UI Element Controls
local labelStatusCtrl
local labelTargetCtrl
local labelCurrentCtrl
local inventoryLabelCtrl

-- Helper: Normalize rotation to range [0, 360)
local function normalizeRotation(r)
	r = r % 360
	if r < 0 then
		r = r + 360
	end
	return r
end

-- Helper: Get shortest angular difference between two rotations on a circle
local function getAngularDifference(r1, r2)
	r1 = normalizeRotation(r1)
	r2 = normalizeRotation(r2)
	local diff = math.abs(r1 - r2)
	return diff > 180 and 360 - diff or diff
end

-- Helper: Find active QTE UI components safely (Targeting QTE_NEW structure)
local function getQTEObjects()
	local qte = playerGui:FindFirstChild("QTE_NEW")
	if not qte then return nil end
	local minigame = qte:FindFirstChild("Minigame")
	if not minigame or not minigame.Visible then return nil end
	local main = minigame:FindFirstChild("Main")
	if not main or not main.Visible then return nil end
	local bars = main:FindFirstChild("Bars")
	local lineFolder = main:FindFirstChild("Line")
	local line = lineFolder and lineFolder:FindFirstChild("Line")
	if not (bars and line and line.Visible) then return nil end
	return qte, main, bars, line
end

-- Helper: Find the child of Bars that is visible and inherits from GuiObject
local function getActiveBar(bars)
	for _, child in ipairs(bars:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			return child
		end
	end
	return nil
end

-- Helper: Simulate a Mouse Click at a safe screen location using VirtualInputManager
local function virtualClick()
	local vim = game:GetService("VirtualInputManager")
	local camera = workspace.CurrentCamera
	local x = camera and camera.ViewportSize.X / 2 or 500
	-- Offset Y by -100 pixels to click above the center to avoid hitting the GUI window
	local y = camera and (camera.ViewportSize.Y / 2) - 100 or 400
	
	vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
	task.wait(0.01)
	vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- Helper: Simulate pressing the Spacebar using VirtualInputManager
local function pressSpace()
	local vim = game:GetService("VirtualInputManager")
	vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	task.wait(0.01)
	vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- Helper: Simulate pressing a key using VirtualInputManager
local function pressKey(keyCode)
	local vim = game:GetService("VirtualInputManager")
	vim:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.01)
	vim:SendKeyEvent(false, keyCode, false, game)
end

-- Helper: Use exploit firesignal to click GUI button silently (keeps chat focus intact)
local function firesignalClick(qte)
	local clicked = false
	local function search(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("GuiButton") and child.Visible then
				if firesignal then
					firesignal(child.MouseButton1Down)
					firesignal(child.MouseButton1Click)
					firesignal(child.MouseButton1Up)
					clicked = true
				end
			end
			search(child)
		end
	end
	search(qte)
	
	-- Fallback to Virtual Click if no Button object is found in QTE
	if not clicked then
		virtualClick()
	end
end

-- Core Auto Farm Loop Function
local function startAutoDigLoop()
	if loopConnection then return end
	
	local trackedBar = nil
	local lastTargetRot = nil
	local hasClickedThisBar = false
	local lastClickTime = 0
	local lastDigTriggerTime = 0
	local qteEndedTime = 0
	local isPerfectHit = true
	local currentBarOffset = 0
	
	local lastLineRotation = nil
	local lastRotationChangeTime = 0
	local previousLineRotation = nil
	
	-- Helper to check if the QTE needle is actively rotating
	local function isQTEActive(line)
		if not line then 
			lastLineRotation = nil
			return false 
		end
		
		local currentRot = line.AbsoluteRotation
		local now = os.clock()
		
		if lastLineRotation == nil or currentRot ~= lastLineRotation then
			lastLineRotation = currentRot
			lastRotationChangeTime = now
			return true
		end
		
		return (now - lastRotationChangeTime) <= 0.15
	end

	-- Listen to child addition inside PlayerGui.Notifications.Main
	if notificationsMain then
		childAddedConnection = notificationsMain.ChildAdded:Connect(function(child)
			if not autoDigEnabled then return end
			
			if debugEnabled then
				print("[Auto Farm] Notification child added: " .. tostring(child.Name) .. " -> Resetting QTE and waiting 1.0s delay")
			end
			
			-- QTE Completed! Reset states and start delay
			trackedBar = nil
			lastTargetRot = nil
			hasClickedThisBar = false
			qteEndedTime = os.clock()
			
			-- Immediately perform a click after 1.0 second delay to start the next dig
			task.spawn(function()
				task.wait(1.0)
				if autoDigEnabled and not trackedBar then
					if clickMethod == "Space Key" then
						pressSpace()
					else
						virtualClick()
					end
				end
			end)
		end)
	end

	loopConnection = RunService.RenderStepped:Connect(function()
		if not autoDigEnabled then return end

		-- Check if player is typing in chat (if settings request pausing)
		if pauseWhileChatting and UserInputService:GetFocusedTextBox() then
			return
		end

		local qte, main, bars, line = getQTEObjects()
		local active = isQTEActive(line)
		
		-- If the QTE is inactive (needle stopped rotating), reset tracking
		if not active then
			if trackedBar then
				if debugEnabled then
					print("[Auto Farm] QTE needle is static. Resetting QTE state.")
				end
				trackedBar = nil
				lastTargetRot = nil
				hasClickedThisBar = false
				qteEndedTime = os.clock()
			end
		else
			-- If QTE is active, dynamically track the currently visible bar
			if qte and main and main.Visible and bars then
				local activeBar = getActiveBar(bars)
				if activeBar then
					if activeBar ~= trackedBar then
						trackedBar = activeBar
						hasClickedThisBar = false
						
						-- Determine if this hit should be Perfect or Imperfect
						isPerfectHit = (math.random(1, 100) <= perfectChance)
						if isPerfectHit then
							currentBarOffset = 0
						else
							-- Shift the target by the fixed offset (randomly left or right)
							local direction = (math.random(0, 1) == 0) and 1 or -1
							currentBarOffset = direction * imperfectOffset
						end
						
						if debugEnabled then
							print(string.format("[Auto Farm] Active bar changed: %s | Perfect: %s | Offset: %d", tostring(trackedBar.Name), tostring(isPerfectHit), currentBarOffset))
						end
					end
				else
					trackedBar = nil
				end
			else
				trackedBar = nil
			end
		end
		
		if trackedBar then
			-- Rotation 0 of Line is vertical (12 o'clock), Rotation 0 of Bars is horizontal (3 o'clock).
			-- Thus, their alignment offset is exactly 90 degrees.
			local targetRot = (trackedBar.AbsoluteRotation + 90 + currentBarOffset) % 360
			local currentRot = line.AbsoluteRotation
			
			-- If the bar position changes, reset the click flag for the new target
			if targetRot ~= lastTargetRot then
				lastTargetRot = targetRot
				hasClickedThisBar = false
			end
			
			local step = 0
			local crossed = false
			local isMovingTowards = true
			if previousLineRotation then
				local A = previousLineRotation
				local B = currentRot
				local T = targetRot
				
				step = getAngularDifference(B, A)
				
				-- Check direction and crossing
				local delta = B - A
				if delta > 180 then
					delta = delta - 360
				elseif delta < -180 then
					delta = delta + 360
				end
				
				local T_shifted = (T - A) % 360
				if delta > 0 then
					-- Clockwise movement
					if T_shifted <= delta then
						crossed = true
					end
				else
					-- Counter-clockwise movement
					if T_shifted >= (360 + delta) then
						crossed = true
					end
				end
				
				-- Check if moving towards target
				local currentDiff = getAngularDifference(B, T)
				local previousDiff = getAngularDifference(A, T)
				isMovingTowards = currentDiff < previousDiff
			end
			
			local currentDiff = getAngularDifference(currentRot, targetRot)
			local dynamicTolerance = math.max(clickTolerance, step * 1.35)
			
			-- Click if crossed, within predictive dynamic tolerance, or within base tolerance
			if not hasClickedThisBar then
				local shouldClick = crossed 
					or (currentDiff <= dynamicTolerance and isMovingTowards) 
					or (currentDiff <= clickTolerance)
					
				if shouldClick then
					local now = os.clock()
					if now - lastClickTime >= clickCooldown then
						hasClickedThisBar = true
						lastClickTime = now
						
						if debugEnabled then
							print(string.format("[Auto Farm] MATCH! Line: %.2f | Target: %.2f | Diff: %.2f | Crossed: %s | DynTol: %.2f", currentRot, targetRot, currentDiff, tostring(crossed), dynamicTolerance))
						end
						
						-- Trigger the click asynchronously
						task.spawn(function()
							if clickMethod == "Firesignal" then
								firesignalClick(qte)
							elseif clickMethod == "Space Key" then
								pressSpace()
							else
								virtualClick()
							end
						end)
					end
				end
			end
			
			previousLineRotation = currentRot
		else
			-- Idle Mode: Spam click to trigger digging (delay of 0.5s)
			local now = os.clock()
			if now - qteEndedTime >= 1.0 then
				if now - lastDigTriggerTime >= digTriggerInterval then
					lastDigTriggerTime = now
					task.spawn(function()
						if clickMethod == "Space Key" then
							pressSpace()
						else
							virtualClick()
						end
					end)
				end
			end
			previousLineRotation = nil
		end
	end)
end

local function stopAutoDigLoop()
	if loopConnection then
		loopConnection:Disconnect()
		loopConnection = nil
	end
	if childAddedConnection then
		childAddedConnection:Disconnect()
		childAddedConnection = nil
	end
end

--// Teleport Feature Helper Functions
local function getInventoryText()
	local pGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not pGui then return nil end
	
	-- Path 1: ShellsNew_Inventory path
	local txtObj = pGui:FindFirstChild("ShellsNew_Inventory")
		and pGui.ShellsNew_Inventory:FindFirstChild("Inventory")
		and pGui.ShellsNew_Inventory.Inventory:FindFirstChild("Fill")
		and pGui.ShellsNew_Inventory.Inventory.Fill:FindFirstChild("Header")
		and pGui.ShellsNew_Inventory.Inventory.Fill.Header:FindFirstChild("Txt")
	if txtObj then
		local text = txtObj.ContentText or txtObj.Text
		if text and text ~= "" then return text end
	end
	
	-- Path 2: BackpackGui path
	local backpackGui = pGui:FindFirstChild("BackpackGui")
	local backpack = backpackGui and backpackGui:FindFirstChild("Backpack")
	local inventory = backpack and backpack:FindFirstChild("Inventory")
	local limit = inventory and inventory:FindFirstChild("Limit")
	local textLabel = limit and limit:FindFirstChild("TextLabel")
	if textLabel then
		local text = textLabel.ContentText or textLabel.Text
		if text and text ~= "" then return text end
	end
	
	return nil
end

local function scanMerchants()
	local list = {}
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local playerPos = root and root.Position or Vector3.new(0, 0, 0)
	
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, zone in ipairs(map:GetChildren()) do
			local npcs = zone:FindFirstChild("NPCs")
			if npcs then
				for _, child in ipairs(npcs:GetChildren()) do
					if string.find(string.lower(child.Name), "merchant") then
						local part = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart or child:FindFirstChildOfClass("BasePart")
						if part then
							local distance = math.round((playerPos - part.Position).Magnitude)
							local displayName = string.format("%s - %s [%d Studs]", zone.Name, child.Name, distance)
							table.insert(list, {
								Name = displayName,
								Value = child
							})
						end
					end
				end
			end
		end
	end
	
	-- Fallback global workspace scan if structured map scan fails
	if #list == 0 then
		for _, child in ipairs(workspace:GetDescendants()) do
			if child:IsA("Model") and string.find(string.lower(child.Name), "merchant") then
				local part = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart or child:FindFirstChildOfClass("BasePart")
				if part then
					local distance = math.round((playerPos - part.Position).Magnitude)
					local displayName = string.format("%s [%d Studs]", child.Name, distance)
					table.insert(list, {
						Name = displayName,
						Value = child
					})
				end
			end
		end
	end
	
	return list
end

local function teleportToClosestMerchant()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local merchants = scanMerchants()
	if #merchants == 0 then
		if Window then
			Window:Notify("Teleport Error", "No merchants found in game!", 3)
		end
		return
	end
	
	local closestMerchant = nil
	local minDistance = math.huge
	
	for _, m in ipairs(merchants) do
		local part = m.Value:FindFirstChild("HumanoidRootPart") or m.Value.PrimaryPart or m.Value:FindFirstChildOfClass("BasePart")
		if part then
			local dist = (root.Position - part.Position).Magnitude
			if dist < minDistance then
				minDistance = dist
				closestMerchant = m.Value
			end
		end
	end
	
	if not closestMerchant then
		if Window then
			Window:Notify("Teleport Error", "No valid merchant model found!", 3)
		end
		return
	end
	
	-- Save current position before teleporting
	savedCFrame = root.CFrame
	
	-- Teleport slightly in front of the closest merchant
	local merchantPart = closestMerchant:FindFirstChild("HumanoidRootPart") or closestMerchant.PrimaryPart or closestMerchant:FindFirstChildOfClass("BasePart")
	root.CFrame = merchantPart.CFrame * CFrame.new(0, 0, 4)
	if Window then
		Window:Notify("Teleport", "Teleported to closest merchant! Position saved.", 3)
	end
end

local function teleportToMerchant()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	if not selectedMerchant then
		if Window then
			Window:Notify("Teleport Error", "Please select a merchant from the dropdown first!", 3)
		end
		return
	end
	
	local merchantPart = selectedMerchant:FindFirstChild("HumanoidRootPart") or selectedMerchant.PrimaryPart or selectedMerchant:FindFirstChildOfClass("BasePart")
	if not merchantPart then
		if Window then
			Window:Notify("Teleport Error", "Merchant part not found!", 3)
		end
		return
	end
	
	-- Save current position before teleporting
	savedCFrame = root.CFrame
	
	-- Teleport slightly in front of the merchant
	root.CFrame = merchantPart.CFrame * CFrame.new(0, 0, 4)
	if Window then
		Window:Notify("Teleport", "Teleported to merchant! Position saved.", 3)
	end
end

local function teleportBack()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	if not savedCFrame then
		if Window then
			Window:Notify("Teleport Error", "No saved position found! Teleport to a merchant first.", 3)
		end
		return
	end
	
	root.CFrame = savedCFrame
	if Window then
		Window:Notify("Teleport", "Returned to original position!", 3)
	end
end

-- Helper: Scan for nearby players and auto-disable farming if needed
local function checkNearbyPlayers()
	if not playerDetectionEnabled then return end
	if not autoDigEnabled then return end
	
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local pRoot = char and char:FindFirstChild("HumanoidRootPart")
			if pRoot then
				local dist = (root.Position - pRoot.Position).Magnitude
				if dist <= playerDetectionDistance then
					-- Player detected! Force toggle off Auto Farm
					autoDigEnabled = false
					stopAutoDigLoop()
					if autoFarmCtrl then
						autoFarmCtrl:SetState(false)
					end
					if Window then
						Window:Notify("Security Alarm", string.format("Player '%s' detected within %.1f studs! Stopped farming.", player.DisplayName or player.Name, dist), 5)
					end
					break
				end
			end
		end
	end
end

-- Initialize GUI Window and Tabs
local function InitUI()
	Window = Library.new("🐚 SHELLS AUTO FARM")
	Window:Notify("Loaded", "Shells Auto Farm Script Loaded! Press G to hide UI.", 4)

	-- 1. Create Tabs
	local mainPage = Window:CreatePage("Auto Farm")
	local teleportPage = Window:CreatePage("Teleport")
	local settingsPage = Window:CreatePage("Settings")

	-- 2. "Auto Farm" Page Elements
	local _, farmCtrl = mainPage:CreateToggle("Auto Farm", false, function(state)
		autoDigEnabled = state
		if state then
			-- Immediately perform a click to trigger/start digging
			task.spawn(function()
				task.wait(0.1) -- short delay to let toggle state register cleanly
				if clickMethod == "Space Key" then
					pressSpace()
				else
					virtualClick()
				end
			end)
			startAutoDigLoop()
			Window:Notify("Enabled", "Auto Farm is now ACTIVE.", 2)
		else
			stopAutoDigLoop()
			Window:Notify("Disabled", "Auto Farm is now INACTIVE.", 2)
		end
	end)
	autoFarmCtrl = farmCtrl

	-- Click Method Dropdown
	mainPage:CreateDropdown("Click Method", "Virtual Click", function()
		return {
			{Name = "Virtual Click", Value = "Virtual Click"},
			{Name = "Firesignal (Silent/No Chat Break)", Value = "Firesignal"},
			{Name = "Space Key", Value = "Space Key"}
		}
	end, function(value)
		clickMethod = value
		Window:Notify("Settings Update", "Method set to: " .. value, 2)
	end)

	-- Inventory Storage Label
	local _, invCtrl = mainPage:CreateLabel("Inventory Storage", "Storage: N/A")
	inventoryLabelCtrl = invCtrl

	-- Perfect Click Chance textbox
	mainPage:CreateTextBox("Perfect Click Chance (%)", "0 to 100...", 100, function(val)
		local num = tonumber(val)
		if num then
			perfectChance = math.clamp(math.round(num), 0, 100)
			Window:Notify("Settings Update", "Perfect Chance set to: " .. tostring(perfectChance) .. "%", 2)
		end
	end)

	-- Imperfect Offset (degrees)
	mainPage:CreateTextBox("Imperfect Offset (°)", "Degrees...", 25, function(val)
		local num = tonumber(val)
		if num then
			imperfectOffset = math.max(1, math.round(num))
			Window:Notify("Settings Update", "Imperfect Offset set to: " .. tostring(imperfectOffset) .. "°", 2)
		end
	end)

	-- Player Detection Toggle & Distance Config
	mainPage:CreateToggle("Player Detection", false, function(state)
		playerDetectionEnabled = state
		Window:Notify("Settings Update", "Player Detection: " .. tostring(state), 2)
	end)

	mainPage:CreateTextBox("Detection Distance (Studs)", "Distance...", 30, function(val)
		local num = tonumber(val)
		if num then
			playerDetectionDistance = num
			Window:Notify("Settings Update", "Detection Distance set to: " .. tostring(num) .. " studs", 2)
		end
	end)

	-- 3. "Teleport" Page Elements
	teleportPage:CreateButton("Teleport to Closest Merchant", function()
		teleportToClosestMerchant()
	end)

	teleportPage:CreateDropdown("Select Merchant", "Choose Merchant...", function()
		return scanMerchants()
	end, function(value)
		selectedMerchant = value
		Window:Notify("Selection", "Selected merchant for teleportation.", 2)
	end)

	teleportPage:CreateButton("Teleport to Merchant", function()
		teleportToMerchant()
	end)

	teleportPage:CreateButton("Teleport Back", function()
		teleportBack()
	end)

	-- 4. "Settings" Page Elements
	settingsPage:CreateToggle("Pause While Chatting", true, function(state)
		pauseWhileChatting = state
		Window:Notify("Settings Update", "Pause while chatting: " .. tostring(state), 2)
	end)

	settingsPage:CreateToggle("Console Debug Output", false, function(state)
		debugEnabled = state
		Window:Notify("Settings Update", "Debug mode: " .. tostring(state), 2)
	end)

	settingsPage:CreateTextBox("Click Cooldown", "Seconds...", 0.1, function(val)
		local num = tonumber(val)
		if num then
			clickCooldown = num
			Window:Notify("Settings Update", "Cooldown set to " .. tostring(num) .. "s", 2)
		end
	end)

	settingsPage:CreateButton("Destroy UI", function()
		stopAutoDigLoop()
		Window:Destroy()
	end)
	
	-- Start background task to update Inventory Label
	task.spawn(function()
		while true do
			task.wait(1)
			if not Window or not Window.ScreenGui or not Window.ScreenGui.Parent then
				break
			end
			if inventoryLabelCtrl then
				local invText = getInventoryText()
				if invText then
					inventoryLabelCtrl:SetText(invText)
				else
					inventoryLabelCtrl:SetText("N/A")
				end
			end
		end
	end)

	-- Start background task to detect nearby players
	task.spawn(function()
		while true do
			task.wait(0.2)
			if not Window or not Window.ScreenGui or not Window.ScreenGui.Parent then
				break
			end
			if playerDetectionEnabled and autoDigEnabled then
				pcall(checkNearbyPlayers)
			end
		end
	end)
end

-- Launch the GUI
InitUI()
