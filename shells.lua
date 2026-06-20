--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

--// GUI Library Definition
local Library = {}
Library.__index = Library

--// Helper: Make Frame Draggable
local function makeDraggable(dragPart, mainPart)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		mainPart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	local conn1 = dragPart.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainPart.Position

			local connChanged
			connChanged = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if connChanged then connChanged:Disconnect() end
				end
			end)
		end
	end)

	local conn2 = dragPart.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	local conn3 = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)

	return {conn1, conn2, conn3}
end

--// Constructor
function Library.new(titleText)
	local self = setmetatable({}, Library)
	self.Connections = {}
	self.TabButtons = {}
	self.ActivePage = nil

	-- parentGui
	local parentGui = (function()
		local success, coreGui = pcall(function()
			return game:GetService("CoreGui")
		end)
		if success and coreGui then
			return coreGui
		end
		return LocalPlayer:WaitForChild("PlayerGui")
	end)()

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CustomTemplateUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parentGui
	self.ScreenGui = screenGui

	-- Notification Frame & Layout
	local notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "Notifications"
	notificationContainer.Size = UDim2.new(0, 280, 1, -20)
	notificationContainer.Position = UDim2.new(1, -290, 0, 10)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.Parent = screenGui
	self.NotificationContainer = notificationContainer

	local notifList = Instance.new("UIListLayout")
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifList.Padding = UDim.new(0, 10)
	notifList.Parent = notificationContainer

	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 420, 0, 280)
	mainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
	mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	mainFrame.BackgroundTransparency = 0.08
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	self.MainFrame = mainFrame

	local mainFrameCorner = Instance.new("UICorner")
	mainFrameCorner.CornerRadius = UDim.new(0, 10)
	mainFrameCorner.Parent = mainFrame

	local mainFrameStroke = Instance.new("UIStroke")
	mainFrameStroke.Color = Color3.fromRGB(255, 255, 255)
	mainFrameStroke.Thickness = 1.0
	mainFrameStroke.Transparency = 0.85
	mainFrameStroke.Parent = mainFrame

	-- Title Bar (Drag Area)
	local titleBar = Instance.new("TextLabel")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundTransparency = 1
	titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleBar.Text = titleText or "✨ TEMPLATE GUI"
	titleBar.Font = Enum.Font.GothamBold
	titleBar.TextSize = 13
	titleBar.Active = true
	titleBar.Parent = mainFrame

	-- Top Divider
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
	self.TabContainer = tabContainer

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
	self.PageContainer = pageContainer

	-- Divider (Vertical)
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Position = UDim2.new(0, 110, 0, 41)
	divider.Size = UDim2.new(0, 1, 1, -41)
	divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	divider.BorderSizePixel = 0
	divider.Parent = mainFrame

	-- Setup Draggable connections
	local dragConns = makeDraggable(titleBar, mainFrame)
	for _, conn in ipairs(dragConns) do
		table.insert(self.Connections, conn)
	end

	-- Key G for Toggling UI Visibility
	local isVisible = true
	local gConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.G then
			isVisible = not isVisible
			mainFrame.Visible = isVisible
		end
	end)
	table.insert(self.Connections, gConn)

	return self
end

--// Notification Method
function Library:Notify(title, text, duration)
	duration = duration or 3
	if not self.ScreenGui or not self.ScreenGui.Parent then return end

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(1, 0, 0, 55)
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = self.NotificationContainer

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
			if not self.ScreenGui or not self.ScreenGui.Parent then return end
			notifFrame:TweenPosition(UDim2.new(1, 300, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.2, true, function()
				pcall(function()
					notifFrame:Destroy()
				end)
			end)
		end)
	end)
end

--// Cleanup / Destroy Method
function Library:Destroy()
	for _, conn in ipairs(self.Connections) do
		if conn and conn.Disconnect then
			pcall(function() conn:Disconnect() end)
		end
	end
	if self.ScreenGui then
		pcall(function() self.ScreenGui:Destroy() end)
	end
end

--// Page Definition
local Page = {}
Page.__index = Page

--// Create Tab / Page
function Library:CreatePage(name)
	local window = self

	-- Tab Button
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
	btn.Parent = self.TabContainer

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

	-- Scrolling Page Frame
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
	pageScroll.Parent = self.PageContainer

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
		if window.ActivePage then
			window.ActivePage.Visible = false
		end
		for _, otherBtn in ipairs(window.TabButtons) do
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
		window.ActivePage = pageScroll
	end

	btn.MouseButton1Click:Connect(select)
	table.insert(window.TabButtons, btn)

	if #window.TabButtons == 1 then
		select()
	end

	return setmetatable({
		Window = window,
		ScrollFrame = pageScroll
	}, Page)
end

--// Page Element: Toggle
function Page:CreateToggle(text, defaultValue, callback)
	local parent = self.ScrollFrame

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

	local controller = {}
	function controller:SetState(newState)
		state = newState
		updateVisuals()
	end

	return row, controller
end

--// Page Element: TextBox
function Page:CreateTextBox(text, placeholderText, defaultValue, callback)
	local parent = self.ScrollFrame

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

	local controller = {}
	function controller:SetText(newVal)
		textBox.Text = tostring(newVal)
	end

	return row, controller
end

--// Page Element: Label
function Page:CreateLabel(text, defaultValue)
	local parent = self.ScrollFrame

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

--// Page Element: Button
function Page:CreateButton(text, callback)
	local parent = self.ScrollFrame

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

--// Page Element: Dropdown
function Page:CreateDropdown(text, placeholderText, scanCallback, selectCallback)
	local parent = self.ScrollFrame

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

	-- List container (floating dropdown list)
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

			-- Clear existing items
			for _, child in ipairs(listContainer:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			-- Populate Options
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

	local controller = {}
	function controller:SetText(t)
		button.Text = t .. "  ▼"
	end
	
	return row, controller
end

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
local imperfectOffsetMin = 20
local imperfectOffsetMax = 30

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
							-- Shift the target by user-configured offset range (randomly left or right)
							local direction = (math.random(0, 1) == 0) and 1 or -1
							local minOff = math.min(imperfectOffsetMin, imperfectOffsetMax)
							local maxOff = math.max(imperfectOffsetMin, imperfectOffsetMax)
							currentBarOffset = direction * math.random(minOff, maxOff)
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

	-- Imperfect Offset Min (degrees)
	mainPage:CreateTextBox("Imperfect Offset Min (°)", "Degrees...", 20, function(val)
		local num = tonumber(val)
		if num then
			imperfectOffsetMin = math.max(1, math.round(num))
			Window:Notify("Settings Update", "Imperfect Offset Min set to: " .. tostring(imperfectOffsetMin) .. "°", 2)
		end
	end)

	-- Imperfect Offset Max (degrees)
	mainPage:CreateTextBox("Imperfect Offset Max (°)", "Degrees...", 30, function(val)
		local num = tonumber(val)
		if num then
			imperfectOffsetMax = math.max(1, math.round(num))
			Window:Notify("Settings Update", "Imperfect Offset Max set to: " .. tostring(imperfectOffsetMax) .. "°", 2)
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
