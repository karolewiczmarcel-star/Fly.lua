-- ===== WATERMARK (WYŻEJ I WIĘKSZY) =====
local function createWatermark()
    -- Sprawdź, czy już istnieje
    if game:GetService("CoreGui"):FindFirstChild("KapitanBombaWatermark") then
        return
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KapitanBombaWatermark"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    -- Główna ramka
    local frame = Instance.new("Frame")
    frame.Name = "WatermarkFrame"
    frame.Size = UDim2.new(0, 280, 0, 40)
    frame.Position = UDim2.new(1, -290, 0, 5) -- Wyżej (Y = 5)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Zaokrąglone rogi
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Czerwone obramowanie (neon)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = frame
    
    -- Tekst
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "WatermarkLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "🔥 KapitanBomba HACK 🔥"
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextSize = 50
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = frame
    
    -- Efekt pulsowania (opcjonalny)
    game:GetService("TweenService"):Create(textLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextTransparency = 0.1
    }):Play()
    
    -- Efekt migania obramowania (opcjonalny)
    game:GetService("TweenService"):Create(stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.05
    }):Play()
    
    print("[WATERMARK] KapitanBomba HACK dodany (wyżej i większy)")
end
