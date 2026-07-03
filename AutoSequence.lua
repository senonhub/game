-- ===== Auto Sequence Script (Rayfield UI + Tween Teleport + Waypoint Parser) =====
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGetAsync('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Sequence",
    LoadingTitle = "Auto Sequence",
    LoadingSubtitle = "by markxdxaxa",
    ConfigurationSaving = { Enabled = false },
})

local Tab = Window:CreateTab("สถานะ", 4483362458)

local StatusLabel = Tab:CreateLabel("สถานะ: รอเริ่มทำงาน")
local Progress = Tab:CreateParagraph({
    Title = "ขั้นตอนการทำงาน",
    Content = "ยังไม่เริ่ม"
})

-- ===== Settings =====
local TWEEN_DURATION = 0.3 -- ความเร็ว tween (ยิ่งน้อยยิ่งเร็ว)
local MONSTER_NAME = "Lv32 Thief"

-- ===== Helper Functions =====
local function setStatus(text)
    StatusLabel:Set("สถานะ: " .. text)
    print("[AutoSeq] " .. text)
end

local function updateProgress(step, total, detail)
    Progress:Set({
        Title = string.format("ขั้นตอน %d/%d", step, total),
        Content = detail
    })
end

-- แปลง waypoint string เป็น CFrame
local function parseWaypoint(wpString)
    local data = wpString:gsub("^WP:%s*", "")

    local nums = {}
    for num in data:gmatch("[-%d%.]+") do
        table.insert(nums, tonumber(num))
    end

    if #nums < 12 then
        warn("[AutoSeq] Waypoint string ไม่ถูกต้อง มีแค่ " .. #nums .. " ค่า (ต้องการ 12)")
        return nil
    end

    return CFrame.new(
        nums[1], nums[2], nums[3],
        nums[4], nums[5], nums[6],
        nums[7], nums[8], nums[9],
        nums[10], nums[11], nums[12]
    )
end

-- ฟังก์ชันหามอนเตอร์ตามชื่อ แล้วสุ่มเลือก 1 ตัว
local function findMonsterCFrame(monsterName)
    local candidates = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == monsterName and obj:IsA("Model") then
            local primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if primary then
                table.insert(candidates, primary)
            end
        end
    end

    if #candidates == 0 then
        warn("[AutoSeq] ไม่เจอมอนเตอร์ชื่อ " .. monsterName)
        return nil
    end

    local chosen = candidates[math.random(1, #candidates)]
    print("[AutoSeq] เจอ " .. #candidates .. " ตัว เลือกวาปไปตัวที่: " .. chosen.Parent.Name)

    -- วาปไปข้าง ๆ ตัวมอน ไม่ใช่ทับตัวมัน
    return chosen.CFrame * CFrame.new(0, 0, 5)
end

-- วาปแบบ Tween (เร็ว)
local function teleportTo(targetCF, duration)
    duration = duration or TWEEN_DURATION
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if hum then
        hum.PlatformStand = true
    end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { CFrame = targetCF }
    )
    tween:Play()
    tween.Completed:Wait()

    if hum then
        hum.PlatformStand = false
    end
end

-- จำลองการกดปุ่ม
local function pressKey(keyCode)
    VIM:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, keyCode, false, game)
end

-- ===== Main Sequence =====
local function runSequence()
    local totalSteps = 4

    -- STEP 1: รอ 3 วิ
    setStatus("รอ 3 วินาที...")
    updateProgress(1, totalSteps, "กำลังรอเริ่มต้น 3 วิ")
    task.wait(3)

    -- STEP 2: วาปไปหามอนเตอร์ (แบบ Tween)
    setStatus("กำลังหามอนเตอร์...")
    updateProgress(2, totalSteps, "ค้นหา " .. MONSTER_NAME .. " แล้ววาปแบบ tween")

    local targetCF = findMonsterCFrame(MONSTER_NAME)
    if targetCF then
        teleportTo(targetCF, TWEEN_DURATION)
    else
        setStatus("ไม่เจอมอนเตอร์! ข้ามการวาป")
    end
    task.wait(0.2)

    -- STEP 3: กดปุ่ม R 1 ครั้ง
    setStatus("กำลังกดปุ่ม R...")
    updateProgress(3, totalSteps, "จำลองการกดปุ่ม R")
    pressKey(Enum.KeyCode.R)

    -- STEP 4: รอ 15 วิ แล้วรีจอยน์
    updateProgress(4, totalSteps, "นับถอยหลังก่อนรีจอยน์")
    for i = 15, 1, -1 do
        setStatus("รีจอยน์ในอีก " .. i .. " วิ")
        task.wait(1)
    end

    setStatus("กำลังรีจอยน์เซิร์ฟเวอร์...")
    task.wait(0.5)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- ===== UI Button + Auto Start =====
Tab:CreateButton({
    Name = "เริ่มทำงาน (รันซ้ำ)",
    Callback = function()
        task.spawn(runSequence)
    end
})

-- เริ่มอัตโนมัติทันทีที่โหลดสคริปต์
task.spawn(runSequence)
