--// ANTI AFK สำหรับ Roblox
local VirtualInputManager = game:GetService("VirtualInputManager")

task.spawn(function()
    while true do
        task.wait(60) -- กด jump ทุก 60 วิ
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        print("[Anti AFK] jumped")
    end
end)

print("[Anti AFK] Started")
