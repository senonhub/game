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

local AutoRespawnEnabled = true -- ค่าเริ่มต้น, ปรับผ่าน toggle ในหน้า UI ได้

HakiTab:CreateButton({
    Name = "รันทันที (ไม่ต้องรอ toggle)",
    Callback = function()
        task.spawn(runHakiSequence)
    end
})

HakiTab:CreateToggle({
    Name = "Auto Respawn (กด spawn เองเมื่อตาย)",
    CurrentValue = true,
    Flag = "AutoRespawnToggle",
    Callback = function(value)
        AutoRespawnEnabled = value
    end,
})-- ============================================================
-- TAB 2: FARM MONSTER (สแกนมอน -> เลือก -> วาปเข้าตี -> auto click)
-- ============================================================
local FarmTab = Window:CreateTab("Farm Monster", 4483362458)

local FarmSettings = {
    Enabled = false,
    AutoClick = true,
    SelectedMonsters = {},
    AttackDistance = 6,
    AutoSwitch = true,
    AntiAFK = true,
    RangedMode = false,
    RangedRadius = 10,
    PullMode = false,
    PullDistance = 5,
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
    Name = "โหมดอาวุธระยะไกล (เล็ง+ยิงรอบตัว)",
    CurrentValue = false,
    Flag = "RangedModeToggle",
    Callback = function(value)
        FarmSettings.RangedMode = value
    end,
})

FarmTab:CreateSlider({
    Name = "ระยะยิงรอบตัว (studs)",
    Range = { 5, 30 },
    Increment = 1,
    CurrentValue = 10,
    Flag = "RangedRadius",
    Callback = function(value)
        FarmSettings.RangedRadius = value
    end,
})

FarmTab:CreateToggle({
    Name = "โหมดดึงมอนมา (ยืนนิ่ง ให้มอนมาข้างหน้า)",
    CurrentValue = false,
    Flag = "PullModeToggle",
    Callback = function(value)
        FarmSettings.PullMode = value
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

-- ===== โหมดอาวุธระยะไกล: หามอนทุกตัวในระยะรอบตัว =====
local Camera = workspace.CurrentCamera

local function getMonstersInRange(nameList, radius)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local nameSet = {}
    for _, n in ipairs(nameList) do nameSet[n] = true end

    local nearby = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and nameSet[obj.Name] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and primary then
                local dist = (primary.Position - hrp.Position).Magnitude
                if dist <= radius then
                    table.insert(nearby, obj)
                end
            end
        end
    end
    return nearby
end

-- ===== โหมดดึงมอนมา (ยืนนิ่ง ให้มอนมาข้างหน้าตัวเรา) =====
local function pullMonsterToPlayer(targetModel, distance)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local primary = targetModel.PrimaryPart or targetModel:FindFirstChild("HumanoidRootPart")
    if not primary then return end

    -- ตั้งตำแหน่งมอนมาข้างหน้าตัวเรา ระยะตามที่ตั้ง
    primary.CFrame = hrp.CFrame * CFrame.new(0, 0, -distance)
end
    local primary = targetModel.PrimaryPart or targetModel:FindFirstChild("HumanoidRootPart")
    if not primary then return end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, primary.Position)

    local screenPos, onScreen = Camera:WorldToViewportPoint(primary.Position)
    if onScreen then
        VIM:SendMouseMoveEvent(screenPos.X, screenPos.Y, game)
    end
end

-- วนเล็ง+ยิงทุกมอนในระยะ ทีละตัวเร็ว ๆ
local function rangedAttackNearby(nameList, radius)
    local targets = getMonstersInRange(nameList, radius)
    for _, mon in ipairs(targets) do
        aimAtTarget(mon)
        task.wait(0.05)
        autoClickOnce()
    end
    return #targets
end

-- ===== ตรวจจับว่าเรากำลังโดนสตันอยู่ไหม (heuristic, ไม่รู้ signal เฉพาะเกม) =====
local baselineWalkSpeed = nil
local lastHealth = nil
local hitCooldownUntil = 0

local function isLikelyStunned()
    local char = LocalPlayer.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- จำค่า WalkSpeed ปกติไว้ครั้งแรก
    if baselineWalkSpeed == nil and hum.WalkSpeed > 0 then
        baselineWalkSpeed = hum.WalkSpeed
    end

    -- เช็ค 1: WalkSpeed ตกเป็น 0 ทั้งที่ปกติไม่ใช่ 0 -> น่าจะโดนสตัน/ร่างกายล็อก
    if baselineWalkSpeed and baselineWalkSpeed > 0 and hum.WalkSpeed == 0 then
        return true
    end

    -- เช็ค 2: สถานะตัวละครเป็น Physics/Ragdoll (มักเกิดตอนโดนกระเด็น/สตัน)
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown then
        return true
    end

    -- เช็ค 3: เพิ่งโดนตี (HP ลดกะทันหัน) -> พักการกดสกิลสั้น ๆ กันโดน stun-lock ซ้ำ
    local currentHealth = hum.Health
    if lastHealth and currentHealth < lastHealth then
        hitCooldownUntil = os.clock() + 0.6 -- หน่วง 0.6 วิ หลังโดนตี ปรับได้ตรงนี้
    end
    lastHealth = currentHealth

    if os.clock() < hitCooldownUntil then
        return true
    end

    return false
end

local lastAntiAFK = 0
local function antiAFKTick()
    local now = os.clock()
    if now - lastAntiAFK < 30 then return end
    lastAntiAFK = now

    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

task.spawn(function()
    while true do
        task.wait(math.random(25, 45) / 100)

        if FarmSettings.AntiAFK then
            antiAFKTick()
        end

        if FarmSettings.Enabled and FarmSettings.SelectedMonsters and #FarmSettings.SelectedMonsters > 0 then

            if FarmSettings.RangedMode then
                -- โหมดอาวุธระยะไกล: เล็ง+ยิงทุกตัวในระยะรอบตัว
                local hitCount = rangedAttackNearby(FarmSettings.SelectedMonsters, FarmSettings.RangedRadius)

                if hitCount > 0 then
                    FarmStatus:Set("สถานะ: ยิงมอนในระยะ " .. hitCount .. " ตัว")
                elseif FarmSettings.AutoSwitch then
                    local available = scanMonsters()
                    if #available > 0 then
                        FarmSettings.SelectedMonsters = { available[math.random(1, #available)] }
                        FarmStatus:Set("สถานะ: สลับไปฟาร์ม " .. FarmSettings.SelectedMonsters[1] .. " แทน")
                    else
                        FarmStatus:Set("สถานะ: ไม่เจอมอน Lv เหลือในแมพเลย")
                    end
                else
                    FarmStatus:Set("สถานะ: ไม่มีมอนในระยะยิง")
                end

            else
                -- โหมดวาปเข้าไปใกล้กลุ่มมอน แล้วเก็บกวาดทุกตัวรอบตัวในระยะ
                local target = findTarget(FarmSettings.SelectedMonsters)

                if target then
                    -- วาปไปด้านหลังตัวที่ใกล้ที่สุดก่อน (เหมือนเดิม)
                    moveBehindTarget(target, FarmSettings.AttackDistance)
                    task.wait(0.1)

                    -- จากนั้นเก็บกวาดทุกตัวที่อยู่ในระยะรอบตัว
                    if FarmSettings.AutoClick then
                        local hitCount = rangedAttackNearby(FarmSettings.SelectedMonsters, FarmSettings.AttackDistance)
                        FarmStatus:Set("สถานะ: ตีมอนรอบตัว " .. hitCount .. " ตัว")
                    else
                        FarmStatus:Set("สถานะ: กำลังฟาร์ม " .. target.Name)
                    end

                elseif FarmSettings.AutoSwitch then
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
    end
end)

-- ============================================================
-- AUTO RESPAWN: กดปุ่ม spawn เองเมื่อตัวละครตาย (เกมไม่รีให้อัตโนมัติ)
-- ============================================================
local AutoRespawnEnabled = true -- ปิด/เปิดตรงนี้ได้ หรือจะทำเป็น toggle ใน UI ก็ได้

-- คลิกปุ่ม GUI โดยจำลองตำแหน่งคลิกจริงบนหน้าจอ
local function clickGuiButton(button)
    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize
    local x = pos.X + size.X / 2
    local y = pos.Y + size.Y / 2

    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.1)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- สแกนหาปุ่มที่ชื่อ/ข้อความมีคำว่า spawn หรือ respawn
local function findRespawnButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local nameCheck = obj.Name:lower()
            local textCheck = obj:IsA("TextButton") and obj.Text:lower() or ""

            if nameCheck:find("spawn") or textCheck:find("spawn") then
                return obj
            end
        end
    end

    return nil
end

local function handleCharacterDeath(char)
    local hum = char:WaitForChild("Humanoid")

    hum.Died:Connect(function()
        if not AutoRespawnEnabled then return end

        task.wait(1) -- รอ GUI spawn โผล่ขึ้นมาก่อน

        local btn = findRespawnButton()
        if btn then
            clickGuiButton(btn)
            print("[AutoRespawn] กดปุ่ม spawn แล้ว: " .. btn:GetFullName())
        else
            warn("[AutoRespawn] หาปุ่ม spawn ไม่เจอ! บอกชื่อปุ่มจริงมาแก้ให้ตรงจุดได้")
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(handleCharacterDeath)
if LocalPlayer.Character then
    handleCharacterDeath(LocalPlayer.Character)
end
