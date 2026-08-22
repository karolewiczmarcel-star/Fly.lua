--[[
    FLY (X) + NOCLIP (Z) + ESP (C) + TURBO FLY 250 (V) + SPEED HACK 23 (B)
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ===== STANY =====
local flying = false
local flyCon = nil
local flySpeed = 50
local turboFly = false
local turboSpeed = 250

local noclip = false
local noclipCon = nil

local espEnabled = false
local espCon = nil
local espCache = {}
local ESP_REFRESH = 0.5
local ESP_RANGE = 500

local speedHack = false
local speedValue = 23
local originalSpeed = 16

-- ===== FLY =====
local function startFly()
    if flying then return end
    flying = true
    workspace.Gravity = 0
    print("[FLY] ON")
    
    flyCon = RunService.Heartbeat:Connect(function()
        if not flying then return end
        if not character or not character.Parent then
            stopFly()
            return
        end
        
        local camLook = camera.CFrame.LookVector
        local targetCF = CFrame.lookAt(rootPart.Position, rootPart.Position + camLook)
        rootPart.CFrame = targetCF
        
        local input = UserInputService
        local move = Vector3.new(0, 0, 0)
        local forward = rootPart.CFrame.LookVector
        local right = rootPart.CFrame.RightVector
        
        if input:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
        if input:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
        if input:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if input:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        
        if move.Magnitude > 0 then
            local speed = turboFly and turboSpeed or flySpeed
            move = move.Unit * speed
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
    print("[FLY] OFF")
end

-- ===== NOCLIP =====
local function toggleNoclip()
    noclip = not noclip
    if noclip then
        print("[NOCLIP] ON")
        noclipCon = RunService.Heartbeat:Connect(function()
            if not noclip then return end
            if not character or not character.Parent then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        print("[NOCLIP] OFF")
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

-- ===== ESP =====
local function findActiveWeapon(char)
    if not char then return nil, nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (handle.Position - root.Position).Magnitude
                    if dist < 3 then
                        local name = child.Name:lower()
                        if name:find("knife") or name:find("dagger") or name:find("blade") or name:find("scythe") or name:find("sword") or name:find("axe") or name:find("machete") or name:find("katana") then
                            return "knife", child
                        elseif name:find("gun") or name:find("pistol") or name:find("revolver") or name:find("rifle") or name:find("shotgun") or name:find("sniper") then
                            return "gun", child
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function updateESP()
    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        
        local char = target.Character
        if not char or not char.Parent then
            local h = espCache[target]
            if h then
                pcall(h.Destroy, h)
                espCache[target] = nil
            end
            continue
        end
        
        local color = nil
        local weaponType, weapon = findActiveWeapon(char)
        
        if weaponType == "knife" then
            color = Color3.fromRGB(255, 0, 0)
        elseif weaponType == "gun" then
            color = Color3.fromRGB(0, 128, 255)
        else
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and player.Character then
                local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    local dist = (root.Position - playerRoot.Position).Magnitude
                    if dist < ESP_RANGE then
                        color = Color3.fromRGB(0, 255, 0)
                    end
                end
            end
        end
        
        if color then
            local highlight = espCache[target]
            if highlight and highlight.Parent then
                highlight.FillColor = color
                highlight.OutlineColor = color
            else
                highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Parent = char
                highlight.FillColor = color
                highlight.FillTransparency = 0.3
                highlight.OutlineColor = color
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                espCache[target] = highlight
            end
        else
            local h = espCache[target]
            if h then
                pcall(h.Destroy, h)
                espCache[target] = nil
            end
        end
    end
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true
    print("[ESP] ON")
    
    updateESP()
    espCon = RunService.Heartbeat:Connect(function()
        if espEnabled then
            if not espCon._lastUpdate or tick() - espCon._lastUpdate > ESP_REFRESH then
                updateESP()
                espCon._lastUpdate = tick()
            end
        end
    end)
end

local function disableESP()
    if not espEnabled then return end
    espEnabled = false
    print("[ESP] OFF")
    
    if espCon then
        espCon:Disconnect()
        espCon = nil
    end
    
    for _, h in pairs(espCache) do
        pcall(h.Destroy, h)
    end
    espCache = {}
end

-- ===== SPEED HACK =====
local function toggleSpeedHack()
    speedHack = not speedHack
    if speedHack then
        humanoid.WalkSpeed = speedValue
        print("[SPEED] ON – " .. speedValue)
    else
        humanoid.WalkSpeed = originalSpeed
        print("[SPEED] OFF – " .. originalSpeed)
    end
end

-- ===== KLAWISZE =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        if flying then
            stopFly()
        else
            startFly()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.Z then
        toggleNoclip()
    end
    
    if input.KeyCode == Enum.KeyCode.C then
        if espEnabled then
            disableESP()
        else
            enableESP()
        end
    end
    
    -- V = turbo fly 250
    if input.KeyCode == Enum.KeyCode.V then
        if flying then
            turboFly = not turboFly
            if turboFly then
                print("[TURBO] ON – prędkość 250")
            else
                print("[TURBO] OFF – prędkość 50")
            end
        else
            print("[TURBO] Włącz najpierw Fly (X)")
        end
    end
    
    -- B = speed hack 23
    if input.KeyCode == Enum.KeyCode.B then
        toggleSpeedHack()
    end
end)

-- ===== RESPAWN =====
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
    if espEnabled then
        disableESP()
        task.wait(0.3)
        enableESP()
    end
    if speedHack then
        speedHack = false
        humanoid.WalkSpeed = originalSpeed
    end
end)

print("=== SKRYPT ZAŁADOWANY ===")
print("X = FLY | Z = NOCLIP | C = ESP")
print("V = TURBO FLY 250 | B = SPEED HACK 23")
print("W/S/A/D = latanie (gdy Fly włączone)")
