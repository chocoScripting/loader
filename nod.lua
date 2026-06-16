-- Services
local Players = game:GetService("Players")

-- Konfigurasi
local TARGET_ATTRIBUTE = "LivesGiven"
local ALT_TARGET_ATTRIBUTE = "livesgiven"
local ESP_NAME = "LivesGiven_ESP"

-- Fungsi untuk membuat BillboardGui (ESP Tanda Panah)
local function applyESP(model)
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not head then return end

	-- Buat BillboardGui (Tanda Panah Merah dengan Outline Hitam) jika belum ada
	local billboard = model:FindFirstChild(ESP_NAME)
	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = ESP_NAME
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 100, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 4.5, 0) -- Posisi dinaikkan lebih tinggi di atas kepala
		billboard.AlwaysOnTop = true -- Tembus pandang dari balik dinding
		billboard.ResetOnSpawn = false

		local label = Instance.new("TextLabel")
		label.Parent = billboard
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Text = "▼" -- Tanda panah ke bawah
		label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Warna merah
		label.TextSize = 32 -- Ukuran teks
		label.Font = Enum.Font.GothamBold -- Font tebal
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Outline warna hitam
		label.TextStrokeTransparency = 0 -- Outline tipis tapi jelas (0 = solid)

		billboard.Parent = model
	end
end

-- Fungsi untuk menghapus ESP jika tidak memenuhi kondisi
local function removeESP(model)
	local billboard = model:FindFirstChild(ESP_NAME)
	if billboard then
		billboard:Destroy()
	end
end

-- Fungsi utama untuk memeriksa model
local function checkModel(model)
	if not model or not model:IsA("Model") then return end

	local livesGiven = model:GetAttribute(TARGET_ATTRIBUTE) or model:GetAttribute(ALT_TARGET_ATTRIBUTE)

	if livesGiven == 1 then
		applyESP(model)
	else
		removeESP(model)
	end
end

-- Deteksi terus menerus tanpa henti menggunakan loop di background
task.spawn(function()
	while true do
		-- Scan semua player yang terdaftar di game
		for _, player in ipairs(Players:GetPlayers()) do
			-- Cari model di workspace sesuai nama player (e.g. workspace.dreamyleaxo)
			local playerModel = workspace:FindFirstChild(player.Name)
			if playerModel and playerModel:IsA("Model") then
				checkModel(playerModel)
			end
		end
		
		-- Tunggu 0.1 detik sebelum melakukan pemindaian berikutnya agar tidak lag
		task.wait(0.1)
	end
end)

print("[ESP Loader] Script deteksi LivesGiven telah dijalankan!")
