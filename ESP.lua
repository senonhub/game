--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

--// SETTINGS
local SHOW_DISTANCE = true -- ให้โชว์ระยะห่างด้วยไหม

--// FIND BOUNTY
local function getBounty(plr)
    local stats = plr:FindFirstChild("leaderstats")
    if stats then
        for _,v in pairs(stats:GetChildren()) do
            if string.find(string.lower(v.Name), "bounty") then
                return v.Value
            end
        end
    end

    -- fallback
    for _,v in pairs(plr:GetDescendants()) do
        if (v:IsA("IntValue") or v:IsA("NumberValue")) and string.find(string.lower(v.Name), "bounty") then
            return v.Value
        end
    end

    return "?"
end

--// CREATE ESP
local function createESP(plr)
    if plr == player then return end

    local function setup(char)
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        -- กันซ้ำ
        if head:FindFirstChild("ESP") then
            head:FindFirstChild("ESP"):Destroy()
        end

        local bill = Instance.new("BillboardGui")
        bill.Name = "ESP"
        bill.Size = UDim2.new(0, 200, 0, 50)
        bill.AlwaysOnTop = true
        bill.Adornee = head
        bill.Parent = head

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1,0,1,0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255, 80, 80)
        text.TextStrokeTransparency = 0
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = bill

        -- อัปเดท realtime
        RunService.RenderStepped:Connect(function()
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

            local bounty = getBounty(plr)

            local distText = ""
            if SHOW_DISTANCE then
                local dist = (plr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                distText = "\n["..math.floor(dist).."m]"
            end

            text.Text = plr.Name.." | "..tostring(bounty)..distText
        end)
    end

    if plr.Character then
        setup(plr.Character)
    end

    plr.CharacterAdded:Connect(setup)
end

--// APPLY TO ALL
for _,plr in pairs(Players:GetPlayers()) do
    createESP(plr)
end

--// NEW PLAYER
Players.PlayerAdded:Connect(createESP)