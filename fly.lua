--[[
    ESP – SZUKA PO KSZTAŁCIE (MeshId, Size)
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

-- ===== ESP – SZUKA PO KSZTAŁCIE =====
local function isKnifeShape(part)
    -- Sprawdź, czy część wygląda jak nóż (długi, cienki, spiczasty)
    if part:IsA("MeshPart") then
        local size = part.Size
        -- Nóż jest zazwyczaj długi w jednej osi, cienki w pozostałych
        if size.X > 1.5 and size.Y < 0.8 and size.Z < 0.8 then
            return true
        end
        if size.Z > 1.5 and size.X < 0.8 and size.Y < 0.8 then
            return true
        end
        -- Sprawdź MeshId (często noże mają specyficzne ID)
        if part.MeshId and (part.MeshId:find("knife") or part.MeshId:find("dagger") or part.MeshId:find("blade")) then
            return true
        end
    end
    -- Sprawdź, czy część ma Handle (często broń ma Handle jako rodzic)
    if part.Parent and part.Parent:FindFirstChild("Handle") then
        return true
    end
    return false
end

local function isGunShape(part)
    -- Sprawdź, czy część wygląda jak pistolet (krótszy, szerszy)
    if part:IsA("MeshPart") then
        local size = part.Size
        -- Pistolet jest zazwyczaj krótszy i szerszy niż nóż
        if size.X > 0.8 and size.X < 2 and size.Y > 0.5 and size.Y < 1.5 and size.Z > 0.5 and size.Z < 1.5 then
            return true
        end
        -- Sprawdź MeshId
        if part.MeshId and (part.MeshId:find("gun") or part.MeshId:find("pistol") or part.MeshId:find("revolver")) then
            return true
        end
    end
    return false
end

local function findWeaponByShape(char)
    if not char then return nil, nil end
    
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("MeshPart") or child:IsA("Part") then
            if isKnifeShape(child) then
                return "knife", child
            end
            if isGunShape(child) then
                return "gun", child
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
        local weaponType, weapon = findWeaponByShape(char)
        
        if weaponType == "knife" then
            color = Color3.fromRGB(255, 0, 0) -- Czerwony
            print("[DEBUG] " .. target.Name .. " ma NÓŻ (kształt)")
        elseif weaponType == "gun" then
            color = Color3.fromRGB(0, 128, 255) -- Niebieski
            print("[DEBUG] " .. target.Name .. " ma PISTOLET (kształt)")
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
    print("[ESP] ON (szukanie po kształcie)")
    
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
print("ESP szuka po KSZTAŁCIE (długi = nóż, krótki/szeroki = pistolet)")
