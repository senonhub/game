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

--// CONFIG FOLDER
local CONFIG_FOLDER = "autofarm_configs"
if not isfolder(CONFIG_FOLDER) then
    makefolder(CONFIG_FOLDER)
end

--// GET CHARACTER NAME
local function getCharacterName()
    local char = player.Character or player.CharacterAdded:Wait()
    return char.Name -- ชื่อตัวละคร
end

local currentCharacter = getCharacterName()
local configFile = CONFIG_FOLDER .. "/" .. currentCharacter .. ".json"

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
local blackScreenEnabled = false  -- ตั้งค่า black screen
local discordReportEnabled = false  -- ตั้งค่า Discord report
local autoPullLever = false  -- ตั้งค่า Auto Pull Lever
local itemsCollected = {}  -- เก็บ items ที่ได้
local discordWebhookUrl = "https://discord.com/api/webhooks/1500473133038047407/pP5P8Q1lDQVebeWtiuNS7vZ1DUUNXZcSjldmFmUUgMXqu4yWnYdo4ef0E6gcSjopydN0"

--// 📦 INVENTORY TRACKING
local previousInventory = {}  -- เก็บ inventory ครั้งก่อน

local function getCurrentInventory()
    local inventory = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                inventory[item.Name] = (inventory[item.Name] or 0) + 1
            end
        end
    end
    return inventory
end

local function trackInventoryChanges()
    local currentInventory = getCurrentInventory()
    
    -- เทียบความต่างจากครั้งก่อน
    for itemName, count in pairs(currentInventory) do
        local previousCount = previousInventory[itemName] or 0
        if count > previousCount then
            local difference = count - previousCount
            table.insert(itemsCollected, {name = itemName, amount = difference})
            print("✅ ได้ " .. itemName .. " x" .. difference)
        end
    end
    
    -- เก็บ inventory ปัจจุบันไว้เพื่อ track ครั้งหน้า
    previousInventory = currentInventory
end

--// AUTO PULL LEVER (รองรับหลายอัน)
local leverActive = false
local pulledLevers = {}  -- เก็บ Lever ที่ pull แล้ว

local function findAllLevers()
    local levers = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            -- ตรวจหา Lever ที่มี ProximityPrompt
            if string.find(obj.Name, "Lever") or string.find(obj.Name, "lever") then
                local prompt = obj:FindFirstChild("ProximityPrompt")
                local leverPos = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("Part")
                if prompt and leverPos and not pulledLevers[obj] then
                    table.insert(levers, {lever = obj, prompt = prompt, pos = leverPos})
                end
            end
        end
    end
    return levers
end

local function getClosestLever(levers)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local charPos = char.HumanoidRootPart.Position
    local closest = nil
    local minDistance = math.huge
    
    for _, leverData in ipairs(levers) do
        local dist = (leverData.pos.Position - charPos).Magnitude
        if dist < minDistance then
            minDistance = dist
            closest = leverData
        end
    end
    
    return closest
end

local function pullLeverAuto(leverData)
    if not leverData then return end
    
    leverActive = true
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        leverActive = false
        return 
    end
    
    -- วาปตัวไปที่ Lever ที่ใกล้ที่สุด
    local hrp = char:FindFirstChild("HumanoidRootPart")
    hrp.CFrame = leverData.pos.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.5)
    
    -- กด E ค้าง 3 วิ
    print("🔴 พบ Lever ที่ใกล้ที่สุด! กำลัง Pull...")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(3)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    
    -- เก็บ Lever ที่ pull แล้ว
    pulledLevers[leverData.lever] = true
    
    task.wait(1)
    leverActive = false
    print("✅ Pull Lever เสร็จ! (อ่านหลายอันได้)")
end

-- โลปหลัก - ตรวจจับ Lever แบบต่อเนื่อง
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoPullLever and not leverActive then
            local allLevers = findAllLevers()
            if #allLevers > 0 then
                local closestLever = getClosestLever(allLevers)
                if closestLever then
                    pullLeverAuto(closestLever)
                end
            end
            
            -- ล้าง pulled levers ทุก 10 วิ
            task.wait(9.8)
            pulledLevers = {}
        else
            task.wait(0.5)
        end
    end
end)

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

--// SAVE / LOAD (ตามชื่อตัวละคร)
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
        bosses = selectedBosses,
        blackScreen = blackScreenEnabled,  -- เก็บ black screen setting
        discordReport = discordReportEnabled,  -- เก็บ discord setting
        autoPullLever = autoPullLever  -- เก็บ auto pull lever setting
    }  
    writefile(configFile, HttpService:JSONEncode(data))
    print("✅ บันทึก config สำหรับ: " .. currentCharacter)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(configFile) then 
        print("📝 ไฟล์ config ใหม่สำหรับตัวละคร: " .. currentCharacter)
        return 
    end
    
    local data = HttpService:JSONDecode(readfile(configFile))
    isRunning = data.auto or false
    hideEnabled = data.hide or false
    weaponFarm = data.weapon or false
    autoRejoin = data.rejoin or false
    farmSpeed = data.farmSpeed or 0.25
    blackScreenEnabled = data.blackScreen or false  -- โหลด black screen
    discordReportEnabled = data.discordReport or false  -- โหลด discord
    autoPullLever = data.autoPullLever or false  -- โหลด auto pull lever
    
    if data.islands then
        for k,v in pairs(data.islands) do
            selectedIslands[k] = v
        end
    end

    bossFarm = data.bossFarm or false
    if data.bosses then
        for k,v in pairs(data.bosses) do
            selectedBosses[k] = v
        end
    end
    
    print("✅ โหลด config สำหรับ: " .. currentCharacter)
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

--// ⚫ BLACK SCREEN OVERLAY (UI อยู่บนสุด)
local blackScreenGui = nil
local function createBlackScreen()
    if blackScreenGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackScreenOverlay"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 0  -- ต่ำสุด
    screenGui.Parent = CoreGui
    
    local blackFrame = Instance.new("Frame")
    blackFrame.Name = "BlackFrame"
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.Position = UDim2.new(0, 0, 0, 0)
    blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackFrame.BackgroundTransparency = 0
    blackFrame.BorderSizePixel = 0
    blackFrame.Parent = screenGui
    
    blackScreenGui = screenGui
    print("⚫ Black Screen เปิดแล้ว (UI อยู่บนสุด)")
end

local function removeBlackScreen()
    if blackScreenGui then
        blackScreenGui:Destroy()
        blackScreenGui = nil
        print("⚪ Black Screen ปิดแล้ว")
    end
end

--// 📊 DISCORD REPORT SYSTEM
local function sendDiscordReport()
    if not discordReportEnabled or #itemsCollected == 0 then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local discordUserId = "670602737376952347"
    local message = "<@" .. discordUserId .. ">\n"
    message = message .. "👤 **Character:** " .. currentCharacter .. "\n"
    message = message .. "📦 **Items Collected:**\n"
    
    -- สรุป items
    local itemCount = 0
    for _, item in pairs(itemsCollected) do
        message = message .. "  • " .. item.name .. " x" .. item.amount .. "\n"
        itemCount = itemCount + item.amount
    end
    
    message = message .. "⏰ **Time:** " .. timestamp
    
    local data = {
        content = message
    }
    
    pcall(function()
        HttpService:PostAsync(discordWebhookUrl, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
        print("✅ ส่ง Discord สำเร็จ! ส่งไป " .. currentCharacter)
    end)
    
    itemsCollected = {}  -- รีเซ็ต
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
            CFrame.new(-192.417801, 22.093403, -456.088654) * CFrame.Angles(0, -0.453476, 0)
        }
    },
    {
        name = "Easter",
        remoteName = "Easter",
        farmPoints = {
            CFrame.new(2303.542236, 6.180947, 2224.365234) * CFrame.Angles(-0.000000, -0.762560, -0.000000)
        }
    },
    {
        name = "BluePlanet",
        remoteName = "BluePlanet",
        farmPoints = {
            CFrame.new(-3481.470703, 25.938200, 1415.678955) * CFrame.Angles(3.141593, -1.376956, 3.141593)
        }
    },
    {
        name = "slayer",
        remoteName = "slayer",
        farmPoints = {
            CFrame.new(-2406.064453, 23.162224, -2990.699951) * CFrame.Angles(-0.000000, -0.673786, -0.000000)
        }
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
mainTab:Label("👤 Character: " .. currentCharacter)

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
        -- ⚫ เปิด Black Screen ถ้าเปิด Auto Farm และ Black Screen ถูกเปิด
        if blackScreenEnabled then
            createBlackScreen()
        end
    else  
        stopHide()
        -- ⚫ ปิด Black Screen เมื่อปิด Auto Farm
        removeBlackScreen()
    end
end)

-- Tower/Rush Weapon Farm
weaponToggle = mainTab:Toggle('Tower/Rush', weaponFarm, function(state)
    weaponFarm = state
    saveConfig()
end)

-- Auto Pull Lever
local leverToggle = mainTab:Toggle('Auto Pull Lever 🔴', autoPullLever, function(state)
    autoPullLever = state
    saveConfig()
    if state then
        print("🔴 Auto Pull Lever เปิดแล้ว!")
    else
        print("⚫ Auto Pull Lever ปิดแล้ว")
    end
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

-- ⚫ Black Screen Toggle
local blackScreenToggle = settingsTab:Toggle('Black Screen (ลดสเปค)', blackScreenEnabled, function(state)
    blackScreenEnabled = state
    saveConfig()
    -- ถ้า Auto Farm กำลังเปิด ให้เปลี่ยน Black Screen ทันที
    if isRunning then
        if state then
            createBlackScreen()
        else
            removeBlackScreen()
        end
    end
end)

-- 📊 Discord Report Toggle
local discordToggle = settingsTab:Toggle('Discord Report (ทุก 5 วิ)', discordReportEnabled, function(state)
    discordReportEnabled = state
    saveConfig()
    if state then
        print("📊 Discord Report เปิดแล้ว - ส่งทุก 5 วินาที")
    else
        print("📊 Discord Report ปิดแล้ว")
    end
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
    if leverToggle and leverToggle.Set then leverToggle:Set(autoPullLever) end
    if farmSpeedDropdown and farmSpeedDropdown.Set then farmSpeedDropdown:Set(farmSpeed) end
    if blackScreenToggle and blackScreenToggle.Set then blackScreenToggle:Set(blackScreenEnabled) end
    if discordToggle and discordToggle.Set then discordToggle:Set(discordReportEnabled) end

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

--// AUTO SAVE =================--
task.spawn(function()
    while true do
        task.wait(3)
        saveConfig()
    end
end)

--// DISCORD REPORT LOOP (ทุก 5 วินาที)
task.spawn(function()
    while true do
        task.wait(5)
        if discordReportEnabled and isRunning then  -- เฉพาะเมื่อ Auto Farm เปิด
            trackInventoryChanges()  -- ✅ เช็ค inventory ทุก 5 วิ
            if #itemsCollected > 0 then
                sendDiscordReport()
            end
        end
    end
end)

-- ensure hide starts if loaded
task.delay(1, function()
    if isRunning and hideEnabled then startHide() end
end)
