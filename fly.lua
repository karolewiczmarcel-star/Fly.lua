--[[
    FLY + NOCLIP + ESP (MM2) + ROTACJA + LOT W KIERUNKU PATRZENIA
    X = FLY | Z = NOCLIP | C = ESP
    W = lecisz tam, gdzie patrzysz (góra/dół też)
    Usunięto: Spacja (góra), Shift (dół)
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ===== WATERMARK =====
local function createWatermark()
    if game:GetService("CoreGui"):FindFirstChild("KapitanBombaWatermark") then
        return
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KapitanBombaWatermark"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Name = "WatermarkFrame"
    frame.Size = UDim2.new(0, 420, 0, 60)
    frame.Position = UDim2.new(1, -430, 0, 2)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 3
    stroke.Transparency = 0.15
    stroke.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "WatermarkLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "🔥 KapitanBomba HACK 🔥"
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextSize = 34
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.2
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = frame
    
    game:GetService("TweenService"):Create(textLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextTransparency = 0.05
    }):Play()
    
    game:GetService("TweenService"):Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.02
    }):Play()
    
    print("[WATERMARK] KapitanBomba HACK dodany")
end

-- ===== FLY =====
local flying = false
local flyCon = nil
local flySpeed = 50

-- ===== NOCLIP =====
local noclip = false
local noclipCon = nil

-- ===== ESP =====
local espEnabled = false
local espCon = nil
local espCache = {}
local espMemory = {}
local ROLE_TIMEOUT = 20

-- ===== FLY Z ROTACJĄ I LOTEM W KIERUNKU PATRZENIA =====
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
        
        -- 🔥 ROTACJA POSTACI W KIERUNKU KAMERY (PEŁNA, GÓRA/DÓŁ)
        local camLook = camera.CFrame.LookVector
        local targetCF = CFrame.lookAt(rootPart.Position, rootPart.Position + camLook)
        rootPart.CFrame = targetCF
        
        -- 🔥 LOT TYLKO POD W (w kierunku patrzenia)
        local input = UserInputService
        local move = Vector3.new(0, 0, 0)
        
        if input:IsKeyDown(Enum.KeyCode.W) then
            local forward = rootPart.CFrame.LookVector
            move = move + forward * flySpeed
        end
        
        -- 🔥 USUNIĘTO: Spacja (góra) i Shift (dół)
        -- Teraz tylko W steruje lotem w kierunku patrzenia
        
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

-- ===== ESP Z TRZEMA KOLORAMI (ZASIĘG 100) =====
local function updateESP()
    for _, target in ipairs(Players:GetPlayers()) do
        if target == player then continue end
        
        local char = target.Character
        local color = nil
        
        if char and char.Parent then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("dagger") or name:find("blade") then
                    color = Color3.fromRGB(255, 0, 0)
                    espMemory[target] = {color = color, role = "murderer", time = os.time() + ROLE_TIMEOUT}
                elseif name:find("gun") or name:find("pistol") or name:find("revolver") then
                    color = Color3.fromRGB(0, 128, 255)
                    espMemory[target] = {color = color, role = "sheriff", time = os.time() + ROLE_TIMEOUT}
                end
            else
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and player.Character then
                    local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if playerRoot then
                        local dist = (root.Position - playerRoot.Position).Magnitude
                        if dist < 100 then
                            color = Color3.fromRGB(0, 255, 0)
                            espMemory[target] = {color = color, role = "innocent", time = os.time() + ROLE_TIMEOUT}
                        end
                    end
                end
            end
        end
        
        if not color and espMemory[target] then
            if os.time() < espMemory[target].time then
                color = espMemory[target].color
            else
                espMemory[target] = nil
            end
        end
        
        if color then
            local highlight = espCache[target]
            if highlight and highlight.Parent then
                highlight.Color3 = color
            else
                highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Parent = char or workspace
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
    print("[ESP] ON (3 kolory, pamięć 20s, zasięg 100)")
    
    espCon = RunService.Heartbeat:Connect(function()
        if espEnabled then
            updateESP()
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
    espMemory = {}
end

-- ===== KLAWISZE =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        if flying then
            stopFly()
            print("[FLY] OFF")
        else
            startFly()
            print("[FLY] ON")
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

-- ===== START =====
createWatermark()

print("=== FINAL VERSION + WATERMARK ZAŁADOWANA ===")
print("[X] FLY | [Z] NOCLIP | [C] ESP")
print("W = lecisz tam, gdzie patrzysz (góra/dół też)")
print("Usunięto: Spacja (góra) i Shift (dół)")
print("Czerwony = Morderca | Niebieski = Szeryf | Zielony = Niewinni (100)")
