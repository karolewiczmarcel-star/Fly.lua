--[[
    Skrypt latania + noclip
    X = latanie (W/S przód/tył, A/D lewo/prawo, Spacja góra, Shift dół)
    Z = noclip (przechodzenie przez ściany)
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local flying = false
local flyConnection = nil
local flySpeed = 50

local noclipEnabled = false
local noclipConnection = nil

-- Funkcja do włączania/wyłączania noclipa
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        print("Noclip włączony")
        -- Wyłącz kolizję dla wszystkich części postaci
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        -- Nasłuchuj na nowe części (np. przy respawnie)
        noclipConnection = character.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end)
    else
        print("Noclip wyłączony")
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        -- Przywróć kolizję dla wszystkich części
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
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
    if flying then stopFly() end
    if noclipEnabled then
        -- Wyłącz noclip przy respawnie (żeby uniknąć bugów)
        noclipEnabled = false
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)

print("Skrypt załadowany!")
print("X = latanie | Z = noclip")
print("W = przód, S = tył, A/D = lewo/prawo, Spacja = góra, Shift = dół")
