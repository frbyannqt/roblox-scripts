-- 1. Load Library Orion (versi stabil)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

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
local Camera = workspace.CurrentCamera

local espEnabled = false
local espCache = {} -- nyimpen objek visual biar gampang dihapus

-- 5. Fungsi Inti ESP
local function applyESP(player)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    -- Bikin Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- warna fill
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- warna outline
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Simpan biar bisa dihapus nanti
    espCache[player] = highlight
end

local function removeESP(player)
    if espCache[player] then
        espCache[player]:Destroy()
        espCache[player] = nil
    end
end

-- 6. Loop buat Update ESP
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if not espCache[player] then
                    applyESP(player)
                end
            else
                removeESP(player)
            end
        end
    end
end)

-- Handle pas player baru join / keluar
Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled then applyESP(player) end
        end)
    end
end)

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
            -- Pas diaktifin, langsung apply ke semua player yang ada
            for _, player in ipairs(Players:GetPlayers()) do
                applyESP(player)
            end
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Highlight Aktif!",
                Time = 3
            })
        else
            -- Pas dimatiin, hapus semua ESP
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
