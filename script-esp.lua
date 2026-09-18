-- 1. Load Library Orion
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- 2. Buat Window
local Window = OrionLib:MakeWindow({
    Name = "Bian Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BianConfig",
    IntroEnabled = false
})

-- 3. Perkecil window + aktifin drag manual
task.spawn(function()
    task.wait(0.2)
    local CoreGui = game:GetService("CoreGui")
    local orionGui = CoreGui:FindFirstChild("Orion")
    if not orionGui then return end

    local Main = orionGui:FindFirstChild("Main")
    if not Main then return end

    -- Perkecil ukuran window
    Main.Size = UDim2.new(0, 460, 0, 300)

    -- Drag system (biar pasti bisa digeser-geser)
    local UIS = game:GetService("UserInputService")
    local topbar = Main:FindFirstChild("Topbar")
    if not topbar then return end

    local dragging, dragInput, dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end)

-- 4. Buat Tab "Visuals"
local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 5. Variabel Penampung
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local espEnabled = false
local lineEnabled = false
local espCache = {}   -- Highlight per player
local lineCache = {}  -- Drawing Line per player

-- 6. Fungsi Inti ESP Highlight
local function applyESP(player)
    if player == LocalPlayer then return end
    if player.UserId == LocalPlayer.UserId then return end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    espCache[player] = highlight
end

local function removeESP(player)
    if espCache[player] then
        espCache[player]:Destroy()
        espCache[player] = nil
    end
end

-- 7. Fungsi ESP Line
local function getLine(player)
    if lineCache[player] then return lineCache[player] end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = Color3.fromRGB(0, 255, 255)
    line.Transparency = 1
    line.Visible = false
    lineCache[player] = line
    return line
end

local function removeLine(player)
    if lineCache[player] then
        lineCache[player]:Remove()
        lineCache[player] = nil
    end
end

-- 8. Loop Update ESP
RunService.RenderStepped:Connect(function()
    -- ESP Highlight
    if espEnabled then
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
    end

    -- ESP Line
    if lineEnabled then
        local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local line = getLine(player)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen and screenPos.Z > 0 then
                        line.From = screenBottom
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    local line = lineCache[player]
                    if line then line.Visible = false end
                end
            end
        end
    end
end)

-- 9. Handle player join / leave
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled then applyESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removeLine(player)
end)

-- 10. Toggle ESP Highlight
VisualsTab:AddToggle({
    Name = "ESP Highlight",
    Default = false,
    Save = true,
    Flag = "ESP_Toggle",
    Callback = function(state)
        espEnabled = state

        if state then
            for _, player in ipairs(Players:GetPlayers()) do
                applyESP(player)
            end
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Highlight Aktif!",
                Time = 3
            })
        else
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

-- 11. Toggle ESP Line
VisualsTab:AddToggle({
    Name = "ESP Line (Tracer)",
    Default = false,
    Save = true,
    Flag = "Line_Toggle",
    Callback = function(state)
        lineEnabled = state

        if state then
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Line Aktif!",
                Time = 3
            })
        else
            -- Sembunyiin semua line
            for _, line in pairs(lineCache) do
                line.Visible = false
            end
            OrionLib:MakeNotification({
                Name = "ESP",
                Content = "ESP Line Nonaktif.",
                Time = 3
            })
        end
    end
})
