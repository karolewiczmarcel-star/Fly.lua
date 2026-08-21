--[[
    ESP – SZUKA TYLKO AKTYWNEJ BRONI (w ręce)
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

local noclip = false
local noclipCon = nil

local espEnabled = false
local espCon = nil
local espCache = {}
local ESP_REFRESH = 0.5
local ESP_RANGE = 500

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

-- ===== ESP – SZUKA TYLKO BRONI W RĘCE =====
local function findActiveWeapon(char)
    if not char then return nil, nil end
    
    -- Sprawdź wszystkie Tool w postaci
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            -- Sprawdź, czy Tool ma Handle (aktywna broń)
            local handle = child:FindFirstChild("Handle")
            if handle then
                -- Sprawdź kształt Handle
                if handle:IsA("BasePart") or handle:IsA("MeshPart") then
                    local size = handle.Size
                    -- Nóż = długi i cienki
                    if (size.X > 1.5 and size.Y < 0.8 and size.Z < 0.8) or
                       (size.Z > 1.5 and size.X < 0.8 and size.Y < 0.8) then
                        return "knife", child
                    end
                    -- Pistolet = krótki i szeroki
                    if size.X > 0.8 and size.X < 2 and size.Y > 0.5 and size.Y < 1.5 and size.Z > 0.5 and size.Z < 1.5 then
                        return "gun", child
                    end
                end
            end
        end
    end
    
    -- Jeśli nie znaleziono Tool z Handle, sprawdź czy gracz ma coś w ręce (MeshPart bezpośrednio)
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("MeshPart") or child:IsA("Part") then
            -- Sprawdź, czy część jest w okolicy dłoni (przybliżona pozycja)
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (child.Position - root.Position).Magnitude
                if dist < 3 then -- Broń w ręce jest blisko rootPart
                    local size = child.Size
                    if (size.X > 1.5 and size.Y < 0.8 and size.Z < 0.8) or
                       (size.Z > 1.5 and size.X < 0.8 and size.Y < 0.8) then
                        return "knife", child
                    end
                    if size.X > 0.8 and size.X < 2 and size.Y > 0.5 and size.Y < 1.5 and size.Z > 0.5 and size.Z < 1.5 then
                        return "gun", child
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
            color = Color3.fromRGB(255, 0, 0) -- Czerwony
            print("[DEBUG] " .. target.Name .. " ma NÓŻ w ręce")
        elseif weaponType == "gun" then
            color = Color3.fromRGB(0, 128, 255) -- Niebieski
            print("[DEBUG] " .. target.Name .. " ma PISTOLET w ręce")
        else
            -- Niewinny – tylko w zasięgu
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and player.Character then
                local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    local dist = (root.Position - playerRoot.Position).Magnitude
                    if dist < ESP_RANGE then
                        color = Color3.fromRGB(0, 255, 0) -- Zielony
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
    print("[ESP] ON (szukam tylko broni w ręce)")
    
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
end)

print("=== SKRYPT ZAŁADOWANY ===")
print("X = FLY | Z = NOCLIP | C = ESP")
print("ESP szuka TYLKO BRONI W RĘCE (ignoruje broń na plecach)")
