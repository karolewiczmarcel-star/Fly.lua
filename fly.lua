--[[
    Skrypt latania + NO CLIP (przechodzi przez wszystko)
    X = latanie (W/S przód/tył, A/D lewo/prawo, Spacja góra, Shift dół)
    Z = noclip (przechodzenie przez ściany) - włącz/wyłącz
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local flying = false
local flyConnection = nil
local flySpeed = 50

local noclipEnabled = false

-- Funkcja do włączania/wyłączania noclipa
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        print("NOCLIP włączony (przechodzisz przez wszystko)")
        -- 1. Wyłącz kolizje dla WSZYSTKICH części
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- 2. Wyłącz kolizje z terenem (ważne dla grubych ścian)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        
        -- 3. Dodaj BodyVelocity do przepychania (opcjonalne, ale pomaga)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1/0, 1/0, 1/0) -- nieskończona siła
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = rootPart
        rootPart:SetAttribute("noclipBV", bv)
        
    else
        print("NOCLIP wyłączony")
        -- 1. Przywróć kolizje
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        
        -- 2. Przywróć stany humanoida
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        
        -- 3. Usuń BodyVelocity
        local bv = rootPart:FindFirstChild("noclipBV")
        if bv then bv:Destroy() end
    end
end

-- Funkcja do latania
local function startFly()
    if flying then return end
    flying = true
    workspace.Gravity = 0

    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flying then return end
        if not character or not character.Parent then
            stopFly()
            return
        end

        local moveDirection = Vector3.new(0, 0, 0)
        local input = game:GetService("UserInputService")

        if input:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if input:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * flySpeed
        end

        rootPart.Velocity = moveDirection
    end)
end

local function stopFly()
    if not flying then return end
    flying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    workspace.Gravity = 196.2
end

-- Obsługa klawiszy
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.X then
        if flying then
            stopFly()
            print("Lot wyłączony")
        else
            startFly()
            print("Lot włączony")
        end
    end

    if input.KeyCode == Enum.KeyCode.Z then
        toggleNoclip()
    end
end)

-- Czyszczenie przy respawnie
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if flying then stopFly() end
    if noclipEnabled then
        noclipEnabled = false
        -- Posprzątaj po noclipie
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        local bv = rootPart:FindFirstChild("noclipBV")
        if bv then bv:Destroy() end
    end
end)

print("Skrypt załadowany!")
print("X = latanie | Z = noclip (włącz/wyłącz) - działa przez wszystko")
print("W = przód, S = tył, A/D = lewo/prawo, Spacja = góra, Shift = dół")
