--[[
    ╔══════════════════════════════════════════╗
    ║   🎴 AUTO ROLL PACK — v2.2               ║
    ║   ✅ ButtonPart = Roll                   ║
    ║   ✅ Press E    = Buy                    ║
    ║   ✅ CardConveyer = Detect Pack + Status ║
    ║   ✨ NEW: Lock by Pack + Card Status     ║
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
-- PACK DATABASE (ประเภทกล่อง)
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

    -- ══════════════ TIER 6 (SECRET) ══════════════
    { name = "Chainsaw Pack",     rarity = "Chainsaw",   tier = 6, emoji = "🪚" },
    { name = "Revenge Pack",      rarity = "Revenge",    tier = 6, emoji = "⏰" },
    { name = "Eternity Pack",     rarity = "Eternity",   tier = 6, emoji = "🌈" },
}

-- ═══════════════════════════════════════
-- ✨ NEW: STATUS DATABASE (variant การ์ดที่ได้ตอนเปิด pack)
-- ═══════════════════════════════════════
local STATUSES = {
    { name = "Normal",     emoji = "⚪" },
    { name = "Golden",     emoji = "🟡" },
    { name = "Diamond",    emoji = "💎" },
    { name = "Venomous",   emoji = "🐍" },
    { name = "Rainbow",    emoji = "🌈" },
    { name = "Sakura",     emoji = "🌸" },
    { name = "Candy",      emoji = "🍬" },
    { name = "Blessed",    emoji = "🌟" },
    { name = "Radioactive",emoji = "☢️" },
    { name = "Glitch",     emoji = "👾" },
    { name = "Starfallen", emoji = "💫" },
    { name = "Admin",      emoji = "🛡️" },
}
-- รายชื่อ status ล้วนๆ (ใช้ทำ Dropdown Options)
local STATUS_NAMES = {}
for _, s in ipairs(STATUSES) do table.insert(STATUS_NAMES, s.emoji .. " " .. s.name) end

-- แปลงจาก "🟡 Golden" (ที่ dropdown ส่งกลับ) → "Golden" (ชื่อล้วน)
local function stripEmoji(labelWithEmoji)
    return labelWithEmoji:match("%s(%S+)$") or labelWithEmoji
end

-- ═══════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════
local cfg = {
    autoRoll    = false,
    rollDelay   = 0.7,   -- หน่วง หลัง Roll (วิ)
    detectDelay = 0.4,   -- รอ pack โผล่หลัง Roll (วิ)
    stopOnFound = true,  -- หยุดหลังซื้อได้
    targets     = {},
    lockedStatuses = {}, -- ✨ NEW: cfg.lockedStatuses[packName] = { [statusName]=true, ... }
    stats       = { rolls = 0, bought = 0, skippedLocked = 0 },
}
for _, p in ipairs(PACKS) do
    cfg.targets[p.name]        = false
    cfg.lockedStatuses[p.name] = {}
end

-- ═══════════════════════════════════════
-- FIND PLAYER PLOT
-- ═══════════════════════════════════════
local function getMyPlot()
    local plots = workspace:FindFirstChild("MAP")
        and workspace.MAP:FindFirstChild("Plots")
    if not plots then return nil end

    for _, folder in ipairs(plots:GetChildren()) do
        for _, plotModel in ipairs(folder:GetChildren()) do
            if plotModel:FindFirstChild(player.Name, true) then
                return plotModel
            end
        end
    end

    for _, folder in ipairs(plots:GetChildren()) do
        local first = folder:FindFirstChildWhichIsA("Model")
        if first then return first end
    end
    return nil
end

-- ✨ NEW: helper หา CardConveyer node ของ plot (ใช้ร่วมกันทั้ง detectPack และ detectStatus)
local function getConveyer()
    local plot = getMyPlot()
    if not plot then return nil, nil end
    local cc = plot:FindFirstChild("CardConveyer", true)
    return plot, cc
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

    local cd = btn:FindFirstChildOfClass("ClickDetector")
    if cd then
        pcall(function() fireclickdetector(cd) end)
        return true
    end

    local pp = btn:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        pcall(function() fireproximityprompt(pp) end)
        return true
    end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local oldPos = hrp.CFrame
        hrp.CFrame = btn.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.1)
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

    VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    return true
end

-- ═══════════════════════════════════════
-- DETECT PACK จาก CardConveyer
-- ═══════════════════════════════════════
local function detectPack()
    local plot, cc = getConveyer()
    if not cc then return nil end

    for _, obj in ipairs(cc:GetDescendants()) do
        for _, pack in ipairs(PACKS) do
            if obj.Name:lower():find(pack.name:lower())
            or obj.Name:lower():find(pack.rarity:lower()) then
                return pack
            end
        end
        if obj:IsA("TextLabel") then
            local txt = obj.Text:lower()
            for _, pack in ipairs(PACKS) do
                if txt:find(pack.name:lower())
                or txt:find(pack.rarity:lower()) then
                    return pack
                end
            end
        end
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

    if plot then
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
    end

    return nil
end

-- ═══════════════════════════════════════
-- ✨ NEW: DETECT STATUS (variant การ์ด) จาก CardConveyer
-- ═══════════════════════════════════════
local function detectStatus()
    local plot, cc = getConveyer()
    if not cc then return nil end

    -- เช็คชื่อ Object / TextLabel / StringValue ใน CardConveyer
    for _, obj in ipairs(cc:GetDescendants()) do
        local nameLower = obj.Name:lower()
        for _, st in ipairs(STATUSES) do
            if nameLower:find(st.name:lower()) then
                return st
            end
        end
        if obj:IsA("TextLabel") then
            local txt = obj.Text:lower()
            for _, st in ipairs(STATUSES) do
                if txt:find(st.name:lower()) then
                    return st
                end
            end
        end
        if obj:IsA("StringValue") then
            local val = obj.Value:lower()
            for _, st in ipairs(STATUSES) do
                if val:find(st.name:lower()) then
                    return st
                end
            end
        end
        -- เช็ค Attribute ชื่อ "Status" / "Rarity" / "Variant" ถ้ามี
        local attrOk, attrVal = pcall(function()
            return obj:GetAttribute("Status") or obj:GetAttribute("Variant") or obj:GetAttribute("CardStatus")
        end)
        if attrOk and attrVal then
            local av = tostring(attrVal):lower()
            for _, st in ipairs(STATUSES) do
                if av:find(st.name:lower()) then
                    return st
                end
            end
        end
    end

    -- ถ้าไม่เจอ status ระบุชัดเจน → ถือว่าเป็น "Normal" (ค่า default ของเกมส่วนใหญ่)
    for _, st in ipairs(STATUSES) do
        if st.name == "Normal" then return st end
    end
    return nil
end

-- ═══════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════
local Win = Rayfield:CreateWindow({
    Name            = "🎴 Auto Roll Pack v2.2",
    LoadingTitle    = "Auto Roll Pack",
    LoadingSubtitle = "Pack + Status Lock Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ════════════════════
-- TAB: CONTROL
-- ════════════════════
local TabCtrl = Win:CreateTab("⚙️ Control", nil)

local lblStatus = TabCtrl:CreateLabel("📌 Status: รอสั่งการ")
local lblStats  = TabCtrl:CreateLabel("🎲 Rolls: 0   ✅ Bought: 0   🔒 Skipped: 0")

local function refreshStats()
    lblStats:Set(string.format(
        "🎲 Rolls: %d   ✅ Bought: %d   🔒 Skipped: %d",
        cfg.stats.rolls, cfg.stats.bought, cfg.stats.skippedLocked))
end

TabCtrl:CreateToggle({
    Name         = "🔄 Auto Roll",
    CurrentValue = false,
    Callback = function(val)
        cfg.autoRoll = val

        if val then
            cfg.stats.rolls, cfg.stats.bought, cfg.stats.skippedLocked = 0, 0, 0
            lblStatus:Set("📌 Status: 🔄 กำลัง Roll...")

            task.spawn(function()
                while cfg.autoRoll do

                    local rolled = doRoll()
                    if not rolled then
                        lblStatus:Set("⚠️ ไม่พบ ButtonPart — ดู Debug")
                        task.wait(1)
                    end

                    cfg.stats.rolls += 1
                    refreshStats()

                    task.wait(cfg.detectDelay)

                    local found  = detectPack()
                    local status = found and detectStatus() or nil -- ✨ NEW

                    if found then
                        local isTarget = cfg.targets[found.name]

                        if isTarget then
                            -- ✨ NEW: เช็คว่า pack+สถานะ คู่นี้ถูกล็อกไว้หรือไม่
                            local lockedSet   = cfg.lockedStatuses[found.name] or {}
                            local isLockedCombo = status and lockedSet[status.name]

                            if isLockedCombo then
                                cfg.stats.skippedLocked += 1
                                refreshStats()
                                lblStatus:Set(string.format(
                                    "🔒 %s %s [%s] เป็น %s %s — ล็อกอยู่ ข้าม",
                                    found.emoji, found.name, found.rarity,
                                    status.emoji, status.name))
                            else
                                lblStatus:Set(string.format(
                                    "👁 %s %s [%s] %s — 🎯 TARGET! กำลังซื้อ...",
                                    found.emoji, found.name, found.rarity,
                                    status and (status.emoji.." "..status.name) or ""))

                                doBuy()
                                cfg.stats.bought += 1
                                refreshStats()

                                Rayfield:Notify({
                                    Title   = "🎴 ได้ Pack!",
                                    Content = string.format(
                                        "%s %s (%s) — สถานะ %s — กด E ซื้อแล้ว!",
                                        found.emoji, found.name, found.rarity,
                                        status and status.name or "ไม่ทราบ"),
                                    Duration = 6,
                                    Image   = "rbxassetid://4483345998",
                                })

                                if cfg.stopOnFound then
                                    cfg.autoRoll = false
                                    lblStatus:Set(string.format(
                                        "✅ ซื้อ %s แล้ว! หยุด Roll", found.name))
                                    break
                                else
                                    task.wait(1.0)
                                end
                            end
                        else
                            lblStatus:Set(string.format(
                                "👁 %s %s [%s] %s",
                                found.emoji, found.name, found.rarity,
                                status and (status.emoji.." "..status.name) or ""))
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
        cfg.stats = { rolls = 0, bought = 0, skippedLocked = 0 }
        refreshStats()
    end
})

-- ════════════════════
-- TAB: TARGET PACKS
-- ════════════════════
local TabPacks = Win:CreateTab("🎯 Target Packs", nil)
TabPacks:CreateLabel("เลือก Pack ที่ต้องการ — จะ Buy อัตโนมัติ:")
TabPacks:CreateLabel("🔒 ล็อกสถานะ = ถ้า pack นี้ออกมาเป็นสถานะที่เลือกไว้ บอทจะข้ามไม่ซื้อ")

local tierLabel = {
    [1]="— Tier 1: Common —",   [2]="— Tier 2: Rare —",
    [3]="— Tier 3: Epic —",     [4]="— Tier 4: Legendary —",
    [5]="— Tier 5: Mythic —",   [6]="— Tier 6: Secret —",
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

    -- ✨ NEW: dropdown เลือกหลายสถานะที่จะ "ล็อกไม่ซื้อ" สำหรับ pack นี้โดยเฉพาะ
    TabPacks:CreateDropdown({
        Name = "  🔒 ล็อกสถานะของ " .. pack.name,
        Options = STATUS_NAMES,
        CurrentOption = {},
        MultipleOptions = true,
        Callback = function(selected)
            local set = {}
            for _, labelWithEmoji in ipairs(selected) do
                set[stripEmoji(labelWithEmoji)] = true
            end
            cfg.lockedStatuses[pack.name] = set
        end
    })
end

TabPacks:CreateDivider()
TabPacks:CreateButton({
    Name = "⭐ เลือก Legendary + Mythic + Secret ทั้งหมด",
    Callback = function()
        for _, p in ipairs(PACKS) do
            if p.tier >= 4 then cfg.targets[p.name] = true end
        end
        Rayfield:Notify({ Title="✅", Content="เลือก Tier 4–6 แล้ว", Duration=2 })
    end
})
TabPacks:CreateButton({
    Name = "🔲 ยกเลิก Target ทั้งหมด",
    Callback = function()
        for _, p in ipairs(PACKS) do cfg.targets[p.name] = false end
        Rayfield:Notify({ Title="🔲", Content="ล้าง target แล้ว", Duration=2 })
    end
})
TabPacks:CreateButton({
    Name = "🔓 ล้างล็อกสถานะทั้งหมด (ทุก Pack)",
    Callback = function()
        for _, p in ipairs(PACKS) do cfg.lockedStatuses[p.name] = {} end
        Rayfield:Notify({ Title="🔓", Content="ล้างสถานะที่ล็อกไว้ทั้งหมดแล้ว", Duration=2 })
    end
})

-- ════════════════════
-- TAB: DEBUG
-- ════════════════════
local TabDbg = Win:CreateTab("🔧 Debug", nil)

TabDbg:CreateButton({
    Name = "👁 ตรวจ Pack + สถานะ ตอนนี้",
    Callback = function()
        local p = detectPack()
        local s = p and detectStatus()
        Rayfield:Notify({
            Title   = p and ("✅ " .. p.name) or "❌ ไม่พบ Pack",
            Content = p and (p.emoji.." "..p.rarity.." | สถานะ: "..(s and (s.emoji.." "..s.name) or "ไม่ทราบ"))
                        or "CardConveyer ว่างอยู่ หรือชื่อไม่ตรง",
            Duration = 5,
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
    Name = "📋 Print รายการล็อกทั้งหมด (Pack + สถานะ) → Console",
    Callback = function()
        print("\n====== LOCKED PACK+STATUS COMBOS ======")
        local count = 0
        for _, p in ipairs(PACKS) do
            local set = cfg.lockedStatuses[p.name]
            if set and next(set) then
                local names = {}
                for statName in pairs(set) do table.insert(names, statName) end
                print("  🔒 " .. p.emoji .. " " .. p.name .. " → " .. table.concat(names, ", "))
                count += 1
            end
        end
        if count == 0 then print("  (ไม่มี pack ที่ล็อกสถานะไว้)") end
        print("========================================\n")
        Rayfield:Notify({
            Title   = "✅ Print แล้ว",
            Content = "มี " .. count .. " pack ที่ตั้งล็อกสถานะไว้ — ดูผลใน F9 Console",
            Duration = 3,
        })
    end
})

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
        local plot, cc = getConveyer()
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
    Title   = "🎴 Auto Roll v2.2 Ready!",
    Content = "แยกระบบ Pack + สถานะการ์ด พร้อมล็อกแบบคู่แล้ว!",
    Duration = 4,
    Image   = "rbxassetid://4483345998",
})
