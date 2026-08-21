--[[
    ESP – NATYCHMIASTOWA REAKCJA NA BROŃ
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
local ESP_REFRESH = 0.5 -- co 0.5 sekundy
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

-- ===== ESP – NATYCHMIASTOWA REAKCJA =====
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
        
        -- 🔥 SZUKAMY BRONI OD NOWA ZA KAŻDYM RAZEM
        local hasKnife = false
        local hasGun = false
        
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("Tool") then
                local name = child.Name:lower()
                if name:find("knife") or name:find("dagger") or name:find("blade") or name:find("scythe") or name:find("sword") or name:find("axe") then
                    hasKnife = true
                    break
                elseif name:find("gun") or name:find("pistol") or name:find("revolver") or name:find("rifle") or name:find("shotgun") then
                    hasGun = true
                    break
                end
            end
        end
        
        -- 🔥 USTAW KOLOR NA PODSTAWIE BRONI
        if hasKnife then
            color = Color3.fromRGB(255, 0, 0) -- Czerwony (Morderca)
        elseif hasGun then
            color = Color3.fromRGB(0, 128, 255) -- Niebieski (Szeryf)
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
        
        -- Zastosuj highlight
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
print("ESP reaguje natychmiast na broń")
