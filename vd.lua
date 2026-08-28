loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

-- =========================
-- AUTO GENERATOR
-- =========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local function autoGenerator()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local skillCheckGui = playerGui:FindFirstChild("SkillCheckPromptGui")
    
    if not skillCheckGui then return end
    
    local check = skillCheckGui:FindFirstChild("Check")
    if not check then return end
    
    local goal = check:FindFirstChild("Goal")
    local line = check:FindFirstChild("Line")
    
    if not goal or not line then return end
    
    -- Track when Goal's AbsoluteRotation is available (non-zero)
    local targetRotation = nil
    
    -- Monitor Goal's AbsoluteRotation
    goal:GetPropertyChangedSignal("AbsoluteRotation"):Connect(function()
        if goal.AbsoluteRotation ~= 0 then
            targetRotation = goal.AbsoluteRotation
        end
    end)
    
    -- Monitor Line's AbsoluteRotation and fire when it matches target
    line:GetPropertyChangedSignal("AbsoluteRotation"):Connect(function()
        if targetRotation and line.AbsoluteRotation == targetRotation then
            local args = {
                workspace:WaitForChild("Map"):WaitForChild("Generators"):WaitForChild("Generator"):WaitForChild("GeneratorPoint1"),
                true
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("RepairEvent"):FireServer(unpack(args))
            targetRotation = nil -- Reset to prevent multiple fires
        end
    end)
end

-- Start auto generator
autoGenerator()

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
        billboard.StudsOffset = Vector3.new(0, 0, 0)
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
        if progress >= 100 then
            textLabel.Text = "[DONE]"
            textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            textLabel.Text = "[" .. tostring(progress) .. "%]"
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
        textLabel.Text = "[LEVER]"
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
