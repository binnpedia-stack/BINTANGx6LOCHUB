-- ============================================================
-- BINTANGX6LOCHUB — NON-PREMIUM FULL LOGIC
-- All free features wired to functional logic.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local PathService = game:GetService("PathfindingService")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CFG = {
    -- ESP
    MasterESP = true, KillerESP = true, SurvivorESP = true,
    GenESP = true, HookESP = false, PalletESP = false, VaultESP = false, GateESP = true,
    ESPRange = 999999, ESPFill = 0.6, ESPOutline = 0.1,
    -- Skill
    AutoSkillCheck = true, InstantSkillCheck = false, SkillCheckMode = "Perfect", SkillCheckSpeed = 1,
    -- Combat
    AutoParry = false, ParryRange = 14, ParryPingComp = true, ParryFacing = true,
    RevolverAimbot = false, RevolverAimbotKey = "MouseButton2", RevolverAimbotRadius = 150,
    SpearAimbot = false, SpearAimbotKey = "MouseButton2",
    -- Movement
    SpeedBoost = false, SpeedMult = 1.3,
    NoclipVaultsPallets = false,
    AlwaysFastVault = false, FakeVault = false,
    -- Teleport
    PathfindingTP = true,
    -- Visuals
    FullBright = false, NoFog = false, RemoveDOF = false, FOV = 70,
}

-- ============================================================
-- ESP CORE (PLAYERS & MAP)
-- ============================================================
local ActiveESP = { Players = {}, Map = {} }
local highlightParent = workspace

local function getColor(role)
    if role == "Killer" then return Color3.fromRGB(255,60,60) end
    if role == "SurvivorKnocked" then return Color3.fromRGB(255,180,60) end
    if role == "SurvivorInjured" then return Color3.fromRGB(255,120,60) end
    if role == "SurvivorHealthy" then return Color3.fromRGB(80,255,120) end
    if role == "Generator" then return Color3.fromRGB(0,200,255) end
    if role == "Hook" then return Color3.fromRGB(255,150,0) end
    if role == "Pallet" then return Color3.fromRGB(200,160,80) end
    if role == "Vault" then return Color3.fromRGB(180,180,180) end
    if role == "Gate" then return Color3.fromRGB(255,220,0) end
    return Color3.fromRGB(255,255,255)
end

local function isKiller(player)
    if player.Team and player.Team.Name == "Killer" then return true end
    if player:GetAttribute("Role") == "Killer" then return true end
    if player:GetAttribute("IsKiller") == true then return true end
    return false
end

local function createPlayerESP(player)
    if ActiveESP.Players[player] then return ActiveESP.Players[player] end
    local hl = Instance.new("Highlight")
    hl.FillTransparency = CFG.ESPFill
    hl.OutlineTransparency = CFG.ESPOutline
    hl.Enabled = false
    hl.Parent = highlightParent
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.Size = UDim2.new(0, 180, 0, 42)
    bb.Enabled = false
    bb.Parent = highlightParent
    local name = Instance.new("TextLabel", bb)
    name.Size = UDim2.new(1,0,0.5,0)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.fromRGB(255,255,255)
    name.TextStrokeTransparency = 0.4
    name.Font = Enum.Font.GothamBold
    name.TextSize = 12
    local info = Instance.new("TextLabel", bb)
    info.Size = UDim2.new(1,0,0.5,0)
    info.Position = UDim2.new(0,0,0.5,0)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(220,220,220)
    info.TextStrokeTransparency = 0.5
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    ActiveESP.Players[player] = { hl = hl, bb = bb, name = name, info = info }
    return ActiveESP.Players[player]
end

local function removePlayerESP(player)
    local e = ActiveESP.Players[player]
    if e then
        pcall(function() e.hl:Destroy() end)
        pcall(function() e.bb:Destroy() end)
        ActiveESP.Players[player] = nil
    end
end

local function updatePlayersESP()
    if not CFG.MasterESP then
        for p, e in pairs(ActiveESP.Players) do
            e.hl.Enabled = false
            e.bb.Enabled = false
        end
        return
    end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local killer = isKiller(plr)
                if (killer and CFG.KillerESP) or (not killer and CFG.SurvivorESP) then
                    local e = createPlayerESP(plr)
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d <= CFG.ESPRange then
                        local roleColor = getColor(killer and "Killer" or "SurvivorHealthy")
                        if plr.Character:GetAttribute("Knocked") then
                            roleColor = getColor("SurvivorKnocked")
                        elseif hum.Health < hum.MaxHealth then
                            roleColor = getColor("SurvivorInjured")
                        end
                        e.hl.Adornee = plr.Character
                        e.hl.FillColor = roleColor
                        e.hl.OutlineColor = roleColor
                        e.hl.Enabled = true
                        e.bb.Adornee = hrp
                        e.bb.Enabled = true
                        e.name.Text = plr.DisplayName
                        e.name.TextColor3 = roleColor
                        
                        local state = "Healthy"
                        if plr.Character:GetAttribute("Knocked") then state = "Knocked"
                        elseif plr.Character:GetAttribute("IsHooked") then state = "Hooked"
                        elseif hum.Health < hum.MaxHealth then state = "Injured" end
                        
                        e.info.Text = string.format("[%dm] %s | %s", math.floor(d), killer and "KILLER" or "SURVIVOR", state)
                    else
                        e.hl.Enabled = false
                        e.bb.Enabled = false
                    end
                else
                    local e = ActiveESP.Players[plr]
                    if e then e.hl.Enabled = false; e.bb.Enabled = false end
                end
            end
        end
    end
    for p in pairs(ActiveESP.Players) do
        if not p.Parent or not p.Character then removePlayerESP(p) end
    end
end

local function clearMapESP()
    for i, e in pairs(ActiveESP.Map) do
        pcall(function() e.hl:Destroy() end)
        pcall(function() e.bb:Destroy() end)
    end
    ActiveESP.Map = {}
end

local function scanMapESP()
    clearMapESP()
    if not CFG.MasterESP then return end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    
    for _, inst in ipairs(map:GetDescendants()) do
        local n = inst.Name
        local role = nil
        if n == "Generator" and inst:IsA("Model") then role = "Generator"
        elseif n == "Hook" or n == "HookPoint" then role = "Hook"
        elseif n == "Pallet" and inst:IsA("Model") then role = "Pallet"
        elseif n == "Window" or n == "Vault" then role = "Vault"
        elseif n == "ExitLever" then role = "Gate" end
        
        if role then
            local show = (role == "Generator" and CFG.GenESP)
                or (role == "Hook" and CFG.HookESP)
                or (role == "Pallet" and CFG.PalletESP)
                or (role == "Vault" and CFG.VaultESP)
                or (role == "Gate" and CFG.GateESP)
            if show then
                local hl = Instance.new("Highlight")
                hl.FillTransparency = CFG.ESPFill
                hl.OutlineTransparency = CFG.ESPOutline
                hl.FillColor = getColor(role)
                hl.OutlineColor = getColor(role)
                hl.Enabled = true
                hl.Adornee = inst
                hl.Parent = highlightParent
                
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.Size = UDim2.new(0, 120, 0, 20)
                bb.Enabled = true
                bb.Adornee = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")) or inst
                bb.Parent = highlightParent
                
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = getColor(role)
                lbl.TextStrokeTransparency = 0.4
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 11
                lbl.Text = role
                
                ActiveESP.Map[inst] = { hl = hl, bb = bb, label = lbl }
            end
        end
    end
end

-- ============================================================
-- SKILL CHECK LOGIC (AUTO / INSTANT)
-- ============================================================
local function getSkillGui()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild("SkillCheckPromptGui") or pg:FindFirstChild("SkillCheckPromptGui-con")
end

local function handleSkillCheck()
    local gui = getSkillGui()
    if not gui then return end
    local check = gui:FindFirstChild("Check")
    if not check or not check.Visible then return end
    
    local line = check:FindFirstChild("Line")
    local goal = check:FindFirstChild("TrapPerfect") or check:FindFirstChild("TrapGoal") or check:FindFirstChild("Goal")
    
    if line and goal then
        if CFG.InstantSkillCheck then
            -- Force perfect hit
            line.Rotation = goal.Rotation
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.02)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        elseif CFG.AutoSkillCheck then
            -- Calculate rotation logic
            local lRot = line.Rotation % 360
            local gRot = goal.Rotation % 360
            local diff = (gRot - lRot + 180) % 360 - 180
            if math.abs(diff) <= 5 then -- Hit zone tolerance
                VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.02)
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end
end

-- ============================================================
-- AIMBOT & SILENT AIM
-- ============================================================
local function getClosestTarget(maxDist, priority)
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= maxDist then
                        if priority == "Furthest" then
                            if d > bestDist then best, bestDist = plr, d end
                        else
                            if d < bestDist then best, bestDist = plr, d end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function updateAimbot()
    if not CFG.RevolverAimbot then return end
    local key = CFG.RevolverAimbotKey
    local isPressed = false
    if key == "MouseButton2" then isPressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif key == "MouseButton1" then isPressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    else isPressed = UIS:IsKeyDown(Enum.KeyCode[key]) end
    
    if isPressed then
        local target = getClosestTarget(CFG.RevolverAimbotRadius, "Nearest")
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
            end
        end
    end
end

-- Hook Silent Aim for Revolver & Spear
local function setupSilentAim()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" then
            local n = self.Name:lower()
            -- Twist of Fate (Revolver)
            if n == "fire" and self.Parent and self.Parent.Name:lower():find("twist") then
                local target = getClosestTarget(200, "Nearest")
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                    if head and args[2] then
                        args[2] = (head.Position - Camera.CFrame.Position).Unit
                    end
                    return oldNamecall(self, unpack(args))
                end
            -- Veil Spear
            elseif n == "spearthrow" then
                local target = getClosestTarget(240, "Nearest")
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                    if head and args[1] then
                        args[1] = { Origin = Camera.CFrame.Position, Direction = (head.Position - Camera.CFrame.Position).Unit }
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- ============================================================
-- AUTO PARRY & FAST VAULT
-- ============================================================
local parryAnimIds = {
    ["71008020992570"]=true, ["72742711718023"]=true, ["72908958549833"]=true, ["73681849513551"]=true,
    ["73923929500477"]=true, ["74968262036854"]=true, ["75857500533792"]=true, ["76385865186777"]=true,
    ["76503974441748"]=true, ["76744850905644"]=true, ["77081789642514"]=true, ["78432063483146"]=true,
}

local function fireParry()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local s = pg and (pg:FindFirstChild("Survivor") or pg:FindFirstChild("Survivor-mob"))
    local c = s and s:FindFirstChild("Controls")
    local a = c and c:FindFirstChild("action")
    if a then
        if firesignal then
            pcall(firesignal, a.MouseButton1Down)
            pcall(firesignal, a.MouseButton1Click)
        end
    end
end

local function setupParry()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and isKiller(plr) and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator and not animator:GetAttribute("VD_Hooked") then
                animator:SetAttribute("VD_Hooked", true)
                animator.AnimationPlayed:Connect(function(track)
                    if not CFG.AutoParry then return end
                    local id = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
                    if id and parryAnimIds[id] then
                        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local killerHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP and killerHRP then
                            if (myHRP.Position - killerHRP.Position).Magnitude <= CFG.ParryRange then
                                fireParry()
                            end
                        end
                    end
                end)
            end
        end
    end
end

local function setupFastVault()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and typeof(self) == "Instance" then
            if self.Name == "VaultEvent" and CFG.AlwaysFastVault then
                local args = {...}
                if args[2] == false then args[2] = true end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- ============================================================
-- TELEPORT
-- ============================================================
local function tpTo(targetType)
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local best, bestDist = nil, math.huge
    
    for _, d in ipairs(map:GetDescendants()) do
        local n = d.Name
        if (targetType == "Generator" and n == "Generator")
            or (targetType == "Hook" and (n == "Hook" or n == "HookPoint"))
            or (targetType == "Pallet" and n == "Pallet")
            or (targetType == "Vault" and (n == "Window" or n == "Vault"))
            or (targetType == "Gate" and n == "ExitLever") then
            local bp = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
            if bp then
                local dist = (bp.Position - myHRP.Position).Magnitude
                if dist < bestDist then best, bestDist = bp, dist end
            end
        end
    end
    if best then
        if CFG.PathfindingTP then
            local path = PathService:CreatePath({AgentRadius=2, AgentHeight=5, AgentCanJump=true})
            local success, _ = pcall(function() path:ComputeAsync(myHRP.Position, best.Position) end)
            if success and path.Status == Enum.PathStatus.Success then
                for _, wp in ipairs(path:GetWaypoints()) do
                    myHRP.CFrame = CFrame.new(wp.Position + Vector3.new(0, 3, 0))
                end
            else
                myHRP.CFrame = best.CFrame + Vector3.new(0, 3, 0)
            end
        else
            myHRP.CFrame = best.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

-- ============================================================
-- RENDER & UPDATE LOOPS
-- ============================================================
RunService.RenderStepped:Connect(function()
    pcall(updatePlayersESP)
    pcall(updateAimbot)
    if CFG.AutoSkillCheck or CFG.InstantSkillCheck then
        pcall(handleSkillCheck)
    end
end)

RunService.Heartbeat:Connect(function()
    if CFG.SpeedBoost then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.05 then
            local spd = char:GetAttribute("Speed") or 16
            local target = spd * CFG.SpeedMult
            local dir = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * target, hrp.AssemblyLinearVelocity.Y, dir.Z * target)
        end
    end
    
    if CFG.NoclipVaultsPallets then
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end

    if CFG.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.GlobalShadows = false
    end
    if CFG.NoFog then
        Lighting.FogStart = 1e6
        Lighting.FogEnd = 1e6
    end
    if Camera then Camera.FieldOfView = CFG.FOV end
end)

-- ============================================================
-- UI (DASHBOARD)
-- ============================================================
local function buildUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BintangX6LocHUB"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 680, 0, 440)
    main.Position = UDim2.new(0.5, -340, 0.5, -220)
    main.BackgroundColor3 = Color3.fromRGB(18,19,24)
    main.BorderSizePixel = 0
    main.Active = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
    local ms = Instance.new("UIStroke", main)
    ms.Color = Color3.fromRGB(45,47,58)
    ms.Thickness = 1.5

    local side = Instance.new("Frame", main)
    side.Size = UDim2.new(0, 160, 1, 0)
    side.BackgroundColor3 = Color3.fromRGB(13,14,18)
    side.BorderSizePixel = 0
    Instance.new("UICorner", side).CornerRadius = UDim.new(0,10)

    -- Header Sidebar
    local logo = Instance.new("Frame", side)
    logo.Size = UDim2.new(1, -20, 0, 60)
    logo.Position = UDim2.new(0, 10, 0, 0)
    logo.BackgroundTransparency = 1
    local lt = Instance.new("TextLabel", logo)
    lt.Size = UDim2.new(1,0,0,22)
    lt.Position = UDim2.new(0,0,0,15)
    lt.BackgroundTransparency = 1
    lt.Text = "BintangX6LocHUB"
    lt.TextColor3 = Color3.fromRGB(255,255,255)
    lt.Font = Enum.Font.GothamBold
    lt.TextSize = 13
    lt.TextXAlignment = Enum.TextXAlignment.Left

    local tabHolder = Instance.new("Frame", side)
    tabHolder.Size = UDim2.new(1,-12,1,-110)
    tabHolder.Position = UDim2.new(0,6,0,70)
    tabHolder.BackgroundTransparency = 1
    local tl = Instance.new("UIListLayout", tabHolder)
    tl.Padding = UDim.new(0,4)
    tl.SortOrder = Enum.SortOrder.LayoutOrder

    local pages = {}
    local tabButtons = {}

    local function makeTab(id, icon, name, order)
        local b = Instance.new("TextButton", tabHolder)
        b.Size = UDim2.new(1,0,0,32)
        b.BackgroundColor3 = Color3.fromRGB(22,24,30)
        b.BackgroundTransparency = 0.6
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = order
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        local ic = Instance.new("TextLabel", b)
        ic.Size = UDim2.new(0,20,1,0)
        ic.Position = UDim2.new(0,8,0,0)
        ic.BackgroundTransparency = 1
        ic.Text = icon
        ic.TextColor3 = Color3.fromRGB(200,200,215)
        ic.TextSize = 14
        local tx = Instance.new("TextLabel", b)
        tx.Size = UDim2.new(1,-34,1,0)
        tx.Position = UDim2.new(0,32,0,0)
        tx.BackgroundTransparency = 1
        tx.Text = name
        tx.TextColor3 = Color3.fromRGB(200,200,215)
        tx.Font = Enum.Font.GothamBold
        tx.TextSize = 11
        tx.TextXAlignment = Enum.TextXAlignment.Left
        tabButtons[id] = { btn = b, txt = tx, ic = ic }
        b.MouseButton1Click:Connect(function()
            for _, tb in pairs(tabButtons) do
                tb.btn.BackgroundTransparency = 0.6
                tb.btn.BackgroundColor3 = Color3.fromRGB(22,24,30)
                tb.txt.TextColor3 = Color3.fromRGB(200,200,215)
                tb.ic.TextColor3 = Color3.fromRGB(200,200,215)
            end
            b.BackgroundTransparency = 0
            b.BackgroundColor3 = Color3.fromRGB(30,32,42)
            tx.TextColor3 = Color3.fromRGB(255,255,255)
            ic.TextColor3 = Color3.fromRGB(255,255,255)
            for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
        end)
        return b
    end

    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1,-170,1,-20)
    content.Position = UDim2.new(0,165,0,10)
    content.BackgroundTransparency = 1

    local function makePage(id)
        local f = Instance.new("ScrollingFrame", content)
        f.Size = UDim2.new(1,0,1,0)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ScrollBarThickness = 3
        f.ScrollBarImageColor3 = Color3.fromRGB(80,85,100)
        f.CanvasSize = UDim2.new(0,0,0,0)
        f.AutomaticCanvasSize = Enum.AutomaticSize.Y
        f.Visible = false
        local ll = Instance.new("UIListLayout", f)
        ll.Padding = UDim.new(0,6)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        pages[id] = f
        return f
    end

    local function section(parent, text)
        local l = Instance.new("TextLabel", parent)
        l.Size = UDim2.new(1,0,0,22)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(120,130,150)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function toggle(parent, label, key, order, callback)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1,0,0,32)
        b.BackgroundColor3 = Color3.fromRGB(22,24,30)
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = order
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        local kn = Instance.new("Frame", b)
        kn.Size = UDim2.new(0,26,0,14)
        kn.Position = UDim2.new(1,-36,0.5,-7)
        kn.BackgroundColor3 = CFG[key] and Color3.fromRGB(80,180,120) or Color3.fromRGB(45,47,58)
        kn.BorderSizePixel = 0
        Instance.new("UICorner", kn).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", kn)
        dot.Size = UDim2.new(0,10,0,10)
        dot.Position = CFG[key] and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
        dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local l = Instance.new("TextLabel", b)
        l.Size = UDim2.new(1,-50,1,0)
        l.Position = UDim2.new(0,10,0,0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = Color3.fromRGB(220,220,230)
        l.Font = Enum.Font.Gotham
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        b.MouseButton1Click:Connect(function()
            CFG[key] = not CFG[key]
            kn.BackgroundColor3 = CFG[key] and Color3.fromRGB(80,180,120) or Color3.fromRGB(45,47,58)
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = CFG[key] and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)}):Play()
            if callback then pcall(callback, CFG[key]) end
        end)
    end

    local function button(parent, label, cb, order, col)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1,0,0,32)
        b.BackgroundColor3 = col or Color3.fromRGB(30,32,42)
        b.BorderSizePixel = 0
        b.Text = label
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.LayoutOrder = order
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        b.MouseButton1Click:Connect(cb)
    end

    local function slider(parent, label, key, min, max, order)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1,0,0,46)
        f.BackgroundColor3 = Color3.fromRGB(22,24,30)
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1,-16,0,18)
        l.Position = UDim2.new(0,10,0,3)
        l.BackgroundTransparency = 1
        l.Text = label .. ": " .. tostring(CFG[key])
        l.TextColor3 = Color3.fromRGB(220,220,230)
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", f)
        bar.Size = UDim2.new(1,-20,0,6)
        bar.Position = UDim2.new(0,10,0,30)
        bar.BackgroundColor3 = Color3.fromRGB(45,47,58)
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)
        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new((CFG[key]-min)/(max-min),0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,255,255)
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
        local dragging = false
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
        bar.InputEnded:Connect(function() dragging = false end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local v = min + rel * (max - min)
                CFG[key] = v
                fill.Size = UDim2.new(rel,0,1,0)
                l.Text = label .. ": " .. string.format("%.1f", v)
            end
        end)
    end

    -- TABS
    makeTab("Combat", "⚔", "Combat", 1)
    makeTab("ESP", "👁", "ESP", 2)
    makeTab("Movement", "🏃", "Movement", 3)
    makeTab("Visuals", "🎨", "Visuals", 4)
    makeTab("Teleport", "📍", "Teleport", 5)

    -- Combat Page
    local cb = makePage("Combat")
    section(cb, "Skill Check")
    toggle(cb, "Auto Skill Check", "AutoSkillCheck", 1)
    toggle(cb, "Instant Skill Check", "InstantSkillCheck", 2)
    slider(cb, "Skill Check Speed", "SkillCheckSpeed", 1, 3, 3)
    section(cb, "Aimbot")
    toggle(cb, "Revolver Aimbot", "RevolverAimbot", 10)
    slider(cb, "Aimbot Radius", "RevolverAimbotRadius", 50, 400, 11)
    section(cb, "Parry (Killer)")
    toggle(cb, "Auto Parry", "AutoParry", 20)
    slider(cb, "Parry Range", "ParryRange", 6, 25, 21)

    -- ESP Page
    local ep = makePage("ESP")
    section(ep, "Player ESP")
    toggle(ep, "Master ESP", "MasterESP", 1, scanMapESP)
    toggle(ep, "Killer ESP", "KillerESP", 2)
    toggle(ep, "Survivor ESP", "SurvivorESP", 3)
    section(ep, "Map ESP")
    toggle(ep, "Generator", "GenESP", 10, scanMapESP)
    toggle(ep, "Gate", "GateESP", 11, scanMapESP)
    toggle(ep, "Hook", "HookESP", 12, scanMapESP)
    toggle(ep, "Pallet", "PalletESP", 13, scanMapESP)
    toggle(ep, "Vault", "VaultESP", 14, scanMapESP)

    -- Movement Page
    local mv = makePage("Movement")
    section(mv, "Speed")
    toggle(mv, "Speed Boost", "SpeedBoost", 1)
    slider(mv, "Speed Multiplier", "SpeedMult", 1, 3, 2)
    section(mv, "Vault/Pallet")
    toggle(mv, "Always Fast Vault", "AlwaysFastVault", 10)
    toggle(mv, "Noclip Vaults & Pallets", "NoclipVaultsPallets", 11)

    -- Visuals Page
    local vs = makePage("Visuals")
    section(vs, "Lighting")
    toggle(vs, "Full Bright", "FullBright", 1)
    toggle(vs, "No Fog", "NoFog", 2)
    section(vs, "Camera")
    slider(vs, "Field of View", "FOV", 70, 160, 10)

    -- Teleport Page
    local tp = makePage("Teleport")
    section(tp, "Quick Teleport")
    button(tp, "TP Generator", function() tpTo("Generator") end, 1)
    button(tp, "TP Gate", function() tpTo("Gate") end, 2)
    button(tp, "TP Hook", function() tpTo("Hook") end, 3)
    button(tp, "TP Pallet", function() tpTo("Pallet") end, 4)
    button(tp, "TP Vault", function() tpTo("Vault") end, 5)

    -- Footer
    local foot = Instance.new("Frame", side)
    foot.Size = UDim2.new(1,-16,0,40)
    foot.Position = UDim2.new(0,8,1,-48)
    foot.BackgroundColor3 = Color3.fromRGB(22,24,30)
    foot.BorderSizePixel = 0
    Instance.new("UICorner", foot).CornerRadius = UDim.new(0,6)
    local av = Instance.new("ImageLabel", foot)
    av.Size = UDim2.new(0,28,0,28)
    av.Position = UDim2.new(0,6,0.5,-14)
    av.BackgroundColor3 = Color3.fromRGB(30,32,42)
    av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=48&h=48"
    Instance.new("UICorner", av).CornerRadius = UDim.new(1,0)
    local un = Instance.new("TextLabel", foot)
    un.Size = UDim2.new(1,-44,0,14)
    un.Position = UDim2.new(0,40,0,6)
    un.BackgroundTransparency = 1
    un.Text = LP.DisplayName
    un.TextColor3 = Color3.fromRGB(255,255,255)
    un.Font = Enum.Font.GothamBold
    un.TextSize = 11
    un.TextXAlignment = Enum.TextXAlignment.Left

    -- BH Button
    local bh = Instance.new("TextButton", sg)
    bh.Size = UDim2.new(0, 40, 0, 40)
    bh.Position = UDim2.new(0, 20, 0, 200)
    bh.BackgroundColor3 = Color3.fromRGB(18,19,24)
    bh.BorderSizePixel = 0
    bh.Text = "BH"
    bh.TextColor3 = Color3.fromRGB(255,255,255)
    bh.Font = Enum.Font.GothamBold
    bh.TextSize = 13
    bh.AutoButtonColor = false
    bh.ZIndex = 5
    Instance.new("UICorner", bh).CornerRadius = UDim.new(1,0)
    bh.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

    -- Drag
    local dragging, ds, sp
    local dh = Instance.new("Frame", main)
    dh.Size = UDim2.new(0,160,0,60)
    dh.Position = UDim2.new(0,0,0,0)
    dh.BackgroundTransparency = 1
    dh.Active = true
    dh.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; ds = i.Position; sp = main.Position end end)
    dh.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
    dh.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

    tabButtons["Combat"].btn.MouseButton1Click:Fire()
end

-- ============================================================
-- INIT
-- ============================================================
task.spawn(function()
    while not LP do task.wait(0.5); LP = Players.LocalPlayer end
    pcall(setupSilentAim)
    pcall(setupFastVault)
    task.spawn(function() while true do task.wait(3); pcall(scanMapESP); pcall(setupParry) end end)
    buildUI()
end)