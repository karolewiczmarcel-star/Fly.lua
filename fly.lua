--[[
    Skrypt latania + NOCLIP TOTALNY (działa zawsze)
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
local noclipConnection = nil
local noclipStepped = nil

-- Funkcja do włączania/wyłączania noclipa
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        print("NOCLIP TOTALNY włączony")
        
        -- 1. Wyłącz kolizje dla WSZYSTKICH części (teraz i w przyszłości)
        local function disableCollision(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            disableCollision(part)
        end
        
        noclipConnection = character.DescendantAdded:Connect(disableCollision)
        
        -- 2. Wyłącz WSZYSTKIE stany humanoida (łącznie z Falling i Jumping)
        local states = {
            Enum.HumanoidStateType.Climbing,
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.GettingUp,
            Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,
            Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Dead
        }
        for _, state in ipairs(states) do
            humanoid:SetStateEnabled(state, false)
        end
        
        -- 3. Wyłącz grawitację dla postaci (żeby nie spadała)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end
        end
        
        -- 4. Dodaj BodyVelocity do przepychania (przez ściany)
        local bv = rootPart:FindFirstChild("noclipBV")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = rootPart
            rootPart:SetAttribute("noclipBV", bv)
        end
        
        -- 5. Co klatkę przepychaj postać do przodu (żeby nie ugrzęzła)
        noclipStepped = game:GetService("RunService").Stepped:Connect(function()
            if not noclipEnabled then return end
            if not character or not character.Parent then return end
            
            -- Przesuń postać o mały krok do przodu (w kierunku kamery)
            local pushDirection = camera.CFrame.LookVector * 0.1
            rootPart.CFrame = rootPart.CFrame + pushDirection
        end)
        
    else
        print("NOCLIP TOTALNY wyłączony")
        
        -- 1. Przywróć kolizje
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.5, 0.3, 0.5, 0)
            end
        end
        
        -- 2. Przywróć stany humanoida
        local states = {
            Enum.HumanoidStateType.Climbing,
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.GettingUp,
            Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,
            Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Dead
        }
        for _, state in ipairs(states) do
            humanoid:SetStateEnabled(state, true)
        end
        
        -- 3. Usuń BodyVelocity
        local bv = rootPart:FindFirstChild("noclipBV")
        if bv then bv:Destroy() end
        
        -- 4. Wyłącz przepychanie
        if noclipStepped then
            noclipStepped:Disconnect()
            noclipStepped = nil
        end
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
        local charDir = rootPart.CFrame.LookVector
        local charRight = rootPart.CFrame.RightVector

        if input:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + charDir
        end
        if input:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - charDir
        end
        if input:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - charRight
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + charRight
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
        if noclipConnection then noclipConnection:Disconnect() end
        if noclipStepped then noclipStepped:Disconnect() end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.5, 0.3, 0.5, 0)
            end
        end
        local bv = rootPart:FindFirstChild("noclipBV")
        if bv then bv:Destroy() end
    end
end)

print("Skrypt załadowany!")
print("X = latanie | Z = noclip (włącz/wyłącz)")
print("W = przód, S = tył, A/D = lewo/prawo, Spacja = góra, Shift = dół")
