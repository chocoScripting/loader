local GUI_LIBRARY_URL = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/GUI.lua?t=" .. tostring(tick())
local Library = loadstring(game:HttpGet(GUI_LIBRARY_URL))()

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Variables
local IsRunning = true
local AutoCollectOres = false
local SelectedPlot = "Plot_2"
local SelectedButton = nil
local AutoBuy = false
local AutoMerge = false
local AutoDeposit = false
local AutoCollectMoney = false

--// Detect Player Plot initially
local function detectPlayerPlot()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return nil end
	for _, plot in ipairs(plots:GetChildren()) do
		-- Check ObjectValue owner
		local ownerObj = plot:FindFirstChild("Owner")
		if ownerObj and ownerObj:IsA("ObjectValue") and ownerObj.Value == LocalPlayer then
			return plot.Name
		end
		-- Check StringValue owner
		local ownerName = plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Owner")
		if ownerName and ownerName:IsA("StringValue") and ownerName.Value == LocalPlayer.Name then
			return plot.Name
		end
	end
	return nil
end

SelectedPlot = detectPlayerPlot() or "Plot_2"

--// touchinterest helper
local function fireTouch(part)
	if not part then return end
	pcall(function()
		local fire = firetouchinterest or (khronos and khronos.firetouchinterest)
		if fire then
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				fire(part, hrp, 0)
				task.wait()
				fire(part, hrp, 1)
			end
		end
	end)
end

--// Dropdown Scan Helpers
local function getPlotsList()
	local list = {}
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			if plot:IsA("Model") or plot:IsA("Folder") then
				table.insert(list, plot.Name)
			end
		end
	end
	if #list == 0 then
		table.insert(list, SelectedPlot)
	end
	return list
end

local function getButtonsList()
	local list = {}
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(SelectedPlot)
	local buttons = plot and plot:FindFirstChild("Buttons")
	if buttons then
		for _, btn in ipairs(buttons:GetChildren()) do
			table.insert(list, btn.Name)
		end
	end
	return list
end

--// INITIALIZE GUI WINDOW & PAGES
local Window = Library.new("⛏️ Pickaxe Tycoon")

-- Global notify wrapper mapping to the active Window instance
local function notify(title, text, duration)
	if Window then
		Window:Notify(title, text, duration)
	end
end

-- Create Pages
local tycoonPage = Window:CreatePage("Tycoon")
local buyPage = Window:CreatePage("Auto Buy")
local miscPage = Window:CreatePage("Misc")

-- Build Tycoon Page
tycoonPage:CreateToggle("Auto Collect Ores", false, function(value)
	AutoCollectOres = value
	notify("Auto Collect Ores", value and "Enabled" or "Disabled", 3)
end)

local mapMultRow, mapMultCtrl = tycoonPage:CreateLabel("Map Multiplier", "Unknown")

tycoonPage:CreateToggle("Auto Deposit", false, function(value)
	AutoDeposit = value
	notify("Auto Deposit", value and "Enabled" or "Disabled", 3)
end)

tycoonPage:CreateToggle("Auto Collect Money", false, function(value)
	AutoCollectMoney = value
	notify("Auto Collect Money", value and "Enabled" or "Disabled", 3)
end)

tycoonPage:CreateToggle("Auto Merge", false, function(value)
	AutoMerge = value
	notify("Auto Merge", value and "Enabled" or "Disabled", 3)
end)

-- Build Auto Buy Page
local btnDropdownCtrl
local plotDropdownRow, plotDropdownCtrl = buyPage:CreateDropdown("Select Plot", SelectedPlot, function()
	return getPlotsList()
end, function(val)
	SelectedPlot = val
	SelectedButton = nil
	if btnDropdownCtrl then
		btnDropdownCtrl:SetText("Select Button")
	end
	notify("Plot Selected", "Active plot set to: " .. val, 2)
end)

local btnDropdownRow
btnDropdownRow, btnDropdownCtrl = buyPage:CreateDropdown("Select Button", "Select Button", function()
	return getButtonsList()
end, function(val)
	SelectedButton = val
	notify("Button Selected", "Target button set to: " .. val, 2)
end)

buyPage:CreateToggle("Auto Buy Button", false, function(value)
	AutoBuy = value
	notify("Auto Buy Button", value and "Enabled" or "Disabled", 3)
end)

-- Build Misc Page
miscPage:CreateButton("Destroy GUI", function()
	IsRunning = false
	AutoCollectOres = false
	AutoBuy = false
	AutoMerge = false
	AutoDeposit = false
	AutoCollectMoney = false
	Window:Destroy()
end)

-- Notify loaded
notify("Loaded", "Pickaxe Tycoon Script Loaded Successfully", 5)



--// BACKGROUND LOOPS //--

-- 1. Auto Collect Ores Loop (0.01s / extremely fast delay)
task.spawn(function()
	while IsRunning do
		if AutoCollectOres then
			pcall(function()
				local remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
				if remote then
					remote = remote:FindFirstChild("LootPickup")
				end
				if remote then
					local ids = {}
					for i = 1, 100 do
						table.insert(ids, i)
					end
					remote:FireServer(ids)
				end
			end)
		end
		task.wait(0.01)
	end
end)

-- 2. Auto Buy Button Loop (0.5s delay)
task.spawn(function()
	while IsRunning do
		if AutoBuy and SelectedPlot and SelectedButton then
			pcall(function()
				local plots = workspace:FindFirstChild("Plots")
				local plot = plots and plots:FindFirstChild(SelectedPlot)
				local buttons = plot and plot:FindFirstChild("Buttons")
				local targetModel = buttons and buttons:FindFirstChild(SelectedButton)
				local buttonPart = targetModel and targetModel:FindFirstChild("Button")
				if buttonPart then
					fireTouch(buttonPart)
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- 3. Auto Merge Loop (0.5s delay)
task.spawn(function()
	while IsRunning do
		if AutoMerge and SelectedPlot then
			pcall(function()
				local plots = workspace:FindFirstChild("Plots")
				local plot = plots and plots:FindFirstChild(SelectedPlot)
				local buttons = plot and plot:FindFirstChild("Buttons")
				local targetModel = buttons and buttons:FindFirstChild("ButtonMerge")
				local buttonPart = targetModel and targetModel:FindFirstChild("Button")
				if buttonPart then
					fireTouch(buttonPart)
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- 4. Auto Deposit Loop (0.5s delay)
task.spawn(function()
	while IsRunning do
		if AutoDeposit and SelectedPlot then
			pcall(function()
				local oreMultPart = workspace:FindFirstChild("OreMultPart")
				local bbGui = oreMultPart and oreMultPart:FindFirstChild("BillboardGui")
				local frame = bbGui and bbGui:FindFirstChild("Frame")
				local multText = frame and frame:FindFirstChild("MultText")
				local currentMult = multText and (multText.ContentText or multText.Text) or ""
				local multNumber = tonumber(string.match(currentMult, "[0-9.]+"))
				if multNumber and multNumber >= 1.3 and multNumber <= 1.5 then
					local plots = workspace:FindFirstChild("Plots")
					local plot = plots and plots:FindFirstChild(SelectedPlot)
					local sell = plot and plot:FindFirstChild("Sell")
					local targetModel = sell and sell:FindFirstChild("DepositButton")
					local buttonPart = targetModel and targetModel:FindFirstChild("Button")
					if buttonPart then
						fireTouch(buttonPart)
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- 5. Auto Collect Money Loop (0.5s delay)
task.spawn(function()
	while IsRunning do
		if AutoCollectMoney and SelectedPlot then
			pcall(function()
				local plots = workspace:FindFirstChild("Plots")
				local plot = plots and plots:FindFirstChild(SelectedPlot)
				local sell = plot and plot:FindFirstChild("Sell")
				local targetModel = sell and sell:FindFirstChild("CollectButton")
				local buttonPart = targetModel and targetModel:FindFirstChild("Button")
				if buttonPart then
					fireTouch(buttonPart)
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- 6. Background Loop to Update Map Multiplier UI (0.5s delay)
task.spawn(function()
	while IsRunning do
		pcall(function()
			local oreMultPart = workspace:FindFirstChild("OreMultPart")
			local bbGui = oreMultPart and oreMultPart:FindFirstChild("BillboardGui")
			local frame = bbGui and bbGui:FindFirstChild("Frame")
			local multText = frame and frame:FindFirstChild("MultText")
			if multText then
				local currentMult = multText.ContentText or multText.Text or "N/A"
				mapMultCtrl:SetText(currentMult)
			else
				mapMultCtrl:SetText("N/A")
			end
		end)
		task.wait(0.5)
	end
end)
