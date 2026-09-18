-- =====================================================================
-- BIAN SCRIPT - UNIVERSAL ESP + UTILS
-- Library: Orion (github.com/jensonhirst/Orion)
-- Support: Delta Mobile & PC
-- =====================================================================

-- =====================================================================
-- SECTION 1: SERVICES & CONSTANTS
-- =====================================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local CAS               = game:GetService("ContextActionService")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- =====================================================================
-- SECTION 2: LOAD ORION
-- =====================================================================
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "Bian Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BianConfig",
    IntroEnabled = false
})

-- =====================================================================
-- SECTION 3: WINDOW RESIZE + DRAG (MOBILE & PC)
-- =====================================================================
task.spawn(function()
    task.wait(0.3)
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

    Main.Size = UDim2.new(0, 460, 0, 320)

    local topbar
    for _, v in pairs(Main:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("TextButton")) and v.Name == "Topbar" then
            topbar = v
            break
        end
    end
    if not topbar then return end

    topbar.Active = true

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
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end)

-- =====================================================================
-- SECTION 4: TABS
-- =====================================================================
local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- =====================================================================
-- SECTION 5: STATE & TRACKING
-- =====================================================================
-- ESP state
local espEnabled        = false
local lineEnabled       = false
local linePosition      = "Bottom"
local nameEnabled       = false

-- Player mod state
local walkSpeedEnabled  = false
local walkSpeedValue    = 16
local jumpPowerEnabled  = false
local jumpPowerValue    = 50
local infJumpEnabled    = false

-- Misc state
local antiAfkEnabled    = false
local fullbrightEnabled = false
local infStaminaEnabled = false
local infStaminaValue   = 1000000

-- Cache & connections
local espCache          = {}
local nameCache         = {}
local lineCache         = {}
local connections       = {}
local isShutdown        = false

local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- =====================================================================
-- SECTION 6: ESP HIGHLIGHT
-- =====================================================================
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

-- =====================================================================
-- SECTION 7: ESP PLAYER NAME
-- =====================================================================
local function applyName(player)
    if isShutdown then return end
    if player == LocalPlayer then return end
    if nameCache[player] then return end

    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Name"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = character

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 18
    label.Font = Enum.Font.SourceSansBold
    label.Parent = bb

    nameCache[player] = bb
end

local function removeName(player)
    if nameCache[player] then
        pcall(function() nameCache[player]:Destroy() end)
        nameCache[player] = nil
    end
end

-- =====================================================================
-- SECTION 8: ESP LINE (TRACER)
-- =====================================================================
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

-- =====================================================================
-- SECTION 9: MAIN RENDER LOOP
-- =====================================================================
track(RunService.RenderStepped:Connect(function()
    if isShutdown then return end

    -- ESP Highlight
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if not espCache[player] then applyESP(player) end
                else
                    removeESP(player)
                end
            end
        end
    end

    -- ESP Name
    if nameEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and player.Character:FindFirstChild("Head") then
                    if not nameCache[player] then applyName(player) end
                else
                    removeName(player)
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

-- =====================================================================
-- SECTION 10: PLAYER JOIN / LEAVE HANDLERS
-- =====================================================================
track(Players.PlayerAdded:Connect(function(player)
    track(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if isShutdown then return end
        if espEnabled then applyESP(player) end
        if nameEnabled then applyName(player) end
    end))
end))

track(Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removeName(player)
    removeLine(player)
end))

-- =====================================================================
-- SECTION 11: VISUALS TAB - ESP CONTROLS
-- =====================================================================
VisualsTab:AddToggle({
    Name = "ESP Highlight",
    Default = false,
    Save = true,
    Flag = "ESP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        espEnabled = state
        if state then
            for _, player in ipairs(Players:GetPlayers()) do applyESP(player) end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Highlight Aktif!", Time = 3})
        else
            for player, _ in pairs(espCache) do removeESP(player) end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Highlight Nonaktif.", Time = 3})
        end
    end
})

VisualsTab:AddToggle({
    Name = "ESP Name",
    Default = false,
    Save = true,
    Flag = "Name_Toggle",
    Callback = function(state)
        if isShutdown then return end
        nameEnabled = state
        if state then
            for _, player in ipairs(Players:GetPlayers()) do applyName(player) end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Name Aktif!", Time = 3})
        else
            for player, _ in pairs(nameCache) do removeName(player) end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Name Nonaktif.", Time = 3})
        end
    end
})

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
            for _, line in pairs(lineCache) do line.Visible = false end
            OrionLib:MakeNotification({Name = "ESP", Content = "ESP Line Nonaktif.", Time = 3})
        end
    end
})

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

-- =====================================================================
-- SECTION 12: PLAYER TAB - WALKSPEED & JUMPPOWER
-- =====================================================================
local function applyWalkSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = walkSpeedEnabled and walkSpeedValue or 16
    end
end

local function applyJumpPower()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = jumpPowerEnabled and jumpPowerValue or 50
    end
end

track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isShutdown then return end
    applyWalkSpeed()
    applyJumpPower()
end))

-- ---------- WALKSPEED ----------
PlayerTab:AddSlider({
    Name = "WalkSpeed (Slider - PC)",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "studs",
    Flag = "WS_Slider",
    Callback = function(value)
        if isShutdown then return end
        walkSpeedValue = value
        if walkSpeedEnabled then applyWalkSpeed() end
    end
})

PlayerTab:AddTextbox({
    Name = "WalkSpeed (Input - Mobile)",
    Default = "16",
    TextDisappear = false,
    Callback = function(text)
        if isShutdown then return end
        local num = tonumber(text)
        if num then
            walkSpeedValue = math.clamp(num, 1, 500)
            if walkSpeedEnabled then applyWalkSpeed() end
        end
    end
})

PlayerTab:AddToggle({
    Name = "Enable WalkSpeed",
    Default = false,
    Save = true,
    Flag = "WS_Toggle",
    Callback = function(state)
        if isShutdown then return end
        walkSpeedEnabled = state
        applyWalkSpeed()
    end
})

-- ---------- JUMPPOWER ----------
PlayerTab:AddSlider({
    Name = "JumpPower (Slider - PC)",
    Min = 50,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "power",
    Flag = "JP_Slider",
    Callback = function(value)
        if isShutdown then return end
        jumpPowerValue = value
        if jumpPowerEnabled then applyJumpPower() end
    end
})

PlayerTab:AddTextbox({
    Name = "JumpPower (Input - Mobile)",
    Default = "50",
    TextDisappear = false,
    Callback = function(text)
        if isShutdown then return end
        local num = tonumber(text)
        if num then
            jumpPowerValue = math.clamp(num, 1, 1000)
            if jumpPowerEnabled then applyJumpPower() end
        end
    end
})

PlayerTab:AddToggle({
    Name = "Enable JumpPower",
    Default = false,
    Save = true,
    Flag = "JP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        jumpPowerEnabled = state
        applyJumpPower()
    end
})
-- =====================================================================
-- SECTION 13: PLAYER TAB - INFINITE STAMINA
-- =====================================================================
local function findStaminaValue()
    local char = LocalPlayer.Character
    -- Cek folder Data
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local stamina = data:FindFirstChild("Stamina")
        if stamina and stamina:IsA("ValueBase") then return stamina end
    end
    -- Cek leaderstats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local stamina = leaderstats:FindFirstChild("Stamina")
        if stamina and stamina:IsA("ValueBase") then return stamina end
    end
    return nil
end

track(RunService.Heartbeat:Connect(function()
    if isShutdown or not infStaminaEnabled then return end
    local stamina = findStaminaValue()
    if stamina then
        pcall(function() stamina.Value = infStaminaValue end)
    end
end))

PlayerTab:AddToggle({
    Name = "Infinite Stamina",
    Default = false,
    Save = true,
    Flag = "Stamina_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infStaminaEnabled = state
        if state then
            OrionLib:MakeNotification({Name = "Player", Content = "Infinite Stamina Aktif!", Time = 3})
        else
            OrionLib:MakeNotification({Name = "Player", Content = "Infinite Stamina Nonaktif.", Time = 3})
        end
    end
})

-- =====================================================================
-- SECTION 14: MISC TAB - INFINITE JUMP (MOBILE-FIXED)
-- =====================================================================
-- Pendekatan: deteksi touch di tombol jump bawaan Roblox (TouchGui)
-- lalu loop Humanoid.Jump = true selama tombol ditahan.
local jumpButtonHeld = false
local jumpButtonConnection = nil

local function setupJumpButton()
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end
        local touchGui = playerGui:WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end

        if jumpButtonConnection then jumpButtonConnection:Disconnect() end

        jumpButtonConnection = jumpButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                jumpButtonHeld = true
            end
        end)

        jumpButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                jumpButtonHeld = false
            end
        end)
    end)
end

-- Fallback buat PC: Space held
local spaceHeld = false
track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true end
end))
track(UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end))

-- Loop infinite jump
track(RunService.RenderStepped:Connect(function()
    if isShutdown or not infJumpEnabled then return end
    if not (jumpButtonHeld or spaceHeld) then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum.Jump = true
    end
end))

-- Re-setup jump button setiap respawn
track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if isShutdown then return end
    setupJumpButton()
end))

MiscTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Save = true,
    Flag = "InfJump_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infJumpEnabled = state
        if state then
            setupJumpButton()
            OrionLib:MakeNotification({Name = "Misc", Content = "Infinite Jump Aktif!", Time = 3})
        else
            jumpButtonHeld = false
            spaceHeld = false
            OrionLib:MakeNotification({Name = "Misc", Content = "Infinite Jump Nonaktif.", Time = 3})
        end
    end
})

-- =====================================================================
-- SECTION 15: MISC TAB - ANTI AFK
-- =====================================================================
track(LocalPlayer.Idled:Connect(function()
    if isShutdown or not antiAfkEnabled then return end
    VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end))

MiscTab:AddToggle({
    Name = "Anti-AFK",
    Default = false,
    Save = true,
    Flag = "AntiAfk_Toggle",
    Callback = function(state)
        if isShutdown then return end
        antiAfkEnabled = state
        if state then
            OrionLib:MakeNotification({Name = "Misc", Content = "Anti-AFK Aktif!", Time = 3})
        else
            OrionLib:MakeNotification({Name = "Misc", Content = "Anti-AFK Nonaktif.", Time = 3})
        end
    end
})

-- =====================================================================
-- SECTION 16: MISC TAB - FULLBRIGHT
-- =====================================================================
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function enableFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
end

local function disableFullbright()
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.Ambient = originalLighting.Ambient
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.GlobalShadows = originalLighting.GlobalShadows
end

MiscTab:AddToggle({
    Name = "Fullbright",
    Default = false,
    Save = true,
    Flag = "Fullbright_Toggle",
    Callback = function(state)
        if isShutdown then return end
        fullbrightEnabled = state
        if state then
            enableFullbright()
            OrionLib:MakeNotification({Name = "Misc", Content = "Fullbright Aktif!", Time = 3})
        else
            disableFullbright()
            OrionLib:MakeNotification({Name = "Misc", Content = "Fullbright Nonaktif.", Time = 3})
        end
    end
})

-- =====================================================================
-- SECTION 17: MISC TAB - SHUTDOWN
-- =====================================================================
local function shutdown()
    if isShutdown then return end
    isShutdown = true

    -- Matiin fitur
    espEnabled = false
    lineEnabled = false
    nameEnabled = false
    walkSpeedEnabled = false
    jumpPowerEnabled = false
    infJumpEnabled = false
    antiAfkEnabled = false
    fullbrightEnabled = false
    infStaminaEnabled = false

    -- Balikin lighting
    pcall(function() disableFullbright() end)

    -- Hapus semua visual
    for player, hl in pairs(espCache) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espCache = {}

    for player, bb in pairs(nameCache) do
        pcall(function() if bb then bb:Destroy() end end)
    end
    nameCache = {}

    for player, line in pairs(lineCache) do
        pcall(function() if line then line:Remove() end end)
    end
    lineCache = {}

    -- Unbind jump button
    pcall(function()
        if jumpButtonConnection then jumpButtonConnection:Disconnect() end
    end)

    -- Disconnect semua koneksi
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    -- Hancurin GUI
    pcall(function()
        if OrionLib and OrionLib.Destroy then OrionLib:Destroy() end
    end)
    pcall(function()
        local orionGui = CoreGui:FindFirstChild("Orion")
        if orionGui then orionGui:Destroy() end
    end)

    print("[Bian Script] Shutdown selesai. Semua fitur dimatikan & GUI dihapus.")
end

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

-- Keybind End (PC)
track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.End then shutdown() end
end))
