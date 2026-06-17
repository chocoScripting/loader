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

--// parentGui
local parentGui = (function()
	local success, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if success and coreGui then
		return coreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end)()

--// Custom UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FootballTrainingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- Notification Frame & Layout
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
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 15)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notificationContainer

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notifFrame

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = Color3.fromRGB(46, 204, 113) -- Vibrant Football Green
	notifStroke.Thickness = 1.2
	notifStroke.Transparency = 0.4
	notifStroke.Parent = notifFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notifFrame

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
	end)
	return ThrowEvent ~= nil and FinishEvent ~= nil, TrainEvent ~= nil, ClaimPassEvent ~= nil, HatchEggEvent ~= nil, CraftEvent ~= nil, StopTrainEvent ~= nil
end

-- Main Frame (Draggable & Transparent like Rayfield)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 270)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -135)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 12)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(46, 204, 113)
mainFrameStroke.Thickness = 1.5
mainFrameStroke.Transparency = 0.3
mainFrameStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
titleBar.BackgroundTransparency = 0.1
titleBar.TextColor3 = Color3.fromRGB(15, 15, 15)
titleBar.Text = "⚽ Football Training"
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Active = true
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 174, 96)),
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

-- Overlay to cover the bottom rounded corners of the title bar
local titleBarOverlay = Instance.new("Frame")
titleBarOverlay.Name = "TitleBarOverlay"
titleBarOverlay.Size = UDim2.new(1, 0, 0, 6)
titleBarOverlay.Position = UDim2.new(0, 0, 1, -6)
titleBarOverlay.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
titleBarOverlay.BorderSizePixel = 0
titleBarOverlay.Parent = titleBar

-- Sidebar Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 0, 0, 38)
tabContainer.Size = UDim2.new(0, 95, 1, -38)
tabContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
tabContainer.BackgroundTransparency = 0.3
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabContainer

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 8)
tabPadding.PaddingLeft = UDim.new(0, 5)
tabPadding.PaddingRight = UDim.new(0, 5)
tabPadding.Parent = tabContainer

-- Page Container
local pageContainer = Instance.new("Frame")
pageContainer.Name = "PageContainer"
pageContainer.Position = UDim2.new(0, 96, 0, 38)
pageContainer.Size = UDim2.new(1, -96, 1, -38)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = mainFrame

-- Divider line between tabs and page content
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Position = UDim2.new(0, 95, 0, 38)
divider.Size = UDim2.new(0, 1, 1, -38)
divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- Draggable Functionality
local function makeDraggable(dragPart, mainPart)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		mainPart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	dragPart.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainPart.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragPart.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

makeDraggable(titleBar, mainFrame)

-- Toggle Hide UI using G
local isVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		isVisible = not isVisible
		mainFrame.Visible = isVisible
	end
end)

-- Component Helper Functions
local function createToggle(parent, text, defaultValue, callback)
	local row = Instance.new("Frame")
	row.Name = text .. "Row"
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.Size = UDim2.new(0, 38, 0, 18)
	switch.Position = UDim2.new(1, -38, 0.5, -9)
	switch.BackgroundColor3 = defaultValue and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 45, 55)
	switch.Text = ""
	switch.AutoButtonColor = false
	switch.Parent = row

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch

	local switchStroke = Instance.new("UIStroke")
	switchStroke.Color = defaultValue and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(80, 80, 90)
	switchStroke.Thickness = 1
	switchStroke.Parent = switch

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(0, 12, 0, 12)
	circle.Position = defaultValue and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = switch

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local state = defaultValue

	local function updateVisuals()
		if state then
			switch.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			switchStroke.Color = Color3.fromRGB(46, 204, 113)
			circle:TweenPosition(UDim2.new(1, -15, 0.5, -6), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		else
			switch.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			switchStroke.Color = Color3.fromRGB(80, 80, 90)
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -6), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		end
	end

	switch.MouseButton1Click:Connect(function()
		state = not state
		updateVisuals()
		callback(state)
	end)

	return row
end

local function createTextBox(parent, text, placeholderText, defaultValue, callback)
	local row = Instance.new("Frame")
	row.Name = text .. "Row"
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.Size = UDim2.new(0.38, 0, 0, 22)
	textBox.Position = UDim2.new(0.62, 0, 0.5, -11)
	textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Text = tostring(defaultValue)
	textBox.PlaceholderText = placeholderText
	textBox.Font = Enum.Font.GothamMedium
	textBox.TextSize = 11
	textBox.ClearTextOnFocus = false
	textBox.Parent = row

	local textBoxCorner = Instance.new("UICorner")
	textBoxCorner.CornerRadius = UDim.new(0, 6)
	textBoxCorner.Parent = textBox

	local textBoxStroke = Instance.new("UIStroke")
	textBoxStroke.Color = Color3.fromRGB(80, 80, 90)
	textBoxStroke.Thickness = 1
	textBoxStroke.Parent = textBox

	textBox.FocusLost:Connect(function(enterPressed)
		local textValue = textBox.Text
		if type(defaultValue) == "number" then
			local val = tonumber(textValue)
			if val then
				callback(val)
			else
				textBox.Text = tostring(defaultValue)
				callback(defaultValue)
			end
		else
			if textValue and textValue ~= "" then
				callback(textValue)
			else
				textBox.Text = tostring(defaultValue)
				callback(defaultValue)
			end
		end
	end)

	return row
end

local function createButton(parent, text, callback)
	local btnFrame = Instance.new("Frame")
	btnFrame.Name = text .. "Frame"
	btnFrame.Size = UDim2.new(1, 0, 0, 38)
	btnFrame.BackgroundTransparency = 1
	btnFrame.Parent = parent

	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, 0, 0, 28)
	button.Position = UDim2.new(0, 0, 0.5, -14)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.TextColor3 = Color3.fromRGB(46, 204, 113)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = btnFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(80, 80, 90)
	btnStroke.Thickness = 1
	btnStroke.Parent = button

	button.MouseButton1Click:Connect(function()
		callback()
	end)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
		btnStroke.Color = Color3.fromRGB(46, 204, 113)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btnStroke.Color = Color3.fromRGB(80, 80, 90)
	end)

	return btnFrame
end

-- Tab switching framework
local tabButtons = {}
local activePage = nil

local function createPage(name)
	-- Create Tab Button
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Tab"
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundTransparency = 1
	btn.Text = "  " .. name
	btn.TextColor3 = Color3.fromRGB(150, 150, 160)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.BorderSizePixel = 0
	btn.Parent = tabContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 0.6, 0)
	indicator.Position = UDim2.new(0, 2, 0.2, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = btn

	-- Create Scrolling Frame for content
	local pageScroll = Instance.new("ScrollingFrame")
	pageScroll.Name = name .. "Page"
	pageScroll.Size = UDim2.new(1, 0, 1, 0)
	pageScroll.BackgroundTransparency = 1
	pageScroll.BorderSizePixel = 0
	pageScroll.ScrollBarThickness = 3
	pageScroll.ScrollBarImageColor3 = Color3.fromRGB(46, 204, 113)
	pageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pageScroll.Visible = false
	pageScroll.Parent = pageContainer

	local pageList = Instance.new("UIListLayout")
	pageList.SortOrder = Enum.SortOrder.LayoutOrder
	pageList.Padding = UDim.new(0, 5)
	pageList.Parent = pageScroll

	local pagePadding = Instance.new("UIPadding")
	pagePadding.PaddingTop = UDim.new(0, 8)
	pagePadding.PaddingBottom = UDim.new(0, 8)
	pagePadding.PaddingLeft = UDim.new(0, 10)
	pagePadding.PaddingRight = UDim.new(0, 12)
	pagePadding.Parent = pageScroll

	local function select()
		if activePage then
			activePage.Visible = false
		end
		for _, otherBtn in ipairs(tabButtons) do
			otherBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
			otherBtn.Indicator.Visible = false
			otherBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			otherBtn.BackgroundTransparency = 1
		end
		btn.TextColor3 = Color3.fromRGB(46, 204, 113)
		btn.Indicator.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.BackgroundTransparency = 0.6
		pageScroll.Visible = true
		activePage = pageScroll
	end

	btn.MouseButton1Click:Connect(select)
	table.insert(tabButtons, btn)

	if #tabButtons == 1 then
		select()
	end

	return pageScroll
end

-- Create Pages
local trainPage = createPage("Training")
local petsPage = createPage("Pets & Eggs")
local miscPage = createPage("Misc")

-- Build Training Page Controls
createToggle(trainPage, "Auto Kick", false, function(value)
	AutoKick = value
	notify("Auto Kick", value and "Enabled" or "Disabled", 3)
end)

createToggle(trainPage, "Auto Train", false, function(value)
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

createTextBox(trainPage, "Kick Mult", "1-100", kickMultiplier, function(value)
	kickMultiplier = value
	notify("Kick Mult Set", "Kick multiplier set to " .. tostring(value), 2)
end)

createTextBox(trainPage, "Train Mult", "1-100", trainMultiplier, function(value)
	trainMultiplier = value
	notify("Train Mult Set", "Train multiplier set to " .. tostring(value), 2)
end)

-- Build Pets Page Controls
createToggle(petsPage, "Auto Hatch", false, function(value)
	AutoHatch = value
	notify("Auto Hatch", value and "Enabled" or "Disabled", 3)
end)

createToggle(petsPage, "Auto Craft", false, function(value)
	AutoCraft = value
	notify("Auto Craft", value and "Enabled" or "Disabled", 3)
end)

createTextBox(petsPage, "Egg Name", "Egg Name...", hatchEggName, function(value)
	hatchEggName = value
	notify("Egg Set", "Target egg set to: " .. tostring(value), 2)
end)

-- Build Misc Page Controls
createToggle(miscPage, "Disable Popups", false, function(value)
	DisablePopups = value
	notify("Disable Popups", value and "Enabled" or "Disabled", 3)
	
	pcall(function()
		local popups = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PopUps")
		if popups then
			popups.Enabled = not value
		end
	end)
end)

createButton(miscPage, "Claim Season Pass", function()
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

createButton(miscPage, "Destroy GUI", function()
	IsRunning = false
	AutoKick = false
	AutoTrain = false
	AutoHatch = false
	AutoCraft = false
	DisablePopups = false
	
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
	
	screenGui:Destroy()
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
