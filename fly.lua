--[[
    Skrypt latania z kamerą
    W = przód (tam gdzie patrzysz)
    S = tył
    A/D = lewo/prawo
    Spacja = góra
    Shift = dół
    X = włącz/wyłącz
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local flying = false
local flyConnection = nil
local flySpeed = 50

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

        -- W = przód (kierunek kamery)
        if input:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        -- S = tył (odwrotnie niż kamera)
        if input:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        -- A = lewo
        if input:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        -- D = prawo
        if input:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        -- Spacja = góra
        if input:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        -- Shift = dół
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
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    if flying then stopFly() end
end)

print("Skrypt załadowany! Naciśnij X, żeby włączyć/wyłączyć latanie.")
print("W = przód, S = tył, A/D = lewo/prawo, Spacja = góra, Shift = dół")
