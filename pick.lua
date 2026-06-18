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
screenGui.Name = "PickaxeTycoonUI"
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
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notificationContainer

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notifFrame

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = Color3.fromRGB(255, 255, 255)
	notifStroke.Thickness = 1.0
	notifStroke.Transparency = 0.6
	notifStroke.Parent = notifFrame

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

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 25)
	descLabel.Position = UDim2.new(0, 10, 0, 23)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = text
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
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

-- Main Frame (Draggable & Minimalist Black/White)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 280)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 10)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(255, 255, 255)
mainFrameStroke.Thickness = 1.0
mainFrameStroke.Transparency = 0.85
mainFrameStroke.Parent = mainFrame

-- Title Bar (Flat Header Area)
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.Text = "⛏️ PICKAXE TYCOON"
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 13
titleBar.Active = true
titleBar.Parent = mainFrame

-- Top Divider separating header from page content
local topDivider = Instance.new("Frame")
topDivider.Name = "TopDivider"
topDivider.Position = UDim2.new(0, 0, 0, 40)
topDivider.Size = UDim2.new(1, 0, 0, 1)
topDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
topDivider.BorderSizePixel = 0
topDivider.Parent = mainFrame

-- Sidebar Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 0, 0, 41)
tabContainer.Size = UDim2.new(0, 110, 1, -41)
tabContainer.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
tabContainer.BackgroundTransparency = 0.5
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabContainer

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 8)
tabPadding.PaddingLeft = UDim.new(0, 6)
tabPadding.PaddingRight = UDim.new(0, 6)
tabPadding.Parent = tabContainer

-- Page Container
local pageContainer = Instance.new("Frame")
pageContainer.Name = "PageContainer"
pageContainer.Position = UDim2.new(0, 111, 0, 41)
pageContainer.Size = UDim2.new(1, -111, 1, -41)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = mainFrame

-- Divider line between tabs and page content
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Position = UDim2.new(0, 110, 0, 41)
divider.Size = UDim2.new(0, 1, 1, -41)
divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
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
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.72, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.Size = UDim2.new(0, 36, 0, 18)
	switch.Position = UDim2.new(1, -36, 0.5, -9)
	switch.BackgroundColor3 = defaultValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
	switch.Text = ""
	switch.AutoButtonColor = false
	switch.Parent = row

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch

	local switchStroke = Instance.new("UIStroke")
	switchStroke.Color = defaultValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
	switchStroke.Thickness = 1.0
	switchStroke.Parent = switch

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(0, 12, 0, 12)
	circle.Position = defaultValue and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
	circle.BackgroundColor3 = defaultValue and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
	circle.BorderSizePixel = 0
	circle.Parent = switch

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local state = defaultValue

	local function updateVisuals()
		if state then
			switch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			switchStroke.Color = Color3.fromRGB(255, 255, 255)
			circle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			circle:TweenPosition(UDim2.new(1, -15, 0.5, -6), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		else
			switch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			switchStroke.Color = Color3.fromRGB(60, 60, 60)
			circle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
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
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.Size = UDim2.new(0.38, 0, 0, 24)
	textBox.Position = UDim2.new(0.62, 0, 0.5, -12)
	textBox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
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
	textBoxStroke.Color = Color3.fromRGB(50, 50, 50)
	textBoxStroke.Thickness = 1.0
	textBoxStroke.Parent = textBox

	textBox.Focused:Connect(function()
		textBoxStroke.Color = Color3.fromRGB(255, 255, 255)
	end)

	textBox.FocusLost:Connect(function(enterPressed)
		textBoxStroke.Color = Color3.fromRGB(50, 50, 50)
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

local function createLabel(parent, text, defaultValue)
	local row = Instance.new("Frame")
	row.Name = text .. "Row"
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.38, 0, 0, 24)
	valueLabel.Position = UDim2.new(0.62, 0, 0.5, -12)
	valueLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.Text = tostring(defaultValue)
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 11
	valueLabel.Parent = row

	local valCorner = Instance.new("UICorner")
	valCorner.CornerRadius = UDim.new(0, 6)
	valCorner.Parent = valueLabel

	local valStroke = Instance.new("UIStroke")
	valStroke.Color = Color3.fromRGB(50, 50, 50)
	valStroke.Thickness = 1.0
	valStroke.Parent = valueLabel

	local controller = {}
	function controller:SetText(newVal)
		valueLabel.Text = tostring(newVal)
	end
	return row, controller
end

local function createButton(parent, text, callback)
	local btnFrame = Instance.new("Frame")
	btnFrame.Name = text .. "Frame"
	btnFrame.Size = UDim2.new(1, 0, 0, 42)
	btnFrame.BackgroundTransparency = 1
	btnFrame.Parent = parent

	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, 0, 0, 30)
	button.Position = UDim2.new(0, 0, 0.5, -15)
	button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = btnFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(50, 50, 50)
	btnStroke.Thickness = 1.0
	btnStroke.Parent = button

	button.MouseButton1Click:Connect(function()
		callback()
	end)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		button.TextColor3 = Color3.fromRGB(15, 15, 15)
		btnStroke.Color = Color3.fromRGB(255, 255, 255)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnStroke.Color = Color3.fromRGB(50, 50, 50)
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
	btn.TextColor3 = Color3.fromRGB(140, 140, 140)
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
	indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
	pageScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
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
			otherBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
			otherBtn.Indicator.Visible = false
			otherBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			otherBtn.BackgroundTransparency = 1
		end
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Indicator.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		btn.BackgroundTransparency = 0.5
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

-- Custom Dropdown Component
local function createDropdown(parent, text, placeholderText, scanCallback, selectCallback)
	local row = Instance.new("Frame")
	row.Name = text .. "Row"
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "DropdownButton"
	button.Size = UDim2.new(0.58, 0, 0, 24)
	button.Position = UDim2.new(0.42, 0, 0.5, -12)
	button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	button.TextColor3 = Color3.fromRGB(220, 220, 220)
	button.Text = placeholderText .. "  ▼"
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 11
	button.BorderSizePixel = 0
	button.Parent = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(50, 50, 50)
	btnStroke.Thickness = 1.0
	btnStroke.Parent = button

	-- List container (floating)
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "DropdownList"
	listContainer.Size = UDim2.new(0.58, 0, 0, 110)
	listContainer.Position = UDim2.new(0.42, 0, 1, 4)
	listContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	listContainer.BorderSizePixel = 0
	listContainer.ZIndex = 100
	listContainer.Visible = false
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.ScrollBarThickness = 3
	listContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	listContainer.Parent = row

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = listContainer

	local listStroke = Instance.new("UIStroke")
	listStroke.Color = Color3.fromRGB(80, 80, 80)
	listStroke.Thickness = 1.0
	listStroke.Parent = listContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = listContainer

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 4)
	listPadding.PaddingBottom = UDim.new(0, 4)
	listPadding.PaddingLeft = UDim.new(0, 4)
	listPadding.PaddingRight = UDim.new(0, 4)
	listPadding.Parent = listContainer

	local isOpen = false

	local function getPageScroll()
		local curr = row
		while curr do
			if curr:IsA("ScrollingFrame") then
				return curr
			end
			curr = curr.Parent
		end
		return nil
	end

	local function toggleDropdown()
		isOpen = not isOpen
		local pageScroll = getPageScroll()
		if pageScroll then
			pageScroll.ClipsDescendants = not isOpen
		end
		
		if isOpen then
			row.ZIndex = 10
			button.ZIndex = 10
			listContainer.ZIndex = 11

			-- Clear items
			for _, child in ipairs(listContainer:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			-- Scan/Get options
			local options = scanCallback()
			if #options == 0 then
				local noItem = Instance.new("TextButton")
				noItem.Size = UDim2.new(1, 0, 0, 24)
				noItem.BackgroundTransparency = 1
				noItem.Text = "No Options"
				noItem.TextColor3 = Color3.fromRGB(150, 150, 150)
				noItem.Font = Enum.Font.GothamItalic
				noItem.TextSize = 11
				noItem.ZIndex = 12
				noItem.Parent = listContainer
			else
				for _, option in ipairs(options) do
					local optBtn = Instance.new("TextButton")
					optBtn.Size = UDim2.new(1, 0, 0, 24)
					optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
					optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
					optBtn.Text = option.Name
					optBtn.Font = Enum.Font.GothamMedium
					optBtn.TextSize = 11
					optBtn.ZIndex = 12
					optBtn.Parent = listContainer

					local optCorner = Instance.new("UICorner")
					optCorner.CornerRadius = UDim.new(0, 4)
					optCorner.Parent = optBtn

					optBtn.MouseButton1Click:Connect(function()
						button.Text = option.Name .. "  ▼"
						isOpen = false
						if pageScroll then
							pageScroll.ClipsDescendants = true
						end
						row.ZIndex = 1
						button.ZIndex = 1
						listContainer.ZIndex = 1
						listContainer.Visible = false
						btnStroke.Color = Color3.fromRGB(50, 50, 50)
						selectCallback(option.Value)
					end)

					optBtn.MouseEnter:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						optBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
					end)

					optBtn.MouseLeave:Connect(function()
						optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
						optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
					end)
				end
			end

			task.defer(function()
				listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
			end)

			listContainer.Visible = true
			btnStroke.Color = Color3.fromRGB(255, 255, 255)
		else
			row.ZIndex = 1
			button.ZIndex = 1
			listContainer.ZIndex = 1
			listContainer.Visible = false
			btnStroke.Color = Color3.fromRGB(50, 50, 50)
		end
	end

	button.MouseButton1Click:Connect(toggleDropdown)

	button.MouseEnter:Connect(function()
		if not isOpen then
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			btnStroke.Color = Color3.fromRGB(100, 100, 100)
		end
	end)

	button.MouseLeave:Connect(function()
		if not isOpen then
			button.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			btnStroke.Color = Color3.fromRGB(50, 50, 50)
		end
	end)

	local dropdownController = {}
	function dropdownController:SetText(t)
		button.Text = t .. "  ▼"
	end
	
	return row, dropdownController
end

-- Helpers to scan folders for dropdowns
local function getPlotsList()
	local list = {}
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			table.insert(list, {Name = plot.Name, Value = plot.Name})
		end
	end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list
end

local function getButtonsList()
	local list = {}
	if not SelectedPlot then return list end
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(SelectedPlot)
	local buttons = plot and plot:FindFirstChild("Buttons")
	if buttons then
		for _, btn in ipairs(buttons:GetChildren()) do
			if btn:IsA("Model") then
				table.insert(list, {Name = btn.Name, Value = btn.Name})
			end
		end
	end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list
end

-- Create Pages
local tycoonPage = createPage("Tycoon")
local buyPage = createPage("Auto Buy")
local miscPage = createPage("Misc")

-- Build Tycoon Page
createToggle(tycoonPage, "Auto Collect Ores", false, function(value)
	AutoCollectOres = value
	notify("Auto Collect Ores", value and "Enabled" or "Disabled", 3)
end)

local mapMultRow, mapMultCtrl = createLabel(tycoonPage, "Map Multiplier", "Unknown")

createToggle(tycoonPage, "Auto Deposit", false, function(value)
	AutoDeposit = value
	notify("Auto Deposit", value and "Enabled" or "Disabled", 3)
end)

createToggle(tycoonPage, "Auto Collect Money", false, function(value)
	AutoCollectMoney = value
	notify("Auto Collect Money", value and "Enabled" or "Disabled", 3)
end)

createToggle(tycoonPage, "Auto Merge", false, function(value)
	AutoMerge = value
	notify("Auto Merge", value and "Enabled" or "Disabled", 3)
end)

-- Build Auto Buy Page
local btnDropdownCtrl
local plotDropdownRow, plotDropdownCtrl = createDropdown(buyPage, "Select Plot", SelectedPlot, function()
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
btnDropdownRow, btnDropdownCtrl = createDropdown(buyPage, "Select Button", "Select Button", function()
	return getButtonsList()
end, function(val)
	SelectedButton = val
	notify("Button Selected", "Target button set to: " .. val, 2)
end)

createToggle(buyPage, "Auto Buy Button", false, function(value)
	AutoBuy = value
	notify("Auto Buy Button", value and "Enabled" or "Disabled", 3)
end)

-- Build Misc Page
createButton(miscPage, "Destroy GUI", function()
	IsRunning = false
	AutoCollectOres = false
	AutoBuy = false
	AutoMerge = false
	AutoDeposit = false
	AutoCollectMoney = false
	screenGui:Destroy()
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
