--[[
    FINAL VERSION – FLY + NOCLIP + ESP (MM2) + WATERMARK
    X = FLY | Z = NOCLIP | C = ESP
    Watermark: "KapitanBomba HACK" (150% większy, wyżej)
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ===== WATERMARK (150% WIĘKSZY, WYŻEJ) =====
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
    
    print("[WATERMARK] KapitanBomba HACK dodany (150% większy, wyżej)")
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

-- ===== FLY =====
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
        
        local tool = char:FindFirstChildOfClass("Tool")
        local color = nil
        
        if tool then
            local name = tool.Name:lower()
            if name:find("knife") or name:find("dagger") or name:find("blade") then
                color = Color3.fromRGB(255, 0, 0)
            elseif name:find("gun") or name:find("pistol") or name:find("revolver") then
                color = Color3.fromRGB(0, 128, 255)
            end
        end
        
        if color then
            local highlight = espCache[target]
            if highlight and highlight.Parent then
                highlight.Color3 = color
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
print("Watermark: KapitanBomba HACK (150% większy, wyżej)")
