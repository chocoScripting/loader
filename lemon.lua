--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Variables
local IsRunning = true
local AutoBuy = false
local AutoUpgrade = false
local AutoFruit = false
local AutoIncome = false
local Buying = false

--// Find Tycoon
local userTycoon = (function()
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Folder") and v.Name:match("Tycoon%d") then
			if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
				return v
			end
		end
	end
end)()

--// GUI Library Definition (From templateGUI.lua)
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
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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

-- Initialize Window
local Window = Library.new("🍋 Sell Lemons - Autofarm")

-- Check Tycoon
if not userTycoon then
	Window:Notify("Error", "Tycoon not found! Script stopped.", 5)
	task.wait(5)
	Window:Destroy()
	return
end

-- Helper notify function mapping to new library
local function notify(title, text, duration)
	Window:Notify(title, text, duration)
end

-- Create Page
local mainPage = Window:CreatePage("Autofarm")

-- Build Controls
mainPage:CreateToggle("Auto Buy", false, function(value)
	AutoBuy = value
	notify("Auto Buy", value and "Enabled" or "Disabled", 3)
end)

mainPage:CreateToggle("Auto Upgrade", false, function(value)
	AutoUpgrade = value
	notify("Auto Upgrade", value and "Enabled" or "Disabled", 3)
end)

mainPage:CreateToggle("Auto Fruit", false, function(value)
	AutoFruit = value
	notify("Auto Fruit", value and "Enabled" or "Disabled", 3)
end)

mainPage:CreateToggle("Auto Income", false, function(value)
	AutoIncome = value
	notify("Auto Income", value and "Enabled" or "Disabled", 3)
end)

mainPage:CreateButton("Destroy GUI", function()
	IsRunning = false
	AutoBuy = false
	AutoUpgrade = false
	AutoFruit = false
	AutoIncome = false
	Window:Destroy()
end)

-- Notify loaded
notify("Loaded", "Tycoon Autofarm Loaded Successfully", 5)

--// Autofarm Helper Functions
local function getButtons()
	local Buttons = {}

	for _, obj in ipairs(userTycoon.Purchases:GetDescendants()) do
		if obj:IsA("Model") then

			local shown = obj:GetAttribute("Shown")
			local purchased = obj:GetAttribute("Purchased")

			if shown == true and purchased ~= true then

				local buttonPart = obj:FindFirstChild("Button")

				if buttonPart and buttonPart:IsA("BasePart") then
					table.insert(Buttons, {
						Name = obj.Name,
						Button = buttonPart,
					})
				end
			end
		end
	end

	return Buttons
end

local function buyButton(buttonData)

	if Buying then
		return
	end

	Buying = true

	local character = LocalPlayer.Character
	if not character then
		Buying = false
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		Buying = false
		return
	end

	local buttonPart = buttonData.Button

	pcall(function()
		firetouchinterest(hrp, buttonPart, 0)
		firetouchinterest(hrp, buttonPart, 1)
	end)

	Buying = false
end

local function upgradeMachines()

	for _, obj in ipairs(userTycoon.Purchases:GetDescendants()) do

		if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then

			pcall(function()

				for level = 1, 100 do
					if not IsRunning or not AutoUpgrade then break end
					obj:InvokeServer(level)
				end

			end)
		end
	end
end

local function autoIncome()
	local wakeRemote
	for _, obj in ipairs(userTycoon:GetDescendants()) do
		if obj:IsA("RemoteFunction") and obj.Name == "WakeIncomeStream" then
			wakeRemote = obj
			break
		end
	end

	if wakeRemote then
		for _, purchase in ipairs(userTycoon.Purchases:GetChildren()) do
			if not IsRunning or not AutoIncome then break end
			
			local formattedName = purchase.Name:gsub("%s+", "")
			-- Filter hanya untuk objek yang mengandung kata "Lemon" (seperti LemonStand, LemonDash)
			-- agar tidak memanggil objek yang salah (seperti Wall/Gate) yang bisa membuat script macet.
			if formattedName:find("Lemon") then
				task.spawn(function()
					pcall(function()
						wakeRemote:InvokeServer(formattedName)
					end)
				end)
			end
		end
	end
end

local Trees = {}

local function addTree(obj)
	if obj:IsA("Model") and obj.Name == "LemonTree" then

		if not table.find(Trees, obj) then
			table.insert(Trees, obj)
		end
	end
end

local function removeTree(obj)

	local index = table.find(Trees, obj)

	if index then
		table.remove(Trees, index)
	end
end

-- initial scan
for _, v in ipairs(workspace:GetDescendants()) do
	addTree(v)
end

-- realtime update
local connAdded = workspace.DescendantAdded:Connect(addTree)
local connRemoving = workspace.DescendantRemoving:Connect(removeTree)

local lastClicked = setmetatable({}, {__mode = "k"})

local activeHighlight = nil
local activeStatusGui = nil

local function removeActiveHighlight()
	if activeHighlight then
		pcall(function()
			activeHighlight:Destroy()
		end)
		activeHighlight = nil
	end
	if activeStatusGui then
		pcall(function()
			activeStatusGui:Destroy()
		end)
		activeStatusGui = nil
	end
end

local function getVisibleFruits(tree)
	local fruits = {}
	for _, obj in ipairs(tree:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Fruit" then
			local clickPart = obj:FindFirstChild("ClickPart")
			if clickPart then
				local detector = clickPart:FindFirstChildOfClass("ClickDetector")
				if detector then
					table.insert(fruits, {
						Part = obj,
						ClickPart = clickPart,
						Detector = detector
					})
				end
			end
		end
	end
	return fruits
end

--// Loops
task.spawn(function()
	while IsRunning do
		task.wait(0.0000001)

		if AutoBuy then

			local Buttons = getButtons()

			for _, button in ipairs(Buttons) do
				if not IsRunning or not AutoBuy then break end
				pcall(function()
					buyButton(button)
				end)
			end
		end
	end
end)

task.spawn(function()
	while IsRunning do
		task.wait(0.00001)

		if AutoUpgrade then
			pcall(function()
				upgradeMachines()
			end)
		end
	end
end)

task.spawn(function()
	while IsRunning do
		task.wait(1)

		if AutoIncome then
			pcall(function()
				autoIncome()
			end)
		end
	end
end)

task.spawn(function()
	while IsRunning do
		task.wait(0.1)

		if AutoFruit then
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")

			if hrp then
				local playerPos = hrp.Position

				-- Salin dan urutkan pohon berdasarkan jarak terdekat ke player
				local sortedTrees = {}
				for _, tree in ipairs(Trees) do
					if tree and tree.Parent then
						table.insert(sortedTrees, tree)
					end
				end

				table.sort(sortedTrees, function(a, b)
					local distA = (a:GetPivot().Position - playerPos).Magnitude
					local distB = (b:GetPivot().Position - playerPos).Magnitude
					return distA < distB
				end)

				for _, tree in ipairs(sortedTrees) do
					if not AutoFruit or not IsRunning then
						break
					end

					if tree and tree.Parent then
						local visibleFruits = getVisibleFruits(tree)

						if #visibleFruits > 0 then
							-- Simpan CFrame asli untuk dikembalikan nanti
							local originalCFrame = hrp.CFrame

							-- Tambahkan Highlight warna putih pada pohon yang sedang diklaim
							removeActiveHighlight()
							pcall(function()
								activeHighlight = Instance.new("Highlight")
								activeHighlight.FillColor = Color3.fromRGB(255, 255, 255)
								activeHighlight.FillTransparency = 0.5
								activeHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
								activeHighlight.OutlineTransparency = 0
								activeHighlight.Parent = tree
							end)

							-- Tambahkan Status BillboardGui di atas pohon
							local totalFruits = #visibleFruits
							pcall(function()
								activeStatusGui = Instance.new("BillboardGui")
								activeStatusGui.Name = "FruitStatus"
								activeStatusGui.Size = UDim2.new(0, 150, 0, 35)
								activeStatusGui.StudsOffset = Vector3.new(0, 10, 0) -- 10 studs di atas pohon agar terlihat
								activeStatusGui.AlwaysOnTop = true
								activeStatusGui.Adornee = tree
								activeStatusGui.Parent = tree

								local bg = Instance.new("Frame")
								bg.Size = UDim2.new(1, 0, 1, 0)
								bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
								bg.BackgroundTransparency = 0.2
								bg.BorderSizePixel = 0
								bg.Parent = activeStatusGui

								local corner = Instance.new("UICorner")
								corner.CornerRadius = UDim.new(0, 6)
								corner.Parent = bg

								local stroke = Instance.new("UIStroke")
								stroke.Color = Color3.fromRGB(253, 218, 13) -- Kuning lemon
								stroke.Thickness = 1.5
								stroke.Parent = bg

								local label = Instance.new("TextLabel")
								label.Size = UDim2.new(1, 0, 1, 0)
								label.BackgroundTransparency = 1
								label.Text = "Lemons: " .. totalFruits .. "/" .. totalFruits
								label.TextColor3 = Color3.fromRGB(253, 218, 13)
								label.Font = Enum.Font.GothamBold
								label.TextSize = 14
								label.Parent = bg
							end)

							-- Tetap stay di bawah pohon selama proses claim (agar di bawah tanah) dan berposisi horizontal (flat)
							local claimingTree = true
							local targetCFrame = tree:GetPivot() * CFrame.new(0, -20, 0) * CFrame.Angles(math.rad(90), 0, 0) -- 20 studs di bawah pohon + horizontal

							task.spawn(function()
								while claimingTree and AutoFruit and IsRunning and tree and tree.Parent do
									pcall(function()
										local char = LocalPlayer.Character
										local currentHrp = char and char:FindFirstChild("HumanoidRootPart")
										if currentHrp then
											currentHrp.CFrame = targetCFrame
											currentHrp.Velocity = Vector3.new(0, 0, 0)
										end
									end)
									task.wait()
								end
							end)

							task.wait(0.1) -- Jeda startup sebelum claim (sama dengan lemon.lua)

							local startTime = tick()
							-- Tetap fokus di pohon ini sampai semua ClickPart buahnya benar-benar hilang (max 5 detik biar ga stuck)
							while #visibleFruits > 0 and AutoFruit and IsRunning and tree and tree.Parent and (tick() - startTime < 5) do
								pcall(function()
									for _, item in ipairs(visibleFruits) do
										local detector = item.Detector
										detector.MaxActivationDistance = 999999
										fireclickdetector(detector)
									end
								end)

								pcall(function()
									if activeStatusGui and activeStatusGui:FindFirstChild("Frame") and activeStatusGui.Frame:FindFirstChild("TextLabel") then
										activeStatusGui.Frame.TextLabel.Text = "Lemons: " .. #visibleFruits .. "/" .. totalFruits
									end
								end)

								task.wait(0.05) -- Jeda setelah klik sebelum scan ulang (sama dengan lemon.lua)
								visibleFruits = getVisibleFruits(tree)
							end

							claimingTree = false
							task.wait(0.05) -- Jeda singkat agar loop teleportasi selesai

							-- Kembalikan karakter ke posisi awal
							pcall(function()
								local char = LocalPlayer.Character
								local currentHrp = char and char:FindFirstChild("HumanoidRootPart")
								if currentHrp then
									currentHrp.CFrame = originalCFrame
								end
							end)

							-- Hapus highlight dan status billboard setelah pohon selesai dibersihkan
							removeActiveHighlight()
						end
					end
				end
			end
		else
			removeActiveHighlight()
		end
	end
	removeActiveHighlight()
end)

-- Clean connections when script is destroyed
task.spawn(function()
	while IsRunning do
		task.wait(1)
	end
	connAdded:Disconnect()
	connRemoving:Disconnect()
	removeActiveHighlight()
end)
