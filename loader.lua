-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- STATE CONTROLS
local IsRunning = true
local selectedScript = nil

-- THEME CONFIGURATION (Crimson Red matching Cursed Blade)
local ThemeColor = Color3.fromRGB(255, 75, 75)
local ThemeColorDark = Color3.fromRGB(200, 40, 40)

-- Connection Tracker
local connections = {}
local function safeConnect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(connections, conn)
	return conn
end

-- Parent GUI Choice (CoreGui or PlayerGui)
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
-- CREATE SCREEN GUI
--================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AngelsLoaderUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notificationContainer

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notifFrame

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = ThemeColor
	notifStroke.Thickness = 1.2
	notifStroke.Transparency = 0.4
	notifStroke.Parent = notifFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = ThemeColor
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

-- Main Frame (Draggable)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 190)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -95)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 12)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = ThemeColor
mainFrameStroke.Thickness = 1.5
mainFrameStroke.Transparency = 0.3
mainFrameStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = ThemeColor
titleBar.TextColor3 = Color3.fromRGB(15, 15, 20)
titleBar.Text = "🚀 Angels - Loader"
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Active = true
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ThemeColor),
	ColorSequenceKeypoint.new(1, ThemeColorDark),
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

-- Overlay to cover the bottom rounded corners of the title bar
local titleBarOverlay = Instance.new("Frame")
titleBarOverlay.Name = "TitleBarOverlay"
titleBarOverlay.Size = UDim2.new(1, 0, 0, 6)
titleBarOverlay.Position = UDim2.new(0, 0, 1, -6)
titleBarOverlay.BackgroundColor3 = ThemeColorDark
titleBarOverlay.BorderSizePixel = 0
titleBarOverlay.Parent = titleBar

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -38)
contentFrame.Position = UDim2.new(0, 0, 0, 38)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = contentFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)
padding.Parent = contentFrame

-- Draggable Functionality
local function makeDraggable(dragPart, mainPart)
	local dragging, dragInput, dragStart, startPos = false
	local function update(input)
		local delta = input.Position - dragStart
		mainPart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	safeConnect(dragPart.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainPart.Position

			safeConnect(input.Changed, function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	safeConnect(dragPart.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	safeConnect(UserInputService.InputChanged, function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

makeDraggable(titleBar, mainFrame)

-- Toggle Hide UI using G
local isVisible = true
safeConnect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		isVisible = not isVisible
		mainFrame.Visible = isVisible
	end
end)

-- Component Helper Functions
local function createButton(parent, text, callback)
	local btnFrame = Instance.new("Frame")
	btnFrame.Name = text .. "Frame"
	btnFrame.Size = UDim2.new(1, 0, 0, 40)
	btnFrame.BackgroundTransparency = 1
	btnFrame.Parent = parent

	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.new(1, 0, 0, 30)
	button.Position = UDim2.new(0, 0, 0.5, -15)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	button.TextColor3 = ThemeColor
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.BorderSizePixel = 0
	button.Parent = btnFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(80, 80, 90)
	btnStroke.Thickness = 1
	btnStroke.Parent = button

	safeConnect(button.MouseButton1Click, callback)

	safeConnect(button.MouseEnter, function()
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
		btnStroke.Color = ThemeColor
	end)

	safeConnect(button.MouseLeave, function()
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btnStroke.Color = Color3.fromRGB(80, 80, 90)
	end)

	return btnFrame
end

-- Single-Select Dropdown with Search
local function createDropdown(scriptList, overlayLabel, btnLabelPrefix)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, -38)
	overlay.Position = UDim2.new(0, 0, 0, 38)
	overlay.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 10
	overlay.Parent = mainFrame

	local oc = Instance.new("UICorner")
	oc.CornerRadius = UDim.new(0, 12)
	oc.Parent = overlay

	local otl = Instance.new("TextLabel")
	otl.Size = UDim2.new(1, -40, 0, 30)
	otl.Position = UDim2.new(0, 15, 0, 5)
	otl.BackgroundTransparency = 1
	otl.Text = overlayLabel
	otl.TextColor3 = ThemeColor
	otl.Font = Enum.Font.GothamBold
	otl.TextSize = 13
	otl.TextXAlignment = Enum.TextXAlignment.Left
	otl.ZIndex = 11
	otl.Parent = overlay

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -35, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.ZIndex = 11
	closeBtn.Parent = overlay
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = closeBtn
	safeConnect(closeBtn.MouseButton1Click, function() overlay.Visible = false end)

	-- Search row
	local searchRow = Instance.new("Frame")
	searchRow.Size = UDim2.new(1, -30, 0, 28)
	searchRow.Position = UDim2.new(0, 15, 0, 38)
	searchRow.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	searchRow.BorderSizePixel = 0
	searchRow.ZIndex = 11
	searchRow.Parent = overlay
	local src = Instance.new("UICorner")
	src.CornerRadius = UDim.new(0, 8)
	src.Parent = searchRow
	local srs = Instance.new("UIStroke")
	srs.Color = Color3.fromRGB(60, 60, 75)
	srs.Thickness = 1
	srs.Parent = searchRow

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -30, 1, 0)
	searchBox.Position = UDim2.new(0, 8, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Text = ""
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
	searchBox.TextColor3 = Color3.fromRGB(230, 230, 230)
	searchBox.Font = Enum.Font.GothamMedium
	searchBox.TextSize = 12
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.ZIndex = 12
	searchBox.Parent = searchRow

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 22, 0, 22)
	clearBtn.Position = UDim2.new(1, -24, 0.5, -11)
	clearBtn.BackgroundTransparency = 1
	clearBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
	clearBtn.Text = "✕"
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 12
	clearBtn.ZIndex = 13
	clearBtn.Parent = searchRow

	safeConnect(searchBox.Focused, function() srs.Color = ThemeColor end)
	safeConnect(searchBox.FocusLost, function() srs.Color = Color3.fromRGB(60, 60, 75) end)

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -30, 1, -76)
	scroll.Position = UDim2.new(0, 15, 0, 72)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = ThemeColor
	scroll.Active = true
	scroll.ZIndex = 11
	scroll.Parent = overlay

	local sl = Instance.new("UIListLayout")
	sl.SortOrder = Enum.SortOrder.LayoutOrder
	sl.Padding = UDim.new(0, 5)
	sl.Parent = scroll
	safeConnect(sl:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, sl.AbsoluteContentSize.Y + 10)
	end)

	local btnRef = {btn = nil}
	local function updateBtn()
		if btnRef.btn then
			if selectedScript then
				btnRef.btn.Text = btnLabelPrefix .. ": " .. selectedScript.Name
			else
				btnRef.btn.Text = "Select Script"
			end
		end
	end

	local rowInsts = {}
	local function buildRows(filter)
		filter = (filter or ""):lower()
		for _, inst in ipairs(rowInsts) do pcall(function() inst:Destroy() end) end
		rowInsts = {}

		for i, scriptObj in ipairs(scriptList) do
			local name = scriptObj.Name
			if filter == "" or name:lower():find(filter, 1, true) then
				local isSelected = (selectedScript == scriptObj)
				local row = Instance.new("Frame")
				row.LayoutOrder = i
				row.Size = UDim2.new(1, -4, 0, 30)
				row.BackgroundColor3 = isSelected and ThemeColor or Color3.fromRGB(45, 45, 55)
				row.BorderSizePixel = 0
				row.ZIndex = 12
				row.Parent = scroll
				table.insert(rowInsts, row)

				local rc = Instance.new("UICorner")
				rc.CornerRadius = UDim.new(0, 6)
				rc.Parent = row
				local rs = Instance.new("UIStroke")
				rs.Color = isSelected and ThemeColor or Color3.fromRGB(70, 70, 80)
				rs.Thickness = 1
				rs.Parent = row

				local lbl = Instance.new("TextButton")
				lbl.Size = UDim2.new(1, 0, 1, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = "  " .. name
				lbl.TextColor3 = isSelected and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(230, 230, 230)
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 11
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 13
				lbl.Parent = row

				safeConnect(lbl.MouseButton1Click, function()
					selectedScript = scriptObj
					updateBtn()
					overlay.Visible = false
				end)
			end
		end
	end

	safeConnect(searchBox:GetPropertyChangedSignal("Text"), function() buildRows(searchBox.Text) end)
	safeConnect(clearBtn.MouseButton1Click, function() searchBox.Text = ""; buildRows("") end)

	local function createDropdownButton(parent)
		local row = Instance.new("Frame")
		row.Name = overlayLabel .. "DropRow"
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundTransparency = 1
		row.Parent = parent

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 30)
		dbtn.Position = UDim2.new(0, 0, 0.5, -15)
		dbtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		dbtn.TextColor3 = Color3.fromRGB(230, 230, 230)
		dbtn.Text = "Select Script"
		dbtn.Font = Enum.Font.GothamBold
		dbtn.TextSize = 12
		dbtn.BorderSizePixel = 0
		dbtn.Parent = row
		btnRef.btn = dbtn

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 8)
		bc.Parent = dbtn
		local bs = Instance.new("UIStroke")
		bs.Color = Color3.fromRGB(80, 80, 90)
		bs.Thickness = 1
		bs.Parent = dbtn

		safeConnect(dbtn.MouseButton1Click, function()
			overlay.Visible = true
			buildRows(searchBox.Text)
		end)

		safeConnect(dbtn.MouseEnter, function() bs.Color = ThemeColor end)
		safeConnect(dbtn.MouseLeave, function() bs.Color = Color3.fromRGB(80, 80, 90) end)

		return row
	end

	return overlay, createDropdownButton, buildRows
end

-- Scripts Configuration
local scriptList = {
	{
		Name = "Cursed Blade",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/cblade.lua"
	},
	{
		Name = "Sell Lemons",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/lemon.lua"
	},
	{
		Name = "Larping",
		Url = "https://raw.githubusercontent.com/chocoScripting/loader/refs/heads/main/larp.lua"
	}
}

-- Build UI Elements
local _, createScriptDropdownBtn, _ = createDropdown(scriptList, "Select Script", "Script")
createScriptDropdownBtn(contentFrame)

createButton(contentFrame, "Load Script", function()
	if not selectedScript then
		notify("Warning", "Please select a script from the dropdown first!", 3)
		return
	end

	notify("Loader", "Loading " .. selectedScript.Name .. "...", 3)
	task.spawn(function()
		local success, err = pcall(function()
			loadstring(game:HttpGet(selectedScript.Url))()
		end)

		if success then
			notify("Success", selectedScript.Name .. " loaded successfully!", 3)
		else
			notify("Error", "Failed to load " .. selectedScript.Name .. ": " .. tostring(err), 5)
			warn("Loader Error: " .. tostring(err))
		end
	end)
end)

createButton(contentFrame, "Destroy GUI", function()
	IsRunning = false
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	connections = {}
	screenGui:Destroy()
end)

-- Initial loaded notification
notify("Loaded", "Angels Loader successfully initialized!", 5)
print("✅ Angels - Loader LOADED!")
print("🎮 Press G to toggle UI | Drag from title bar")
