--// SERVICES
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--// CREATE UI
local gui = Instance.new("ScreenGui")
gui.Name = "BountyDisplay"
pcall(function()
    gui.Parent = game.CoreGui
end)

local label = Instance.new("TextLabel")
label.Parent = gui
label.Size = UDim2.new(0, 220, 0, 50)
label.Position = UDim2.new(0, 10, 0, 200) -- ซ้ายบน ปรับได้
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(255,255,0)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "Bounty: loading..."

--// FIND BOUNTY
local function findBounty()
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        for _,v in pairs(stats:GetChildren()) do
            if string.find(string.lower(v.Name), "bounty") then
                return v
            end
        end
    end

    -- fallback (เผื่อเกมซ่อน)
    for _,v in pairs(player:GetDescendants()) do
        if (v:IsA("IntValue") or v:IsA("NumberValue")) and string.find(string.lower(v.Name), "bounty") then
            return v
        end
    end

    return nil
end

--// UPDATE UI
local function setup()
    local bounty = findBounty()

    if not bounty then
        label.Text = "Bounty: not found"
        warn("หา bounty ไม่เจอ")
        return
    end

    -- ค่าเริ่มต้น
    label.Text = "Bounty: "..tostring(bounty.Value)

    -- realtime update
    bounty:GetPropertyChangedSignal("Value"):Connect(function()
        label.Text = "Bounty: "..tostring(bounty.Value)
    end)
end

-- รอโหลดตัวละคร
if player.Character then
    setup()
else
    player.CharacterAdded:Wait()
    task.wait(1)
    setup()
end