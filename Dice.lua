local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local points = {
    CFrame.new(-1918.75537, -18.6209354, 11269.3906, -0.261455745, -3.25640208e-08, -0.965215445, 1.78579063e-09, 1, -3.42212978e-08, 0.965215445, -1.06710276e-08, -0.261455745),
    CFrame.new(-1872.14563, -18.6232357, 11319.9639, 0.839467347, 1.24359092e-08, 0.543410182, 6.48919096e-09, 1, -3.29095293e-08, -0.543410182, 3.11527657e-08, 0.839467347),
    CFrame.new(-1806.98572, -18.7327805, 11323.584, 0.954321802, -5.09058407e-10, -0.298780739, -5.41932853e-11, 1, -1.87688221e-09, 0.298780739, 1.80734139e-09, 0.954321802),
    CFrame.new(-1800.74194, -18.5979099, 11362.2178, -0.962470651, 5.86135318e-09, 0.271385849, 3.56015728e-09, 1, -8.97175134e-09, -0.271385849, -7.66887087e-09, -0.962470651),
    CFrame.new(-1875.50354, -18.6209679, 11364.5938, 0.239026636, -1.19764432e-09, -0.97101301, 1.71290999e-08, 1, 2.98313907e-09, 0.97101301, -1.73456289e-08, 0.239026636),
    CFrame.new(-1994.29236, -18.6785908, 11359.915, -0.9951756, -1.14046739e-09, 0.0981095731, -1.41586243e-09, 1, -2.73739231e-09, -0.0981095731, -2.86309576e-09, -0.9951756),
    CFrame.new(-2076.72705, -18.7125988, 11349.6309, -0.379452139, 3.56895349e-08, 0.92521137, -6.9025333e-08, 1, -6.6883473e-08, -0.92521137, -8.92420999e-08, -0.379452139)
}

local running = false
local currentTween

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "TweenWaypointUI"
gui.ResetOnSpawn = false

local parentOK = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)

if not parentOK or not gui.Parent then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(210, 120)
frame.Position = UDim2.new(0.5, -105, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Active = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Tween Waypoints"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 15
title.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 36)
toggle.Position = UDim2.fromOffset(10, 34)
toggle.Text = "เริ่ม"
toggle.TextSize = 15
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
toggle.Parent = frame

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 28)
status.Position = UDim2.fromOffset(10, 78)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 13
status.Text = "สถานะ: หยุด"
status.Parent = frame

-- ลาก UI ได้ด้วยเมาส์หรือจอสัมผัส
local dragging = true
local dragInput, dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local function stopTween()
    running = false

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

toggle.MouseButton1Click:Connect(function()
    if running then
        stopTween()
        toggle.Text = "เริ่ม"
        toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
        status.Text = "สถานะ: หยุด"
        return
    end

    running = true
    toggle.Text = "หยุด"
    toggle.BackgroundColor3 = Color3.fromRGB(190, 65, 65)

    task.spawn(function()
        while running do
            for i, targetCF in ipairs(points) do
                if not running then break end

                local character = player.Character
                    or player.CharacterAdded:Wait()
                local root = character:WaitForChild("HumanoidRootPart")

                if not running then break end

                -- ปรับความเร็วได้ตรงนี้
                local speed = 100
                local distance = (root.Position - targetCF.Position).Magnitude
                local duration = math.max(distance / speed, 0.1)

                currentTween = TweenService:Create(
                    root,
                    TweenInfo.new(duration, Enum.EasingStyle.Linear),
                    {CFrame = targetCF}
                )

                status.Text = "กำลังไปจุด " .. i .. "/" .. #points
                currentTween:Play()
                local playbackState = currentTween.Completed:Wait()
                currentTween = nil

                if not running then break end
                if playbackState ~= Enum.PlaybackState.Completed then break end

                status.Text = "หยุดที่จุด " .. i .. "/" .. #points

                for _ = 1, 50 do
                    if not running then break end
                    task.wait(0.1)
                end
            end
        end

        currentTween = nil
        toggle.Text = "เริ่ม"
        toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
        status.Text = "สถานะ: หยุด"
    end)
end)
