--[[
    FLY + NOCLIP + AUTO-ROTACJA
    X = włącz/wyłącz latanie
    Z = włącz/wyłącz noclip
    WASD = ruch, Spacja = góra, Shift = dół
    Postać automatycznie obraca się w kierunku kamery
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local flying = false
local flyCon = nil
local flySpeed = 50

local noclip = false
local noclipCon = nil

-- FUNKCJA NOCLIP
local function toggleNoclip()
    noclip = not noclip
    if noclip then
        print("Noclip ON")
        noclipCon = game:GetService("RunService").Heartbeat:Connect(function()
            if not noclip then return end
            if not character or not character.Parent then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        print("Noclip OFF")
        if noclipCon then
            noclipCon:Disconnect()
            noclipCon = nil
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- FUNKCJA FLY
local function startFly()
    if flying then return end
    flying = true
    workspace.Gravity = 0
    
    flyCon = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        if not character or not character.Parent then
            stopFly()
            return
        end
        
        -- 🔥 OBRÓT POSTACI W KIERUNKU KAMERY (tylko w osi Y)
        local camLook = camera.CFrame.LookVector
        local camY = Vector3.new(camLook.X, 0, camLook.Z).Unit
        if camY.Magnitude > 0 then
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + camY)
        end
        
        -- STEROWANIE LOTEM (względem kierunku postaci)
        local input = game:GetService("UserInputService")
        local move = Vector3.new(0, 0, 0)
        local forward = rootPart.CFrame.LookVector
        local right = rootPart.CFrame.RightVector
        
        if input:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
        if input:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
        if input:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if input:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if input:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if input:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
        
        if move.Magnitude > 0 then
            move = move.Unit * flySpeed
        end
        
        rootPart.Velocity = move
    end)
end

local function stopFly()
    if not flying then return end
    flying = false
    if flyCon then
        flyCon:Disconnect()
        flyCon = nil
    end
    workspace.Gravity = 196.2
end

-- OBSŁUGA KLAWISZY
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        if flying then
            stopFly()
            print("Fly OFF")
        else
            startFly()
            print("Fly ON")
        end
    end
    
    if input.KeyCode == Enum.KeyCode.Z then
        toggleNoclip()
    end
end)

-- RESPAWN
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if flying then stopFly() end
    if noclip then
        noclip = false
        if noclipCon then
            noclipCon:Disconnect()
            noclipCon = nil
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)

print("=== SKRYPT ZAŁADOWANY ===")
print("X = Fly | Z = Noclip")
print("Postać automatycznie obraca się w kierunku kamery")
print("W/S = przód/tył | A/D = lewo/prawo")
print("Spacja = góra | Shift = dół")
