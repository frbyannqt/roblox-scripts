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
local ok, OrionLib = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
end)
if not ok or not OrionLib then
    warn("[Bian Script] Gagal load Orion: " .. tostring(OrionLib))
    return
end

local Window = OrionLib:MakeWindow({
    Name = "Bian Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BianConfig",
    IntroEnabled = false
})

-- =====================================================================
-- SECTION 3: WINDOW RESIZE + DRAG
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
local VisualsTab = Window:MakeTab({ Name = "Visuals", Icon = "rbxassetid://4483345998", PremiumOnly = false })
local PlayerTab  = Window:MakeTab({ Name = "Player",  Icon = "rbxassetid://4483345998", PremiumOnly = false })
local MiscTab    = Window:MakeTab({ Name = "Misc",    Icon = "rbxassetid://4483345998", PremiumOnly = false })

-- =====================================================================
-- SECTION 5: STATE & TRACKING
-- =====================================================================
local espEnabled    = false
local lineEnabled   = false
local nameEnabled   = false
local linePosition  = "Bottom"

local walkSpeedEnabled = false
local walkSpeedValue   = 16
local jumpPowerEnabled = false
local jumpPowerValue   = 50
local infJumpEnabled   = false
local noclipEnabled    = false
local flyEnabled       = false
local flySpeed         = 50

local antiAfkEnabled    = false
local fullbrightEnabled = false
local infStaminaEnabled = false
local infStaminaValue   = 1000000

local spectateTarget   = nil
local teleportEnabled  = false
local teleportPanel    = nil
local teleportConns    = {}
local teleportToggleRef = nil

local espCache  = {}
local nameCache = {}
local lineCache = {}
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

    if lineEnabled then
        local origin
        if linePosition == "Top" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
        else
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        end

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

    -- Spectate: pastiin kamera tetep nge-follow target
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
    Name = "ESP Highlight",
    Default = false, Save = true, Flag = "ESP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        espEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
        else
            for p, _ in pairs(espCache) do removeESP(p) end
        end
    end
})

VisualsTab:AddToggle({
    Name = "ESP Name",
    Default = false, Save = true, Flag = "Name_Toggle",
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
    Name = "ESP Line (Tracer)",
    Default = false, Save = true, Flag = "Line_Toggle",
    Callback = function(state)
        if isShutdown then return end
        lineEnabled = state
        if not state then
            for _, line in pairs(lineCache) do line.Visible = false end
        end
    end
})

VisualsTab:AddDropdown({
    Name = "Line Position",
    Default = "Bottom", Options = {"Bottom", "Top"},
    Save = true, Flag = "Line_Pos",
    Callback = function(value)
        if isShutdown then return end
        linePosition = value
    end
})

-- =====================================================================
-- SECTION 12: WALKSPEED & JUMPPOWER
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
    Name = "WalkSpeed (Slider - PC)",
    Min = 16, Max = 200, Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1, ValueName = "studs", Flag = "WS_Slider",
    Callback = function(value)
        if isShutdown then return end
        walkSpeedValue = value
        if walkSpeedEnabled then applyWalkSpeed() end
    end
})

PlayerTab:AddTextbox({
    Name = "WalkSpeed (Input - Mobile)",
    Default = "16",
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
    Default = false, Save = true, Flag = "WS_Toggle",
    Callback = function(state)
        if isShutdown then return end
        walkSpeedEnabled = state
        applyWalkSpeed()
    end
})

PlayerTab:AddSlider({
    Name = "JumpPower (Slider - PC)",
    Min = 50, Max = 300, Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1, ValueName = "power", Flag = "JP_Slider",
    Callback = function(value)
        if isShutdown then return end
        jumpPowerValue = value
        if jumpPowerEnabled then applyJumpPower() end
    end
})

PlayerTab:AddTextbox({
    Name = "JumpPower (Input - Mobile)",
    Default = "50",
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
    Default = false, Save = true, Flag = "JP_Toggle",
    Callback = function(state)
        if isShutdown then return end
        jumpPowerEnabled = state
        applyJumpPower()
    end
})

-- =====================================================================
-- SECTION 13: INFINITE STAMINA
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
    Name = "Infinite Stamina",
    Default = false, Save = true, Flag = "Stamina_Toggle",
    Callback = function(state)
        if isShutdown then return end
        infStaminaEnabled = state
    end
})

-- =====================================================================
-- SECTION 14: NOCLIP
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
    Name = "Noclip",
    Default = false, Save = true, Flag = "Noclip_Toggle",
    Callback = function(state)
        if isShutdown then return end
        noclipEnabled = state
        if not state then setCollide(true) end
    end
})

-- =====================================================================
-- SECTION 15: FLY
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

    if hum and hum.MoveDirection.Magnitude > 0 then
        velocity = hum.MoveDirection * flySpeed
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        velocity = velocity + Vector3.new(0, flySpeed, 0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity = velocity - Vector3.new(0, flySpeed, 0)
    end

    flyVelocity.Velocity = velocity
    flyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
end))

track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isShutdown then return end
    if flyEnabled then
        stopFly()
        startFly()
    end
end))

PlayerTab:AddSlider({
    Name = "Fly Speed",
    Min = 10, Max = 300, Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5, ValueName = "speed", Flag = "Fly_Speed",
    Callback = function(value)
        if isShutdown then return end
        flySpeed = value
    end
})

PlayerTab:AddToggle({
    Name = "Fly",
    Default = false, Save = true, Flag = "Fly_Toggle",
    Callback = function(state)
        if isShutdown then return end
        flyEnabled = state
        if state then startFly() else stopFly() end
    end
})

-- =====================================================================
-- SECTION 16: TELEPORT / SPECTATE FLOATING PANEL
-- =====================================================================
local function stopSpectate()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
    spectateTarget = nil
end

local function destroyTeleportPanel()
    if teleportPanel then
        pcall(function() teleportPanel:Destroy() end)
        teleportPanel = nil
    end
    for _, c in ipairs(teleportConns) do
        pcall(function() c:Disconnect() end)
    end
    teleportConns = {}
end

local function buildTeleportPanel()
    destroyTeleportPanel()

    local pg = LocalPlayer:WaitForChild("PlayerGui")

    local sg = Instance.new("ScreenGui")
    sg.Name = "BianTeleportPanel"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999999
    sg.Parent = pg
    teleportPanel = sg

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 270, 0, 340)
    frame.Position = UDim2.new(0, 15, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 100)
    stroke.Thickness = 1
    stroke.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    header.BorderSizePixel = 0
    header.Parent = frame

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 10)
    hCorner.Parent = header

    -- Tutup sudut bawah header biar rata
    local hFix = Instance.new("Frame")
    hFix.Size = UDim2.new(1, 0, 0, 10)
    hFix.Position = UDim2.new(0, 0, 1, -10)
    hFix.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    hFix.BorderSizePixel = 0
    hFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Teleport / Spectate"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 15
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Header drag
    do
        local dragging, dragInput, dragStart, startPos

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        local dragConn = UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        table.insert(teleportConns, dragConn)
    end

    -- Scroll list
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PlayerList"
    scroll.Size = UDim2.new(1, -10, 1, -95)
    scroll.Position = UDim2.new(0, 5, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 140)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
    end)

    local function rebuildList()
        if not teleportPanel then return end
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end

        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                count = count + 1

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -4, 0, 32)
                row.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
                row.BorderSizePixel = 0
                row.LayoutOrder = count
                row.Parent = scroll

                local rc = Instance.new("UICorner")
                rc.CornerRadius = UDim.new(0, 6)
                rc.Parent = row

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -130, 1, 0)
                nameLbl.Position = UDim2.new(0, 8, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = p.Name
                nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLbl.TextSize = 13
                nameLbl.Font = Enum.Font.SourceSans
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                nameLbl.Parent = row

                local specBtn = Instance.new("TextButton")
                specBtn.Size = UDim2.new(0, 55, 1, -8)
                specBtn.Position = UDim2.new(1, -120, 0, 4)
                specBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
                specBtn.BorderSizePixel = 0
                specBtn.Text = "Spec"
                specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                specBtn.TextSize = 13
                specBtn.Font = Enum.Font.SourceSansBold
                specBtn.AutoButtonColor = true
                specBtn.Parent = row

                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(0, 4)
                sc.Parent = specBtn

                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0, 55, 1, -8)
                tpBtn.Position = UDim2.new(1, -60, 0, 4)
                tpBtn.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
                tpBtn.BorderSizePixel = 0
                tpBtn.Text = "TP"
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.TextSize = 13
                tpBtn.Font = Enum.Font.SourceSansBold
                tpBtn.AutoButtonColor = true
                tpBtn.Parent = row

                local tc = Instance.new("UICorner")
                tc.CornerRadius = UDim.new(0, 4)
                tc.Parent = tpBtn

                specBtn.MouseButton1Click:Connect(function()
                    if isShutdown then return end
                    local char = p.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        Camera.CameraSubject = hum
                        spectateTarget = p
                        OrionLib:MakeNotification({Name = "Teleport", Content = "Spectating: " .. p.Name, Time = 2})
                    end
                end)

                tpBtn.MouseButton1Click:Connect(function()
                    if isShutdown then return end
                    local myChar = LocalPlayer.Character
                    local tChar = p.Character
                    if myChar and tChar then
                        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                        local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                        if myHrp and tHrp then
                            myHrp.CFrame = tHrp.CFrame + Vector3.new(0, 3, 0)
                            OrionLib:MakeNotification({Name = "Teleport", Content = "Teleported to " .. p.Name, Time = 2})
                        end
                    end
                end)
            end
        end

        if count == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, -10, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Text = "Tidak ada player lain"
            empty.TextColor3 = Color3.fromRGB(180, 180, 180)
            empty.TextSize = 14
            empty.Font = Enum.Font.SourceSansItalic
            empty.Parent = scroll
        end
    end

    rebuildList()

    -- Cancel button
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "CancelBtn"
    cancelBtn.Size = UDim2.new(1, -20, 0, 34)
    cancelBtn.Position = UDim2.new(0, 10, 1, -42)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "✕ Cancel / Close"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.SourceSansBold
    cancelBtn.AutoButtonColor = true
    cancelBtn.Parent = frame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = cancelBtn

    cancelBtn.MouseButton1Click:Connect(function()
        pcall(stopSpectate)
        destroyTeleportPanel()
        teleportEnabled = false
        if teleportToggleRef then
            pcall(function() teleportToggleRef:Set(false) end)
        end
        OrionLib:MakeNotification({Name = "Teleport", Content = "Panel ditutup", Time = 2})
    end)

    -- Auto refresh
    table.insert(teleportConns, Players.PlayerAdded:Connect(function()
        task.wait(0.2)
        rebuildList()
    end))
    table.insert(teleportConns, Players.PlayerRemoving:Connect(function()
        task.wait(0.2)
        rebuildList()
    end))
end

teleportToggleRef = PlayerTab:AddToggle({
    Name = "Teleport / Spectate Panel",
    Default = false, Save = false, Flag = "TP_Panel_Toggle",
    Callback = function(state)
        if isShutdown then return end
        teleportEnabled = state
        if state then
            buildTeleportPanel()
        else
            pcall(stopSpectate)
            destroyTeleportPanel()
        end
    end
})

-- =====================================================================
-- SECTION 17: INFINITE JUMP
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
    Name = "Infinite Jump",
    Default = false, Save = true, Flag = "InfJump_Toggle",
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
-- SECTION 18: ANTI-AFK
-- =====================================================================
track(LocalPlayer.Idled:Connect(function()
    if isShutdown or not antiAfkEnabled then return end
    VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end))

MiscTab:AddToggle({
    Name = "Anti-AFK",
    Default = false, Save = true, Flag = "AntiAfk_Toggle",
    Callback = function(state)
        if isShutdown then return end
        antiAfkEnabled = state
    end
})

-- =====================================================================
-- SECTION 19: FULLBRIGHT
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
    Default = false, Save = true, Flag = "Fullbright_Toggle",
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

    espEnabled = false
    lineEnabled = false
    nameEnabled = false
    walkSpeedEnabled = false
    jumpPowerEnabled = false
    infJumpEnabled = false
    noclipEnabled = false
    flyEnabled = false
    antiAfkEnabled = false
    fullbrightEnabled = false
    infStaminaEnabled = false

    pcall(stopFly)
    pcall(stopSpectate)
    pcall(disableFullbright)
    pcall(destroyTeleportPanel)

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
    Name = "Shutdown (Matikan Semua)",
    Callback = function()
        OrionLib:MakeNotification({Name = "Shutdown", Content = "Mematikan semua fitur...", Time = 2})
        task.wait(0.3)
        shutdown()
    end
})

track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.End then shutdown() end
end))
