--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Variables
local IsRunning = true
local AutoCash = false
local AutoCrate = false
local AutoUpgrade = false
local WebhookEnabled = false
local selectedCrates = {}
local selectedUpgrades = {}

--// Drop Webhook Settings
local webhookUrl = "https://discord.com/api/webhooks/1513211154548129863/GEqsaPfRC-HTnhqJDhNClJxhz1_shzRuf-5q_ScxljMqpGmwCO2oTwe3PyG7lo1sfjKR"
local dropHistory = {} -- Max 10 items
local bestDropHistory = {} -- Max 20 items (Mythical+)
local lastProcessed = ""
local lastProcessedTime = 0

--// Lists
local CRATE_LIST    = {"WoodenCrate", "SilverCrate", "GoldenCrate", "DiamondCrate", "RubyCrate"}
local UPGRADE_LIST  = {"BuyCooldown", "BuyMult", "BuyWalkspeed", "BuyMaxTime"}

local TIER_COLORS = {
	["common"] = Color3.fromRGB(170, 170, 170),
	["rare"] = Color3.fromRGB(85, 85, 255),
	["epic"] = Color3.fromRGB(128, 0, 128),
	["legendary"] = Color3.fromRGB(255, 170, 0),
	["mythical"] = Color3.fromRGB(255, 0, 0),
	["exclusive"] = Color3.fromRGB(255, 85, 255)
}

local TIER_DECIMALS = {
	["common"] = 11184810,    -- #aaaaaa
	["rare"] = 5592575,       -- #5555ff
	["epic"] = 8388736,       -- #800080
	["legendary"] = 16755200, -- #ffaa00
	["mythical"] = 16711680,  -- #ff0000
	["exclusive"] = 16733695  -- #ff55ff
}

--// Connection Tracker
local connections = {}
local function safeConnect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(connections, conn)
	return conn
end

--// parentGui
local parentGui = (function()
	local success, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if success and coreGui then return coreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end)()

--// ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LarperUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

-- Notification
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

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = notifFrame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(85, 180, 247); s.Thickness = 1.2; s.Transparency = 0.4; s.Parent = notifFrame

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, -20, 0, 20); tl.Position = UDim2.new(0, 10, 0, 5)
	tl.BackgroundTransparency = 1; tl.Text = title
	tl.TextColor3 = Color3.fromRGB(85, 180, 247); tl.Font = Enum.Font.GothamBold
	tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Parent = notifFrame

	local dl = Instance.new("TextLabel")
	dl.Size = UDim2.new(1, -20, 0, 25); dl.Position = UDim2.new(0, 10, 0, 23)
	dl.BackgroundTransparency = 1; dl.Text = text
	dl.TextColor3 = Color3.fromRGB(230, 230, 230); dl.Font = Enum.Font.GothamMedium
	dl.TextSize = 11; dl.TextXAlignment = Enum.TextXAlignment.Left
	dl.TextWrapped = true; dl.Parent = notifFrame

	notifFrame.Position = UDim2.new(1, 300, 0, 0)
	notifFrame:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	task.delay(duration, function()
		pcall(function()
			if not screenGui or not screenGui.Parent then return end
			notifFrame:TweenPosition(UDim2.new(1, 300, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.2, true, function()
				pcall(function() notifFrame:Destroy() end)
			end)
		end)
	end)
end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mfc = Instance.new("UICorner"); mfc.CornerRadius = UDim.new(0, 12); mfc.Parent = mainFrame
local mfs = Instance.new("UIStroke"); mfs.Color = Color3.fromRGB(85, 180, 247); mfs.Thickness = 1.5; mfs.Transparency = 0.3; mfs.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(85, 180, 247)
titleBar.TextColor3 = Color3.fromRGB(15, 15, 20)
titleBar.Text = "💰 Larper - Autofarm"
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Active = true
titleBar.Parent = mainFrame

local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 12); tbc.Parent = titleBar
local tbg = Instance.new("UIGradient")
tbg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 180, 247)), ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 130, 210))})
tbg.Rotation = 90; tbg.Parent = titleBar

local tbo = Instance.new("Frame")
tbo.Size = UDim2.new(1, 0, 0, 6); tbo.Position = UDim2.new(0, 0, 1, -6)
tbo.BackgroundColor3 = Color3.fromRGB(58, 130, 210); tbo.BorderSizePixel = 0; tbo.Parent = titleBar

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
padding.PaddingTop = UDim.new(0, 10); padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 15); padding.PaddingRight = UDim.new(0, 15)
padding.Parent = contentFrame

-- Draggable
local function makeDraggable(dragPart, mainPart)
	local dragging, dragInput, dragStart, startPos = false
	local function update(i) mainPart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+(i.Position-dragStart).X, startPos.Y.Scale, startPos.Y.Offset+(i.Position-dragStart).Y) end
	safeConnect(dragPart.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = i.Position; startPos = mainPart.Position
			safeConnect(i.Changed, function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	safeConnect(dragPart.InputChanged, function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
	end)
	safeConnect(UserInputService.InputChanged, function(i)
		if i == dragInput and dragging then update(i) end
	end)
end
makeDraggable(titleBar, mainFrame)

local isVisible = true
safeConnect(UserInputService.InputBegan, function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then isVisible = not isVisible; mainFrame.Visible = isVisible end
end)

-- Toggle Helper
local function createToggle(parent, text, defaultValue, callback)
	local row = Instance.new("Frame")
	row.Name = text.."Row"; row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundTransparency = 1; row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(230, 230, 230); lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

	local sw = Instance.new("TextButton")
	sw.Size = UDim2.new(0, 42, 0, 20); sw.Position = UDim2.new(1, -42, 0.5, -10)
	sw.BackgroundColor3 = defaultValue and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(45, 45, 55)
	sw.Text = ""; sw.AutoButtonColor = false; sw.Parent = row

	local swc = Instance.new("UICorner"); swc.CornerRadius = UDim.new(1, 0); swc.Parent = sw
	local sws = Instance.new("UIStroke"); sws.Color = defaultValue and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(80, 80, 90); sws.Thickness = 1; sws.Parent = sw

	local ci = Instance.new("Frame")
	ci.Size = UDim2.new(0, 14, 0, 14); ci.Position = defaultValue and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	ci.BackgroundColor3 = Color3.fromRGB(255, 255, 255); ci.BorderSizePixel = 0; ci.Parent = sw
	local cic = Instance.new("UICorner"); cic.CornerRadius = UDim.new(1, 0); cic.Parent = ci

	local state = defaultValue
	local function upd()
		if state then
			sw.BackgroundColor3 = Color3.fromRGB(85, 180, 247); sws.Color = Color3.fromRGB(85, 180, 247)
			ci:TweenPosition(UDim2.new(1, -17, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		else
			sw.BackgroundColor3 = Color3.fromRGB(45, 45, 55); sws.Color = Color3.fromRGB(80, 80, 90)
			ci:TweenPosition(UDim2.new(0, 3, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		end
	end
	safeConnect(sw.MouseButton1Click, function() state = not state; upd(); callback(state) end)
	return row
end

-- Button Helper
local function createButton(parent, text, callback)
	local bf = Instance.new("Frame")
	bf.Name = text.."Frame"; bf.Size = UDim2.new(1, 0, 0, 40); bf.BackgroundTransparency = 1; bf.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30); btn.Position = UDim2.new(0, 0, 0.5, -15)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); btn.TextColor3 = Color3.fromRGB(85, 180, 247)
	btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.BorderSizePixel = 0; btn.Parent = bf

	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(80, 80, 90); bs.Thickness = 1; bs.Parent = btn

	safeConnect(btn.MouseButton1Click, function() callback() end)
	safeConnect(btn.MouseEnter, function() btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65); bs.Color = Color3.fromRGB(85, 180, 247) end)
	safeConnect(btn.MouseLeave, function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); bs.Color = Color3.fromRGB(80, 80, 90) end)
	return bf
end

--// Generic Multi-Select Dropdown with Search
local function createMultiDropdown(itemList, selectedTable, overlayLabel, btnLabelPrefix, zBase)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, -38); overlay.Position = UDim2.new(0, 0, 0, 38)
	overlay.BackgroundColor3 = Color3.fromRGB(15, 15, 20); overlay.BorderSizePixel = 0
	overlay.Visible = false; overlay.Active = true; overlay.ZIndex = zBase; overlay.Parent = mainFrame

	local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 12); oc.Parent = overlay

	local otl = Instance.new("TextLabel")
	otl.Size = UDim2.new(1, -40, 0, 30); otl.Position = UDim2.new(0, 15, 0, 5)
	otl.BackgroundTransparency = 1; otl.Text = overlayLabel
	otl.TextColor3 = Color3.fromRGB(85, 180, 247); otl.Font = Enum.Font.GothamBold
	otl.TextSize = 13; otl.TextXAlignment = Enum.TextXAlignment.Left; otl.ZIndex = zBase+1; otl.Parent = overlay

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -35, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
	closeBtn.Text = "X"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12
	closeBtn.ZIndex = zBase+1; closeBtn.Parent = overlay
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = closeBtn
	safeConnect(closeBtn.MouseButton1Click, function() overlay.Visible = false end)

	-- Search row
	local searchRow = Instance.new("Frame")
	searchRow.Size = UDim2.new(1, -30, 0, 28); searchRow.Position = UDim2.new(0, 15, 0, 38)
	searchRow.BackgroundColor3 = Color3.fromRGB(30, 30, 38); searchRow.BorderSizePixel = 0
	searchRow.ZIndex = zBase+1; searchRow.Parent = overlay
	local src = Instance.new("UICorner"); src.CornerRadius = UDim.new(0, 8); src.Parent = searchRow
	local srs = Instance.new("UIStroke"); srs.Color = Color3.fromRGB(60, 60, 75); srs.Thickness = 1; srs.Parent = searchRow

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -30, 1, 0); searchBox.Position = UDim2.new(0, 8, 0, 0)
	searchBox.BackgroundTransparency = 1; searchBox.Text = ""; searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110); searchBox.TextColor3 = Color3.fromRGB(230, 230, 230)
	searchBox.Font = Enum.Font.GothamMedium; searchBox.TextSize = 12
	searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false
	searchBox.ZIndex = zBase+2; searchBox.Parent = searchRow

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 22, 0, 22); clearBtn.Position = UDim2.new(1, -24, 0.5, -11)
	clearBtn.BackgroundTransparency = 1; clearBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
	clearBtn.Text = "✕"; clearBtn.Font = Enum.Font.GothamBold; clearBtn.TextSize = 12
	clearBtn.ZIndex = zBase+3; clearBtn.Parent = searchRow

	safeConnect(searchBox.Focused, function() srs.Color = Color3.fromRGB(85, 180, 247) end)
	safeConnect(searchBox.FocusLost, function() srs.Color = Color3.fromRGB(60, 60, 75) end)

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -30, 1, -76); scroll.Position = UDim2.new(0, 15, 0, 72)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = Color3.fromRGB(85, 180, 247)
	scroll.Active = true; scroll.ZIndex = zBase+1; scroll.Parent = overlay

	local sl = Instance.new("UIListLayout"); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Padding = UDim.new(0, 5); sl.Parent = scroll
	safeConnect(sl:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, sl.AbsoluteContentSize.Y + 10)
	end)

	local btnRef = {btn = nil}
	local function getCount()
		local n = 0
		for _, v in pairs(selectedTable) do if v then n = n + 1 end end
		return n
	end
	local function updateBtn()
		if btnRef.btn then
			btnRef.btn.Text = btnLabelPrefix .. " [" .. getCount() .. " Selected]"
		end
	end

	local rowInsts = {}
	local function buildRows(filter)
		filter = (filter or ""):lower()
		for _, inst in ipairs(rowInsts) do pcall(function() inst:Destroy() end) end
		rowInsts = {}

		for i, name in ipairs(itemList) do
			if filter == "" or name:lower():find(filter, 1, true) then
				local row = Instance.new("Frame")
				row.LayoutOrder = i; row.Size = UDim2.new(1, -4, 0, 30)
				row.BackgroundColor3 = selectedTable[name] and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(45, 45, 55)
				row.BorderSizePixel = 0; row.ZIndex = zBase+2; row.Parent = scroll
				table.insert(rowInsts, row)

				local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
				local rs = Instance.new("UIStroke")
				rs.Color = selectedTable[name] and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(70, 70, 80)
				rs.Thickness = 1; rs.Parent = row

				local lbl = Instance.new("TextButton")
				lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
				lbl.Text = "  " .. name
				lbl.TextColor3 = selectedTable[name] and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(230, 230, 230)
				lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
				lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = zBase+3; lbl.Parent = row

				local cn = name
				safeConnect(lbl.MouseButton1Click, function()
					selectedTable[cn] = not selectedTable[cn]
					local sel = selectedTable[cn]
					row.BackgroundColor3 = sel and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(45, 45, 55)
					rs.Color = sel and Color3.fromRGB(85, 180, 247) or Color3.fromRGB(70, 70, 80)
					lbl.TextColor3 = sel and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(230, 230, 230)
					updateBtn()
				end)
			end
		end
	end

	safeConnect(searchBox:GetPropertyChangedSignal("Text"), function() buildRows(searchBox.Text) end)
	safeConnect(clearBtn.MouseButton1Click, function() searchBox.Text = ""; buildRows("") end)

	local function createDropdownButton(parent)
		local row = Instance.new("Frame")
		row.Name = overlayLabel.."DropRow"; row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundTransparency = 1; row.Parent = parent

		local dbtn = Instance.new("TextButton")
		dbtn.Size = UDim2.new(1, 0, 0, 30); dbtn.Position = UDim2.new(0, 0, 0.5, -15)
		dbtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); dbtn.TextColor3 = Color3.fromRGB(230, 230, 230)
		dbtn.Text = btnLabelPrefix .. " [0 Selected]"
		dbtn.Font = Enum.Font.GothamBold; dbtn.TextSize = 12; dbtn.BorderSizePixel = 0; dbtn.Parent = row
		btnRef.btn = dbtn

		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = dbtn
		local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(80, 80, 90); bs.Thickness = 1; bs.Parent = dbtn

		safeConnect(dbtn.MouseButton1Click, function()
			overlay.Visible = true; buildRows(searchBox.Text)
		end)
		safeConnect(dbtn.MouseEnter, function() bs.Color = Color3.fromRGB(85, 180, 247) end)
		safeConnect(dbtn.MouseLeave, function() bs.Color = Color3.fromRGB(80, 80, 90) end)

		return row
	end

	return overlay, createDropdownButton, buildRows
end

--// Build Dropdowns
local _, createCrateDropdownBtn, _    = createMultiDropdown(CRATE_LIST,   selectedCrates,   "Select Crates",   "Select Crates",   10)
local _, createUpgradeDropdownBtn, _  = createMultiDropdown(UPGRADE_LIST, selectedUpgrades, "Select Upgrades", "Select Upgrades", 20)

--// Build Controls
createToggle(contentFrame, "Auto Cash", false, function(value)
	AutoCash = value; notify("Auto Cash", value and "Enabled" or "Disabled", 3)
end)

createCrateDropdownBtn(contentFrame)

createToggle(contentFrame, "Auto Crate", false, function(value)
	AutoCrate = value; notify("Auto Crate", value and "Enabled" or "Disabled", 3)
end)

createUpgradeDropdownBtn(contentFrame)

createToggle(contentFrame, "Auto Upgrade", false, function(value)
	AutoUpgrade = value; notify("Auto Upgrade", value and "Enabled" or "Disabled", 3)
end)

createToggle(contentFrame, "Webhook Drops", false, function(value)
	WebhookEnabled = value; notify("Webhook Drops", value and "Enabled" or "Disabled", 3)
end)

createButton(contentFrame, "Destroy GUI", function()
	IsRunning = false; AutoCash = false; AutoCrate = false; AutoUpgrade = false; WebhookEnabled = false
	for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
	connections = {}
	screenGui:Destroy()
end)

notify("Loaded", "Larper Autofarm Loaded Successfully", 5)

--// Webhook State & Sender Function
local webhookMessageId = nil
local isSendingWebhook = false
local pendingWebhookUpdate = false

local function sendWebhook()
	if not WebhookEnabled or webhookUrl == "" then return end
	if isSendingWebhook then
		pendingWebhookUpdate = true
		return
	end
	isSendingWebhook = true

	task.spawn(function()
		while true do
			pendingWebhookUpdate = false

			-- Build Best Drops (Mythical+) field value
			local bestDescription = ""
			for i, drop in ipairs(bestDropHistory) do
	
			end
			if bestDescription == "" then bestDescription = "None yet." end

			-- Build Recent Drops field value
			local recentDescription = ""
			for i, drop in ipairs(dropHistory) do
				recentDescription = recentDescription .. string.format("%d. %s [%s] <t:%d:R>\n", i, drop.name, drop.tier:upper(), drop.timestamp)
			end
			if recentDescription == "" then recentDescription = "None yet." end

			local latestColor = 5592575 -- default blue
			if #dropHistory > 0 then
				local latestTier = dropHistory[#dropHistory].tier:lower()
				for rawTier, dec in pairs(TIER_DECIMALS) do
					if latestTier:find(rawTier, 1, true) then
						latestColor = dec
						break
					end
				end
			end

			local http = http_request or request or (http and http.request) or syn.request
			if not http then break end

			local payload = game:GetService("HttpService"):JSONEncode({
				embeds = {
					{
						title = "🎒 Larper - Drop History Tracker",
						color = latestColor,
						fields = {
							{
								name = "🏆 Best Drops (Mythical+)",
								value = bestDescription,
								inline = false
							},
							{
								name = "🎒 Recent 10 Drops",
								value = recentDescription,
								inline = false
							}
						},
						timestamp = DateTime.now():ToIsoDate()
					}
				}
			})

			local success = false
			pcall(function()
				if webhookMessageId then
					-- Edit the existing message using PATCH
					local url = webhookUrl .. "/messages/" .. webhookMessageId
					local res = http({
						Url = url,
						Method = "PATCH",
						Headers = { ["Content-Type"] = "application/json" },
						Body = payload
					})

					if res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then
						success = true
					else
						-- Message was probably deleted or invalid, reset ID so we create a new one next time
						webhookMessageId = nil
					end
				else
					-- Create a new message using POST (with wait=true to get the message ID back)
					local url = webhookUrl .. "?wait=true"
					local res = http({
						Url = url,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = payload
					})

					if res and res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 and res.Body then
						local data = game:GetService("HttpService"):JSONDecode(res.Body)
						if data and data.id then
							webhookMessageId = data.id
							success = true
						end
					end
				end
			end)

			-- If another update was requested while we were sending, loop again
			if not pendingWebhookUpdate then
				break
			end
			task.wait(0.5) -- Cool down to avoid Discord rate limits
		end
		isSendingWebhook = false
	end)
end

--// Add Drop Handler
local function addDrop(name, tier, isDuplicate)
	local tierStr = tier or "unknown"
	if isDuplicate then
		tierStr = tierStr .. ", duplicate"
	end

	local dropInfo = {
		name = name,
		tier = tierStr,
		timestamp = os.time()
	}

	-- Add to Recent 10 Drops
	if #dropHistory >= 10 then
		table.remove(dropHistory, 1)
	end
	table.insert(dropHistory, dropInfo)

	-- Add to Best Drops (Mythical+) (max 20 items)
	local lowerTier = (tier or ""):lower()
	if lowerTier == "mythical" or lowerTier == "exclusive" then
		if #bestDropHistory >= 20 then
			table.remove(bestDropHistory, 1)
		end
		table.insert(bestDropHistory, dropInfo)
	end

	sendWebhook()
end

--// Deduplicated Process Drop
local function processDrop(name, tier, isDuplicate)
	local now = os.clock()
	local identifier = name .. "_" .. tostring(tier) .. "_" .. tostring(isDuplicate)
	if identifier == lastProcessed and (now - lastProcessedTime) < 3 then
		return
	end
	lastProcessed = identifier
	lastProcessedTime = now
	addDrop(name, tier, isDuplicate)
end

--// Hook: Listen directly to ReplicatedStorage CrateRemote OnClientEvent
-- Hook 2 was removed because Hook 1 is 100% reliable and Hook 2 caused double triggers due to tier mismatch/parsing.
task.spawn(function()
	pcall(function()
		local crateRemote = game:GetService("ReplicatedStorage"):WaitForChild("CrateRemote", 10)
		if crateRemote then
			safeConnect(crateRemote.OnClientEvent, function(p16, p17, p18, p19)
				if p16 == "ShowDrop" then
					processDrop(p17, p18, p19)
				end
			end)
		end
	end)
end)

--// Auto Cash Loop
task.spawn(function()
	while IsRunning do
		task.wait(0.05)
		if AutoCash then
			pcall(function()
				local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
				local ui = playerGui and playerGui:FindFirstChild("UI")
				local hud = ui and ui:FindFirstChild("Hud")
				local centerBottom = hud and hud:FindFirstChild("CenterBottom")
				local btn = centerBottom and centerBottom:FindFirstChild("ActivateButton")
				if btn then
					if firesignal then
						firesignal(btn.MouseButton1Click)
						firesignal(btn.Activated)
					elseif getconnections then
						for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
							conn:Fire()
						end
						for _, conn in ipairs(getconnections(btn.Activated)) do
							conn:Fire()
						end
					end
				end
			end)
		end
	end
end)

--// Auto Crate Loop
task.spawn(function()
	local crateRemote
	while IsRunning do
		task.wait(0.1)
		if AutoCrate then
			pcall(function()
				if not crateRemote then crateRemote = game:GetService("ReplicatedStorage"):WaitForChild("CrateRemote") end
				for name, sel in pairs(selectedCrates) do
					if sel and IsRunning then pcall(function() crateRemote:FireServer(name) end) end
				end
			end)
		end
	end
end)

--// Auto Upgrade Loop
task.spawn(function()
	local shopRemote
	while IsRunning do
		task.wait(0.1)
		if AutoUpgrade then
			pcall(function()
				if not shopRemote then shopRemote = game:GetService("ReplicatedStorage"):WaitForChild("Shop") end
				for name, sel in pairs(selectedUpgrades) do
					if sel and IsRunning then pcall(function() shopRemote:FireServer(name) end) end
				end
			end)
		end
	end
end)
