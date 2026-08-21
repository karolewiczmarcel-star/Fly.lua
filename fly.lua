--[[
    IRIS IMGUI – FLY (X) + NOCLIP (Z) + ESP (C) + FLING (J)
    Wymaga: Iris v2.5.0+ (załadowane przez loadstring)
]]

-- ===== ZAŁADOWANIE IRIS =====
local Iris = loadstring(game:HttpGet("https://raw.githubusercontent.com/paradoxum-games/iris/main/out.lua"))()
Iris:Init()

-- ===== STANY =====
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
local espCon = nil
local espCache = {}
local ESP_REFRESH = 0.5
local ESP_RANGE = 500

-- ===== FLING =====
local selectedPlayer = nil
local flingEnabled = false

-- ===== IRIS STANY =====
local menuVisible = Iris.State(true)
local selectedPlayerState = Iris.State(nil)

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

-- ===== IRIS MENU =====
local function createIrisMenu()
    -- Ukryj domyślny kursor Robloxa, żeby nie przeszkadzał
    UserInputService.MouseIconEnabled = false
    
    Iris:Connect(function()
        -- Główne okno – sterowanie
        Iris.Window({ "KapitanBomba HACK" }, { 
            size = Iris.State(Vector2.new(350, 450)),
            position = Iris.State(Vector2.new(100, 100))
        })
        
        -- Sekcja: Sterowanie
        Iris.Separator()
        Iris.Text({ "STEROWANIE:" })
        Iris.Text({ "X = Fly | Z = Noclip | C = ESP" })
        Iris.Separator()
        
        -- Sekcja: Status
        Iris.Text({ "STATUS:" })
        Iris.Text({ "Fly: " .. (flying and "ON" or "OFF") })
        Iris.Text({ "Noclip: " .. (noclip and "ON" or "OFF") })
        Iris.Text({ "ESP: " .. (espEnabled and "ON" or "OFF") })
        Iris.Separator()
        
        -- Sekcja: Wybór gracza do flinga
        Iris.Text({ "WYBIERZ GRACZA DO FLINGA:" })
        
        -- Lista graczy (przyciski)
        local players = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(players, p)
            end
        end
        
        -- Sortuj alfabetycznie
        table.sort(players, function(a, b) return a.Name < b.Name end)
        
        for _, p in ipairs(players) do
            local btnText = p.Name
            if selectedPlayer == p then
                btnText = "▶ " .. p.Name .. " ◀"
            end
            
            local clicked = Iris.Button({ btnText })
            if clicked then
                selectedPlayer = p
                print("[MENU] Wybrano: " .. p.Name)
            end
        end
        
        Iris.Separator()
        
        -- Przycisk FLING
        local flingBtn = Iris.Button({ "🔥 FLING WYBRANEGO GRACZA" })
        if flingBtn then
            if selectedPlayer then
                flingPlayer(selectedPlayer)
            else
                print("[MENU] Brak wybranego gracza!")
            end
        end
        
        -- Jeśli nie ma graczy
        if #players == 0 then
            Iris.Text({ "❌ Brak innych graczy na serwerze" })
        end
        
        Iris.End()
    end)
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
    
    -- J = pokaż/ukryj menu Iris (domyślnie widoczne)
    if input.KeyCode == Enum.KeyCode.J then
        menuVisible:set(not menuVisible:get())
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
createIrisMenu()

print("=== IRIS MENU ZAŁADOWANE ===")
print("X = FLY | Z = NOCLIP | C = ESP")
print("J = pokaż/ukryj menu")
print("Wybierz gracza w menu i kliknij FLING")
