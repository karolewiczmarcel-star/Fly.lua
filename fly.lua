--[[
    FLY (X) + NOCLIP (Z) + ESP (C) + FLING MENU (J)
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

local menuOpen = false
local menuGui = nil

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

-- ===== FLING =====
local function flingPlayer(target)
    if not target or target == player then return end
    
    local char = target.Character
    if not char or not char.Parent then return end
    
    local targetRoot = char:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    for i = 1, 5 do
        targetRoot.Velocity = Vector3.new(0, 50, 0) * (i * 10)
        task.wait(0.05)
    end
    
    targetRoot.Velocity = Vector3.new(0, 100, 0) + Vector3.new(50, 0, 50)
    task.wait(0.1)
    targetRoot.Velocity = Vector3.new(0, 200, 0) + Vector3.new(-50, 0, -50)
    
    print("[FLING] " .. target.Name .. " został wyrzucony!")
end

-- ===== MENU POD J =====
local function createMenu()
    if menuGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlingMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Name = "MenuFrame"
    frame.Size = UDim2.new(0, 260, 0, 300)
    frame.Position = UDim2.new(0.5, -130, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔥 FLING MENU 🔥"
    title.TextColor3 = Color3.fromRGB(255, 0, 0)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -30, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = frame
    closeBtn.Activated:Connect(function()
        toggleMenu()
    end)
    
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "PlayerList"
    listFrame.Size = UDim2.new(1, -10, 1, -40)
    listFrame.Position = UDim2.new(0, 5, 0, 35)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    listFrame.BackgroundTransparency = 0.3
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.Parent = frame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame
    
    menuGui = {
        Frame = frame,
        ScreenGui = screenGui,
        ListFrame = listFrame,
        ListLayout = listLayout
    }
    
    updatePlayerList()
end

local function updatePlayerList()
    if not menuGui then return end
    
    for _, child in ipairs(menuGui.ListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local players = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(players, p)
        end
    end
    
    table.sort(players, function(a, b) return a.Name < b.Name end)
    
    for _, p in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        btn.Text = p.Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = menuGui.ListFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn
        
        btn.Activated:Connect(function()
            flingPlayer(p)
        end)
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        end)
    end
    
    local count = #players
    menuGui.ListFrame.CanvasSize = UDim2.new(0, 0, 0, count * 32 + 10)
end

local function toggleMenu()
    if not menuGui then
        createMenu()
    end
    menuOpen = not menuOpen
    menuGui.Frame.Visible = menuOpen
    if menuOpen then
        print("[MENU] Otwarto")
        updatePlayerList()
        if not menuGui._refreshCon then
            menuGui._refreshCon = RunService.Heartbeat:Connect(function()
                if menuOpen and menuGui then
                    if not menuGui._lastUpdate or tick() - menuGui._lastUpdate > 2 then
                        updatePlayerList()
                        menuGui._lastUpdate = tick()
                    end
                end
            end)
        end
    else
        print("[MENU] Zamknięto")
        if menuGui and menuGui._refreshCon then
            menuGui._refreshCon:Disconnect()
            menuGui._refreshCon = nil
        end
    end
end

-- ===== KLAWISZE =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        if flying then stopFly() else startFly() end
    end
    
    if input.KeyCode == Enum.KeyCode.Z then
        toggleNoclip()
    end
    
    if input.KeyCode == Enum.KeyCode.C then
        if espEnabled then disableESP() else enableESP() end
    end
    
    if input.KeyCode == Enum.KeyCode.J then
        toggleMenu()
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
print("J = FLING MENU (lista graczy)")
