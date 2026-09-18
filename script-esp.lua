-- Ganti baris ini:
if hum and hum.MoveDirection.Magnitude > 0 then
    velocity = hum.MoveDirection * flySpeed
end

-- Jadi ini:
local look = Camera.CFrame.LookVector
local right = Camera.CFrame.RightVector

-- Maju/mundur pakai joystick mobile atau WASD
local moveInput = hum and hum.MoveDirection or Vector3.zero
if moveInput.Magnitude > 0 then
    velocity = moveInput * flySpeed
else
    velocity = look * (flySpeed * 0.5) -- default maju pelan
end
