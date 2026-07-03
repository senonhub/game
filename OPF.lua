-- ===== Auto Farm Haki (Rayfield UI) =====
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGetAsync('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm Haki",
    LoadingTitle = "Auto Farm Haki",
    LoadingSubtitle = "by markxdxaxa",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFarmHaki",
        FileName = LocalPlayer.Name, -- แยก config ตาม username อัตโนมัติ
    },
})

local Tab = Window:CreateTab("Farm", 4483362458)

-- ===== State =====
local Settings = {
    Enabled = false,
    AutoClick = true,
    SelectedMonster = nil,
    AttackDistance = 6,
    AutoSwitch = true,
    AntiAFK = true,
}

local StatusLabel = Tab:CreateLabel("สถานะ: ปิดอยู่")

-- ===== สแกนมอนสเตอร์ทั้งแมพ (รวมชื่อซ้ำเป็น 1 ตัวเลือก) =====
local function scanMonsters()
    local names = {}
    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            -- ข้าม player character และมอนที่ตายแล้ว
            if hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                if not seen[obj.Name] then
                    seen[obj.Name] = true
                    table.insert(names, obj.Name)
                end
            end
        end
    end

    table.sort(names)
    return names
end

-- ===== Dropdown เลือกมอนสเตอร์ =====
local MonsterDropdown = Tab:CreateDropdown({
    Name = "เลือกมอนสเตอร์",
    Options = scanMonsters(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "MonsterDropdown",
    Callback = function(option)
        Settings.SelectedMonster = option[1]
    end,
})

Tab:CreateButton({
    Name = "รีเฟรชรายชื่อมอนสเตอร์",
    Callback = function()
        local list = scanMonsters()
        MonsterDropdown:Refresh(list)
        Rayfield:Notify({
            Title = "รีเฟรชแล้ว",
            Content = "เจอมอนสเตอร์ " .. #list .. " ประเภทในแมพ",
            Duration = 3,
        })
    end
})

-- ===== ระยะโจมตี =====
Tab:CreateSlider({
    Name = "ระยะโจมตี (studs)",
    Range = { 3, 20 },
    Increment = 1,
    CurrentValue = 6,
    Flag = "AttackDistance",
    Callback = function(value)
        Settings.AttackDistance = value
    end,
})

-- ===== Auto คลิก =====
Tab:CreateToggle({
    Name = "Auto คลิกโจมตี",
    CurrentValue = true,
    Flag = "AutoClickToggle",
    Callback = function(value)
        Settings.AutoClick = value
    end,
})

-- ===== Auto-switch มอนตัวใหม่เมื่อตัวเดิมตาย/หายไปหมด =====
Tab:CreateToggle({
    Name = "Auto-switch มอนสเตอร์อัตโนมัติ",
    CurrentValue = true,
    Flag = "AutoSwitchToggle",
    Callback = function(value)
        Settings.AutoSwitch = value
    end,
})

-- ===== Anti-AFK =====
Tab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(value)
        Settings.AntiAFK = value
    end,
})

-- ===== ปุ่มหลัก เปิด/ปิดระบบ =====
Tab:CreateToggle({
    Name = "Auto Farm Haki",
    CurrentValue = false,
    Flag = "AutoFarmHakiToggle",
    Callback = function(value)
        Settings.Enabled = value
        StatusLabel:Set("สถานะ: " .. (value and "กำลังทำงาน" or "ปิดอยู่"))
    end,
})

-- ===== หามอนสเตอร์ตัวที่ใกล้ที่สุดตามชื่อที่เลือก =====
local function findTarget(name)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, closestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and primary then
                local dist = (primary.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest
end

-- ===== วาปไปด้านหลังมอน เว้นระยะตามที่ตั้ง =====
local function moveBehindTarget(targetModel, distance)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local primary = targetModel.PrimaryPart or targetModel:FindFirstChild("HumanoidRootPart")
    if not primary then return end

    -- ตำแหน่งด้านหลังมอน (อิงทิศที่มันหันหน้าอยู่) ห่างตามระยะที่ตั้ง
    local behindPos = (primary.CFrame * CFrame.new(0, 0, distance)).Position
    local lookAtTarget = CFrame.new(behindPos, primary.Position)

    hrp.CFrame = lookAtTarget
end

-- ===== จำลองคลิกโจมตี =====
local function autoClickOnce()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- ===== Anti-AFK: จำลองกดปุ่มเบา ๆ กันเตะออกจากเซิร์ฟเวอร์ =====
local lastAntiAFK = 0
local function antiAFKTick()
    local now = os.clock()
    if now - lastAntiAFK < 30 then return end -- ทำทุก ~30 วิ พอ ไม่ถี่เกินไป
    lastAntiAFK = now

    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- ===== Main Loop =====
task.spawn(function()
    while true do
        -- Randomize delay กันดูเป็น pattern บอทชัดเกินไป (0.25 - 0.45 วิ)
        task.wait(math.random(25, 45) / 100)

        if Settings.AntiAFK then
            antiAFKTick()
        end

        if Settings.Enabled and Settings.SelectedMonster then
            local target = findTarget(Settings.SelectedMonster)

            if target then
                moveBehindTarget(target, Settings.AttackDistance)

                if Settings.AutoClick then
                    autoClickOnce()
                end

                StatusLabel:Set("สถานะ: กำลังฟาร์ม " .. Settings.SelectedMonster)

            elseif Settings.AutoSwitch then
                -- ไม่เจอมอนตัวที่เลือก -> ลองสลับไปมอนอื่นที่ยังอยู่ในแมพอัตโนมัติ
                local available = scanMonsters()
                if #available > 0 then
                    Settings.SelectedMonster = available[math.random(1, #available)]
                    StatusLabel:Set("สถานะ: สลับไปฟาร์ม " .. Settings.SelectedMonster .. " แทน")
                else
                    StatusLabel:Set("สถานะ: ไม่เจอมอนเหลือในแมพเลย")
                end

            else
                StatusLabel:Set("สถานะ: ไม่เจอ " .. Settings.SelectedMonster .. " ในแมพ")
            end
        end
    end
end)
