-- 1. Load Library Orion (Menggunakan link alternatif yang lebih stabil untuk mobile)
local OrionLib = loadstring(game:HttpGet('https://githubusercontent.com'))()

-- 2. Buat Window
local Window = OrionLib:MakeWindow({
    Name = "ESP Simpel by [Nama Kamu]",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ESPConfig",
    IntroEnabled = false
})

-- 3. Buat Tab "Visuals"
local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 4. Variabel Penampung
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local espEnabled = false
local espCache = {} -- Menyimpan objek visual agar gampang dihapus

-- 5. Fungsi Inti ESP
local function applyESP(player)
    if player == LocalPlayer or espCache[player] then return end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    -- Bikin Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- warna fill (Merah)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- warna outline (Putih)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- LANGSUNG simpan ke cache agar tidak terduplikasi oleh RenderStepped
    espCache[player] = highlight
end

local function removeESP(player)
    if espCache[player] then
        pcall(function()
            espCache[player]:Destroy()
        end)
        espCache[player] = nil
    end
end

-- 6. Loop untuk Update ESP (Diperbaiki agar tidak spam membuat Highlight)
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                -- Cek apakah karakter punya highlight, jika tidak dan belum ada di cache, buat baru
                if not espCache[player] and not character:FindFirstChild("ESP_Highlight") then
                    applyESP(player)
                end
            else
                removeESP(player)
            end
        end
    end
end)

-- Handle saat player baru join
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if espEnabled then
            character:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.5)
            if espEnabled then applyESP(player) end
        end
    end)
end)

-- Handle saat player keluar game
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- 7. Toggle di UI
VisualsTab:AddToggle({
    Name = "Enable ESP (Highlight)",
    Default = false,
    Save = true,
    Flag = "ESP_Toggle",
    Callback = function(state)
        espEnabled = state
        
        if state then
            -- Pas diaktifkan, langsung apply ke semua player yang ada
            for _, player in ipairs(Players:GetPlayers()) do
                applyESP(player)
            end
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Highlight Aktif!",
                Time = 3
            })
        else
            -- Pas dimatikan, hapus semua ESP dan bersihkan cache
            for player, _ in pairs(espCache) do
                removeESP(player)
            end
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Highlight Nonaktif.",
                Time = 3
            })
        end
    end
})

-- Memastikan UI Orion ter-load sempurna
OrionLib:Init()
