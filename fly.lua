--[[
    MEGA SKRYPT DO MM2
    X = włącz/wyłącz FLY
    Z = włącz/wyłącz NOCLIP
    C = włącz/wyłącz ESP (MM2)
    
    FLY: WASD = ruch, Spacja = góra, Shift = dół
    NOCLIP: przechodzenie przez ściany
    ESP: Morderca = Czerwony, Szeryf = Niebieski
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ===== FLY =====
local flying = false
local flyCon = nil
local flySpeed = 50

-- ===== NOCLIP =====
local noclip = false
local noclipCon = nil

-- ===== ESP =====
local espEnabled = false
local espConnections = {}
local espHighlights = {}

-- ===== FLY FUNKCJE =====
local function startFly()
    if flying then return end
    flying = true
    workspace.Gravity = 0
    
    flyCon = RunService.Heartbeat:Connect(function()
        if not flying then return end
        if not character or not character.Parent then
            stopFly()
            return
        end
        
        local input = UserInputService
        local move = Vector3.new(0, 0, 0)
        local forward = rootPart.CFrame.LookVector
        local right = rootPart.CFrame.RightVector
        local up = rootPart.CFrame.UpVector
        
        if input:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
        if input:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
        if input:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if input:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if input:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
        if input:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - up end
        
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

-- ===== NOCLIP FUNKCJE =====
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

-- ===== ESP FUNKCJE (MM2) =====
local function removeESP(target)
    local char = target.Character
    if char then
        local highlight = char:FindFirstChild("ESP_Highlight")
        if highlight then highlight:Destroy() end
    end
end

local function clearESP()
    for _, target in ipairs(Players:GetPlayers()) do
        removeESP(target)
    end
    espHighlights = {}
end

local function updateESP()
    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        
        local char = target.Character
        if not char or not char.Parent then
            removeESP(target)
            continue
        end
        
        -- Sprawdź broń
        local tool = char:FindFirstChildOfClass("Tool")
        local isMurderer = false
        local isSheriff = false
        
        if tool then
            local toolName = tool.Name:lower()
            if toolName:find("knife") or toolName:find("dagger") or toolName:find("blade") then
                isMurderer = true
            elseif toolName:find("gun") or toolName:find("pistol") or toolName:find("revolver") then
                isSheriff = true
            end
        end
        
        -- Ustaw kolor
        local color
        if isMurderer then
            color = Color3.new(1, 0, 0) -- Czerwony
        elseif isSheriff then
            color = Color3.new(0, 0.5, 1) -- Niebieski
        else
            removeESP(target)
            continue
        end
        
        -- Dodaj highlight
        local highlight = char:FindFirstChild("ESP_Highlight")
        if highlight then
            highlight.Color3 = color
        else
            highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Parent = char
            highlight.FillColor = color
            highlight.FillTransparency = 0.4
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true
    print("[ESP] ON (MM2)")
    
    local con = RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        updateESP()
    end)
    table.insert(espConnections, con)
    
    -- Nowi gracze
    local playerAddedCon = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function()
            if espEnabled then updateESP() end
        end)
    end)
    table.insert(espConnections, playerAddedCon)
    
    updateESP()
end

local function disableESP()
    if not espEnabled then return end
    espEnabled = false
    print("[ESP] OFF")
    
    for _, con in ipairs(espConnections) do
        con:Disconnect()
    end
    espConnections = {}
    clearESP()
end

-- ===== OBSŁUGA KLAWISZY =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- X = FLY
    if input.KeyCode == Enum.KeyCode.X then
        if flying then
            stopFly()
            print("[FLY] OFF")
        else
            startFly()
            print("[FLY] ON")
        end
    end
    
    -- Z = NOCLIP
    if input.KeyCode == Enum.KeyCode.Z then
        toggleNoclip()
    end
    
    -- C = ESP
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
        -- Poczekaj chwilę i włącz ESP ponownie
        task.wait(0.5)
        enableESP()
    end
end)

-- ===== START =====
print("=== MEGA SKRYPT ZAŁADOWANY ===")
print("[X] = FLY (WASD + Spacja/Shift)")
print("[Z] = NOCLIP (przechodzenie przez ściany)")
print("[C] = ESP MM2 (Morderca = Czerwony, Szeryf = Niebieski)")
print("=== POWODZENIA ===")
