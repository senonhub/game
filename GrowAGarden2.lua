-- // Grow a Garden 2 - All in One Script
-- // UI: Rayfield | Executor: Delta X
-- // PlaceId: 97598239454123

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("Rayfield failed to load: " .. tostring(Rayfield))
    return
end

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- // Crop List (จาก growagarden2.fandom.com/wiki/Crops)
local CROPS = {
    "Acorn", "Apple", "Bamboo", "Banana", "Beanstalk",
    "Blueberry", "Cactus", "Carrot", "Cherry", "Coconut",
    "Corn", "Dragon's Breath", "Glow Mushroom", "Grape",
    "Horned Melon", "Invisibility Mushroom", "Jump Mushroom",
    "Lotus", "Mango", "Moon Bloom", "Mushroom",
    "Pineapple", "Poison Apple", "Pomegranate", "Pumpkin",
    "Strawberry", "Sunflower", "Thorn Rose", "Tomato",
    "Tulip", "Venus Fly Trap",
}

local CROPS_WITH_ALL = {"All"}
for _, v in ipairs(CROPS) do
    table.insert(CROPS_WITH_ALL, v)
end

-- // State
local State = {
    -- Visuals
    DisableParticles = false,
    DisableMutationVFX = false,
    HideOwnPlants = false,
    HideOwnFruitsOnly = false,
    HideForeignPlants = false,

    -- Auto
    AutoSell = false,
    AutoSellItem = "All",
    AutoBuySeed = false,
    AutoBuyGear = false,
    AutoBuyPet = false,
    AutoCollect = false,
    AutoCollectItem = "All",
    MinWeight = 0,
    SellDelay = 1,

    -- Shovel
    AutoGroupPlants = false,
    GroupPosition = Vector3.new(0, 0, 0),

    -- Mail
    MailTarget = "",
    MailCategory = "Fruits",
    MailAmount = 1,
    MailItem = "",

    -- Anti AFK
    AntiAFK = false,
}

-- // Helpers
local function Notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Image = 4483362458,
    })
end

local function GetRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if not remote then
        warn("[GAG2] Remote not found: " .. name)
    end
    return remote
end

local function SafeFire(remoteName, ...)
    local remote = GetRemote(remoteName)
    if remote then
        pcall(function()
            remote:FireServer(...)
        end)
    end
end

local function SafeInvoke(remoteName, ...)
    local remote = GetRemote(remoteName)
    if remote then
        local ok, result = pcall(function()
            return remote:InvokeServer(...)
        end)
        if ok then return result end
    end
end

-- // Particle disable
local function SetParticles(disabled)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = not disabled
        end
    end
end

local function SetMutationVFX(disabled)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and obj.Parent and obj.Parent.Name:lower():find("mutation") then
            obj.Enabled = not disabled
        end
        if obj:IsA("BillboardGui") and obj.Name:lower():find("mutation") then
            obj.Enabled = not disabled
        end
    end
end

-- // Hide plants
local function SetOwnPlantsVisible(hide)
    for _, plot in ipairs(Workspace:GetDescendants()) do
        if plot.Name == "Plot" or plot.Name:lower():find("farm") then
            if plot:FindFirstChild("Owner") and plot.Owner.Value == LocalPlayer.UserId then
                for _, plant in ipairs(plot:GetChildren()) do
                    if plant:IsA("Model") then
                        for _, part in ipairs(plant:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.LocalTransparencyModifier = hide and 1 or 0
                            end
                        end
                    end
                end
            end
        end
    end
end

local function SetForeignPlantsVisible(hide)
    for _, plot in ipairs(Workspace:GetDescendants()) do
        if plot.Name == "Plot" or plot.Name:lower():find("farm") then
            local ownerVal = plot:FindFirstChild("Owner")
            if ownerVal and ownerVal.Value ~= LocalPlayer.UserId then
                for _, plant in ipairs(plot:GetChildren()) do
                    if plant:IsA("Model") then
                        for _, part in ipairs(plant:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.LocalTransparencyModifier = hide and 1 or 0
                            end
                        end
                    end
                end
            end
        end
    end
end

-- // Anti AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- // Auto Collect loop
task.spawn(function()
    while task.wait(0.8) do
        if State.AutoCollect then
            pcall(function()
                for _, plot in ipairs(Workspace:GetDescendants()) do
                    if (plot.Name == "Plot" or plot.Name:lower():find("farm")) then
                        local ownerVal = plot:FindFirstChild("Owner")
                        if ownerVal and ownerVal.Value == LocalPlayer.UserId then
                            for _, fruit in ipairs(plot:GetDescendants()) do
                                if fruit:IsA("Model") and fruit:FindFirstChild("Weight") then
                                    local w = fruit.Weight.Value
                                    local nameMatch = (State.AutoCollectItem == "All") or (fruit.Name == State.AutoCollectItem)
                                    if w >= State.MinWeight and nameMatch then
                                        SafeFire("CollectFruit", fruit)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- // Auto Sell loop
task.spawn(function()
    while task.wait(State.SellDelay) do
        if State.AutoSell then
            pcall(function()
                if State.AutoSellItem == "All" then
                    SafeFire("SellAll")
                else
                    SafeFire("SellItem", State.AutoSellItem)
                end
            end)
        end
    end
end)

-- // Auto Buy Seed loop
task.spawn(function()
    while task.wait(2) do
        if State.AutoBuySeed then
            pcall(function()
                SafeFire("BuySeed")
            end)
        end
    end
end)

-- // Auto Buy Gear loop
task.spawn(function()
    while task.wait(2) do
        if State.AutoBuyGear then
            pcall(function()
                SafeFire("BuyGear")
            end)
        end
    end
end)

-- // Auto Buy Pet loop
task.spawn(function()
    while task.wait(2) do
        if State.AutoBuyPet then
            pcall(function()
                SafeFire("BuyPet")
            end)
        end
    end
end)

-- // Auto Group Plants (Shovel)
task.spawn(function()
    while task.wait(1) do
        if State.AutoGroupPlants then
            pcall(function()
                for _, plot in ipairs(Workspace:GetDescendants()) do
                    if (plot.Name == "Plot" or plot.Name:lower():find("farm")) then
                        local ownerVal = plot:FindFirstChild("Owner")
                        if ownerVal and ownerVal.Value == LocalPlayer.UserId then
                            local i = 0
                            for _, plant in ipairs(plot:GetChildren()) do
                                if plant:IsA("Model") and plant.PrimaryPart then
                                    local targetPos = State.GroupPosition + Vector3.new(i * 4, 0, 0)
                                    SafeFire("MovePlant", plant, targetPos)
                                    i = i + 1
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- // BUILD RAYFIELD UI
-- =============================================

local Window = Rayfield:CreateWindow({
    Name = "🌱 Grow a Garden 2",
    LoadingTitle = "GAG2 Script",
    LoadingSubtitle = "by Delta X",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GAG2Script",
        FileName = "Config",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- =============================================
-- TAB: MAIN (Visuals)
-- =============================================

local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateSection("Visuals & Optimization")

MainTab:CreateToggle({
    Name = "Disable All Particles",
    CurrentValue = false,
    Flag = "DisableParticles",
    Callback = function(val)
        State.DisableParticles = val
        SetParticles(val)
        Notify("Particles", val and "ปิด Particles แล้ว" or "เปิด Particles แล้ว")
    end,
})

MainTab:CreateToggle({
    Name = "Disable Mutation VFX",
    CurrentValue = false,
    Flag = "DisableMutationVFX",
    Callback = function(val)
        State.DisableMutationVFX = val
        SetMutationVFX(val)
        Notify("Mutation VFX", val and "ปิด Mutation VFX แล้ว" or "เปิด Mutation VFX แล้ว")
    end,
})

MainTab:CreateToggle({
    Name = "Hide Own Plants",
    CurrentValue = false,
    Flag = "HideOwnPlants",
    Callback = function(val)
        State.HideOwnPlants = val
        SetOwnPlantsVisible(val)
    end,
})

MainTab:CreateToggle({
    Name = "Hide Own Fruits Only",
    CurrentValue = false,
    Flag = "HideOwnFruitsOnly",
    Callback = function(val)
        State.HideOwnFruitsOnly = val
    end,
})

MainTab:CreateToggle({
    Name = "Hide Foreign Plants",
    CurrentValue = false,
    Flag = "HideForeignPlants",
    Callback = function(val)
        State.HideForeignPlants = val
        SetForeignPlantsVisible(val)
    end,
})

-- =============================================
-- TAB: AUTOMATIC
-- =============================================

local AutoTab = Window:CreateTab("⚡ Automatic", 4483362458)

AutoTab:CreateSection("Auto Collect")

AutoTab:CreateDropdown({
    Name = "เลือก Crop ที่จะเก็บ",
    Options = CROPS_WITH_ALL,
    CurrentOption = {"All"},
    Flag = "AutoCollectItem",
    Callback = function(val)
        State.AutoCollectItem = val[1] or val
    end,
})

AutoTab:CreateSlider({
    Name = "Min Weight to Collect",
    Range = {0, 1000},
    Increment = 1,
    Suffix = "g",
    CurrentValue = 0,
    Flag = "MinWeight",
    Callback = function(val)
        State.MinWeight = val
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Collect Fruits",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(val)
        State.AutoCollect = val
        Notify("Auto Collect", val and "เปิดแล้ว" or "ปิดแล้ว")
    end,
})

AutoTab:CreateSection("Auto Sell")

AutoTab:CreateDropdown({
    Name = "เลือก Crop ที่จะขาย",
    Options = CROPS_WITH_ALL,
    CurrentOption = {"All"},
    Flag = "AutoSellItem",
    Callback = function(val)
        State.AutoSellItem = val[1] or val
    end,
})

AutoTab:CreateSlider({
    Name = "Sell Delay (วินาที)",
    Range = {0.5, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "SellDelay",
    Callback = function(val)
        State.SellDelay = val
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Sell All",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(val)
        State.AutoSell = val
        Notify("Auto Sell", val and "เปิดแล้ว" or "ปิดแล้ว")
    end,
})

AutoTab:CreateSection("Auto Buy")

AutoTab:CreateToggle({
    Name = "Auto Buy Seeds",
    CurrentValue = false,
    Flag = "AutoBuySeed",
    Callback = function(val)
        State.AutoBuySeed = val
        Notify("Auto Buy Seeds", val and "เปิดแล้ว" or "ปิดแล้ว")
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Buy Gear",
    CurrentValue = false,
    Flag = "AutoBuyGear",
    Callback = function(val)
        State.AutoBuyGear = val
        Notify("Auto Buy Gear", val and "เปิดแล้ว" or "ปิดแล้ว")
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Buy Pet",
    CurrentValue = false,
    Flag = "AutoBuyPet",
    Callback = function(val)
        State.AutoBuyPet = val
        Notify("Auto Buy Pet", val and "เปิดแล้ว" or "ปิดแล้ว")
    end,
})

-- =============================================
-- TAB: SHOVEL
-- =============================================

local ShovelTab = Window:CreateTab("⛏️ Shovel", 4483362458)

ShovelTab:CreateSection("Plant Management")

ShovelTab:CreateInput({
    Name = "Group Position X",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Flag = "GroupX",
    Callback = function(val)
        local num = tonumber(val)
        if num then
            State.GroupPosition = Vector3.new(num, State.GroupPosition.Y, State.GroupPosition.Z)
        end
    end,
})

ShovelTab:CreateInput({
    Name = "Group Position Z",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Flag = "GroupZ",
    Callback = function(val)
        local num = tonumber(val)
        if num then
            State.GroupPosition = Vector3.new(State.GroupPosition.X, State.GroupPosition.Y, num)
        end
    end,
})

ShovelTab:CreateButton({
    Name = "📍 ใช้ตำแหน่งปัจจุบัน",
    Callback = function()
        local pos = HumanoidRootPart.Position
        State.GroupPosition = Vector3.new(pos.X, pos.Y, pos.Z)
        Notify("Shovel", "บันทึกตำแหน่ง: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Z))
    end,
})

ShovelTab:CreateToggle({
    Name = "Auto Group Plants",
    CurrentValue = false,
    Flag = "AutoGroupPlants",
    Callback = function(val)
        State.AutoGroupPlants = val
        Notify("Auto Group", val and "เปิดแล้ว — ย้ายต้นไม้รวมจุดเดียวกัน" or "ปิดแล้ว")
    end,
})

-- =============================================
-- TAB: MAIL
-- =============================================

local MailTab = Window:CreateTab("✉️ Mail", 4483362458)

MailTab:CreateSection("Mail Delivery Settings")

MailTab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Enter exact username",
    RemoveTextAfterFocusLost = false,
    Flag = "MailTarget",
    Callback = function(val)
        State.MailTarget = val
    end,
})

MailTab:CreateSlider({
    Name = "Amount Limit",
    Range = {1, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "MailAmount",
    Callback = function(val)
        State.MailAmount = val
    end,
})

MailTab:CreateDropdown({
    Name = "Select Category to Scan",
    Options = {"Fruits", "Seeds", "Gear", "Pets", "All"},
    CurrentOption = {"Fruits"},
    Flag = "MailCategory",
    Callback = function(val)
        State.MailCategory = val[1] or val
    end,
})

MailTab:CreateDropdown({
    Name = "Select Item to Send",
    Options = CROPS_WITH_ALL,
    CurrentOption = {"All"},
    Flag = "MailItem",
    Callback = function(val)
        State.MailItem = val[1] or val
    end,
})

MailTab:CreateButton({
    Name = "🔄 Refresh Backpack Items",
    Callback = function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local items = {}
            for _, item in ipairs(backpack:GetChildren()) do
                table.insert(items, item.Name)
            end
            Notify("Backpack", "พบ " .. #items .. " ไอเทม")
        else
            Notify("Backpack", "ไม่พบ Backpack")
        end
    end,
})

MailTab:CreateButton({
    Name = "📨 Send Mail",
    Callback = function()
        if State.MailTarget == "" then
            Notify("Mail Error", "กรุณาใส่ Target Username ก่อน", 3)
            return
        end
        local ok, err = pcall(function()
            SafeFire("SendMail", {
                target = State.MailTarget,
                category = State.MailCategory,
                item = State.MailItem,
                amount = State.MailAmount,
            })
        end)
        if ok then
            Notify("Mail Sent ✅", "ส่งไปที่ " .. State.MailTarget .. " แล้ว")
        else
            Notify("Mail Failed ❌", tostring(err), 4)
        end
    end,
})

-- =============================================
-- TAB: SETTINGS
-- =============================================

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateSection("Player Settings")

SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(val)
        State.AntiAFK = val
        Notify("Anti AFK", val and "เปิดแล้ว — จะไม่ถูก kick" or "ปิดแล้ว")
    end,
})

SettingsTab:CreateToggle({
    Name = "No Clip (ทะลุกำแพง)",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(val)
        local connection
        if val then
            connection = RunService.Stepped:Connect(function()
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            Notify("NoClip", "เปิดแล้ว")
        else
            if connection then connection:Disconnect() end
            Notify("NoClip", "ปิดแล้ว")
        end
    end,
})

SettingsTab:CreateSection("Walk Speed / Jump")

SettingsTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(val)
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end,
})

SettingsTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(val)
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end,
})

SettingsTab:CreateSection("Script Info")

SettingsTab:CreateLabel("🌱 Grow a Garden 2 — All in One")
SettingsTab:CreateLabel("⚡ Executor: Delta X")
SettingsTab:CreateLabel("📦 PlaceId: 97598239454123")

-- =============================================
-- Init notify
-- =============================================

Rayfield:LoadConfiguration()

task.wait(1)
Notify("🌱 GAG2 Script", "โหลดสำเร็จ! พร้อมใช้งานแล้วครับ", 4)
