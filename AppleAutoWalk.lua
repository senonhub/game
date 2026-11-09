--[[
    Apple Auto Walk  (เดินเก็บ Apple อัตโนมัติ)
    - สแกน Apple ที่ spawn อยู่ใน Workspace.AutumnApples
    - เลือก Apple ที่ใกล้ตัวที่สุด (เฉพาะที่อยู่ในโซน Workspace.Zones.AppleArea)
    - ใช้ Humanoid:MoveTo เดินไปเก็บเหมือนผู้เล่นจริง + กระโดดเมื่อติด
    - มีปุ่ม ON/OFF บนหน้าจอ (เหมาะกับมือถือ)
]]

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS        = game:GetService("ReplicatedStorage")
local lp        = Players.LocalPlayer

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local CFG = {
    Enabled        = true,
    ApplesFolder   = "AutumnApples",          -- โฟลเดอร์ที่ Apple spawn (รูปที่ 1)
    ZonePath       = {"Zones", "AppleArea"},  -- โซนที่ Apple เกิด (รูปที่ 3)
    NamePattern    = "^Apple_",               -- ชื่อ Apple เช่น Apple_RedSpeckle
    ExcludeParents = {"Apples", "Zones"},     -- โฟลเดอร์ต้นแบบ (รูปที่ 2) ห้ามเก็บ
    ZoneOnly       = true,                    -- เก็บเฉพาะที่อยู่ในโซน
    ZonePadding    = 6,                       -- ขยายขอบโซน (studs)
    ReachDistance  = 3.5,                     -- ระยะถือว่าถึงแล้ว (แนวราบ)
    GiveUpTime     = 6,                       -- เดินไปนานเกินนี้แล้วข้าม (วินาที)
    BlacklistTime  = 15,                      -- เวลาที่ข้าม Apple ที่เก็บไม่ได้
    TouchFallback  = true,                    -- ถ้าเดินถึงแล้วไม่หาย ให้ firetouchinterest ช่วย
    WalkSpeed      = nil,                     -- ใส่เลขถ้าอยากปรับความเร็ว เช่น 24
    IdleWait       = 0.5,                     -- รอเมื่อไม่มี Apple
}

------------------------------------------------------------
-- กันรันซ้ำ
------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.AppleAutoWalk then
    pcall(function() env.AppleAutoWalk.Stop() end)
end

local alive      = true
local collected  = 0
local blacklist  = {}   -- [instance] = expireTime
local gui

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function posOf(o)
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Model") then
        local ok, cf = pcall(function() return o:GetPivot() end)
        if ok then return cf.Position end
    end
end

local function getZone()
    local z = Workspace
    for _, n in ipairs(CFG.ZonePath) do
        z = z and z:FindFirstChild(n)
    end
    return z
end

local function inZone(zone, pos)
    if not CFG.ZoneOnly or not zone then return true end
    local cf, size
    if zone:IsA("BasePart") then
        cf, size = zone.CFrame, zone.Size
    elseif zone:IsA("Model") then
        cf, size = zone:GetBoundingBox()
    else
        return true
    end
    local rel = cf:PointToObjectSpace(pos)
    local pad = CFG.ZonePadding
    return math.abs(rel.X) <= size.X / 2 + pad and math.abs(rel.Z) <= size.Z / 2 + pad
end

local function isExcluded(o)
    for _, n in ipairs(CFG.ExcludeParents) do
        if o.Parent and o.Parent.Name == n then return true end
    end
    return o:IsDescendantOf(RS)
end

local function isApple(o)
    return (o:IsA("Model") or o:IsA("BasePart"))
        and o.Name:match(CFG.NamePattern) ~= nil
        and not isExcluded(o)
end

local lastFullScan = 0
local function scanApples()
    local list = {}
    local root = Workspace:FindFirstChild(CFG.ApplesFolder)
    if root then
        for _, o in ipairs(root:GetChildren()) do
            if isApple(o) then list[#list + 1] = o end
        end
    end
    -- สำรอง: ถ้าไม่เจอเลย ค่อยสแกนทั้ง Workspace (จำกัดทุก 2 วิ)
    if #list == 0 and os.clock() - lastFullScan > 2 then
        lastFullScan = os.clock()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if isApple(o) then list[#list + 1] = o end
        end
    end
    return list
end

local function pickNearest(hrp)
    local zone, now = getZone(), os.clock()
    local best, bestD
    for _, a in ipairs(scanApples()) do
        local exp = blacklist[a]
        if exp and exp > now then continue end
        local p = posOf(a)
        if p and inZone(zone, p) then
            local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
            if not bestD or d < bestD then best, bestD = a, d end
        end
    end
    return best
end

local function flatDist(a, b)
    return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function touchFallback(hrp, apple)
    if not (CFG.TouchFallback and firetouchinterest) then return end
    local parts = apple:IsA("BasePart") and {apple} or {}
    if apple:IsA("Model") then
        for _, d in ipairs(apple:GetDescendants()) do
            if d:IsA("BasePart") then parts[#parts + 1] = d end
        end
    end
    for _, p in ipairs(parts) do
        pcall(function()
            firetouchinterest(hrp, p, 0)
            firetouchinterest(hrp, p, 1)
        end)
    end
end

-- เดินไปหา Apple 1 ลูก; คืน true ถ้า Apple หายไป (เก็บสำเร็จ)
local function walkTo(hum, hrp, apple)
    local t0        = os.clock()
    local lastCheck = t0
    local lastPos   = hrp.Position

    while alive and CFG.Enabled and apple.Parent and hum.Health > 0 do
        local p = posOf(apple)
        if not p then break end

        if flatDist(p, hrp.Position) <= CFG.ReachDistance then
            task.wait(0.15)
            if apple.Parent then touchFallback(hrp, apple) task.wait(0.15) end
            return apple.Parent == nil
        end

        if os.clock() - t0 > CFG.GiveUpTime then return false end

        hum:MoveTo(p)

        -- ติดสิ่งกีดขวาง -> กระโดด
        if os.clock() - lastCheck > 0.6 then
            if (hrp.Position - lastPos).Magnitude < 0.6 then hum.Jump = true end
            lastPos, lastCheck = hrp.Position, os.clock()
        end
        task.wait(0.1)
    end
    return apple.Parent == nil
end

------------------------------------------------------------
-- GUI (ปุ่มเปิด/ปิด + ตัวนับ)
------------------------------------------------------------
local function makeGui()
    gui = Instance.new("ScreenGui")
    gui.Name = "AppleAutoWalkGui"
    gui.ResetOnSpawn = false
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 40)
    btn.Position = UDim2.new(0, 10, 0.45, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function refresh()
        btn.Text = (CFG.Enabled and "🍎 ON  " or "🍎 OFF  ") .. collected
        btn.BackgroundColor3 = CFG.Enabled and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(120, 40, 40)
    end
    btn.MouseButton1Click:Connect(function()
        CFG.Enabled = not CFG.Enabled
        refresh()
    end)
    refresh()
    return refresh
end

local refreshGui = makeGui()

------------------------------------------------------------
-- Main loop
------------------------------------------------------------
task.spawn(function()
    while alive do
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if CFG.Enabled and hum and hrp and hum.Health > 0 then
            if CFG.WalkSpeed then hum.WalkSpeed = CFG.WalkSpeed end

            local apple = pickNearest(hrp)
            if apple then
                if walkTo(hum, hrp, apple) then
                    collected += 1
                    refreshGui()
                elseif apple.Parent then
                    blacklist[apple] = os.clock() + CFG.BlacklistTime
                end
            else
                task.wait(CFG.IdleWait)
            end
        else
            task.wait(0.5)
        end
        task.wait()
    end
end)

env.AppleAutoWalk = {
    Stop = function()
        alive = false
        if gui then gui:Destroy() end
    end,
    Config = CFG,
}
