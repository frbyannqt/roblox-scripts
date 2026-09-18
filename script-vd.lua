-- =====================================================================
-- BIAN - VIOLENCE DISTRICT
-- Gabungan script publik buat game [CURE] Violence District
-- Semua script di-load pake pcall biar aman kalau ada yang error
-- =====================================================================

-- =====================================================================
-- SERVICE
-- =====================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =====================================================================
-- NOTIFIKASI (pake starter gui sederhana)
-- =====================================================================
local function notify(title, msg)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "BianVD_Notify"
        sg.ResetOnSpawn = false
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 60)
        frame.Position = UDim2.new(0.5, -150, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.BorderSizePixel = 0
        frame.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -20, 0, 25)
        titleLbl.Position = UDim2.new(0, 10, 0, 5)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.TextSize = 14
        titleLbl.Font = Enum.Font.SourceSansBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = frame

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -20, 0, 25)
        msgLbl.Position = UDim2.new(0, 10, 0, 28)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text = msg
        msgLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        msgLbl.TextSize = 12
        msgLbl.Font = Enum.Font.SourceSans
        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
        msgLbl.Parent = frame

        task.delay(5, function()
            pcall(function() sg:Destroy() end)
        end)
    end)
end

notify("Bian - Violence District", "Loading scripts...")

-- =====================================================================
-- DAFTAR SCRIPT PUBLIK
-- =====================================================================
local scripts = {
    {
        name = "6locc / ViolenceDistrict.lua",
        url = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/ViolenceDistrict.lua"
    }
}

-- =====================================================================
-- LOAD SEMUA SCRIPT
-- =====================================================================
local loaded, failed = 0, 0

for _, s in ipairs(scripts) do
    local ok, err = pcall(function()
        loadstring(game:HttpGet(s.url))()
    end)

    if ok then
        loaded = loaded + 1
        notify("Loaded", s.name)
    else
        failed = failed + 1
        warn("[Bian VD] Gagal load " .. s.name .. ": " .. tostring(err))
        notify("Gagal load", s.name .. " - " .. tostring(err))
    end
end

notify("Selesai", loaded .. " script loaded, " .. failed .. " gagal.")
