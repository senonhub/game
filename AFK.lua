-- Anti AFK ครอบจักรวาล
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- วิธีที่ 1: กัน AFK หลัก
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- วิธีที่ 2: ขยับตัวนิดๆ กันเกมจับ
task.spawn(function()
    while true do
        task.wait(120) -- ทุก 2 นาที
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame *= CFrame.new(0,0,0.05)
            end
        end)
    end
end)

-- วิธีที่ 3: จำลองกดปุ่ม
task.spawn(function()
    while true do
        task.wait(180)
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end
end)
