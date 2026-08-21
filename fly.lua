--[[
    FLY + NOCLIP + PŁYNNA ROTACJA
    X = włącz/wyłącz latanie
    Z = włącz/wyłącz noclip
    Postać płynnie obraca się w kierunku kamery
    W = lecisz tam, gdzie patrzysz (w tym w górę/dół)
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

-- NOCLIP
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

-- FLY + PŁYNNA ROTACJA
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
        
        -- 🔥 PŁYNNA ROTACJA POSTACI (w kierunku kamery)
        local camCF = camera.CFrame
        local targetCF = CFrame.new(rootPart.Position, rootPart.Position + camCF.LookVector)
        rootPart.CFrame = rootPart.CFrame:Lerp(targetCF, 0.3) -- 0.3 = płynność
        
        -- 🔥 LECISZ TAM, GDZIE PATRZY POSTAĆ (czyli kamera)
        local input = game:GetService("UserInputService")
        local move = Vector3.new(0, 0, 0)
        local forward = rootPart.CFrame.LookVector
        local right = rootPart.CFrame.RightVector
        local up = rootPart.CFrame.UpVector
        
        -- W = lecisz w kierunku patrzenia (do przodu)
        if input:IsKeyDown(Enum.KeyCode.W) then
            move = move + forward
        end
        -- S = lecisz do tyłu
        if input:IsKeyDown(Enum.KeyCode.S) then
            move = move - forward
        end
        -- A/D = lewo/prawo
        if input:IsKeyDown(Enum.KeyCode.A) then
            move = move - right
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            move = move + right
        end
        -- Spacja = góra (względem postaci)
        if input:IsKeyDown(Enum.KeyCode.Space) then
            move = move + up
        end
        -- Shift = dół
        if input:IsKeyDown(Enum.KeyCode.LeftShift) then
            move = move - up
        end
        
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
print("Postać płynnie obraca się w kierunku kamery")
print("W = lecisz w kierunku patrzenia (góra/dół też)")
print("S = tył | A/D = lewo/prawo")
print("Spacja = góra | Shift = dół")
