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
screenGui.Name = "SellLemonsUI"
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
	notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	notifFrame.BackgroundTransparency = 0.05
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notificationContainer

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notifFrame

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = Color3.fromRGB(253, 218, 13)
	notifStroke.Thickness = 1.2
	notifStroke.Transparency = 0.4
	notifStroke.Parent = notifFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(253, 218, 13)
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

-- Check Tycoon
if not userTycoon then
	notify("Error", "Tycoon not found! Script stopped.", 5)
	task.wait(5)
	screenGui:Destroy()
	return
end

-- Main Frame (Draggable)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 270)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -135)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 12)
mainFrameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Color = Color3.fromRGB(253, 218, 13)
mainFrameStroke.Thickness = 1.5
mainFrameStroke.Transparency = 0.3
mainFrameStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(253, 218, 13)
titleBar.TextColor3 = Color3.fromRGB(15, 15, 20)
titleBar.Text = "🍋 Sell Lemons - Autofarm"
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Active = true
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 218, 13)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 170, 10)),
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

-- Overlay to cover the bottom rounded corners of the title bar
local titleBarOverlay = Instance.new("Frame")
titleBarOverlay.Name = "TitleBarOverlay"
titleBarOverlay.Size = UDim2.new(1, 0, 0, 6)
titleBarOverlay.Position = UDim2.new(0, 0, 1, -6)
titleBarOverlay.BackgroundColor3 = Color3.fromRGB(220, 170, 10)
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
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.Size = UDim2.new(0, 42, 0, 20)
	switch.Position = UDim2.new(1, -42, 0.5, -10)
	switch.BackgroundColor3 = defaultValue and Color3.fromRGB(253, 218, 13) or Color3.fromRGB(45, 45, 55)
	switch.Text = ""
	switch.AutoButtonColor = false
	switch.Parent = row

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch

	local switchStroke = Instance.new("UIStroke")
	switchStroke.Color = defaultValue and Color3.fromRGB(253, 218, 13) or Color3.fromRGB(80, 80, 90)
	switchStroke.Thickness = 1
	switchStroke.Parent = switch

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(0, 14, 0, 14)
	circle.Position = defaultValue and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = switch

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local state = defaultValue

	local function updateVisuals()
		if state then
			switch.BackgroundColor3 = Color3.fromRGB(253, 218, 13)
			switchStroke.Color = Color3.fromRGB(253, 218, 13)
			circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		else
			switch.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			switchStroke.Color = Color3.fromRGB(80, 80, 90)
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		end
	end

	switch.MouseButton1Click:Connect(function()
		state = not state
		updateVisuals()
		callback(state)
	end)

	return row
end

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
	button.TextColor3 = Color3.fromRGB(253, 218, 13)
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

	button.MouseButton1Click:Connect(function()
		callback()
	end)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
		btnStroke.Color = Color3.fromRGB(253, 218, 13)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btnStroke.Color = Color3.fromRGB(80, 80, 90)
	end)

	return btnFrame
end

-- Build Controls
createToggle(contentFrame, "Auto Buy", false, function(value)
	AutoBuy = value
	notify("Auto Buy", value and "Enabled" or "Disabled", 3)
end)

createToggle(contentFrame, "Auto Upgrade", false, function(value)
	AutoUpgrade = value
	notify("Auto Upgrade", value and "Enabled" or "Disabled", 3)
end)

createToggle(contentFrame, "Auto Fruit", false, function(value)
	AutoFruit = value
	notify("Auto Fruit", value and "Enabled" or "Disabled", 3)
end)

createToggle(contentFrame, "Auto Income", false, function(value)
	AutoIncome = value
	notify("Auto Income", value and "Enabled" or "Disabled", 3)
end)

createButton(contentFrame, "Destroy GUI", function()
	IsRunning = false
	AutoBuy = false
	AutoUpgrade = false
	AutoFruit = false
	AutoIncome = false
	screenGui:Destroy()
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

local function collectFruit(tree)
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local fruitsToCollect = {}
	for _, obj in ipairs(tree:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Fruit" then
			local clickPart = obj:FindFirstChild("ClickPart")
			if clickPart then
				local detector = clickPart:FindFirstChildOfClass("ClickDetector")
				if detector then
					table.insert(fruitsToCollect, detector)
				end
			end
		end
	end

	if #fruitsToCollect > 0 then
		local originalCFrame = hrp.CFrame
		local camera = workspace.CurrentCamera
		local oldCameraType = camera.CameraType
		local oldCameraCFrame = camera.CFrame

		pcall(function()
			-- Kunci kamera agar layar pemain tidak bergerak/jitter sama sekali
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = oldCameraCFrame

			-- Teleport karakter ke pohon
			hrp.CFrame = tree:GetPivot() + Vector3.new(0, 5, 0)
			task.wait(0.1)

			-- Klik semua buah
			for _, detector in ipairs(fruitsToCollect) do
				if not IsRunning or not AutoFruit then break end
				fireclickdetector(detector)
			end

			task.wait(0.05)
			-- Kembalikan karakter ke posisi awal
			hrp.CFrame = originalCFrame
		end)

		-- Kembalikan kontrol kamera ke semula
		pcall(function()
			camera.CameraType = oldCameraType
		end)
	end
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
		task.wait(3)

		if AutoFruit then

			for _, tree in ipairs(Trees) do

				if not AutoFruit or not IsRunning then
					break
				end

				if tree and tree.Parent then

					pcall(function()
						collectFruit(tree)
					end)
				end
			end
		end
	end
end)

-- Clean connections when script is destroyed
task.spawn(function()
	while IsRunning do
		task.wait(1)
	end
	connAdded:Disconnect()
	connRemoving:Disconnect()
end)