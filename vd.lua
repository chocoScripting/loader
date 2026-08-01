loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- FULL NOCLIP WITH TOGGLE GUI
-- =========================
local NoclipEnabled = false
local NoclipConnection = nil

-- Helper: Make Frame Draggable
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

-- Toggle Noclip Function
local function toggleNoclip(enabled)
    NoclipEnabled = enabled
    
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    if enabled then
        NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Re-enable collision
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Create Small Toggle GUI
local function createNoclipGui()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("NoclipGui")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoclipGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Draggable container (no background)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 80, 0, 30)
    container.Position = UDim2.new(0, 20, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    -- Toggle button (no background)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 16
    toggleBtn.TextStrokeTransparency = 0.5
    toggleBtn.Parent = container
    
    -- Make draggable
    makeDraggable(toggleBtn, container)
    
    -- Toggle functionality
    toggleBtn.MouseButton1Click:Connect(function()
        toggleNoclip(not NoclipEnabled)
        if NoclipEnabled then
            toggleBtn.Text = "ON"
            toggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            toggleBtn.Text = "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

createNoclipGui()

local map = workspace:WaitForChild("Map")
local scannedContainers = {}
local function setupGenerator(generator)
    if not generator or not generator:IsA("Model") then return end
    if generator:GetAttribute("GeneratorGuiSetup") then return end
    generator:SetAttribute("GeneratorGuiSetup", true)
    local billboard = generator:FindFirstChild("GeneratorProgressGui")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "GeneratorProgressGui"
        billboard.Adornee = generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart")
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = generator
    end
    local textLabel = billboard:FindFirstChild("ProgressLabel")
    if not textLabel then
        textLabel = Instance.new("TextLabel")
        textLabel.Name = "ProgressLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextStrokeTransparency = 0.7
        textLabel.TextSize = 16
        textLabel.Parent = billboard
    end
    local function updateProgress()
        local rawProgress = generator:GetAttribute("RepairProgress") or 0
        local progress = math.ceil(rawProgress)
        textLabel.Text = "⚙️" .. tostring(progress) .. "%"
        if progress >= 100 then
            textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end
    generator:GetAttributeChangedSignal("RepairProgress"):Connect(updateProgress)
    updateProgress()
end
local function setupExitLever(lever)
    if not lever or not lever:IsA("Model") then return end
    if lever:GetAttribute("ExitLeverGuiSetup") then return end
    lever:SetAttribute("ExitLeverGuiSetup", true)
    local billboard = lever:FindFirstChild("ExitLeverGui")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ExitLeverGui"
        billboard.Adornee = lever.PrimaryPart or lever:FindFirstChildWhichIsA("BasePart")
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = lever
    end
    local textLabel = billboard:FindFirstChild("LeverLabel")
    if not textLabel then
        textLabel = Instance.new("TextLabel")
        textLabel.Name = "LeverLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextStrokeTransparency = 0.7
        textLabel.TextSize = 16
        textLabel.Text = "Lever"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        textLabel.Parent = billboard
    end
end
local function scanGateForLever(gate)
    if not gate or not gate:IsA("Model") then return end
    for _, child in ipairs(gate:GetChildren()) do
        if child:IsA("Model") and child.Name == "ExitLever" then
            setupExitLever(child)
        end
    end
    gate.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child.Name == "ExitLever" then
            setupExitLever(child)
        end
    end)
end
local function scanContainer(container)
    if scannedContainers[container] then return end
    scannedContainers[container] = true
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Model") and child.Name == "Generator" then
            setupGenerator(child)
        elseif child:IsA("Model") and child.Name == "Gate" then
            scanGateForLever(child)
        end
    end
    container.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child.Name == "Generator" then
            setupGenerator(child)
        elseif child:IsA("Model") and child.Name == "Gate" then
            scanGateForLever(child)
        end
    end)
end
scanContainer(map)
for _, child in ipairs(map:GetChildren()) do
    if child:IsA("Folder") then
        scanContainer(child)
    end
end
map.ChildAdded:Connect(function(child)
    if child:IsA("Folder") then
        scanContainer(child)
    elseif child:IsA("Model") then
        if child.Name == "Generator" then
            setupGenerator(child)
        elseif child.Name == "Gate" then
            scanGateForLever(child)
        end
    end
end)
