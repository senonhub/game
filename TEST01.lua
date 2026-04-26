--// LOAD UI
local Library = loadstring(game:HttpGet('https://gist.githubusercontent.com/MjContiga1/6e2c779299e9bf3d3f9edb5bff97b2fb/raw/29b9f1cc215ad4e583271d1ad229f34c921553a8/Lib%2520ui%2520test.lua'))()
local window = Library:Window('AutoFarm')
local mainTab = window:Tab('Main')
local settingsTab = window:Tab('SETTINGS')
local bossTab = window:Tab('BOSS')

--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local teleportRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TeleportToPortal")

--// CONFIG
local saveFile = "autofarm_config.json"

--// SETTINGS
local weaponFarm     = false
local farmSpeed      = 0.50
local isRunning      = false
local hideEnabled    = false
local selectedIslands = {}
local weaponName     = "Strongest In History"
local autoRejoin     = false
local bossFarm       = false
local activeFarm     = "none"
local selectedBosses = {}

--// WEAPON FARM
local switchDelay = 0.5
local fSpamDelay  = 0.1
local weapons     = {"Anos", "Strongest Of Today"}
local equipRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipWeapon")

local function equipWeaponSafe(wName)
    local char = player.Character
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name == wName then return end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(wName)
        if tool then tool.Parent = char return end
    end
    pcall(function() equipRemote:FireServer("Equip", wName) end)
end

local function unanchorHRP()
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end
end

--// SAVE / LOAD
local function saveConfig()
    if not writefile then return end
    pcall(function()
        local data = {
            auto = isRunning, hide = hideEnabled, weapon = weaponFarm,
            rejoin = autoRejoin, farmSpeed = farmSpeed,
            islands = selectedIslands, bossFarm = bossFarm, bosses = selectedBosses
        }
        writefile(saveFile, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(saveFile) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(saveFile)) end)
    if not ok or not data then return end
    isRunning   = data.auto      or false
    hideEnabled = data.hide      or false
    weaponFarm  = data.weapon    or false
    autoRejoin  = data.rejoin    or false
    farmSpeed   = data.farmSpeed or 0.25
    if data.islands then for k,v in pairs(data.islands) do selectedIslands[k] = v end end
    bossFarm = data.bossFarm or false
    if data.bosses then for k,v in pairs(data.bosses) do selectedBosses[k] = v end end
end
loadConfig()

-- ══════════════════════════════════════════════
--// ANTI AFK  (รันตลอดเวลา)
-- ══════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(60)
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end)

-- ══════════════════════════════════════════════
--// HUD  (ลาก + พับ + bounty)
-- ══════════════════════════════════════════════
local hud = Instance.new("ScreenGui")
hud.Name         = "AutoFarmHUD"
hud.ResetOnSpawn = false
pcall(function() hud.Parent = CoreGui end)

local frame = Instance.new("Frame")
frame.Parent           = hud
frame.Size             = UDim2.new(0, 230, 0, 110)
frame.Position         = UDim2.new(0, 12, 0, 180)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel  = 0
frame.Active           = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Parent           = frame
header.Size             = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel  = 0

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 8)
hCorner.Parent = header

local title = Instance.new("TextLabel")
title.Parent               = header
title.Size                 = UDim2.new(1, -36, 1, 0)
title.Position             = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3           = Color3.fromRGB(220, 220, 255)
title.Font                 = Enum.Font.GothamBold
title.TextSize             = 13
title.TextXAlignment       = Enum.TextXAlignment.Left
title.Text                 = "⚔ AutoFarm HUD"

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent           = header
toggleBtn.Size             = UDim2.new(0, 28, 0, 22)
toggleBtn.Position         = UDim2.new(1, -30, 0, 3)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
toggleBtn.TextColor3       = Color3.fromRGB(200, 200, 255)
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.TextSize         = 14
toggleBtn.Text             = "−"
toggleBtn.BorderSizePixel  = 0
local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 5)
bCorner.Parent = toggleBtn

-- Content
local content = Instance.new("Frame")
content.Parent               = frame
content.Size                 = UDim2.new(1, 0, 1, -28)
content.Position             = UDim2.new(0, 0, 0, 28)
content.BackgroundTransparency = 1

local function makeLabel(yPos, color)
    local l = Instance.new("TextLabel")
    l.Parent               = content
    l.Size                 = UDim2.new(1, -16, 0, 20)
    l.Position             = UDim2.new(0, 8, 0, yPos)
    l.BackgroundTransparency = 1
    l.TextColor3           = color or Color3.fromRGB(200, 200, 200)
    l.Font                 = Enum.Font.Gotham
    l.TextSize             = 12
    l.TextXAlignment       = Enum.TextXAlignment.Left
    l.Text                 = "—"
    return l
end

local bountyLabel = makeLabel(4,  Color3.fromRGB(255, 220, 60))
local statusLabel = makeLabel(26, Color3.fromRGB(120, 220, 120))
local farmLabel   = makeLabel(48, Color3.fromRGB(160, 200, 255))
local bossLabel   = makeLabel(70, Color3.fromRGB(255, 140, 140))

-- พับ / กาง
local collapsed = false
toggleBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    frame.Size     = collapsed and UDim2.new(0, 230, 0, 28) or UDim2.new(0, 230, 0, 110)
    toggleBtn.Text = collapsed and "+" or "−"
end)

-- Drag
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ══════════════════════════════════════════════
--// BOUNTY
-- ══════════════════════════════════════════════
local function findBounty()
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        for _, v in pairs(stats:GetChildren()) do
            if string.find(string.lower(v.Name), "bounty") then return v end
        end
    end
    for _, v in pairs(player:GetDescendants()) do
        if (v:IsA("IntValue") or v:IsA("NumberValue"))
        and string.find(string.lower(v.Name), "bounty") then return v end
    end
    return nil
end

local function fmt(n)
    if n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function setupBounty()
    local bounty = findBounty()
    if not bounty then bountyLabel.Text = "💰 Bounty: not found" return end
    bountyLabel.Text = "💰 Bounty: " .. fmt(bounty.Value)
    bounty:GetPropertyChangedSignal("Value"):Connect(function()
        bountyLabel.Text = "💰 Bounty: " .. fmt(bounty.Value)
    end)
end

if player.Character then setupBounty()
else player.CharacterAdded:Wait() task.wait(1) setupBounty() end

-- Status update
task.spawn(function()
    while true do
        task.wait(0.5)
        statusLabel.Text = "⚡ Farm: " .. (isRunning and "ON" or "OFF")
            .. "   Boss: " .. (bossFarm and "ON" or "OFF")
        local iName, bName = "—", "—"
        for name, v in pairs(selectedIslands) do if v then iName = name break end end
        for name, v in pairs(selectedBosses)  do if v then bName = name break end end
        farmLabel.Text = "🗺 Island: " .. iName
        bossLabel.Text = "👹 Boss: "   .. bName
    end
end)

-- ══════════════════════════════════════════════
--// AUTO REJOIN
-- ══════════════════════════════════════════════
local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
if promptGui and promptGui:FindFirstChild("promptOverlay") then
    promptGui.promptOverlay.ChildAdded:Connect(function(child)
        if autoRejoin and child.Name == "ErrorPrompt" then
            task.wait(2)
            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end

-- ══════════════════════════════════════════════
--// HIDE WORLD
-- ══════════════════════════════════════════════
local hiddenFolder = Instance.new("Folder")
hiddenFolder.Parent = ReplicatedStorage
local hidingLoop = false

local function startHide()
    hidingLoop = true
    task.spawn(function()
        while hidingLoop do
            local char = player.Character
            for _, v in pairs(workspace:GetChildren()) do
                if v ~= char and v.Name ~= "Camera" and v.Name ~= "Terrain"
                and not selectedIslands[v.Name] then
                    pcall(function() v.Parent = hiddenFolder end)
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopHide()
    hidingLoop = false
    for _, v in pairs(hiddenFolder:GetChildren()) do v.Parent = workspace end
end

-- ══════════════════════════════════════════════
--// WEAPON LOOPS
-- ══════════════════════════════════════════════
task.spawn(function()
    local index = 1
    while true do
        if weaponFarm then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            if weapons[index] then pcall(function() equipWeaponSafe(weapons[index]) end) end
            index = index % #weapons + 1
            task.wait(switchDelay)
        else task.wait(0.2) end
    end
end)

task.spawn(function()
    while true do
        if weaponFarm then
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            task.wait(fSpamDelay)
        else task.wait(0.2) end
    end
end)

-- ══════════════════════════════════════════════
--// BOSS DATA
-- ══════════════════════════════════════════════
local Bosses = {
    { name="Shibuya",   remoteName="Shibuya",   farmPoints={
        CFrame.new(1844.276978,8.486135,332.343933)*CFrame.Angles(0,-1.151117,0),
        CFrame.new(1523.045776,8.486135,222.293930)*CFrame.Angles(0,1.032041,0),
        CFrame.new(1585.698975,72.720535,-14.644113)*CFrame.Angles(0,0.331550,0) }},
    { name="Sailor",    remoteName="Sailor",    farmPoints={
        CFrame.new(249.164780,7.593238,920.676636)*CFrame.Angles(-3.141593,-0.030496,3.141593) }},
    { name="Ninja",     remoteName="Ninja",     farmPoints={
        CFrame.new(-2102.323975,12.801344,-593.768005)*CFrame.Angles(0,1.264190,0) }},
    { name="Hollow",    remoteName="Hollow",    farmPoints={
        CFrame.new(-561.725403,-1.921275,1218.843140)*CFrame.Angles(0,-0.024930,0) }},
    { name="Judgement", remoteName="Judgement", farmPoints={
        CFrame.new(-1401.960571,21.119366,-1375.238647)*CFrame.Angles(0,1.156247,0) }},
}
for _, v in ipairs(Bosses) do
    if selectedBosses[v.name] == nil then selectedBosses[v.name] = false end
end

-- ══════════════════════════════════════════════
--// ISLAND DATA
-- ══════════════════════════════════════════════
local Islands = {
    { name="Soul Dominion",    remoteName="SoulDominion", farmPoints={ CFrame.new(-1337.597290,1604.373291,1591.893555)*CFrame.Angles(-3.141593,1.567292,-3.141593) }},
    { name="Lawless Island",   remoteName="Lawless",      farmPoints={ CFrame.new(63,0,1817) }},
    { name="Ninja Island",     remoteName="Ninja",        farmPoints={ CFrame.new(-1870,8,-738) }},
    { name="Judgement Island", remoteName="Judgement",    farmPoints={ CFrame.new(-1273,1,-1187) }},
    { name="Academy Island",   remoteName="Academy",      farmPoints={ CFrame.new(1069,1,1273) }},
    { name="Slime Island",     remoteName="Slime",        farmPoints={ CFrame.new(177,11,-159) }},
    { name="Shinjuku Island",  remoteName="Shinjuku",     farmPoints={ CFrame.new(-16,1,-1843), CFrame.new(664,1,-1696) }},
    { name="Hueco Mundo",      remoteName="Hueco",        farmPoints={ CFrame.new(-368,0,1096) }},
    { name="Shibuya Station",  remoteName="Shibuya",      farmPoints={ CFrame.new(1399,8,486) }},
    { name="Snow Island",      remoteName="Snow",         farmPoints={ CFrame.new(-406,-1,-994) }},
    { name="Desert Island",    remoteName="Desert",       farmPoints={ CFrame.new(-787,-4,-430) }},
    { name="Jungle Island",    remoteName="Jungle",       farmPoints={ CFrame.new(-566,0,402) }},
    { name="Starter Island",   remoteName="Starter",      farmPoints={ CFrame.new(177,11,-159) }},
    { name="Bizarre",          remoteName="Bizarre",      farmPoints={ CFrame.new(-3073.359131,7.518671,-666.597839)*CFrame.Angles(0,0.624027,0) }},
    { name="Punch",            remoteName="Punch",        farmPoints={ CFrame.new(-1579.000732,2.682251,1841.026123)*CFrame.Angles(0,-0.063341,0) }},
    { name="StarterSea2",      remoteName="StarterSea2",  farmPoints={ CFrame.new(-324.656219,-3.666585,-121.629074)*CFrame.Angles(0,-1.448254,0), CFrame.new(-192.417801,22.093403,-456.088654)*CFrame.Angles(0,-0.453476,0) }},
    { name="Easter",           remoteName="Easter",       farmPoints={ CFrame.new(2303.542236,6.180947,2224.365234)*CFrame.Angles(0,-0.762560,0) }},
}
for _, v in ipairs(Islands) do
    if selectedIslands[v.name] == nil then selectedIslands[v.name] = false end
end

-- ══════════════════════════════════════════════
--// AUTO EQUIP + SPAM X
-- ══════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.3)
        if isRunning or bossFarm then
            local char    = player.Character
            local backpack = player:FindFirstChild("Backpack")
            if char and backpack then
                for _, tool in pairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower() == weaponName:lower() then
                        tool.Parent = char
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if isRunning or bossFarm then
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.X, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.X, false, game)
        end
    end
end)

-- ══════════════════════════════════════════════
--// MAIN FARM LOOP  (Boss priority > Island)
-- ══════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if bossFarm then
            activeFarm = "boss"
            for _, data in ipairs(Bosses) do
                if not bossFarm then break end
                if not selectedBosses[data.name] then continue end
                teleportRemote:FireServer(data.remoteName)
                task.wait(1)
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp  = char:WaitForChild("HumanoidRootPart")
                hrp.Anchored = true
                for _, point in ipairs(data.farmPoints) do
                    if not bossFarm then break end
                    hrp.CFrame = point
                    task.wait(math.max(0.1, farmSpeed))
                end
            end
            if not bossFarm then unanchorHRP() activeFarm = "none" end

        elseif isRunning then
            activeFarm = "island"
            for _, island in ipairs(Islands) do
                if not isRunning then break end
                if not selectedIslands[island.name] then continue end
                teleportRemote:FireServer(island.remoteName)
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp  = char:WaitForChild("HumanoidRootPart")
                hrp.Anchored = true
                task.wait(math.max(0.1, farmSpeed))
                for _, point in ipairs(island.farmPoints) do
                    if not isRunning then break end
                    hrp.CFrame = point
                    task.wait(math.max(0.1, farmSpeed))
                end
            end
            if not isRunning then unanchorHRP() activeFarm = "none" end

        else
            activeFarm = "none"
            unanchorHRP()
        end
    end
end)

-- ══════════════════════════════════════════════
--// UI TABS
-- ══════════════════════════════════════════════
local autoFarmToggle, hideToggle, rejoinToggle, weaponToggle, farmSpeedDropdown, islandsDropdown

mainTab:Label("Auto Farm System")

autoFarmToggle = mainTab:Toggle('Auto Farm', isRunning, function(state)
    isRunning = state
    saveConfig()
    if state then
        local char = player.Character
        if char then
            local has = false
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("Tool") and v.Name == weaponName then has = true break end
            end
            if not has then equipWeaponSafe(weaponName) end
        end
        if hideEnabled then startHide() end
    else
        unanchorHRP()
        stopHide()
    end
end)

weaponToggle = mainTab:Toggle('Tower/Rush', weaponFarm, function(state)
    weaponFarm = state
    saveConfig()
end)

local islandNames = {}
for _, v in ipairs(Islands) do table.insert(islandNames, v.name) end
islandsDropdown = mainTab:Dropdown("Select Islands", islandNames, function(selected)
    for k in pairs(selectedIslands) do selectedIslands[k] = false end
    for _, name in pairs(selected) do selectedIslands[name] = true end
    saveConfig()
end, true)

mainTab:Toggle('Farm All Islands', false, function(state)
    for _, island in ipairs(Islands) do selectedIslands[island.name] = state end
    saveConfig()
end)

-- SETTINGS TAB
local speedOptions = {0.25, 0.5, 0.75, 1}
farmSpeedDropdown = settingsTab:Dropdown("Farm Speed", speedOptions, function(selected)
    farmSpeed = math.max(0.1, tonumber(selected) or 0.25)
    saveConfig()
end)

hideToggle = settingsTab:Toggle('Hide World', hideEnabled, function(state)
    hideEnabled = state
    saveConfig()
    if state and isRunning then startHide() end
    if not state then stopHide() end
end)

rejoinToggle = settingsTab:Toggle('Auto Rejoin', autoRejoin, function(state)
    autoRejoin = state
    saveConfig()
end)

-- BOSS TAB
local bossToggle = bossTab:Toggle('Auto Farm Boss', bossFarm, function(state)
    bossFarm = state
    if not state then unanchorHRP() end
    saveConfig()
end)

local bossNames = {}
for _, v in ipairs(Bosses) do table.insert(bossNames, v.name) end
local bossDropdown = bossTab:Dropdown("Select Boss Map", bossNames, function(selected)
    for k in pairs(selectedBosses) do selectedBosses[k] = false end
    for _, name in pairs(selected) do selectedBosses[name] = true end
    saveConfig()
end, true)

bossTab:Toggle('Farm All Boss', false, function(state)
    for _, v in ipairs(Bosses) do selectedBosses[v.name] = state end
    saveConfig()
end)

-- ══════════════════════════════════════════════
--// SYNC UI หลังโหลด config
-- ══════════════════════════════════════════════
task.delay(0.5, function()
    if autoFarmToggle    and autoFarmToggle.Set    then autoFarmToggle:Set(isRunning)    end
    if hideToggle        and hideToggle.Set         then hideToggle:Set(hideEnabled)      end
    if rejoinToggle      and rejoinToggle.Set       then rejoinToggle:Set(autoRejoin)     end
    if weaponToggle      and weaponToggle.Set       then weaponToggle:Set(weaponFarm)     end
    if farmSpeedDropdown and farmSpeedDropdown.Set  then farmSpeedDropdown:Set(farmSpeed) end

    local sel = {}
    for name, v in pairs(selectedIslands) do if v then table.insert(sel, name) end end
    if islandsDropdown and islandsDropdown.Set then islandsDropdown:Set(sel) end

    if bossToggle and bossToggle.Set then bossToggle:Set(bossFarm) end
    local selB = {}
    for name, v in pairs(selectedBosses) do if v then table.insert(selB, name) end end
    if bossDropdown and bossDropdown.Set then bossDropdown:Set(selB) end
end)

-- AUTO SAVE
task.spawn(function()
    while true do
        task.wait(3)
        pcall(saveConfig)
    end
end)

task.delay(1, function()
    if isRunning and hideEnabled then startHide() end
end)
