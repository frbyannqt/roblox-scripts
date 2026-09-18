-- =====================================================================
-- BIAN SCRIPT - UNIVERSAL ESP + UTILS
-- Library: Orion (github.com/jensonhirst/Orion)
-- Support: Delta Mobile & PC
-- =====================================================================

-- =====================================================================
-- SECTION 1: SERVICES
-- =====================================================================
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Lighting    = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui     = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

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
        if v:IsA("Frame") and v.Name == "Main" then Main = v break end
    end
    if not Main then return end

    Main.Size = UDim2.new(0, 460, 0, 320)

    local topbar
    for _, v in pairs(Main:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("TextButton")) and v.Name == "Topbar" then
            topbar = v break
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
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
local VisualsTab = Window:MakeTab({ Name = "Visuals", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local PlayerTab  = Window:MakeTab({ Name = "Player",  Icon = "rbxassetid://4483345998", PremiumOnly = false })
local MiscTab    = Window:MakeTab({ Name = "Misc",    Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- =====================================================================
-- SECTION 5: STATE & TRACKING
-- =====================================================================
-- ESP state
local espEnabled, lineEnabled, nameEnabled = false, false, false
local linePosition = "Bottom"

-- Player mod state
local walkSpeedEnabled, walkSpeedValue = false, 16
local jumpPowerEnabled, jumpPowerValue = false, 50
local infJumpEnabled = false
local noclipEnabled  = false
local flyEnabled     = false
local flySpeed       = 50

-- Misc state
local antiAfkEnabled    = false
local fullbrightEnabled = false
local infStaminaEnabled = false
local infStaminaValue   = 1000000

-- Teleport state
local spectateTarget = nil

-- Cache & connections
local espCache, nameCache, lineCache = {}, {}, {}
local connections = {}
local isShutdown  = false

local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- =====================================================================
-- SECTION 6: ESP HIGHLIGHT
-- =====================================================================
local function applyESP(player)
    if isShutdown or player == LocalPlayer or espCache[player] then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    espCache[player] = hl
end

local function removeESP(player)
    if espCache[player] then
        pcall(function() espCache[player]:Destroy() end)
        espCache[player] = nil
    end
end

-- =====================================================================
-- SECTION 7: ESP NAME
-- =====================================================================
local function applyName(player)
    if isShutdown or player == LocalPlayer or nameCache[player] then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Name"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = char

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
-- SECTION 8: ESP LINE
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
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if not espCache[p] then applyESP(p) end
                else
                    removeESP(p)
                end
            end
        end
    end

    -- ESP Name
    if nameEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Character and p.Character:FindFirstChild("Head") then
                    if not nameCache[p] then applyName(p) end
                else
                    removeName(p)
                end
            end
        end
    end

    -- ESP Line
    if lineEnabled then
        local origin = (linePosition == "Top")
            and Vector2.new(Camera.ViewportSize.X / 2, 0)
            or  Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local line = getLine(p)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen and screenPos.Z > 0 then
                        line.From = origin
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    local line = lineCache[p]
                    if line then line.Visible = false end
                end
            end
        end
    end

    -- Spectate: re-set camera subject kalau target respawn
    if spectateTarget and spectateTarget.Character then
        local hum = spectateTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum and Camera.CameraSubject ~= hum then
            Camera.CameraSubject = hum
        end
    end
end))

-- =====================================================================
-- SECTION 10: PLAYER JOIN / LEAVE
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
-- SECTION 11: VISUALS TAB
-- =====================================================================
VisualsTab:AddToggle({
    Name = "ESP Highlight", Default = false, Save = true, Flag = "ESP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        espEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
            OrionLib:MakeNotification({Name="ESP", Content="ESP Highlight Aktif!", Time=3})
        else
            for p, _ in pairs(espCache) do removeESP(p) end
            OrionLib:MakeNotification({Name="ESP", Content="ESP Highlight Nonaktif.", Time=3})
        end
    end
})

VisualsTab:AddToggle({
    Name = "ESP Name", Default = false, Save = true, Flag = "Name_Toggle",
    Callback = function(state)
        if isShutdown then return end
        nameEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do applyName(p) end
        else
            for p, _ in pairs(nameCache) do removeName(p) end
        end
    end
})

VisualsTab:AddToggle({
    Name = "ESP Line (Tracer)", Default = false, Save = true, Flag = "Line_Toggle",
    Callback = function(state)
        if isShutdown then return end
        lineEnabled = state
        if not state then
            for _, line in pairs(lineCache) do line.Visible = false end
        end
    end
})

VisualsTab:AddDropdown({
    Name = "Line Position", Default = "Bottom", Options = {"Bottom", "Top"},
    Save = true, Flag = "Line_Pos",
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
    if hum then hum.WalkSpeed = walkSpeedEnabled and walkSpeedValue or 16 end
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

PlayerTab:AddSlider({
    Name = "WalkSpeed (Slider - PC)", Min = 16, Max = 200, Default = 16,
    Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "studs", Flag = "WS_Slider",
    Callback = function(value)
        if isShutdown then return end
        walkSpeedValue = value
        if walkSpeedEnabled then applyWalkSpeed() end
    end
})

PlayerTab:AddTextbox({
    Name = "WalkSpeed (Input - Mobile)", Default = "16", TextDisappear = false,
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
    Name = "Enable WalkSpeed", Default = false, Save = true, Flag = "WS_Toggle",
    Callback = function(state)
        if isShutdown then return end
        walkSpeedEnabled = state
        applyWalkSpeed()
    end
})

PlayerTab:AddSlider({
    Name = "JumpPower (Slider - PC)", Min = 50, Max = 300, Default = 50,
    Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "power", Flag = "JP_Slider",
    Callback = function(value)
        if isShutdown then return end
        jumpPowerValue = value
        if jumpPowerEnabled then applyJumpPower() end
    end
})

PlayerTab:AddTextbox({
    Name = "JumpPower (Input - Mobile)", Default = "50", TextDisappear = false,
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
    Name = "Enable JumpPower", Default = false, Save = true, Flag = "JP_Toggle",
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
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local s = data:FindFirstChild("Stamina")
        if s and s:IsA("ValueBase") then return s end
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local s = ls:FindFirstChild("Stamina")
        if s and s:IsA("ValueBase") then return s end
    end
    return nil
end

track(RunService.Heartbeat:Connect(function()
    if isShutdown or not infStaminaEnabled then return end
    local stamina = findStaminaValue()
    if stamina then pcall(function() stamina.Value = infStaminaValue end) end
end))

PlayerTab:AddToggle({
    Name = "Infinite Stamina", Default = false, Save = true, Flag = "Stamina_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infStaminaEnabled = state
    end
})

-- =====================================================================
-- SECTION 14: PLAYER TAB - NOCLIP
-- =====================================================================
local function setCollide(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = state end
    end
end

track(RunService.Stepped:Connect(function()
    if isShutdown or not noclipEnabled then return end
    setCollide(false)
end))

PlayerTab:AddToggle({
    Name = "Noclip", Default = false, Save = true, Flag = "Noclip_Toggle",
    Callback = function(state)
        if isShutdown then return end
        noclipEnabled = state
        if not state then setCollide(true) end
        OrionLib:MakeNotification({
            Name = "Player",
            Content = state and "Noclip Aktif!" or "Noclip Nonaktif.",
            Time = 3
        })
    end
})

-- =====================================================================
-- SECTION 15: PLAYER TAB - FLY
-- =====================================================================
local flyVelocity, flyGyro

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "BianFlyVelocity"
    flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = hrp

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "BianFlyGyro"
    flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyGyro.P = 1000
    flyGyro.D = 50
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
end

local function stopFly()
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

track(RunService.RenderStepped:Connect(function()
    if isShutdown or not flyEnabled then return end
    if not flyVelocity or not flyGyro then return end
    local hrp = flyVelocity.Parent
    if not hrp or not hrp.Parent then return end

    local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
    local velocity = Vector3.zero

    -- Horizontal: WASD (PC) atau joystick (mobile) via MoveDirection
    if hum and hum.MoveDirection.Magnitude > 0 then
        velocity = hum.MoveDirection * flySpeed
    end

    -- Vertical (PC): Space naik, Shift/Ctrl turun
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        velocity = velocity + Vector3.new(0, flySpeed, 0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity = velocity - Vector3.new(0, flySpeed, 0)
    end

    flyVelocity.Velocity = velocity
    flyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
end))

-- Kalau karakter respawn pas fly aktif, restart fly-nya
track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isShutdown then return end
    if flyEnabled then
        stopFly()
        startFly()
    end
end))

PlayerTab:AddSlider({
    Name = "Fly Speed", Min = 10, Max = 300, Default = 50,
    Color = Color3.fromRGB(255,255,255), Increment = 5, ValueName = "speed", Flag = "Fly_Speed",
    Callback = function(value)
        if isShutdown then return end
        flySpeed = value
    end
})

PlayerTab:AddToggle({
    Name = "Fly", Default = false, Save = true, Flag = "Fly_Toggle",
    Callback = function(state)
        if isShutdown then return end
        flyEnabled = state
        if state then
            startFly()
            OrionLib:MakeNotification({Name="Player", Content="Fly Aktif! (Arah: lihat kamera, Space/Shift naik-turun)", Time=5})
        else
            stopFly()
            OrionLib:MakeNotification({Name="Player", Content="Fly Nonaktif.", Time=3})
        end
    end
})

-- =====================================================================
-- SECTION 16: PLAYER TAB - TELEPORT / SPECTATE
-- =====================================================================
local function getPlayerNames()
    local names = {"-- Pilih Player --"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local playerDropdown
playerDropdown = PlayerTab:AddDropdown({
    Name = "Select Player",
    Default = "-- Pilih Player --",
    Options = getPlayerNames(),
    Flag = "TP_Target",
    Callback = function(value)
        if isShutdown then return end
        if value == "-- Pilih Player --" then
            spectateTarget = nil
        else
            spectateTarget = Players:FindFirstChild(value)
        end
    end
})

local function refreshPlayerDropdown()
    if isShutdown or not playerDropdown then return end
    pcall(function() playerDropdown:Refresh(getPlayerNames(), true) end)
end

track(Players.PlayerAdded:Connect(function()
    task.wait(0.2)
    refreshPlayerDropdown()
end))

track(Players.PlayerRemoving:Connect(function()
    task.wait(0.2)
    refreshPlayerDropdown()
end))

local function startSpectate(player)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
        spectateTarget = player
    end
end

local function stopSpectate()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
    spectateTarget = nil
end

PlayerTab:AddButton({
    Name = "👁 Spectate Player",
    Callback = function()
        if isShutdown then return end
        if not spectateTarget then
            OrionLib:MakeNotification({Name="Teleport", Content="Pilih player dulu!", Time=3})
            return
        end
        startSpectate(spectateTarget)
        OrionLib:MakeNotification({Name="Teleport", Content="Spectating: "..spectateTarget.Name, Time=3})
    end
})

PlayerTab:AddButton({
    Name = "🎯 Teleport to Player",
    Callback = function()
        if isShutdown then return end
        if not spectateTarget then
            OrionLib:MakeNotification({Name="Teleport", Content="Pilih player dulu!", Time=3})
            return
        end
        local char = LocalPlayer.Character
        local targetChar = spectateTarget.Character
        if char and targetChar then
            local myHrp = char:FindFirstChild("HumanoidRootPart")
            local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
            if myHrp and targetHrp then
                myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
                OrionLib:MakeNotification({Name="Teleport", Content="Teleported to "..spectateTarget.Name, Time=3})
            end
        end
    end
})

PlayerTab:AddButton({
    Name = "❌ Cancel Spectate",
    Callback = function()
        if isShutdown then return end
        stopSpectate()
        OrionLib:MakeNotification({Name="Teleport", Content="Spectate dibatalkan", Time=3})
    end
})

-- =====================================================================
-- SECTION 17: MISC TAB - INFINITE JUMP (MOBILE-FIXED)
-- =====================================================================
local jumpButtonHeld = false
local spaceHeld = false

local function setupJumpButton()
    pcall(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not pg then return end
        local tg = pg:WaitForChild("TouchGui", 5)
        if not tg then return end
        local tcf = tg:WaitForChild("TouchControlFrame", 5)
        if not tcf then return end
        local jb = tcf:WaitForChild("JumpButton", 5)
        if not jb then return end

        jb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                jumpButtonHeld = true
            end
        end)
        jb.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                jumpButtonHeld = false
            end
        end)
    end)
end

track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end))

track(RunService.RenderStepped:Connect(function()
    if isShutdown or not infJumpEnabled then return end
    if not (jumpButtonHeld or spaceHeld) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then hum.Jump = true end
end))

track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if isShutdown then return end
    setupJumpButton()
end))

MiscTab:AddToggle({
    Name = "Infinite Jump", Default = false, Save = true, Flag = "InfJump_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infJumpEnabled = state
        if state then
            setupJumpButton()
        else
            jumpButtonHeld = false
            spaceHeld = false
        end
    end
})

-- =====================================================================
-- SECTION 18: MISC TAB - ANTI AFK
-- =====================================================================
track(LocalPlayer.Idled:Connect(function()
    if isShutdown or not antiAfkEnabled then return end
    VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end))

MiscTab:AddToggle({
    Name = "Anti-AFK", Default = false, Save = true, Flag = "AntiAfk_Toggle",
    Callback = function(state)
        if isShutdown then return end
        antiAfkEnabled = state
    end
})

-- =====================================================================
-- SECTION 19: MISC TAB - FULLBRIGHT
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
    Name = "Fullbright", Default = false, Save = true, Flag = "Fullbright_Toggle",
    Callback = function(state)
        if isShutdown then return end
        fullbrightEnabled = state
        if state then enableFullbright() else disableFullbright() end
    end
})

-- =====================================================================
-- SECTION 20: SHUTDOWN
-- =====================================================================
local function shutdown()
    if isShutdown then return end
    isShutdown = true

    espEnabled, lineEnabled, nameEnabled = false, false, false
    walkSpeedEnabled, jumpPowerEnabled = false, false
    infJumpEnabled, noclipEnabled = false, false
    flyEnabled = false
    antiAfkEnabled, fullbrightEnabled, infStaminaEnabled = false, false, false

    pcall(stopFly)
    pcall(stopSpectate)
    pcall(disableFullbright)

    for _, hl in pairs(espCache) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espCache = {}

    for _, bb in pairs(nameCache) do
        pcall(function() if bb then bb:Destroy() end end)
    end
    nameCache = {}

    for _, line in pairs(lineCache) do
        pcall(function() if line then line:Remove() end end)
    end
    lineCache = {}

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    pcall(function()
        if OrionLib and OrionLib.Destroy then OrionLib:Destroy() end
    end)
    pcall(function()
        local og = CoreGui:FindFirstChild("Orion")
        if og then og:Destroy() end
    end)

    print("[Bian Script] Shutdown selesai.")
end

MiscTab:AddButton({
    Name = "🛑 Shutdown (Matikan Semua)",
    Callback = function()
        OrionLib:MakeNotification({Name="Shutdown", Content="Mematikan semua fitur...", Time=2})
        task.wait(0.3)
        shutdown()
    end
})

track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.End then shutdown() end
end))
