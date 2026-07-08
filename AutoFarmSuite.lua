-- ===== Auto Farm Suite (Rayfield UI) =====
-- ระบบแยกกันอิสระ: Farm Haki (sequence) กับ Farm Monster (ฟาร์มมอน)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGetAsync('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm Suite",
    LoadingTitle = "Auto Farm Suite",
    LoadingSubtitle = "by markxdxaxa",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFarmSuite",
        FileName = LocalPlayer.Name, -- แยก config ตาม username อัตโนมัติ
    },
})

-- ============================================================
-- TAB 1: FARM HAKI (รอ 3 วิ -> วาป -> กด R -> รอ 15 วิ -> รีจอยน์)
-- ============================================================
local HakiTab = Window:CreateTab("Farm Haki", 4483362458)

local HakiStatus = HakiTab:CreateLabel("สถานะ: ปิดอยู่")
local HakiProgress = HakiTab:CreateParagraph({
    Title = "ขั้นตอนการทำงาน",
    Content = "ยังไม่เริ่ม"
})

local HakiSettings = {
    Enabled = false,
    TweenDuration = 0.3,
    TargetCFrame = CFrame.new(
        -246.981857, 274.981079, 355.338745,
        -0.397099733, -0.144510329, 0.90632695,
        -0.342020452, 0.939692497, -2.3111701e-05,
        -0.851665318, -0.309991539, -0.422577143
    ),
}

local function hakiSetStatus(text)
    HakiStatus:Set("สถานะ: " .. text)
    print("[FarmHaki] " .. text)
end

local function hakiUpdateProgress(step, total, detail)
    HakiProgress:Set({
        Title = string.format("ขั้นตอน %d/%d", step, total),
        Content = detail
    })
end

local function hakiTeleportTo(targetCF, duration)
    duration = duration or HakiSettings.TweenDuration
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if hum then hum.PlatformStand = true end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { CFrame = targetCF }
    )
    tween:Play()
    tween.Completed:Wait()

    if hum then hum.PlatformStand = false end
end

local function hakiPressKey(keyCode)
    VIM:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, keyCode, false, game)
end

local function runHakiSequence()
    local totalSteps = 4

    hakiSetStatus("รอ 3 วินาที...")
    hakiUpdateProgress(1, totalSteps, "กำลังรอเริ่มต้น 3 วิ")
    task.wait(3)

    hakiSetStatus("กำลังวาป (tween)...")
    hakiUpdateProgress(2, totalSteps, "วาปไปพิกัดเป้าหมายแบบ tween")
    hakiTeleportTo(HakiSettings.TargetCFrame, HakiSettings.TweenDuration)
    task.wait(0.2)

    hakiSetStatus("กำลังกดปุ่ม R...")
    hakiUpdateProgress(3, totalSteps, "จำลองการกดปุ่ม R")
    hakiPressKey(Enum.KeyCode.R)

    hakiUpdateProgress(4, totalSteps, "นับถอยหลังก่อนรีจอยน์")
    for i = 15, 1, -1 do
        hakiSetStatus("รีจอยน์ในอีก " .. i .. " วิ")
        task.wait(1)
    end

    hakiSetStatus("กำลังรีจอยน์เซิร์ฟเวอร์...")
    task.wait(0.5)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

HakiTab:CreateToggle({
    Name = "เปิดใช้งาน Farm Haki",
    CurrentValue = false,
    Flag = "FarmHakiToggle",
    Callback = function(value)
        HakiSettings.Enabled = value
        if value then
            hakiSetStatus("เริ่มทำงาน")
            task.spawn(runHakiSequence)
        else
            hakiSetStatus("ปิดอยู่")
        end
    end,
})

HakiTab:CreateButton({
    Name = "รันทันที (ไม่ต้องรอ toggle)",
    Callback = function()
        task.spawn(runHakiSequence)
    end
})

-- ============================================================
-- TAB 2: FARM MONSTER (สแกนมอน -> เลือก -> วาปเข้าตี -> auto click)
-- ============================================================
local FarmTab = Window:CreateTab("Farm Monster", 4483362458)

local FarmSettings = {
    Enabled = false,
    AutoClick = false,
    SelectedMonsters = {},
    AttackDistance = 6,
    AutoSwitch = false,
    AntiAFK = true,
}

local FarmStatus = FarmTab:CreateLabel("สถานะ: ปิดอยู่")

local function scanMonsters()
    local names = {}
    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            -- กรองเฉพาะชื่อที่ขึ้นต้นด้วย "Lv" เท่านั้น
            if hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) and obj.Name:match("^Lv") then
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

local MonsterDropdown = FarmTab:CreateDropdown({
    Name = "เลือกมอนสเตอร์ (เลือกได้หลายตัว)",
    Options = scanMonsters(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MonsterDropdown",
    Callback = function(options)
        FarmSettings.SelectedMonsters = options -- เก็บเป็น array แทนค่าเดียว
    end,
})

FarmTab:CreateButton({
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

FarmTab:CreateSlider({
    Name = "ระยะโจมตี (studs)",
    Range = { 3, 20 },
    Increment = 1,
    CurrentValue = 6,
    Flag = "AttackDistance",
    Callback = function(value)
        FarmSettings.AttackDistance = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto คลิกโจมตี",
    CurrentValue = true,
    Flag = "AutoClickToggle",
    Callback = function(value)
        FarmSettings.AutoClick = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto-switch มอนสเตอร์อัตโนมัติ",
    CurrentValue = true,
    Flag = "AutoSwitchToggle",
    Callback = function(value)
        FarmSettings.AutoSwitch = value
    end,
})

FarmTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(value)
        FarmSettings.AntiAFK = value
    end,
})

FarmTab:CreateToggle({
    Name = "เปิดใช้งาน Farm Monster",
    CurrentValue = false,
    Flag = "FarmMonsterToggle",
    Callback = function(value)
        FarmSettings.Enabled = value
        FarmStatus:Set("สถานะ: " .. (value and "กำลังทำงาน" or "ปิดอยู่"))
    end,
})

local function findTarget(nameList)
    if not nameList or #nameList == 0 then return nil end

    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nameSet = {}
    for _, n in ipairs(nameList) do nameSet[n] = true end

    local closest, closestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and nameSet[obj.Name] then
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

local function moveBehindTarget(targetModel, distance)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local primary = targetModel.PrimaryPart or targetModel:FindFirstChild("HumanoidRootPart")
    if not primary then return end

    local behindPos = (primary.CFrame * CFrame.new(0, 0, distance)).Position
    local lookAtTarget = CFrame.new(behindPos, primary.Position)

    hrp.CFrame = lookAtTarget
end

local function autoClickOnce()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local lastAntiAFK = 0
local function antiAFKTick()
    local now = os.clock()
    if now - lastAntiAFK < 300 then return end
    lastAntiAFK = now

    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- ============================================================
-- TAB 3: SKILL MACRO (กดค้าง = สแปมสกิลรัว / กดแล้วปล่อย = กดครั้งเดียวปกติ)
-- ============================================================
local UserInputService = game:GetService("UserInputService")

local SkillTab = Window:CreateTab("Skill Macro", 4483362458)

local SkillStatus = SkillTab:CreateLabel("สถานะ: ปิดอยู่")

local SKILL_KEYS = {
    Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V,
    Enum.KeyCode.B, Enum.KeyCode.N, Enum.KeyCode.F, Enum.KeyCode.G,
    Enum.KeyCode.H, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L,
}

local SkillSettings = {
    Enabled = false,          -- เปิด/ปิดระบบสกิลรวม
    HoldSpamInterval = 0.15,  -- ระยะห่างระหว่างการสแปมตอนกดค้าง (วินาที)
    HoldThreshold = 0.15,     -- กดนานเกินเท่านี้ = ถือว่า "ค้าง" ไม่ใช่ "แตะ"
    PerKeyEnabled = {},       -- true/false ต่อปุ่ม ว่าจะให้ระบบนี้ทำงานกับปุ่มนั้นไหม
}

for _, key in ipairs(SKILL_KEYS) do
    SkillSettings.PerKeyEnabled[key.Name] = true
end

SkillTab:CreateToggle({
    Name = "เปิดใช้งานระบบสกิล (Hold/Tap)",
    CurrentValue = false,
    Flag = "SkillMacroToggle",
    Callback = function(value)
        SkillSettings.Enabled = value
        SkillStatus:Set("สถานะ: " .. (value and "ทำงานอยู่" or "ปิดอยู่"))
    end,
})

SkillTab:CreateSlider({
    Name = "ความเร็วสแปมตอนกดค้าง (วินาที/ครั้ง)",
    Range = { 0.05, 0.5 },
    Increment = 0.05,
    CurrentValue = 0.15,
    Flag = "HoldSpamInterval",
    Callback = function(value)
        SkillSettings.HoldSpamInterval = value
    end,
})

SkillTab:CreateSlider({
    Name = "เวลาขั้นต่ำที่นับว่า \"กดค้าง\" (วินาที)",
    Range = { 0.05, 0.5 },
    Increment = 0.05,
    CurrentValue = 0.15,
    Flag = "HoldThreshold",
    Callback = function(value)
        SkillSettings.HoldThreshold = value
    end,
})

SkillTab:CreateParagraph({
    Title = "ปุ่มที่รองรับ",
    Content = "Z X C V B N F G H J K L\n• แตะสั้นๆ (Tap) = กดสกิลครั้งเดียวตามปกติ\n• กดค้างไว้ (Hold) = ระบบจะสแปมกดปุ่มนั้นซ้ำๆให้อัตโนมัติจนกว่าจะปล่อย"
})

for _, key in ipairs(SKILL_KEYS) do
    SkillTab:CreateToggle({
        Name = "ใช้งานปุ่ม " .. key.Name,
        CurrentValue = true,
        Flag = "SkillKey_" .. key.Name,
        Callback = function(value)
            SkillSettings.PerKeyEnabled[key.Name] = value
        end,
    })
end

-- เก็บ state ต่อปุ่ม: เวลาเริ่มกด, กำลังสแปมอยู่ไหม, task ของ loop สแปม
local keyState = {}
for _, key in ipairs(SKILL_KEYS) do
    keyState[key.Name] = {
        pressedAt = 0,
        isHoldSpamming = false,
        spamThread = nil,
    }
end

local function isTrackedKey(keyCode)
    for _, key in ipairs(SKILL_KEYS) do
        if key == keyCode then return key end
    end
    return nil
end

local function startHoldSpam(key)
    local state = keyState[key.Name]
    state.isHoldSpamming = true
    state.spamThread = task.spawn(function()
        while state.isHoldSpamming do
            -- จำลองการกดปุ่มซ้ำๆ ให้เกมรับรู้ว่ามีการกด key นี้อีกครั้ง
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            VIM:SendKeyEvent(false, key, false, game)
            SkillStatus:Set("สถานะ: กำลังสแปมปุ่ม " .. key.Name)
            task.wait(SkillSettings.HoldSpamInterval)
        end
    end)
end

local function stopHoldSpam(key)
    local state = keyState[key.Name]
    state.isHoldSpamming = false
    if state.spamThread then
        task.cancel(state.spamThread)
        state.spamThread = nil
    end
    SkillStatus:Set("สถานะ: ทำงานอยู่")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not SkillSettings.Enabled then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local key = isTrackedKey(input.KeyCode)
    if not key then return end
    if not SkillSettings.PerKeyEnabled[key.Name] then return end

    local state = keyState[key.Name]
    state.pressedAt = os.clock()

    -- รอเช็คว่ากดนานเกิน threshold ไหม ถ้าเกิน = เริ่มโหมดค้าง (สแปม)
    task.spawn(function()
        task.wait(SkillSettings.HoldThreshold)
        -- ถ้าเวลาเริ่มกดยังตรงกับตอนนี้ แปลว่ายังกดปุ่มนี้ค้างอยู่ (ยังไม่ปล่อย)
        if state.pressedAt ~= 0 and not state.isHoldSpamming then
            startHoldSpam(key)
        end
    end)
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not SkillSettings.Enabled then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local key = isTrackedKey(input.KeyCode)
    if not key then return end

    local state = keyState[key.Name]
    local heldDuration = os.clock() - state.pressedAt
    state.pressedAt = 0

    if state.isHoldSpamming then
        -- ปล่อยปุ่มหลังจากสแปมค้างไว้ -> หยุดสแปม
        stopHoldSpam(key)
    else
        -- แตะสั้นๆแล้วปล่อยก่อนถึง threshold -> ถือเป็นการกดปกติครั้งเดียว (เกมรับ input จริงไปแล้วตามปกติ)
        SkillStatus:Set("สถานะ: แตะปุ่ม " .. key.Name .. " (tap)")
    end
end)

task.spawn(function()
    while true do
        task.wait(math.random(25, 45) / 100)

        if FarmSettings.AntiAFK then
            antiAFKTick()
        end

        if FarmSettings.Enabled and FarmSettings.SelectedMonsters and #FarmSettings.SelectedMonsters > 0 then
            local target = findTarget(FarmSettings.SelectedMonsters)

            if target then
                moveBehindTarget(target, FarmSettings.AttackDistance)

                if FarmSettings.AutoClick then
                    autoClickOnce()
                end

                FarmStatus:Set("สถานะ: กำลังฟาร์ม " .. target.Name)

            elseif FarmSettings.AutoSwitch then
                -- ไม่เจอมอนตามที่เลือกไว้เลย -> ลองสแกนหาชื่อ Lv อื่นที่ยังเหลือแทน
                local available = scanMonsters()
                if #available > 0 then
                    FarmSettings.SelectedMonsters = { available[math.random(1, #available)] }
                    FarmStatus:Set("สถานะ: สลับไปฟาร์ม " .. FarmSettings.SelectedMonsters[1] .. " แทน")
                else
                    FarmStatus:Set("สถานะ: ไม่เจอมอน Lv เหลือในแมพเลย")
                end

            else
                FarmStatus:Set("สถานะ: ไม่เจอมอนที่เลือกไว้ในแมพ")
            end
        end
    end
end)
