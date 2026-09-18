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

-- 3. Perkecil window + drag support (PC & Mobile)
task.spawn(function()
    task.wait(0.3)
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")

    local orionGui = CoreGui:FindFirstChild("Orion")
    if not orionGui then return end

    local Main
    for _, v in pairs(orionGui:GetDescendants()) do
        if v:IsA("Frame") and v.Name == "Main" then
            Main = v
            break
        end
    end
    if not Main then return end

    Main.Size = UDim2.new(0, 460, 0, 300)

    local topbar
    for _, v in pairs(Main:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("TextButton")) and v.Name == "Topbar" then
            topbar = v
            break
        end
    end
    if not topbar then return end

    topbar.Active = true

    local dragging = false
    local dragInput, dragStart, startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

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
            updateDrag(input)
        end
    end)
end)

-- 4. Buat Tab
local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 5. Variabel & Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local espEnabled = false
local lineEnabled = false
local linePosition = "Bottom"
local infJumpEnabled = false
local espCache = {}
local lineCache = {}
local connections = {}
local isShutdown = false

local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- 6. ESP Highlight
local function applyESP(player)
    if isShutdown then return end
    if player == LocalPlayer then return end
    if player.UserId == LocalPlayer.UserId then return end
    if espCache[player] then return end

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
        pcall(function() espCache[player]:Destroy() end)
        espCache[player] = nil
    end
end

-- 7. ESP Line
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
        pcall(function() lineCache[player]:Remove() end)
        lineCache[player] = nil
    end
end

-- 8. Loop Update ESP
track(RunService.RenderStepped:Connect(function()
    if isShutdown then return end

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
        local origin
        if linePosition == "Top" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
        else
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local line = getLine(player)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen and screenPos.Z > 0 then
                        line.From = origin
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
end))

-- 9. Player Join / Leave
track(Players.PlayerAdded:Connect(function(player)
    track(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and not isShutdown then applyESP(player) end
    end))
end))

track(Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removeLine(player)
end))

-- 10. Toggle ESP Highlight
VisualsTab:AddToggle({
    Name = "ESP Highlight",
    Default = false,
    Save = true,
    Flag = "ESP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        espEnabled = state

        if state then
            for _, player in ipairs(Players:GetPlayers()) do
                applyESP(player)
            end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Highlight Aktif!", Time = 3})
        else
            for player, _ in pairs(espCache) do
                removeESP(player)
            end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Highlight Nonaktif.", Time = 3})
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
        if isShutdown then return end
        lineEnabled = state

        if state then
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Line Aktif!", Time = 3})
        else
            for _, line in pairs(lineCache) do
                line.Visible = false
            end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Line Nonaktif.", Time = 3})
        end
    end
})

-- 12. Dropdown Posisi Line
VisualsTab:AddDropdown({
    Name = "Line Position",
    Default = "Bottom",
    Options = {"Bottom", "Top"},
    Save = true,
    Flag = "Line_Pos",
    Callback = function(value)
        if isShutdown then return end
        linePosition = value
    end
})

-- 13. ===== INFINITE JUMP (REVISI) =====
-- Pakai ContextActionService biar ke-detect di semua platform,
-- termasuk tombol jump bawaan di mobile (Delta).
local function onJumpAction(actionName, inputState, inputObject)
    if isShutdown or not infJumpEnabled then return end
    if inputState ~= Enum.UserInputState.Begin then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- Bind ke aksi CharacterJump bawaan Roblox
CAS:BindAction("BianInfiniteJump", onJumpAction, false, Enum.PlayerActions.CharacterJump)

MiscTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Save = true,
    Flag = "InfJump_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infJumpEnabled = state

        if state then
            OrionLib:MakeNotification({Name = "Misc", Content = "Infinite Jump Aktif!", Time = 3})
        else
            OrionLib:MakeNotification({Name = "Misc", Content = "Infinite Jump Nonaktif.", Time = 3})
        end
    end
})

-- 14. ===== SHUTDOWN FUNCTION =====
local function shutdown()
    if isShutdown then return end
    isShutdown = true

    espEnabled = false
    lineEnabled = false
    infJumpEnabled = false

    -- Unbind ContextActionService
    pcall(function()
        CAS:UnbindAction("BianInfiniteJump")
    end)

    for player, hl in pairs(espCache) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espCache = {}

    for player, line in pairs(lineCache) do
        pcall(function() if line then line:Remove() end end)
    end
    lineCache = {}

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    pcall(function()
        if OrionLib and OrionLib.Destroy then
            OrionLib:Destroy()
        end
    end)

    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local orionGui = CoreGui:FindFirstChild("Orion")
        if orionGui then orionGui:Destroy() end
    end)

    print("[Bian Script] Shutdown selesai. Semua fitur dimatikan & GUI dihapus.")
end

-- 15. Tombol Shutdown
MiscTab:AddButton({
    Name = "🛑 Shutdown (Matikan Semua)",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Shutdown",
            Content = "Mematikan semua fitur...",
            Time = 2
        })
        task.wait(0.3)
        shutdown()
    end
})

-- 16. Keybind End (PC) buat shutdown
track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.End then
        shutdown()
    end
end))
