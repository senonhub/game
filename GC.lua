--[[
    ╔══════════════════════════════════════════╗
    ║   🎴 AUTO ROLL PACK — v2.3               ║
    ║   ✅ ButtonPart = Roll                   ║
    ║   ✅ Press E    = Buy                    ║
    ║   ✅ CardConveyer = Detect Pack + Status ║
    ║   ✨ FIX: ต้องเลือกสถานะก่อนถึงจะซื้อ    ║
    ║   ✨ FIX: รอ detect card จริงก่อนตัดสินใจ ║
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
-- STATUS DATABASE (variant การ์ดที่ได้ตอนเปิด pack)
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
local STATUS_NAMES = {}
for _, s in ipairs(STATUSES) do table.insert(STATUS_NAMES, s.emoji .. " " .. s.name) end

local function stripEmoji(labelWithEmoji)
    return labelWithEmoji:match("%s(%S+)$") or labelWithEmoji
end

-- ═══════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════
local cfg = {
    autoRoll     = false,
    rollDelay    = 0.7,   -- หน่วงหลัง Roll สำเร็จ (วิ) ก่อน roll รอบถัดไป
    detectTimeout= 2.0,   -- ✨ NEW: เวลาสูงสุดที่จะรอ+วนเช็ค card หลัง roll (วิ)
    pollInterval = 0.1,   -- ✨ NEW: ความถี่ในการเช็คซ้ำระหว่างรอ card โผล่
    stopOnFound  = true,  -- หยุดหลังซื้อได้
    targets      = {},
    lockedStatuses = {},  -- cfg.lockedStatuses[packName] = { [statusName]=true, ... } = "สถานะที่ต้องการซื้อ"
    stats = { rolls = 0, bought = 0, skippedNoStatus = 0, skippedNotTarget = 0 },
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
-- DETECT STATUS (variant การ์ด) จาก CardConveyer
-- ═══════════════════════════════════════
local function detectStatus()
    local plot, cc = getConveyer()
    if not cc then return nil end

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

    for _, st in ipairs(STATUSES) do
        if st.name == "Normal" then return st end
    end
    return nil
end

-- ═══════════════════════════════════════
-- ✨ NEW: รอจนกว่า card จริงจะโผล่บน Conveyer (กันปัญหา roll เร็วเกิน detect ไม่ทัน)
-- วนเช็คซ้ำทุก pollInterval วิ จนกว่าจะเจอ pack หรือหมดเวลา timeout
-- ═══════════════════════════════════════
local function waitForCard(timeout)
    local start = tick()
    repeat
        local found = detectPack()
        if found then
            local status = detectStatus()
            return found, status
        end
        task.wait(cfg.pollInterval)
    until tick() - start >= timeout
    return nil, nil -- หมดเวลา ยังไม่เจอ card
end

-- ═══════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════
local Win = Rayfield:CreateWindow({
    Name            = "🎴 Auto Roll Pack v2.3",
    LoadingTitle    = "Auto Roll Pack",
    LoadingSubtitle = "Pack + Status Match Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ════════════════════
-- TAB: CONTROL
-- ════════════════════
local TabCtrl = Win:CreateTab("⚙️ Control", nil)

local lblStatus = TabCtrl:CreateLabel("📌 Status: รอสั่งการ")
local lblStats  = TabCtrl:CreateLabel("🎲 Rolls: 0   ✅ Bought: 0")

local function refreshStats()
    lblStats:Set(string.format(
        "🎲 Rolls: %d   ✅ Bought: %d   ⏭ ข้าม(สถานะไม่ตรง/ยังไม่เลือก): %d",
        cfg.stats.rolls, cfg.stats.bought, cfg.stats.skippedNoStatus))
end

TabCtrl:CreateToggle({
    Name         = "🔄 Auto Roll",
    CurrentValue = false,
    Callback = function(val)
        cfg.autoRoll = val

        if val then
            cfg.stats = { rolls = 0, bought = 0, skippedNoStatus = 0, skippedNotTarget = 0 }
            lblStatus:Set("📌 Status: 🔄 กำลัง Roll...")

            task.spawn(function()
                while cfg.autoRoll do

                    local rolled = doRoll()
                    if not rolled then
                        lblStatus:Set("⚠️ ไม่พบ ButtonPart — ดู Debug")
                        task.wait(1)
                        continue
                    end

                    cfg.stats.rolls += 1
                    refreshStats()

                    -- ✨ FIX: วนรอจนเจอ card จริงๆ (หรือ timeout) แทนการ wait คงที่แล้วเช็คครั้งเดียว
                    local found, status = waitForCard(cfg.detectTimeout)

                    if found then
                        local isTarget = cfg.targets[found.name]

                        if not isTarget then
                            -- pack ไม่ตรง target → ข้ามเสมอ (ไม่สนสถานะ)
                            lblStatus:Set(string.format(
                                "🔄 %s %s [%s] — ไม่ใช่ target ข้าม",
                                found.emoji, found.name, found.rarity))

                        else
                            -- pack ตรง target → เช็คสถานะต่อ
                            local lockedSet    = cfg.lockedStatuses[found.name] or {}
                            local hasSelection = next(lockedSet) ~= nil
                            local statusMatch  = hasSelection and status and lockedSet[status.name]

                            if not hasSelection then
                                -- ยังไม่ได้เลือกสถานะที่ต้องการเลย → ไม่ซื้อ
                                cfg.stats.skippedNoStatus += 1
                                refreshStats()
                                lblStatus:Set(string.format(
                                    "⚠️ %s %s [%s] ตรง target แต่ยังไม่ได้เลือกสถานะที่ต้องการ — ข้าม",
                                    found.emoji, found.name, found.rarity))

                            elseif statusMatch then
                                -- ✅ ตรงทั้ง pack และสถานะ → ซื้อ
                                lblStatus:Set(string.format(
                                    "👁 %s %s [%s] %s — 🎯 ตรงเงื่อนไข! กำลังซื้อ...",
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
                                        "✅ ซื้อ %s (%s) แล้ว! หยุด Roll",
                                        found.name, status and status.name or ""))
                                    break
                                else
                                    task.wait(1.0)
                                end
                            else
                                -- pack ตรง target แต่สถานะไม่ตรงที่เลือกไว้ → ข้าม
                                cfg.stats.skippedNoStatus += 1
                                refreshStats()
                                lblStatus:Set(string.format(
                                    "🔒 %s %s [%s] เป็น %s — ไม่ตรงสถานะที่เลือก ข้าม",
                                    found.emoji, found.name, found.rarity,
                                    status and status.name or "ไม่ทราบ"))
                            end
                        end
                    else
                        -- หมดเวลา timeout ยังหา card ไม่เจอเลย (roll เร็วเกิน หรือ CardConveyer ยังไม่โผล่)
                        lblStatus:Set(string.format(
                            "⏱ Roll #%d — รอ %.1fวิ แล้วไม่เจอ card เลย (ลองเพิ่ม Detect Timeout)",
                            cfg.stats.rolls, cfg.detectTimeout))
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
    Name         = "⏱ Roll Delay หลังซื้อ/ข้าม (วิ)",
    Range        = {0.2, 3.0},
    Increment    = 0.1,
    CurrentValue = 0.7,
    Callback = function(val) cfg.rollDelay = val end
})

-- ✨ NEW: ปรับเวลาสูงสุดที่จะวนรอ card หลัง roll แต่ละครั้ง
TabCtrl:CreateSlider({
    Name         = "🕐 Detect Timeout — เวลาสูงสุดรอ card โผล่ (วิ)",
    Range        = {0.5, 5.0},
    Increment    = 0.1,
    CurrentValue = 2.0,
    Callback = function(val) cfg.detectTimeout = val end
})

-- ✨ NEW: ความถี่ในการวนเช็คระหว่างรอ
TabCtrl:CreateSlider({
    Name         = "🔁 ความถี่เช็คซ้ำระหว่างรอ (วิ)",
    Range        = {0.05, 0.5},
    Increment    = 0.05,
    CurrentValue = 0.1,
    Callback = function(val) cfg.pollInterval = val end
})

TabCtrl:CreateButton({
    Name = "🔁 Reset Stats",
    Callback = function()
        cfg.stats = { rolls = 0, bought = 0, skippedNoStatus = 0, skippedNotTarget = 0 }
        refreshStats()
    end
})

-- ════════════════════
-- TAB: TARGET PACKS
-- ════════════════════
local TabPacks = Win:CreateTab("🎯 Target Packs", nil)
TabPacks:CreateLabel("เลือก Pack ที่ต้องการ — จะ Buy อัตโนมัติ:")
TabPacks:CreateLabel("🎯 เลือกสถานะที่ต้องการของ Pack นั้น — ต้องเลือกอย่างน้อย 1 อัน ไม่งั้นจะไม่ซื้อ")
TabPacks:CreateLabel("กติกา: Pack ตรง + สถานะตรงที่เลือก = ซื้อ | อย่างใดอย่างหนึ่งไม่ตรง (หรือยังไม่เลือกสถานะ) = ข้าม")

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

    TabPacks:CreateDropdown({
        Name = "  🎯 สถานะที่ต้องการของ " .. pack.name,
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
    Name = "⭐ เลือก Legendary + Mythic + Secret ทั้งหมด (ไม่รวมสถานะ — ต้องไปเลือกสถานะเองด้วย)",
    Callback = function()
        for _, p in ipairs(PACKS) do
            if p.tier >= 4 then cfg.targets[p.name] = true end
        end
        Rayfield:Notify({ Title="✅", Content="เลือก Tier 4–6 แล้ว — อย่าลืมเลือกสถานะของแต่ละ pack ด้วย", Duration=4 })
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
    Name = "🔓 ล้างสถานะที่เลือกทั้งหมด (ทุก Pack)",
    Callback = function()
        for _, p in ipairs(PACKS) do cfg.lockedStatuses[p.name] = {} end
        Rayfield:Notify({ Title="🔓", Content="ล้างสถานะที่เลือกไว้ทั้งหมดแล้ว", Duration=2 })
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
    Name = "📋 Print เงื่อนไข Target+สถานะ ที่ตั้งไว้ → Console",
    Callback = function()
        print("\n====== TARGET PACK + STATUS CONDITIONS ======")
        local count = 0
        for _, p in ipairs(PACKS) do
            if cfg.targets[p.name] then
                local set = cfg.lockedStatuses[p.name]
                local names = {}
                for statName in pairs(set) do table.insert(names, statName) end
                local statusText = (#names > 0) and table.concat(names, ", ") or "⚠️ ยังไม่ได้เลือกสถานะ (จะไม่ซื้อ)"
                print("  🎯 " .. p.emoji .. " " .. p.name .. " → " .. statusText)
                count += 1
            end
        end
        if count == 0 then print("  (ยังไม่ได้เลือก target pack ใดๆ)") end
        print("==============================================\n")
        Rayfield:Notify({
            Title   = "✅ Print แล้ว",
            Content = "มี " .. count .. " pack ที่ตั้ง target ไว้ — ดูผลใน F9 Console",
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
    Title   = "🎴 Auto Roll v2.3 Ready!",
    Content = "แก้ logic + แก้ปัญหา roll เร็วเกิน detect ไม่ทันแล้ว!",
    Duration = 4,
    Image   = "rbxassetid://4483345998",
})
