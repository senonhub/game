--[[
    ╔══════════════════════════════════════════╗
    ║   🎴 AUTO ROLL PACK — v2.0               ║
    ║   ✅ ButtonPart = Roll                   ║
    ║   ✅ Press E    = Buy                    ║
    ║   ✅ CardConveyer = Detect Pack          ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local VIM         = game:GetService("VirtualInputManager")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

-- ═══════════════════════════════════════
-- LOAD RAYFIELD
-- ═══════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ═══════════════════════════════════════
-- PACK DATABASE
-- ═══════════════════════════════════════
local PACKS = {
    { name = "Ruin Pack",         rarity = "Ruin",       tier = 1, emoji = "💀" },
    { name = "Mage Pack",         rarity = "Reborn",     tier = 1, emoji = "🔮" },
    { name = "Beast Pack",        rarity = "Beast",      tier = 1, emoji = "🐺" },
    { name = "Viking Pack",       rarity = "Nordic",     tier = 1, emoji = "⚔️" },
    { name = "Gamer Pack",        rarity = "Gamer",      tier = 1, emoji = "🎮" },
    { name = "Hunter Pack",       rarity = "Hunter",     tier = 2, emoji = "🏹" },
    { name = "Soul Pack",         rarity = "Soul",       tier = 2, emoji = "👻" },
    { name = "Swordsman Pack",    rarity = "Swordsman",  tier = 2, emoji = "🗡️" },
    { name = "Manga Pack",        rarity = "Manga",      tier = 2, emoji = "📖" },
    { name = "Bizarre Pack",      rarity = "Paradox",    tier = 3, emoji = "🌀" },
    { name = "Grimoire Pack",     rarity = "Magic",      tier = 3, emoji = "📚" },
    { name = "Oni Pack",          rarity = "Oni",        tier = 3, emoji = "👺" },
    { name = "Chaos Pack",        rarity = "Chaos",      tier = 3, emoji = "💥" },
    { name = "Soccer Pack",       rarity = "Striker",    tier = 3, emoji = "⚽" },
    { name = "Titan Pack",        rarity = "Founder",    tier = 4, emoji = "🔱" },
    { name = "Evolved Pack",      rarity = "Evolved",    tier = 4, emoji = "⚡" },
    { name = "Monarch Pack",      rarity = "Shadow",     tier = 4, emoji = "👑" },
    { name = "Pirate King Pack",  rarity = "Emperor",    tier = 4, emoji = "🏴‍☠️" },
    { name = "Demon Pack",        rarity = "Demon",      tier = 4, emoji = "😈" },
    { name = "Galaxy Pack",       rarity = "Celestial",  tier = 5, emoji = "🌌" },
    { name = "Heaven Pack",       rarity = "Heavenly",   tier = 5, emoji = "😇" },
    { name = "Void Pack",         rarity = "Corrupted",  tier = 5, emoji = "🕳️" },
    { name = "Empyrean Pack",     rarity = "Sacred",     tier = 5, emoji = "✨" },
}

-- ═══════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════
local cfg = {
    autoRoll    = false,
    rollDelay   = 0.7,   -- หน่วง หลัง Roll (วิ)
    detectDelay = 0.4,   -- รอ pack โผล่หลัง Roll (วิ)
    stopOnFound = true,  -- หยุดหลังซื้อได้
    targets     = {},
    stats       = { rolls = 0, bought = 0 },
}
for _, p in ipairs(PACKS) do cfg.targets[p.name] = false end

-- ═══════════════════════════════════════
-- FIND PLAYER PLOT
-- ═══════════════════════════════════════
-- Workspace > MAP > Plots > [folder] > Plot_N0
local function getMyPlot()
    local plots = workspace:FindFirstChild("MAP")
        and workspace.MAP:FindFirstChild("Plots")
    if not plots then return nil end

    for _, folder in ipairs(plots:GetChildren()) do
        for _, plotModel in ipairs(folder:GetChildren()) do
            -- เช็คว่า plot นี้มีชื่อ player ไหม
            if plotModel:FindFirstChild(player.Name, true) then
                return plotModel
            end
        end
    end

    -- fallback: คืน Plot แรกที่เจอ
    for _, folder in ipairs(plots:GetChildren()) do
        local first = folder:FindFirstChildWhichIsA("Model")
        if first then return first end
    end
    return nil
end

-- ═══════════════════════════════════════
-- ROLL — กด ButtonPart
-- ═══════════════════════════════════════
local function doRoll()
    local plot = getMyPlot()
    if not plot then
        warn("[AutoRoll] ❌ ไม่พบ Plot ของ player")
        return false
    end

    local btn = plot:FindFirstChild("ButtonPart", true)
    if not btn then
        warn("[AutoRoll] ❌ ไม่พบ ButtonPart ใน Plot")
        return false
    end

    -- ลอง ClickDetector ก่อน
    local cd = btn:FindFirstChildOfClass("ClickDetector")
    if cd then
        -- executor function: fireclickdetector
        pcall(function() fireclickdetector(cd) end)
        return true
    end

    -- ลอง ProximityPrompt
    local pp = btn:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        pcall(function() fireproximityprompt(pp) end)
        return true
    end

    -- fallback: VirtualClick (teleport & click)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local oldPos = hrp.CFrame
        hrp.CFrame = btn.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.1)
        -- press E ที่ตำแหน่งปุ่ม
        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        hrp.CFrame = oldPos
        return true
    end

    return false
end

-- ═══════════════════════════════════════
-- BUY — กด E (ProximityPrompt)
-- ═══════════════════════════════════════
local function doBuy()
    local plot = getMyPlot()
    if not plot then return false end

    -- 1. หา ProximityPrompt ใน Hover หรือ CardConveyer
    local tryNodes = { "Hover", "CardConveyer", "RecoverPack" }
    for _, nodeName in ipairs(tryNodes) do
        local node = plot:FindFirstChild(nodeName, true)
        if node then
            local pp = node:FindFirstChildOfClass("ProximityPrompt")
                or node:FindFirstChildWhichIsA("ProximityPrompt", true)
            if pp then
                pcall(function() fireproximityprompt(pp) end)
                return true
            end
        end
    end

    -- 2. หา ProximityPrompt ทุกตัวใน plot แล้วยิงอันที่ใกล้ที่สุด
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local nearest, nearDist = nil, math.huge
        for _, obj in ipairs(plot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Parent:IsA("BasePart") then
                local dist = (obj.Parent.Position - hrp.Position).Magnitude
                if dist < nearDist then
                    nearest  = obj
                    nearDist = dist
                end
            end
        end
        if nearest then
            pcall(function() fireproximityprompt(nearest) end)
            return true
        end
    end

    -- 3. fallback: VirtualInputManager กด E
    VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    return true
end

-- ═══════════════════════════════════════
-- DETECT PACK จาก CardConveyer
-- ═══════════════════════════════════════
local function detectPack()
    local plot = getMyPlot()
    if not plot then return nil end

    -- หา CardConveyer
    local cc = plot:FindFirstChild("CardConveyer", true)
    if not cc then return nil end

    -- สแกน descendants ทั้งหมด
    for _, obj in ipairs(cc:GetDescendants()) do
        -- เช็คชื่อ Object
        for _, pack in ipairs(PACKS) do
            if obj.Name:lower():find(pack.name:lower())
            or obj.Name:lower():find(pack.rarity:lower()) then
                return pack
            end
        end
        -- เช็ค Text Label
        if obj:IsA("TextLabel") then
            local txt = obj.Text:lower()
            for _, pack in ipairs(PACKS) do
                if txt:find(pack.name:lower())
                or txt:find(pack.rarity:lower()) then
                    return pack
                end
            end
        end
        -- เช็ค StringValue
        if obj:IsA("StringValue") then
            local val = obj.Value:lower()
            for _, pack in ipairs(PACKS) do
                if val:find(pack.name:lower())
                or val:find(pack.rarity:lower()) then
                    return pack
                end
            end
        end
    end

    -- ลองดูใน SurfaceGui / BillboardGui บน CardConveyer
    local function scanGui(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local txt = obj.Text:lower()
                for _, pack in ipairs(PACKS) do
                    if txt:find(pack.name:lower())
                    or txt:find(pack.rarity:lower()) then
                        return pack
                    end
                end
            end
        end
    end

    local result = scanGui(cc)
    if result then return result end

    -- สุดท้าย: scan ทั้ง plot
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj:IsA("Model") then
            for _, pack in ipairs(PACKS) do
                if obj.Name:lower():find(pack.name:lower())
                or obj.Name:lower():find(pack.rarity:lower()) then
                    return pack
                end
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════
local Win = Rayfield:CreateWindow({
    Name            = "🎴 Auto Roll Pack v2",
    LoadingTitle    = "Auto Roll Pack",
    LoadingSubtitle = "ButtonPart + E Buy Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ════════════════════
-- TAB: CONTROL
-- ════════════════════
local TabCtrl = Win:CreateTab("⚙️ Control", nil)

local lblStatus = TabCtrl:CreateLabel("📌 Status: รอสั่งการ")
local lblStats  = TabCtrl:CreateLabel("🎲 Rolls: 0   ✅ Bought: 0")

TabCtrl:CreateToggle({
    Name         = "🔄 Auto Roll",
    CurrentValue = false,
    Callback = function(val)
        cfg.autoRoll = val

        if val then
            cfg.stats.rolls  = 0
            cfg.stats.bought = 0
            lblStatus:Set("📌 Status: 🔄 กำลัง Roll...")

            task.spawn(function()
                while cfg.autoRoll do

                    -- ① Roll (กด ButtonPart)
                    local rolled = doRoll()
                    if not rolled then
                        lblStatus:Set("⚠️ ไม่พบ ButtonPart — ดู Debug")
                        task.wait(1)
                    end

                    cfg.stats.rolls += 1
                    lblStats:Set(string.format(
                        "🎲 Rolls: %d   ✅ Bought: %d",
                        cfg.stats.rolls, cfg.stats.bought))

                    -- ② รอ pack โผล่บน Conveyer
                    task.wait(cfg.detectDelay)

                    -- ③ ตรวจ pack ปัจจุบัน
                    local found = detectPack()

                    if found then
                        local isTarget = cfg.targets[found.name]
                        lblStatus:Set(string.format(
                            "👁 %s %s [%s]%s",
                            found.emoji, found.name, found.rarity,
                            isTarget and " 🎯 TARGET!" or ""))

                        if isTarget then
                            -- ④ BUY (กด E)
                            doBuy()
                            cfg.stats.bought += 1
                            lblStats:Set(string.format(
                                "🎲 Rolls: %d   ✅ Bought: %d",
                                cfg.stats.rolls, cfg.stats.bought))

                            Rayfield:Notify({
                                Title   = "🎴 ได้ Pack!",
                                Content = string.format(
                                    "%s %s (%s) — กด E ซื้อแล้ว!",
                                    found.emoji, found.name, found.rarity),
                                Duration = 6,
                                Image   = "rbxassetid://4483345998",
                            })

                            if cfg.stopOnFound then
                                cfg.autoRoll = false
                                lblStatus:Set(string.format(
                                    "✅ ซื้อ %s แล้ว! หยุด Roll", found.name))
                                break
                            else
                                task.wait(1.0) -- รอหลังซื้อก่อน roll ต่อ
                            end
                        end
                    else
                        lblStatus:Set(string.format(
                            "🔄 Roll #%d — ไม่เจอ target", cfg.stats.rolls))
                    end

                    task.wait(cfg.rollDelay)
                end
            end)

        else
            lblStatus:Set("📌 Status: ⏸ หยุด")
        end
    end
})

TabCtrl:CreateToggle({
    Name         = "⏹ หยุดเมื่อซื้อได้",
    CurrentValue = true,
    Callback = function(val) cfg.stopOnFound = val end
})

TabCtrl:CreateDivider()

TabCtrl:CreateSlider({
    Name         = "⏱ Roll Delay (วิ)",
    Range        = {0.2, 3.0},
    Increment    = 0.1,
    CurrentValue = 0.7,
    Callback = function(val) cfg.rollDelay = val end
})

TabCtrl:CreateSlider({
    Name         = "🕐 Detect Delay หลัง Roll (วิ)",
    Range        = {0.1, 2.0},
    Increment    = 0.1,
    CurrentValue = 0.4,
    Callback = function(val) cfg.detectDelay = val end
})

TabCtrl:CreateButton({
    Name = "🔁 Reset Stats",
    Callback = function()
        cfg.stats = { rolls = 0, bought = 0 }
        lblStats:Set("🎲 Rolls: 0   ✅ Bought: 0")
    end
})

-- ════════════════════
-- TAB: TARGET PACKS
-- ════════════════════
local TabPacks = Win:CreateTab("🎯 Target Packs", nil)
TabPacks:CreateLabel("เลือก Pack ที่ต้องการ — จะ Buy อัตโนมัติ:")

local tierLabel = {
    [1]="— Tier 1: Common —", [2]="— Tier 2: Rare —",
    [3]="— Tier 3: Epic —",   [4]="— Tier 4: Legendary —",
    [5]="— Tier 5: Mythic —",
}
local shownTier = {}
for _, pack in ipairs(PACKS) do
    if not shownTier[pack.tier] then
        shownTier[pack.tier] = true
        TabPacks:CreateDivider()
        TabPacks:CreateLabel(tierLabel[pack.tier])
    end
    TabPacks:CreateToggle({
        Name         = pack.emoji .. " " .. pack.name .. " [" .. pack.rarity .. "]",
        CurrentValue = false,
        Callback = function(val) cfg.targets[pack.name] = val end
    })
end

TabPacks:CreateDivider()
TabPacks:CreateButton({
    Name = "⭐ เลือก Legendary + Mythic ทั้งหมด",
    Callback = function()
        for _, p in ipairs(PACKS) do
            if p.tier >= 4 then cfg.targets[p.name] = true end
        end
        Rayfield:Notify({ Title="✅", Content="เลือก Tier 4–5 แล้ว", Duration=2 })
    end
})
TabPacks:CreateButton({
    Name = "🔲 ยกเลิกทั้งหมด",
    Callback = function()
        for _, p in ipairs(PACKS) do cfg.targets[p.name] = false end
        Rayfield:Notify({ Title="🔲", Content="ล้าง target แล้ว", Duration=2 })
    end
})

-- ════════════════════
-- TAB: DEBUG
-- ════════════════════
local TabDbg = Win:CreateTab("🔧 Debug", nil)

TabDbg:CreateButton({
    Name = "👁 ตรวจ Pack ตอนนี้ (CardConveyer)",
    Callback = function()
        local p = detectPack()
        Rayfield:Notify({
            Title   = p and ("✅ " .. p.name) or "❌ ไม่พบ Pack",
            Content = p and (p.emoji.." "..p.rarity) or "CardConveyer ว่างอยู่ หรือชื่อไม่ตรง",
            Duration = 4,
        })
    end
})

TabDbg:CreateButton({
    Name = "🎯 ทดสอบ Roll (กด ButtonPart)",
    Callback = function()
        local ok = doRoll()
        Rayfield:Notify({
            Title   = ok and "✅ Roll สำเร็จ" or "❌ Roll ล้มเหลว",
            Content = ok and "กด ButtonPart แล้ว!" or "ไม่พบ ButtonPart / ClickDetector",
            Duration = 3,
        })
    end
})

TabDbg:CreateButton({
    Name = "💰 ทดสอบ Buy (กด E)",
    Callback = function()
        local ok = doBuy()
        Rayfield:Notify({
            Title   = ok and "✅ Buy ส่งแล้ว" or "❌ Buy ล้มเหลว",
            Content = ok and "ส่ง ProximityPrompt / E แล้ว" or "ไม่พบ ProximityPrompt",
            Duration = 3,
        })
    end
})

TabDbg:CreateDivider()

TabDbg:CreateButton({
    Name = "📋 Print Plot Structure → Console",
    Callback = function()
        local plot = getMyPlot()
        if not plot then
            warn("[Debug] ❌ ไม่พบ plot")
            return
        end
        print("\n====== PLOT STRUCTURE: " .. plot.Name .. " ======")
        for _, obj in ipairs(plot:GetDescendants()) do
            local indent = string.rep("  ", obj:GetFullName():split(".").n - plot:GetFullName():split(".").n)
            print(indent .. obj.ClassName .. " | " .. obj.Name)
        end
        print("==========================================\n")
        Rayfield:Notify({
            Title   = "✅ Print แล้ว",
            Content = "ดูผลใน F9 Console",
            Duration = 2,
        })
    end
})

TabDbg:CreateButton({
    Name = "📋 Print CardConveyer Contents",
    Callback = function()
        local plot = getMyPlot()
        if not plot then warn("[Debug] ไม่พบ plot"); return end
        local cc = plot:FindFirstChild("CardConveyer", true)
        if not cc then warn("[Debug] ไม่พบ CardConveyer"); return end
        print("\n====== CardConveyer Contents ======")
        for _, obj in ipairs(cc:GetDescendants()) do
            local extra = ""
            if obj:IsA("TextLabel") then extra = ' text="'..obj.Text..'"' end
            if obj:IsA("StringValue") then extra = ' val="'..obj.Value..'"' end
            print("  " .. obj.ClassName .. " | " .. obj.Name .. extra)
        end
        print("===================================\n")
        Rayfield:Notify({ Title="✅", Content="ดูผลใน Console", Duration=2 })
    end
})

-- ═══════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════
Rayfield:Notify({
    Title   = "🎴 Auto Roll v2 Ready!",
    Content = "ButtonPart Roll + E Buy โหลดแล้ว!",
    Duration = 4,
    Image   = "rbxassetid://4483345998",
})
