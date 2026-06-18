-- PLAYER & GUI SERVICES
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- GAME SERVICES
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local entityfolder = workspace:FindFirstChild("Entity")
local cachedArg1 = nil
local currentTarget = nil
local loot = workspace:FindFirstChild("FX")

-- Dynamic Event Locator (Resolves issues where the Event changes on weapon swap/death)
local function getEvent()
    if not char then return nil end
    local netMessage = char:FindFirstChild("NetMessage")
    if netMessage then
        return netMessage:FindFirstChild("TrigerSkill")
    end
    return nil
end

-- Handle Character Respawn and Weapon Switching
local function setupCharacter(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    
    newChar.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            -- Reset weapon code cache on tool swap so it recalculates
            cachedArg1 = nil
        end
    end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    task.spawn(setupCharacter, player.Character)
end

-- STATE CONTROLS
local IsRunning = true
local features = {
    KillAura = false,
    AutoFarm = false,
    AutoPickup = false,
    InfiniteRange = false,
    Cover = false,
    MerchantESP = false,
    EntityESP = false,
    SellAll = false
}
local sellList = {}
for i = 1, 200 do
    table.insert(sellList, i)
end
local farmOffset = CFrame.new(0, 7, 0) -- Jarak teleport AutoFarm (Di atas musuh agar tidak terkena hit)
local killAuraRange = 100 -- Jarak deteksi maksimal Kill Aura (Ubah angka ini jika ingin memperpendek/memperpanjang jarak serang)
local damageMultiplier = 1 -- Jumlah hit per serang (Damage Multiplier)
local merchantHighlights = {} -- Store Highlight instances for merchants
local entityHighlights = {} -- Store Highlight instances for entities

-- THEME CONFIGURATION (Crimson Red for Cursed Blade ESP & Highlights)
local ThemeColor = Color3.fromRGB(255, 75, 75)
local ThemeColorDark = Color3.fromRGB(200, 40, 40)

--// =============================================================================
--// GUI LIBRARY DEFINITION (From templateGUI.lua)
--// =============================================================================
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
		return playerGui
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
		if callback then callback(state) end
	end)

	local controller = {}
	function controller.Set(newState)
		if state ~= newState then
			state = newState
			updateVisuals()
			if callback then callback(state) end
		end
	end
	function controller:SetState(newState)
		controller.Set(newState)
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
				if callback then callback(val) end
			else
				textBox.Text = tostring(defaultValue)
				if callback then callback(defaultValue) end
			end
		else
			if textValue and textValue ~= "" then
				if callback then callback(textValue) end
			else
				textBox.Text = tostring(defaultValue)
				if callback then callback(defaultValue) end
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
		if callback then callback() end
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
						if selectCallback then selectCallback(option.Value) end
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
--// INITIALIZE GUI WINDOW & PAGES
--// =============================================================================
local Window = Library.new("⚔️ Angels - Cursed Blade")

local combatPage = Window:CreatePage("Combat")
local espPage = Window:CreatePage("ESP & Teleport")
local miscPage = Window:CreatePage("Utility")
local settingsPage = Window:CreatePage("Settings")

-- Global notify wrapper mapping to the active Window instance
local function notify(title, text, duration)
    if Window then
        Window:Notify(title, text, duration)
    end
end

--// =============================================================================
--// CREATE WINDOW ELEMENTS
--// =============================================================================

-- Global Kill Aura Toggle variable for programmatic access in Auto Farm loop
local killAuraToggle

-- 1. COMBAT PAGE
local _, killAuraToggleObj = combatPage:CreateToggle("Kill Aura", false, function(value)
    features.KillAura = value
    notify("Kill Aura", value and "Enabled" or "Disabled", 3)
end)
killAuraToggle = killAuraToggleObj

combatPage:CreateToggle("Auto Farm", false, function(value)
    features.AutoFarm = value
    notify("Auto Farm", value and "Enabled" or "Disabled", 3)
end)

combatPage:CreateToggle("Infinite Range", false, function(value)
    features.InfiniteRange = value
    notify("Infinite Range", value and "Enabled" or "Disabled", 3)
end)

combatPage:CreateTextBox("Multiplier", "1-100", damageMultiplier, function(value)
    damageMultiplier = value
    notify("Multiplier Set", "Damage multiplier set to " .. tostring(value), 2)
end)

-- 2. ESP & TELEPORT PAGE
espPage:CreateToggle("Merchant ESP", false, function(value)
    features.MerchantESP = value
    notify("Merchant ESP", value and "Enabled" or "Disabled", 3)
    if not value then
        for _, highlight in ipairs(merchantHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        merchantHighlights = {}
        -- Cleanup billboards
        local eitem = workspace:FindFirstChild("EItem")
        if eitem then
            for _, v in ipairs(eitem:GetDescendants()) do
                if v.Name == "_MerchantBB" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end)

espPage:CreateToggle("Entity ESP", false, function(value)
    features.EntityESP = value
    notify("Entity ESP", value and "Enabled" or "Disabled", 3)
    if not value then
        for _, highlight in ipairs(entityHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        entityHighlights = {}
        -- Cleanup billboards
        if entityfolder then
            for _, v in ipairs(entityfolder:GetDescendants()) do
                if v.Name == "_EntityBB" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end)

local selectedMerchant = nil

espPage:CreateDropdown("Select Merchant", "Choose Merchant", function()
    local options = {}
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        local count = 0
        for _, v in ipairs(eitem:GetChildren()) do
            if v.Name == "Merchant" then
                count = count + 1
                local displayName = "Merchant " .. count
                local hrpPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                if hrpPart and hrp then
                    local dist = math.floor((hrp.Position - hrpPart.Position).Magnitude)
                    displayName = string.format("Merchant %d [%d studs]", count, dist)
                end
                table.insert(options, { Name = displayName, Value = v })
            end
        end
        local merchantFolder = eitem:FindFirstChild("Merchant")
        if merchantFolder and merchantFolder:IsA("Folder") then
            for _, v in ipairs(merchantFolder:GetChildren()) do
                count = count + 1
                local hrpPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart") or v
                local displayName = v.Name
                if hrpPart and hrpPart:IsA("BasePart") and hrp then
                    local dist = math.floor((hrp.Position - hrpPart.Position).Magnitude)
                    displayName = string.format("%s [%d studs]", v.Name, dist)
                end
                table.insert(options, { Name = displayName, Value = v })
            end
        end
    end
    return options
end, function(val)
    selectedMerchant = val
end)

espPage:CreateButton("Teleport to Merchant", function()
    if not selectedMerchant or not selectedMerchant.Parent then
        notify("Teleport", "Pilih Merchant terlebih dahulu!", 3)
        return
    end
    local targetCF = nil
    if selectedMerchant:IsA("Model") then
        if selectedMerchant.PrimaryPart then
            targetCF = selectedMerchant.PrimaryPart.CFrame
        else
            local part = selectedMerchant:FindFirstChildWhichIsA("BasePart")
            if part then targetCF = part.CFrame end
        end
    elseif selectedMerchant:IsA("BasePart") then
        targetCF = selectedMerchant.CFrame
    end
    if targetCF and hrp then
        hrp.CFrame = targetCF * CFrame.new(0, 3, 0)
        notify("Teleport", "Berhasil teleport ke " .. selectedMerchant.Name, 3)
    else
        notify("Teleport", "Gagal mendapatkan posisi Merchant!", 3)
    end
end)

-- 3. UTILITY PAGE
miscPage:CreateToggle("Auto Pickup", false, function(value)
    features.AutoPickup = value
    notify("Auto Pickup", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateToggle("Cover Player", false, function(value)
    features.Cover = value
    notify("Cover Player", value and "Enabled" or "Disabled", 3)
end)

miscPage:CreateToggle("Sell All", false, function(value)
    features.SellAll = value
    notify("Sell All", value and "Enabled" or "Disabled", 3)
end)

local selectedPlayerName = nil

miscPage:CreateDropdown("Select Player", "Choose Player", function()
    local options = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            table.insert(options, {
                Name = p.DisplayName .. " (@" .. p.Name .. ")",
                Value = p.Name
            })
        end
    end
    return options
end, function(val)
    selectedPlayerName = val
end)

-- 4. SETTINGS PAGE
local fpsLabel, fpsCtrl = settingsPage:CreateLabel("FPS", "60")

settingsPage:CreateButton("Destroy GUI", function()
    IsRunning = false
    features.KillAura = false
    features.AutoFarm = false
    features.AutoPickup = false
    features.InfiniteRange = false
    features.Cover = false
    features.MerchantESP = false
    features.EntityESP = false
    features.SellAll = false
    for _, highlight in ipairs(merchantHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    merchantHighlights = {}
    for _, highlight in ipairs(entityHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    entityHighlights = {}
    
    -- Cleanup billboards when UI is destroyed
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        for _, v in ipairs(eitem:GetDescendants()) do
            if v.Name == "_MerchantBB" then
                pcall(function() v:Destroy() end)
            end
        end
    end
    if entityfolder then
        for _, v in ipairs(entityfolder:GetDescendants()) do
            if v.Name == "_EntityBB" then
                pcall(function() v:Destroy() end)
            end
        end
    end

    Window:Destroy()
end)

-- Notify loaded
notify("Loaded", "Angels - Cursed Blade Loaded Successfully", 5)

--================================================================
-- UTILITY FUNCTIONS
--================================================================

local function Entity(radius)
    local entity = {}
    if not entityfolder or not hrp then return entity end
    for _, v in ipairs(entityfolder:GetChildren()) do
        local Entityhrp = v:FindFirstChild("HumanoidRootPart")
        local EntityHumanoid = v:FindFirstChild("Humanoid")

        if Entityhrp and EntityHumanoid and EntityHumanoid.Health > 0 then
            if radius == math.huge or (hrp.Position - Entityhrp.Position).Magnitude <= radius then
                entity[#entity+1] = v
            end
        end
    end
    return entity
end

--================================================================
-- HOOK SKILL
--================================================================

local oldnamecall
oldnamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "FireServer" and string.lower(self.Name) == "trigerskill" then
        cachedArg1 = args[1]
    end
    return oldnamecall(self, ...)
end)

--================================================================
-- MERCHANT ESP
--================================================================

local function getMerchants()
    local merchants = {}
    local eitem = workspace:FindFirstChild("EItem")
    if eitem then
        for _, v in ipairs(eitem:GetChildren()) do
            if v.Name == "Merchant" and v:IsA("Model") then
                table.insert(merchants, v)
            end
        end
        local merchantFolder = eitem:FindFirstChild("Merchant")
        if merchantFolder and merchantFolder:IsA("Folder") then
            for _, v in ipairs(merchantFolder:GetChildren()) do
                if v:IsA("Model") then
                    table.insert(merchants, v)
                end
            end
        end
    end
    return merchants
end

local function getOrCreateBillboard(merchant)
    local headPart = merchant:FindFirstChild("Head")
        or merchant:FindFirstChild("HumanoidRootPart")
        or merchant:FindFirstChildWhichIsA("BasePart")
    if not headPart then return end

    local bb = headPart:FindFirstChild("_MerchantBB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "_MerchantBB"
        bb.Size = UDim2.new(0, 120, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Parent = headPart

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = bb
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = bg
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Color = Color3.fromRGB(255, 215, 0)
        bgStroke.Thickness = 1.2
        bgStroke.Parent = bg

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -8, 0.5, 0)
        titleLbl.Position = UDim2.new(0, 4, 0, 2)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "🛒 Merchant"
        titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 13
        titleLbl.TextXAlignment = Enum.TextXAlignment.Center
        titleLbl.Parent = bg

        local distLbl = Instance.new("TextLabel")
        distLbl.Name = "Distance"
        distLbl.Size = UDim2.new(1, -8, 0.5, -2)
        distLbl.Position = UDim2.new(0, 4, 0.5, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "... studs"
        distLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Center
        distLbl.Parent = bg
    end
    return bb
end

local function createHighlight(model)
    if not model:IsA("Model") then return nil end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    return highlight
end

-- Merchant ESP + Billboard label update loop
task.spawn(function()
    local cleanedUp = true
    while IsRunning do
        if features.MerchantESP then
            cleanedUp = false
            local merchants = getMerchants()
            local activeHighlights = {}

            for _, merchant in ipairs(merchants) do
                local existingHighlight = merchant:FindFirstChild("Highlight")
                if existingHighlight then
                    table.insert(activeHighlights, existingHighlight)
                else
                    local newHighlight = createHighlight(merchant)
                    if newHighlight then
                        table.insert(activeHighlights, newHighlight)
                    end
                end

                -- Update billboard distance label
                local bb = getOrCreateBillboard(merchant)
                if bb and hrp then
                    local headPart = bb.Parent
                    if headPart and headPart:IsA("BasePart") then
                        local dist = math.floor((hrp.Position - headPart.Position).Magnitude)
                        local distLbl = bb:FindFirstChild("Frame") and bb.Frame:FindFirstChild("Distance")
                        if distLbl then
                            distLbl.Text = tostring(dist) .. " studs"
                        end
                    end
                end
            end

            -- Remove stale highlights
            for i = #merchantHighlights, 1, -1 do
                local hl = merchantHighlights[i]
                if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
                    pcall(function() if hl then hl:Destroy() end end)
                    table.remove(merchantHighlights, i)
                end
            end
            merchantHighlights = activeHighlights
            task.wait(0.5)
        else
            if not cleanedUp then
                cleanedUp = true
                -- Cleanup highlights
                if #merchantHighlights > 0 then
                    for _, hl in ipairs(merchantHighlights) do
                        pcall(function() if hl then hl:Destroy() end end)
                    end
                    merchantHighlights = {}
                end
                -- Cleanup billboards
                local eitem = workspace:FindFirstChild("EItem")
                if eitem then
                    for _, v in ipairs(eitem:GetDescendants()) do
                        if v.Name == "_MerchantBB" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
end)

--================================================================
-- ENTITY ESP
--================================================================

local function getOrCreateEntityBillboard(entity)
    local headPart = entity:FindFirstChild("Head")
        or entity:FindFirstChild("HumanoidRootPart")
        or entity:FindFirstChildWhichIsA("BasePart")
    if not headPart then return end

    local bb = headPart:FindFirstChild("_EntityBB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "_EntityBB"
        bb.Size = UDim2.new(0, 120, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Parent = headPart

        local bg = Instance.new("Frame")
        bg.Name = "Frame"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
        bg.BackgroundTransparency = 0.3
        bg.BorderSizePixel = 0
        bg.Parent = bb
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = bg
        local bgStroke = Instance.new("UIStroke")
        bgStroke.Color = ThemeColor
        bgStroke.Thickness = 1.2
        bgStroke.Parent = bg

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -8, 0.5, 0)
        titleLbl.Position = UDim2.new(0, 4, 0, 2)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "💀 " .. entity.Name
        titleLbl.TextColor3 = ThemeColor
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Center
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.Parent = bg

        local distLbl = Instance.new("TextLabel")
        distLbl.Name = "Distance"
        distLbl.Size = UDim2.new(1, -8, 0.5, -2)
        distLbl.Position = UDim2.new(0, 4, 0.5, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "... studs"
        distLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        distLbl.Font = Enum.Font.GothamMedium
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Center
        distLbl.Parent = bg
    end
    return bb
end

local function createEntityHighlight(model)
    if not model:IsA("Model") then return nil end
    local highlight = Instance.new("Highlight")
    highlight.Name = "EntityHighlight"
    highlight.Adornee = model
    highlight.FillColor = ThemeColor
    highlight.OutlineColor = ThemeColorDark
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    return highlight
end

task.spawn(function()
    local cleanedUp = true
    while IsRunning do
        if features.EntityESP then
            cleanedUp = false
            local currentEntityFolder = workspace:FindFirstChild("Entity")
            local entities = {}
            if currentEntityFolder then
                for _, v in ipairs(currentEntityFolder:GetChildren()) do
                    if v:IsA("Model") then
                        table.insert(entities, v)
                    end
                end
            end
            local activeEntityHighlights = {}

            for _, entity in ipairs(entities) do
                local existingHighlight = entity:FindFirstChild("EntityHighlight")
                if existingHighlight then
                    table.insert(activeEntityHighlights, existingHighlight)
                else
                    local newHighlight = createEntityHighlight(entity)
                    if newHighlight then
                        table.insert(activeEntityHighlights, newHighlight)
                    end
                end

                -- Update billboard distance label
                local bb = getOrCreateEntityBillboard(entity)
                if bb and hrp and hrp.Parent then
                    local headPart = bb.Parent
                    if headPart and headPart:IsA("BasePart") then
                        local dist = math.floor((hrp.Position - headPart.Position).Magnitude)
                        local frame = bb:FindFirstChild("Frame")
                        local distLbl = frame and frame:FindFirstChild("Distance")
                        if distLbl then
                            distLbl.Text = tostring(dist) .. " studs"
                        end
                    end
                end
            end

            -- Remove stale highlights
            for i = #entityHighlights, 1, -1 do
                local hl = entityHighlights[i]
                if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
                    pcall(function() if hl then hl:Destroy() end end)
                    table.remove(entityHighlights, i)
                end
            end
            entityHighlights = activeEntityHighlights
            task.wait(0.5)
        else
            if not cleanedUp then
                cleanedUp = true
                -- Cleanup highlights
                if #entityHighlights > 0 then
                    for _, hl in ipairs(entityHighlights) do
                        pcall(function() if hl then hl:Destroy() end end)
                    end
                    entityHighlights = {}
                end
                -- Cleanup billboards
                local currentEntityFolder = workspace:FindFirstChild("Entity")
                if currentEntityFolder then
                    for _, v in ipairs(currentEntityFolder:GetDescendants()) do
                        if v.Name == "_EntityBB" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
end)

--================================================================
-- AUTO SELL
--================================================================

task.spawn(function()
    while IsRunning do
        if features.SellAll then
            local args = {
                539767613,
                sellList
            }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
            end)
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

--================================================================
-- AUTO PICKUP
--================================================================

task.spawn(function()
    while IsRunning do
        if features.AutoPickup and hrp then
            local currentLoot = workspace:FindFirstChild("FX") or loot
            if currentLoot then
                for _, touch in ipairs(currentLoot:GetDescendants()) do
                    if not IsRunning or not features.AutoPickup or not hrp then break end
                    if touch:IsA("TouchTransmitter") then
                        local part = touch.Parent
                        if part and part:IsA("BasePart") and hrp and hrp.Parent then
                            pcall(function()
                                firetouchinterest(hrp, part, 0)
                                firetouchinterest(hrp, part, 1)
                            end)
                        end
                    end
                end
            end
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- AUTO FARM + KILL AURA
--================================================================

task.spawn(function()
    while IsRunning do
        if features.AutoFarm and hrp then
            if killAuraToggle then
                killAuraToggle.Set(true)
            end

            if currentTarget then
                local hum = currentTarget:FindFirstChild("Humanoid")
                local hrp2 = currentTarget:FindFirstChild("HumanoidRootPart")

                if not hum or hum.Health <= 0 or not hrp2 then
                    currentTarget = nil
                end
            end

            if not currentTarget then
                local entities = Entity(math.huge) -- No limit for Auto Farm range!

                local closest = nil
                local shortest = math.huge

                for _, v in ipairs(entities) do
                    local targetHRP = v:FindFirstChild("HumanoidRootPart")
                    local targetHum = v:FindFirstChild("Humanoid")

                    if targetHRP and targetHum and targetHum.Health > 0 then
                        local dist = (hrp.Position - targetHRP.Position).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = v
                        end
                    end
                end

                currentTarget = closest
            end

            if currentTarget then
                local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    hrp.CFrame = targetHRP.CFrame * farmOffset
                end
            end
            task.wait()
        else
            currentTarget = nil
            task.wait(0.2)
        end
    end
end)

--================================================================
-- COVER PLAYER
--================================================================

task.spawn(function()
    while IsRunning do
        if features.Cover and hrp and selectedPlayerName then
            local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
            if targetPlayer and targetPlayer.Character then
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    hrp.CFrame = targetHRP.CFrame * farmOffset
                end
            end
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- KILL AURA EXECUTION
--================================================================

local function fireKillAuraEvent(target)
    local currentEvent = getEvent()
    if not currentEvent or not target then return end
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    -- Option A: Serangan di antara player dan target (2 stud lebih dekat ke player) menghadap ke target
    local cf = targetHRP.CFrame
    if hrp then
        local diff = targetHRP.Position - hrp.Position
        local direction = diff.Magnitude > 0.1 and diff.Unit or Vector3.new(0, 0, -1)
        cf = CFrame.lookAt(targetHRP.Position - direction * 2, targetHRP.Position)
    end

    if cachedArg1 then
        if cachedArg1 == 102 then
            -- Bow (102) targets the "Collision" part inside the enemy model
            local hitTarget = target:FindFirstChild("Collision") or targetHRP or target
            currentEvent:FireServer(102, "Atk", hitTarget, {})
        else
            -- Sword (101) & Staff (103) require CFrame
            currentEvent:FireServer(cachedArg1, "Enter", cf, 1)
        end
    else
        -- If cachedArg1 is nil, fire default skills for all known weapons
        local hitTarget = target:FindFirstChild("Collision") or targetHRP or target
        currentEvent:FireServer(101, "Enter", cf, 1)
        currentEvent:FireServer(103, "Enter", cf, 1)
        currentEvent:FireServer(102, "Atk", hitTarget, {})
    end
end

task.spawn(function()
    while IsRunning do
        if features.KillAura and hrp then
            if currentTarget then
                local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                local targetHum = currentTarget:FindFirstChild("Humanoid")

                if targetHRP and targetHum and targetHum.Health > 0 then
                    for i = 1, damageMultiplier do
                        fireKillAuraEvent(currentTarget)
                    end
                end
            else
                local currentRange = killAuraRange
                if features.InfiniteRange then
                    currentRange = math.huge
                end
                local entities = Entity(currentRange)
                
                -- Sort entities by distance to player (closest first)
                table.sort(entities, function(a, b)
                    local aHRP = a:FindFirstChild("HumanoidRootPart")
                    local bHRP = b:FindFirstChild("HumanoidRootPart")
                    if aHRP and bHRP then
                        return (hrp.Position - aHRP.Position).Magnitude < (hrp.Position - bHRP.Position).Magnitude
                    end
                    return false
                end)

                -- Attack up to 10 closest entities
                local attackCount = 0
                for _, v in ipairs(entities) do
                    if attackCount >= 10 then break end
                    local targetHRP = v:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        attackCount = attackCount + 1
                        for i = 1, damageMultiplier do
                            fireKillAuraEvent(v)
                        end
                    end
                end
            end
            task.wait(0.05)
        else
            task.wait(0.2)
        end
    end
end)

--================================================================
-- STATS UPDATE
--================================================================

local frameTimer = tick()
local frameCounter = 0
local fps = 60

local fpsConnection
fpsConnection = RunService.RenderStepped:Connect(function()
    if not IsRunning then
        if fpsConnection then
            fpsConnection:Disconnect()
        end
        return
    end
    frameCounter = frameCounter + 1
    if (tick() - frameTimer) >= 1 then
        fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
        if fpsCtrl then
            fpsCtrl:SetText(tostring(fps))
        end
    end
end)

print("✅ Angels - Cursed Blade LOADED!")
print("🎮 Press G to toggle UI | Drag from title bar")
print("⚔️ Kill Aura | 🚜 Auto Farm | 🛡️ Cover Player | 💰 Auto Pickup")
