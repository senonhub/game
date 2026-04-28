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
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local teleportRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TeleportToPortal")

--// CONFIG
local saveFile = "autofarm_config.json"

--// SETTINGS
local weaponFarm = false
local farmSpeed = 0.50
local isRunning = false
local hideEnabled = false
local selectedIslands = {}
local weaponName = "Strongest In History"
local autoRejoin = false
local bossFarm = false
local isBossActive = false
local selectedBosses = {}

--// ========== ระบบพับ UI (PC + มือถือ) ========== --
local uiVisible = true

-- หา UI Container
local function findUIContainer()
    task.wait(1)
    for _, gui in pairs(player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and not gui.Name:match("Roblox") then
            if gui:FindFirstChild("Main") or gui:FindFirstChild("Container") or 
               gui.Name:match("UI") or gui.Name:match("Lib") then
                return gui
            end
        end
    end
    for i = #player.PlayerGui:GetChildren(), 1, -1 do
        local gui = player.PlayerGui:GetChildren()[i]
        if gui:IsA("ScreenGui") and not gui.Name:match("Roblox") then
            return gui
        end
    end
end

local uiContainer = findUIContainer()

-- สร้างปุ่มพับ UI สำหรับมือถือ
local toggleButton = Instance.new("ScreenGui")
toggleButton.Name = "ToggleUI"
toggleButton.ResetOnSpawn = false
toggleButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleButton.Parent = player.PlayerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(1, -70, 0, 10) -- มุมขวาบน
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.BorderSizePixel = 0
button.Text = "UI"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 20
button.Font = Enum.Font.GothamBold
button.Parent = toggleButton

-- ทำให้มน
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

-- เงา
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 127)
stroke.Thickness = 2
stroke.Parent = button

-- ฟังก์ชันพับ UI
local function toggleUI()
    uiVisible = not uiVisible
    if uiContainer then
        uiContainer.Enabled = uiVisible
    end
    
    -- เปลี่ยนสีปุ่ม
    if uiVisible then
        stroke.Color = Color3.fromRGB(0, 255, 127) -- เขียว
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        stroke.Color = Color3.fromRGB(255, 50, 50) -- แดง
        button.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    end
end

button.MouseButton1Click:Connect(toggleUI)

-- ระบบลาก (สำหรับมือถือ)
local dragging, dragInput, dragStart, startPos

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Keybind สำหรับ PC (Right Ctrl)
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleUI()
    end
end)

--// ========== จบระบบพับ UI ========== --

--// WEAPON FARM
local switchDelay = 0.5
local fSpamDelay = 0.1
local weapons = {"Anos", "Strongest Of Today"}
local equipRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipWeapon")
local function equipWeaponSafe(weaponName)
local char = player.Character
if not char then return end

-- เช็คว่าถืออยู่แล้วไหม  
for _, v in pairs(char:GetChildren()) do  
    if v:IsA("Tool") and v.Name == weaponName then  
        return  
    end  
end  

-- หาในกระเป๋า  
local backpack = player:FindFirstChild("Backpack")  
if backpack then  
    local tool = backpack:FindFirstChild(weaponName)  
    if tool then  
        tool.Parent = char  
        return  
    end  
end  

-- fallback ยิง remote  
pcall(function()  
    equipRemote:FireServer("Equip", weaponName)  
end)

end

--// SAVE / LOAD
local function saveConfig()
if not writefile then return end
local data = {
auto = isRunning,
hide = hideEnabled,
weapon = weaponFarm,
rejoin = autoRejoin,
farmSpeed = farmSpeed,
islands = selectedIslands,

bossFarm = bossFarm,  
    bosses = selectedBosses  
      
}  
writefile(saveFile, HttpService:JSONEncode(data))

end

local function loadConfig()
if not readfile or not isfile or not isfile(saveFile) then return end
local data = HttpService:JSONDecode(readfile(saveFile))
isRunning = data.auto or false
hideEnabled = data.hide or false
weaponFarm = data.weapon or false
autoRejoin = data.rejoin or false
farmSpeed = data.farmSpeed or 0.25
if data.islands then
for k,v in pairs(data.islands) do
selectedIslands[k] = v
end
end

-- 🔥 โหลด boss
bossFarm = data.bossFarm or false

if data.bosses then
for k,v in pairs(data.bosses) do
selectedBosses[k] = v
end
end
end

-- โหลด config ทันที
loadConfig()

--// AUTO REJOIN (ปลอดภัย)
local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
if promptGui and promptGui:FindFirstChild("promptOverlay") then
promptGui.promptOverlay.ChildAdded:Connect(function(child)
if autoRejoin and child.Name == "ErrorPrompt" then
task.wait(2)
TeleportService:Teleport(game.PlaceId, player)
end
end)
end

--// HIDE WORLD
local hiddenFolder = Instance.new("Folder")
hiddenFolder.Parent = ReplicatedStorage
local hidingLoop = false

local function startHide()
hidingLoop = true
task.spawn(function()
while hidingLoop do
local char = player.Character
for _, v in pairs(workspace:GetChildren()) do
if v ~= char and v.Name ~= "Camera" and v.Name ~= "Terrain" then
if not selectedIslands[v.Name] then
pcall(function() v.Parent = hiddenFolder end)
end
end
end
task.wait(0.5) -- ลด lag
end
end)
end

local function stopHide()
hidingLoop = false
for _, v in pairs(hiddenFolder:GetChildren()) do
v.Parent = workspace
end
end

--// WEAPON LOOP
task.spawn(function()
local index = 1
while true do
if weaponFarm then
VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
if equipRemote and weapons[index] then
pcall(function() equipWeaponSafe(weapons[index]) end)
end
index = index + 1
if index > #weapons then index = 1 end
task.wait(switchDelay)
else
task.wait(0.2)
end
end
end)

task.spawn(function()
while true do
if weaponFarm then
VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
task.wait(fSpamDelay)
else
task.wait(0.2)
end
end
end)
local Bosses = {
{
name = "Shibuya",
remoteName = "Shibuya",
farmPoints = {
CFrame.new(1844.276978, 8.486135, 332.343933) * CFrame.Angles(0, -1.151117, 0), -- Sorcerer
CFrame.new(1523.045776, 8.486135, 222.293930) * CFrame.Angles(0, 1.032041, 0), -- Vessel
CFrame.new(1585.698975, 72.720535, -14.644113) * CFrame.Angles(0, 0.331550, 0) -- King
}
},

{  
    name = "Sailor",  
    remoteName = "Sailor",  
    farmPoints = {  
        CFrame.new(249.164780, 7.593238, 920.676636) * CFrame.Angles(-3.141593, -0.030496, 3.141593) -- Solo + Vampire  
    }  
},  

{  
    name = "Ninja",  
    remoteName = "Ninja",  
    farmPoints = {  
        CFrame.new(-2102.323975, 12.801344, -593.768005) * CFrame.Angles(0, 1.264190, 0) -- Shinobi  
    }  
},  

{  
    name = "Hollow",  
    remoteName = "Hollow",  
    farmPoints = {  
        CFrame.new(-561.725403, -1.921275, 1218.843140) * CFrame.Angles(0, -0.024930, 0) -- Manipulator  
    }  
},  

{  
    name = "Judgement",  
    remoteName = "Judgement",  
    farmPoints = {  
        CFrame.new(-1401.960571, 21.119366, -1375.238647) * CFrame.Angles(0, 1.156247, 0) -- Yamato  
    }  
}

}
-- ✅ DEFAULT
for _, v in ipairs(Bosses) do
if selectedBosses[v.name] == nil then
selectedBosses[v.name] = false
end
end

-- ✅ FIND BOSS
local function findBoss(targetNames)
for _, v in pairs(workspace:GetDescendants()) do
if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
for _, name in ipairs(targetNames) do
if string.find(v.Name, name) then
return v
end
end
end
end
return nil
end

-- ✅ CHECK BOSS
local function isBossAlive()
return bossFarm
end

local Islands = {
{
name = "Soul Dominion",
remoteName = "SoulDominion",
farmPoints = {
CFrame.new(-1337.597290, 1604.373291, 1591.893555)
* CFrame.Angles(-3.141593, 1.567292, -3.141593)
}
},

{  
    name="Lawless Island",  
    remoteName="Lawless",  
    farmPoints={CFrame.new(63,0,1817)}  
},  

{  
    name="Ninja Island",  
    remoteName="Ninja",  
    farmPoints={CFrame.new(-1870,8,-738)}  
},  

{  
    name="Judgement Island",  
    remoteName="Judgement",  
    farmPoints={CFrame.new(-1273,1,-1187)}  
},  

{  
    name="Academy Island",  
    remoteName="Academy",  
    farmPoints={CFrame.new(1069,1,1273)}  
},  

{  
    name="Slime Island",  
    remoteName="Slime",  
    farmPoints={CFrame.new(177,11,-159)}  
},  

{  
    name="Shinjuku Island",  
    remoteName="Shinjuku",  
    farmPoints={CFrame.new(-16,1,-1843), CFrame.new(664,1,-1696)}  
},  

{  
    name="Hueco Mundo",  
    remoteName="Hueco",  
    farmPoints={CFrame.new(-368,0,1096)}  
},  

{  
    name="Shibuya Station",  
    remoteName="Shibuya",  
    farmPoints={CFrame.new(1399,8,486)}  
},  

{  
    name="Snow Island",  
    remoteName="Snow",  
    farmPoints={CFrame.new(-406,-1,-994)}  
},  

{  
    name="Desert Island",  
    remoteName="Desert",  
    farmPoints={CFrame.new(-787,-4,-430)}  
},  

{  
    name="Jungle Island",  
    remoteName="Jungle",  
    farmPoints={CFrame.new(-566,0,402)}  
},  

{  
    name="Starter Island",  
    remoteName="Starter",  
    farmPoints={CFrame.new(177,11,-159)}  
},

{
name = "Bizarre",
remoteName = "Bizarre",
farmPoints = {
CFrame.new(-3073.359131, 7.518671, -666.597839) * CFrame.Angles(0, 0.624027, 0)
}
},

{
name = "Punch",
remoteName = "Punch",
farmPoints = {
CFrame.new(-1579.000732, 2.682251, 1841.026123) * CFrame.Angles(0, -0.063341, 0)
}
},

{
name = "StarterSea2",
remoteName = "StarterSea2",
farmPoints = {
CFrame.new(-324.656219, -3.666585, -121.629074) * CFrame.Angles(0, -1.448254, 0),
CFrame.new(-192.417801, 22.093403, -456.088654) * CFrame.Angles(0, -0.453476, 0)}
},
{name = "Easter",
remoteName = "Easter",
farmPoints = {CFrame.new(2303.542236, 6.180947, 2224.365234) * CFrame.Angles(-0.000000, -0.762560, -0.000000)}

}
}
for _, v in ipairs(Islands) do
if selectedIslands[v.name] == nil then
selectedIslands[v.name] = false
end
end

--// AUTO EQUIP
task.spawn(function()
while true do
task.wait(0.3)
if isRunning or isBossActive then
local char = player.Character
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

--// SPAM X
task.spawn(function()
while true do
task.wait(0.5)
if isRunning or isBossActive then
VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.X, false, game)
VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.X, false, game)
end
end
end)

--// MAIN FARM
task.spawn(function()
while true do
task.wait(0.1)
if isRunning and not isBossActive then
for _, island in ipairs(Islands) do
if not isRunning then break end
if not selectedIslands[island.name] then continue end
teleportRemote:FireServer(island.remoteName)
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
hrp.Anchored = true
task.wait(farmSpeed)
for _, point in ipairs(island.farmPoints) do
if not isRunning then break end
hrp.CFrame = point
task.wait(farmSpeed)
end
end
else
local char = player.Character
if char then
local hrp = char:FindFirstChild("HumanoidRootPart")
if hrp then hrp.Anchored = false end
end
end
end
end)
task.spawn(function()
while true do
task.wait(0.1)

isBossActive = bossFarm  

    if isBossActive then  
        for _, data in ipairs(Bosses) do  
            if not isBossActive then break end  
            if not selectedBosses[data.name] then continue end  

            teleportRemote:FireServer(data.remoteName)  
            task.wait(1)  

            local char = player.Character or player.CharacterAdded:Wait()  
            local hrp = char:WaitForChild("HumanoidRootPart")  
            hrp.Anchored = true  

            for _, point in ipairs(data.farmPoints) do  
                if not isBossActive then break end  
                hrp.CFrame = point  
                task.wait(farmSpeed)  
            end  
        end  
    else  
        -- 🔥 กันตัวค้าง  
        local char = player.Character  
        if char then  
            local hrp = char:FindFirstChild("HumanoidRootPart")  
            if hrp then hrp.Anchored = false end  
        end  
    end  
end

end)
-- Toggle / Dropdown object เก็บไว้
local autoFarmToggle, hideToggle, rejoinToggle, weaponToggle, farmSpeedDropdown, islandsDropdown

--================ MAIN TAB =================--
mainTab:Label("Auto Farm System")

-- Auto Farm
autoFarmToggle = mainTab:Toggle('Auto Farm', isRunning, function(state)
isRunning = state
saveConfig()

if state then  
    local char = player.Character  
    if char then  
        local hasWeapon = false  
        for _, v in pairs(char:GetChildren()) do  
            if v:IsA("Tool") and v.Name == weaponName then  
                hasWeapon = true  
                break  
            end  
        end  
        if not hasWeapon then  
            equipWeaponSafe(weaponName)  
        end  
    end  

    if hideEnabled then startHide() end  
else  
    stopHide()  
end

end)

-- Tower/Rush Weapon Farm
weaponToggle = mainTab:Toggle('Tower/Rush', weaponFarm, function(state)
weaponFarm = state
saveConfig()
end)

-- Islands selection
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

--================ SETTINGS TAB =================--
settingsTab:Label("🎮 Press Right Ctrl or UI Button to Toggle")

-- Farm Speed
local speedOptions = {0.25, 0.5, 0.75, 1}
farmSpeedDropdown = settingsTab:Dropdown("Farm Speed", speedOptions, function(selected)
farmSpeed = tonumber(selected) or 0.25
saveConfig()
end)

-- Hide World
hideToggle = settingsTab:Toggle('Hide World', hideEnabled, function(state)
hideEnabled = state
saveConfig()
if state and isRunning then startHide() end
if not state then stopHide() end
end)

-- Auto Rejoin
rejoinToggle = settingsTab:Toggle('Auto Rejoin', autoRejoin, function(state)
autoRejoin = state
saveConfig()
end)

--bossfarm
local bossToggle = bossTab:Toggle('Auto Farm Boss', bossFarm, function(state)
bossFarm = state
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
for _, v in ipairs(Bosses) do
selectedBosses[v.name] = state
end
saveConfig()
end)

--================ SYNC UI หลังโหลด config =================--
task.delay(0.5, function()
if autoFarmToggle and autoFarmToggle.Set then autoFarmToggle:Set(isRunning) end
if hideToggle and hideToggle.Set then hideToggle:Set(hideEnabled) end
if rejoinToggle and rejoinToggle.Set then rejoinToggle:Set(autoRejoin) end
if weaponToggle and weaponToggle.Set then weaponToggle:Set(weaponFarm) end
if farmSpeedDropdown and farmSpeedDropdown.Set then farmSpeedDropdown:Set(farmSpeed) end

local selectedList = {}  
for name, v in pairs(selectedIslands) do  
    if v then table.insert(selectedList, name) end  
end  
if islandsDropdown and islandsDropdown.Set then islandsDropdown:Set(selectedList) end  
if bossToggle and bossToggle.Set then bossToggle:Set(bossFarm) end

local selectedBossList = {}
for name, v in pairs(selectedBosses) do
if v then table.insert(selectedBossList, name) end
end

if bossDropdown and bossDropdown.Set then
bossDropdown:Set(selectedBossList)
end
end)

--================ AUTO SAVE =================--
task.spawn(function()
while true do
task.wait(3)
saveConfig()
end
end)

-- ensure hide starts if loaded
task.delay(1, function()
if isRunning and hideEnabled then startHide() end
end)
