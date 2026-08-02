local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({
	Title = "PayatboyZ",
	Author = "โดย Dexq",
	Folder = "PayatboyZUI",
	Size = UDim2.fromOffset(480, 310),
	Transparent = true,
	Theme = "Red",
	HideSearchBar = true,
	OpenButton = {
		Title = "เปิด PayatboyZ",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		Enabled = true,
		Draggable = true,
		Scale = 0.8,
		Color = ColorSequence.new(Color3.fromHex("#ff0000"), Color3.fromHex("#8b0000")),
	},
})
local MainTab = Window:Tab({
	Title = "หลัก",
	Icon = "solar:home-bold",
})
local PotionTab = Window:Tab({
	Title = "น้ำยา",
	Icon = "lucide:flask-conical",
})
local RaidTab = Window:Tab({
	Title = "เรด",
	Icon = "lucide:swords",
})
local TradeTab = Window:Tab({
	Title = "แลกเปลี่ยน",
	Icon = "lucide:arrow-right-left",
})
local FilterConfig = {
	EnableRarityFilter = false,
	EnableMutationFilter = false,
	BuyRarities = {},
	BuyMutations = {},
}
local function getSpawnPackClickDetector()
	local player = game:GetService("Players").LocalPlayer
	local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
	if plotNum ~= 0 then
		local plotFolder = workspace:FindFirstChild("MAP")
			and workspace.MAP:FindFirstChild("Plots")
			and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
		if plotFolder and plotFolder:FindFirstChild("Plot_N0") then
			for _, v in ipairs(plotFolder.Plot_N0:GetDescendants()) do
				if v:IsA("ClickDetector") and v.Parent.Name == "ButtonPart" then
					return v
				end
			end
		end
	end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if
			desc:IsA("ClickDetector")
			and desc.Parent
			and desc.Parent.Name == "ButtonPart"
			and desc.Parent.Parent
			and desc.Parent.Parent.Name == "Plot_N0"
		then
			return desc
		end
	end
	return nil
end
MainTab:Button({
	Title = "ช่องเก็บของ",
	Callback = function()
		local localPlayer = game:GetService("Players").LocalPlayer
		local backpack = localPlayer:FindFirstChild("Backpack")
		local char = localPlayer.Character
		local items = {}
		local function checkItem(t)
			if t:IsA("Tool") then
				local cardName = t:GetAttribute("CardName")
				if cardName then
					local mutation = tostring(t:GetAttribute("CardMutation") or "Normal")
					local grade = tostring(t:GetAttribute("CardGrade") or "N/A")
					local level = tonumber(t:GetAttribute("CardLevel")) or 1
					table.insert(
						items,
						string.format(
							"[Card] %s | Lvl: %d | Mutation: %s | Grade: %s",
							cardName,
							level,
							mutation,
							grade
						)
					)
					return
				end
				local packName = t:GetAttribute("TemplateName")
				if packName then
					local mutation = tostring(t:GetAttribute("Mutation") or "Normal")
					local rarity = tostring(t:GetAttribute("Rarity") or "N/A")
					table.insert(
						items,
						string.format("[Pack] %s | Rarity: %s | Mutation: %s", packName, rarity, mutation)
					)
					return
				end
				table.insert(items, string.format("[Item] %s", t.Name))
			end
		end
		if backpack then
			for _, t in ipairs(backpack:GetChildren()) do
				checkItem(t)
			end
		end
		if char then
			for _, t in ipairs(char:GetChildren()) do
				checkItem(t)
			end
		end
		if #items > 0 then
			local resultText = "Inventory\n" .. table.concat(items, "\n")
			if setclipboard then
				setclipboard(resultText)
				if WindUI and WindUI.Notify then
					WindUI:Notify({ Title = "ช่องเก็บของ", Content = "คัดลอกสำเร็จ!", Duration = 5 })
				end
			else
				if WindUI and WindUI.Notify then
					WindUI:Notify({
						Title = "ช่องเก็บของ",
						Content = "ตัวรันไม่รองรับ setclipboard!",
						Duration = 5,
					})
				end
			end
		else
			if WindUI and WindUI.Notify then
				WindUI:Notify({ Title = "ช่องเก็บของ", Content = "ช่องเก็บของว่างเปล่า!", Duration = 5 })
			end
		end
	end,
})
getgenv().AutoSpawnPack = false
local AutoSpawnToggle = MainTab:Toggle({
	Title = "สุ่มแพ็กอัตโนมัติ",
	Callback = function(state)
		getgenv().AutoSpawnPack = state
		if state then
			task.spawn(function()
				local cd = getSpawnPackClickDetector()
				if not cd then
					WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "ไม่พบปุ่มสุ่มแพ็ก!", Duration = 3 })
					getgenv().AutoSpawnPack = false
					return
				end
				while getgenv().AutoSpawnPack do
					local activeCards = 0
					if getgenv().CardFolder then
						for _, model in ipairs(getgenv().CardFolder:GetChildren()) do
							if
								model:IsA("Model")
								and model:GetAttribute("IgnoreTutoBeam") ~= nil
								and model:FindFirstChildWhichIsA("ProximityPrompt", true)
							then
								if getgenv().AutoBuyCards and model:GetAttribute("Rejected") then
									continue
								end
								activeCards = activeCards + 1
							end
						end
					end
					if getgenv().AutoBuyCards then
						if activeCards == 0 then
							pcall(fireclickdetector, cd)
							task.wait(0.3)
						else
							task.wait(0.05)
						end
					else
						pcall(fireclickdetector, cd)
						if activeCards >= 3 then
							task.wait(0.2)
						else
							task.wait(0.01)
						end
					end
				end
			end)
		end
	end,
})
local RaritiesList = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
	"Divine",
	"Transcendent",
	"Shadow",
	"Emperor",
	"Demon",
	"Manga",
	"Celestial",
	"Heavenly",
	"Corrupted",
	"Striker",
	"Sacred",
	"Paradox",
	"Founder",
	"Evolved",
	"Magic",
	"Oni",
	"Chaos",
	"Ruin",
	"Reborn",
	"Beast",
	"Nordic",
	"Hunter",
	"Soul",
	"Swordsman",
	"Gamer",
	"Revenge",
	"Chainsaw",
	"Eternity",
	"Academy",
	"Dynasty",
	"Grail",
	"Conquest",
	"Blaze",
	"Devour",
	"Mystery",
	"VIP",
	"Event",
	"Limited",
}
getgenv().SelectedRarities = {}
local RarityDropdown = MainTab:Dropdown({
	Title = "เลือกความหายากที่ต้องการซื้อ",
	Multi = true,
	Values = RaritiesList,
	Value = {},
	Callback = function(value)
		getgenv().SelectedRarities = {}
		if type(value) == "table" then
			for k, v in pairs(value) do
				if type(k) == "number" then
					getgenv().SelectedRarities[string.lower(tostring(v))] = true
				else
					getgenv().SelectedRarities[string.lower(tostring(k))] = v
				end
			end
		elseif type(value) == "string" then
			getgenv().SelectedRarities[string.lower(value)] = true
		end
	end,
})
local MutationsList = {
	"Normal",
	"Golden",
	"Diamond",
	"Venomous",
	"Rainbow",
	"Sakura",
	"Candy",
	"Blessed",
	"Radioactive",
	"Glitch",
	"Starfallen",
	"Admin",
	"Unknow",
}
getgenv().SelectedMutations = {}
local MutationDropdown = MainTab:Dropdown({
	Title = "เลือกกลายพันธุ์ที่ต้องการซื้อ",
	Multi = true,
	Values = MutationsList,
	Value = {},
	Callback = function(value)
		getgenv().SelectedMutations = {}
		if type(value) == "table" then
			for k, v in pairs(value) do
				if type(k) == "number" then
					getgenv().SelectedMutations[string.lower(tostring(v))] = true
				else
					getgenv().SelectedMutations[string.lower(tostring(k))] = v
				end
			end
		elseif type(value) == "string" then
			getgenv().SelectedMutations[string.lower(value)] = true
		end
	end,
})
getgenv().CardFolder = getgenv().CardFolder or nil
getgenv().PromptCooldowns = getgenv().PromptCooldowns or {}
local RunService = game:GetService("RunService")
local function findCardFolder()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			local model = desc:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("IgnoreTutoBeam") ~= nil then
				getgenv().CardFolder = model.Parent
				return true
			end
		end
	end
	return false
end
local function GetAllInventorySummary()
	local player = game:GetService("Players").LocalPlayer
	local inventory = {}
	local function scanFolder(folder)
		if not folder then
			return
		end
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Tool") then
				local rarityAttr = item:GetAttribute("Rarity")
				local cardNameAttr = item:GetAttribute("CardName")
				local groupKey = rarityAttr or cardNameAttr or item.Name
				if
					not item:GetAttribute("Rarity")
					and item:FindFirstChild("Rarity")
					and item.Rarity:IsA("StringValue")
				then
					groupKey = item.Rarity.Value
				end
				local mutation = item:GetAttribute("Mutation") or "Normal"
				if
					not item:GetAttribute("Mutation")
					and item:FindFirstChild("Mutation")
					and item.Mutation:IsA("StringValue")
				then
					mutation = item.Mutation.Value
				end
				if not string.find(string.lower(item.Name), "box") and groupKey ~= "Box" then
					if not inventory[groupKey] then
						inventory[groupKey] = {}
					end
					if not inventory[groupKey][mutation] then
						inventory[groupKey][mutation] = 0
					end
					inventory[groupKey][mutation] = inventory[groupKey][mutation] + 1
				end
			end
		end
	end
	pcall(function()
		scanFolder(player:FindFirstChild("Backpack"))
		if player.Character then
			scanFolder(player.Character)
		end
	end)
	local resultLines = {}
	for key, mutations in pairs(inventory) do
		local mutStrings = {}
		for mut, count in pairs(mutations) do
			table.insert(mutStrings, mut .. " x" .. tostring(count))
		end
		table.insert(resultLines, tostring(key) .. ": " .. table.concat(mutStrings, " | "))
	end
	if #resultLines > 0 then
		local fullText = table.concat(resultLines, "\n")
		if string.len(fullText) > 1000 then
			return string.sub(fullText, 1, 1000) .. "..."
		end
		return fullText
	else
		return "None"
	end
end
local function SendWebhook(url, rarity, mutation)
	local req = (syn and syn.request)
		or (http and http.request)
		or http_request
		or (fluxus and fluxus.request)
		or request
	if not req then
		return
	end
	local inventoryText = "Unknown"
	pcall(function()
		inventoryText = GetAllInventorySummary()
	end)
	local data = {
		["content"] = "",
		["embeds"] = {
			{
				["title"] = "🎉 Card Bought!",
				["description"] = "Successfully bought a card matching your criteria.",
				["type"] = "rich",
				["color"] = 5579688,
				["fields"] = {
					{
						["name"] = "Rarity",
						["value"] = tostring(rarity),
						["inline"] = true,
					},
					{
						["name"] = "Mutation",
						["value"] = tostring(mutation),
						["inline"] = true,
					},
					{
						["name"] = "Full Inventory",
						["value"] = inventoryText,
						["inline"] = false,
					},
				},
				["timestamp"] = DateTime.now():ToIsoDate(),
			},
		},
	}
	pcall(function()
		req({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = game:GetService("HttpService"):JSONEncode(data),
		})
	end)
end
local function instantBuyLoop()
	if not getgenv().AutoBuyCards then
		return
	end
	if not getgenv().CardFolder then
		findCardFolder()
	end
	if not getgenv().CardFolder then
		return
	end
	for _, model in ipairs(getgenv().CardFolder:GetChildren()) do
		if not model:IsA("Model") or model:GetAttribute("IgnoreTutoBeam") == nil then
			continue
		end
		local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt then
			continue
		end
		local rarityLabel = model:FindFirstChild("Rarity", true)
		local mutationLabel = model:FindFirstChild("Mutation", true)
		if rarityLabel then
			local cleanRarityText = string.gsub(rarityLabel.Text, "<[^>]+>", "")
			local cardRarity = string.match(cleanRarityText, "^%s*(.-)%s*$") or ""
			if cardRarity ~= "" and cardRarity ~= "Label" then
				local cardMutation = "Normal"
				if mutationLabel then
					local cleanMutationText = string.gsub(mutationLabel.Text, "<[^>]+>", "")
					local mText = string.match(cleanMutationText, "^%s*(.-)%s*$") or ""
					if mText ~= "" and mText ~= "Label" then
						cardMutation = mText
					end
				end
				local matchRarity = true
				if next(getgenv().SelectedRarities) ~= nil then
					matchRarity = (getgenv().SelectedRarities[string.lower(cardRarity)] == true)
				end
				local matchMutation = true
				if next(getgenv().SelectedMutations) ~= nil then
					matchMutation = (getgenv().SelectedMutations[string.lower(cardMutation)] == true)
				end
				if matchRarity and matchMutation then
					local now = tick()
					if not getgenv().PromptCooldowns[prompt] or now - getgenv().PromptCooldowns[prompt] > 0.05 then
						getgenv().PromptCooldowns[prompt] = now
						pcall(function()
							prompt.RequiresLineOfSight = false
							prompt.MaxActivationDistance = 99999
							fireproximityprompt(prompt)
						end)
						if getgenv().DiscordWebhook and getgenv().DiscordWebhook ~= "" then
							if not getgenv().NotifiedCards then
								getgenv().NotifiedCards = {}
							end
							if not getgenv().NotifiedCards[prompt] then
								getgenv().NotifiedCards[prompt] = true
								task.spawn(function()
									SendWebhook(getgenv().DiscordWebhook, cardRarity, cardMutation)
								end)
							end
						end
					end
				else
					model:SetAttribute("Rejected", true)
				end
			end
		end
	end
end
if getgenv().BruteForceLoop then
	getgenv().BruteForceLoop:Disconnect()
end
getgenv().BruteForceLoop = RunService.Heartbeat:Connect(instantBuyLoop)
getgenv().AutoBuyCards = false
local AutoBuyToggle = MainTab:Toggle({
	Title = "ซื้อที่เลือกเดี๋ยวนี้",
	Callback = function(state)
		getgenv().AutoBuyCards = state
	end,
})
getgenv().AutoCarry = false
getgenv().AutoCarryDelay = 5
local AutoCarryToggle = MainTab:Toggle({
	Title = "เก็บเงินอัตโนมัติ (Carry)",
	Callback = function(state)
		getgenv().AutoCarry = state
		if state then
			task.spawn(function()
				while getgenv().AutoCarry do
					local player = game:GetService("Players").LocalPlayer
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					local searchArea = workspace
					local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
					if plotNum ~= 0 then
						local plotFolder = workspace:FindFirstChild("MAP")
							and workspace.MAP:FindFirstChild("Plots")
							and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
						if plotFolder then
							searchArea = plotFolder
						end
					end
					for _, prompt in ipairs(searchArea:GetDescendants()) do
						if prompt:IsA("ProximityPrompt") then
							local txt = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()
							if txt:find("carry") then
								pcall(function()
									local targetPos
									if prompt.Parent:IsA("BasePart") then
										targetPos = prompt.Parent.Position
									elseif prompt.Parent:IsA("Attachment") then
										targetPos = prompt.Parent.WorldPosition
									elseif prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart then
										targetPos = prompt.Parent.PrimaryPart.Position
									end
									local originalCFrame
									if hrp and targetPos then
										originalCFrame = hrp.CFrame
										hrp.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
										task.wait(0.2)
									end
									prompt.RequiresLineOfSight = false
									prompt.MaxActivationDistance = 99999
									fireproximityprompt(prompt)
									task.wait(0.1)
									if originalCFrame then
										hrp.CFrame = originalCFrame
									end
								end)
							end
						end
					end
					local delayTime = tonumber(getgenv().AutoCarryDelay) or 5
					if delayTime < 1 then
						delayTime = 1
					end
					local elapsed = 0
					while getgenv().AutoCarry and elapsed < (delayTime * 60) do
						task.wait(1)
						elapsed = elapsed + 1
					end
					task.wait(1)
				end
			end)
		end
	end,
})
getgenv().AutoSellBox = false
local AutoSellBoxToggle = MainTab:Toggle({
	Title = "ขายกล่องอัตโนมัติ",
	Callback = function(state)
		getgenv().AutoSellBox = state
		if state then
			task.spawn(function()
				while getgenv().AutoSellBox do
					local player = game:GetService("Players").LocalPlayer
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					local backpack = player:FindFirstChild("Backpack")
					local boxTool = nil
					if backpack then
						for _, tool in ipairs(backpack:GetChildren()) do
							if tool:IsA("Tool") and (tool:GetAttribute("BoxValue") ~= nil or tool.Name:find("Box")) then
								boxTool = tool
								break
							end
						end
					end
					if boxTool and character and character:FindFirstChild("Humanoid") then
						character.Humanoid:EquipTool(boxTool)
						task.wait(0.2)
					end
					local isEquipped = false
					if character then
						for _, tool in ipairs(character:GetChildren()) do
							if tool:IsA("Tool") and (tool:GetAttribute("BoxValue") ~= nil or tool.Name:find("Box")) then
								isEquipped = true
								break
							end
						end
					end
					if isEquipped and hrp then
						local plotNum = player:FindFirstChild("PlotNumber") and player.PlotNumber.Value or 0
						if plotNum ~= 0 then
							local plotFolder = workspace:FindFirstChild("MAP")
								and workspace.MAP:FindFirstChild("Plots")
								and workspace.MAP.Plots:FindFirstChild(tostring(plotNum))
							if
								plotFolder
								and plotFolder:FindFirstChild("Plot_N0")
								and plotFolder.Plot_N0:FindFirstChild("SellPart")
							then
								local sellPart = plotFolder.Plot_N0.SellPart
								local prompt = sellPart:FindFirstChildWhichIsA("ProximityPrompt", true)
								if prompt then
									pcall(function()
										local originalCFrame = hrp.CFrame
										hrp.CFrame = sellPart.CFrame + Vector3.new(0, 3, 0)
										task.wait(0.15)
										prompt.RequiresLineOfSight = false
										prompt.MaxActivationDistance = 99999
										fireproximityprompt(prompt)
										task.wait(0.1)
										hrp.CFrame = originalCFrame
									end)
								end
							end
						end
					end
					task.wait(1)
				end
			end)
		end
	end,
})
local AutoCarrySlider = MainTab:Slider({
	Title = "หน่วงเวลาเก็บเงิน (นาที)",
	Step = 1,
	Value = {
		Min = 1,
		Max = 30,
		Default = getgenv().AutoCarryDelay or 5,
	},
	Callback = function(value)
		getgenv().AutoCarryDelay = value
	end,
})
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local antiAfkConnection
getgenv().AntiAfkState = false
local AntiAfkToggle = MainTab:Toggle({
	Title = "ป้องกันหลุด (Anti AFK)",
	Callback = function(state)
		getgenv().AntiAfkState = state
		if state then
			antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		else
			if antiAfkConnection then
				antiAfkConnection:Disconnect()
				antiAfkConnection = nil
			end
		end
	end,
})
local function isBoostActive(boostName)
	local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	if not PlayerGui then
		return true
	end
	local InfoGui = PlayerGui:FindFirstChild("InfoGui")
	if not InfoGui then
		return true
	end
	local Boost = InfoGui:FindFirstChild("Boost")
	if not Boost then
		return true
	end
	local BoostFrame = Boost:FindFirstChild(boostName)
	if not BoostFrame then
		return false
	end
	if not BoostFrame.Visible then
		return false
	end
	for _, v in ipairs(BoostFrame:GetDescendants()) do
		if v:IsA("TextLabel") then
			if v.Text == "00:00:00" or v.Text == "00:00" then
				return false
			end
		end
	end
	return true
end
local function getPotionAmount(potionId)
	local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	if not PlayerGui then
		return 0
	end
	local GuiMid = PlayerGui:FindFirstChild("GuiMid")
	if not GuiMid then
		return 0
	end
	local Items = GuiMid:FindFirstChild("Items")
	if not Items then
		return 0
	end
	local ItemsFrame = Items:FindFirstChild("ItemsFrame")
	if not ItemsFrame then
		return 0
	end
	local ScrollingFrameItems = ItemsFrame:FindFirstChild("ScrollingFrameItems")
	if not ScrollingFrameItems then
		return 0
	end
	local ObjectFrame = ScrollingFrameItems:FindFirstChild("ObjectFrame_" .. potionId)
	if not ObjectFrame then
		return 0
	end
	if not ObjectFrame.Visible then
		return 0
	end
	local ObjectButton = ObjectFrame:FindFirstChild("ObjectButton")
	if not ObjectButton then
		return 0
	end
	local Quantity = ObjectButton:FindFirstChild("Quantity")
	if not Quantity or not Quantity:IsA("TextLabel") then
		return 0
	end
	local amountStr = Quantity.Text:gsub("x", "")
	return tonumber(amountStr) or 0
end
local function setupPotionToggle(title, titleTH, boostName, itemIdPrefix)
	local genvName = "AutoUse" .. title
	getgenv()[genvName] = false
	PotionTab:Toggle({
		Title = "ใช้น้ำยา" .. titleTH .. "อัตโนมัติ",
		Value = getgenv()[genvName],
		Callback = function(state)
			getgenv()[genvName] = state
			if state then
				task.spawn(function()
					local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
					local ItemsRE = Remotes and Remotes:WaitForChild("ItemsRE", 5)
					if not ItemsRE then
						return
					end
					while getgenv()[genvName] do
						if not isBoostActive(boostName) then
							local amt1 = getPotionAmount(itemIdPrefix .. "1")
							local amt2 = getPotionAmount(itemIdPrefix .. "2")
							local amt3 = getPotionAmount(itemIdPrefix .. "3")
							if WindUI and WindUI.Notify then
								WindUI:Notify({
									Title = "เช็คกระเป๋าน้ำยา" .. titleTH,
									Content = string.format("คงเหลือ - III: %d | II: %d | I: %d", amt3, amt2, amt1),
									Duration = 3,
								})
							end
							if amt3 > 0 then
								ItemsRE:FireServer(
									"UseItem",
									{ ItemId = itemIdPrefix .. "3", Amount = math.min(5, amt3) }
								)
							elseif amt2 > 0 then
								ItemsRE:FireServer(
									"UseItem",
									{ ItemId = itemIdPrefix .. "2", Amount = math.min(5, amt2) }
								)
							elseif amt1 > 0 then
								ItemsRE:FireServer(
									"UseItem",
									{ ItemId = itemIdPrefix .. "1", Amount = math.min(5, amt1) }
								)
							end
						end
						task.wait(2)
					end
				end)
			end
		end,
	})
end
setupPotionToggle("Luck", "โชค", "PotionLuck", "LuckPotion")
setupPotionToggle("Cash", "เงิน", "PotionCash", "CashPotion")
setupPotionToggle("Mutation", "กลายพันธุ์", "PotionMutation", "MutationPotion")
setupPotionToggle("Production", "ผลผลิต", "PotionProduction", "ProductionPotion")
getgenv().AutoTower = false
local AutoTowerToggle = RaidTab:Toggle({
	Title = "ลงหอคอยอัตโนมัติ",
	Value = getgenv().AutoTower,
	Callback = function(state)
		getgenv().AutoTower = state
		if not state then
			local cam = workspace.CurrentCamera
			local character = game:GetService("Players").LocalPlayer.Character
			if cam and getgenv().TowerSavedCamCF then
				cam.CameraType = Enum.CameraType.Custom
				if character and character:FindFirstChild("Humanoid") then
					cam.CameraSubject = character.Humanoid
				end
				getgenv().TowerSavedCamCF = nil
			end
			if getgenv().TowerOriginalCFrame and character then
				character:PivotTo(getgenv().TowerOriginalCFrame)
				getgenv().TowerOriginalCFrame = nil
			end
		end
		if state then
			task.spawn(function()
				while getgenv().AutoTower do
					local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
					if playerGui then
						local equipBtn, battleBtn, nextBtn, playBtn, openBtn, autoReplayBtn, hideBattleBtn, showBattleBtn
						local function isGuiVisible(gui)
							if not gui then
								return false
							end
							if gui:IsA("GuiObject") and not gui.Visible then
								return false
							end
							local current = gui.Parent
							while current and current:IsA("GuiObject") do
								if not current.Visible then
									return false
								end
								current = current.Parent
							end
							if current and current:IsA("ScreenGui") then
								return current.Enabled
							end
							return true
						end
						for _, v in ipairs(playerGui:GetDescendants()) do
							if (v:IsA("TextButton") or v:IsA("TextLabel")) and v.Text then
								local text = string.upper(string.match(v.Text, "^%s*(.-)%s*$") or "")
								if text == "EQUIP BEST" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										equipBtn = btn
									end
								elseif text == "BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										battleBtn = btn
									end
								elseif text == "NEXT" or text == "NEXT FLOOR" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										nextBtn = btn
									end
								elseif text == "PLAY" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										playBtn = btn
									end
								elseif text == "AUTO REPLAY" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										autoReplayBtn = btn
									end
								elseif text == "HIDE BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										hideBattleBtn = btn
									end
								elseif text == "SHOW BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										showBattleBtn = btn
									end
								elseif string.find(text, "OPEN INFINITY TOWER") then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn then
										openBtn = btn
									end
								end
							end
						end
						local openPrompt
						for _, p in ipairs(workspace:GetDescendants()) do
							if p:IsA("ProximityPrompt") then
								local pText = string.upper(p.ActionText .. " " .. p.ObjectText)
								if
									string.find(pText, "OPEN INFINITY TOWER") or string.find(pText, "INFINITY TOWER")
								then
									openPrompt = p
									break
								end
							end
						end
						local function fireButton(btn)
							if not btn then
								return
							end
							pcall(function()
								local fired = false
								if getconnections then
									for _, conn in pairs(getconnections(btn.Activated)) do
										pcall(function()
											conn:Fire()
										end)
										fired = true
									end
									for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
										pcall(function()
											conn:Fire()
										end)
										fired = true
									end
									for _, conn in pairs(getconnections(btn.MouseButton1Down)) do
										pcall(function()
											conn:Fire()
										end)
										fired = true
									end
								end
								if not fired then
									local vim = game:GetService("VirtualInputManager")
									local absPos = btn.AbsolutePosition
									local absSize = btn.AbsoluteSize
									local center = absPos + (absSize / 2)
									vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, true, game, 1)
									task.wait(0.1)
									vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, false, game, 1)
								end
							end)
						end
						local inBattle = equipBtn or battleBtn or autoReplayBtn or showBattleBtn
						if openPrompt and not inBattle then
							pcall(function()
								local hrp = game:GetService("Players").LocalPlayer.Character
									and game:GetService("Players").LocalPlayer.Character
										:FindFirstChild("HumanoidRootPart")
								if hrp then
									local targetPos
									if openPrompt.Parent:IsA("BasePart") then
										targetPos = openPrompt.Parent.Position
									elseif openPrompt.Parent:IsA("Attachment") then
										targetPos = openPrompt.Parent.WorldPosition
									elseif openPrompt.Parent:IsA("Model") and openPrompt.Parent.PrimaryPart then
										targetPos = openPrompt.Parent.PrimaryPart.Position
									end
									if targetPos then
										local dist = (hrp.Position - targetPos).Magnitude
										if dist > 15 then
											local character = game:GetService("Players").LocalPlayer.Character
											if not getgenv().TowerOriginalCFrame then
												getgenv().TowerOriginalCFrame = character:GetPivot()
											end
											local cam = workspace.CurrentCamera
											if cam then
												getgenv().TowerSavedCamCF = cam.CFrame
												cam.CameraType = Enum.CameraType.Scriptable
											end
											character:PivotTo(CFrame.new(targetPos) + Vector3.new(0, 3, 0))
											task.wait(0.1)
										end
									end
								end
								openPrompt.RequiresLineOfSight = false
								openPrompt.MaxActivationDistance = 99999
								fireproximityprompt(openPrompt)
							end)
							task.wait(0.1)
						end
						if openBtn and not (equipBtn or battleBtn) then
							fireButton(openBtn)
							task.wait(0.1)
						end
						if equipBtn then
							fireButton(equipBtn)
							task.wait(0.1)
						end
						if battleBtn then
							fireButton(battleBtn)
							task.wait(0.2)
							local character = game:GetService("Players").LocalPlayer.Character
							if getgenv().TowerOriginalCFrame and character then
								character:PivotTo(getgenv().TowerOriginalCFrame)
								getgenv().TowerOriginalCFrame = nil
								local cam = workspace.CurrentCamera
								local char = game:GetService("Players").LocalPlayer.Character
								if cam and getgenv().TowerSavedCamCF then
									cam.CameraType = Enum.CameraType.Custom
									if char and char:FindFirstChild("Humanoid") then
										cam.CameraSubject = char.Humanoid
									end
									getgenv().TowerSavedCamCF = nil
								end
							end
						end
						if autoReplayBtn then
							local color = autoReplayBtn.BackgroundColor3
							if
								autoReplayBtn.BackgroundTransparency > 0.5
								and autoReplayBtn.Parent
								and autoReplayBtn.Parent:IsA("GuiObject")
							then
								color = autoReplayBtn.Parent.BackgroundColor3
							end
							if
								autoReplayBtn:IsA("ImageButton")
								and autoReplayBtn.ImageColor3 ~= Color3.new(1, 1, 1)
							then
								color = autoReplayBtn.ImageColor3
							end
							local isGreen = (color.G > color.R + 0.1)
							if isGreen then
								getgenv().AutoReplayToggled = true
							elseif not getgenv().AutoReplayToggled then
								fireButton(autoReplayBtn)
								getgenv().AutoReplayToggled = true
								task.wait(0.2)
							end
						end
						if not (autoReplayBtn or showBattleBtn or hideBattleBtn) then
							getgenv().AutoReplayToggled = false
						end
						if autoReplayBtn or showBattleBtn then
							local character = game:GetService("Players").LocalPlayer.Character
							if getgenv().TowerOriginalCFrame and character then
								character:PivotTo(getgenv().TowerOriginalCFrame)
								getgenv().TowerOriginalCFrame = nil
								local cam = workspace.CurrentCamera
								local char = game:GetService("Players").LocalPlayer.Character
								if cam and getgenv().TowerSavedCamCF then
									cam.CameraType = Enum.CameraType.Custom
									if char and char:FindFirstChild("Humanoid") then
										cam.CameraSubject = char.Humanoid
									end
									getgenv().TowerSavedCamCF = nil
								end
							end
						end
						if hideBattleBtn then
							fireButton(hideBattleBtn)
							task.wait(0.2)
						end
						if nextBtn then
							fireButton(nextBtn)
							task.wait(0.2)
						end
						if playBtn then
							fireButton(playBtn)
							task.wait(0.2)
						end
					end
					task.wait(0.2)
				end
			end)
		end
	end,
})
getgenv().BossRaidDifficulty = "NIGHTMARE"
local BossRaidDiffDropdown = RaidTab:Dropdown({
	Title = "ระดับความยากบอสเรด",
	Value = "NIGHTMARE",
	Values = { "EASY", "MEDIUM", "HARD", "NIGHTMARE" },
	Callback = function(Value)
		getgenv().BossRaidDifficulty = Value
	end,
})
getgenv().AutoBossRaid = false
local AutoBossRaidToggle = RaidTab:Toggle({
	Title = "ลงบอสเรดอัตโนมัติ",
	Value = getgenv().AutoBossRaid,
	Callback = function(state)
		getgenv().AutoBossRaid = state
		if state then
			getgenv().AutoTower = false
			task.spawn(function()
				while getgenv().AutoBossRaid do
					local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
					if playerGui then
						local equipBtn, battleBtn, diffBtn, autoReplayBtn, showBattleBtn, hideBattleBtn, nextBtn, playBtn
						local function isGuiVisible(gui)
							if not gui then
								return false
							end
							if gui:IsA("GuiObject") and not gui.Visible then
								return false
							end
							local current = gui.Parent
							while current and current:IsA("GuiObject") do
								if not current.Visible then
									return false
								end
								current = current.Parent
							end
							if current and current:IsA("ScreenGui") then
								return current.Enabled
							end
							return true
						end
						local function fireButton(btn)
							pcall(function()
								local fired = false
								if btn.Parent:IsA("ProximityPrompt") then
									return
								end
								for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
									c:Fire()
									fired = true
								end
								if not fired then
									for _, c in ipairs(getconnections(btn.MouseButton1Down)) do
										c:Fire()
										fired = true
									end
									for _, c in ipairs(getconnections(btn.MouseButton1Up)) do
										c:Fire()
										fired = true
									end
									for _, c in ipairs(getconnections(btn.Activated)) do
										c:Fire()
										fired = true
									end
								end
								if not fired then
									local vim = game:GetService("VirtualInputManager")
									local absPos = btn.AbsolutePosition
									local absSize = btn.AbsoluteSize
									local center = absPos + (absSize / 2)
									vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, true, game, 1)
									task.wait(0.1)
									vim:SendMouseButtonEvent(center.X, center.Y + 36, 0, false, game, 1)
								end
							end)
						end
						local alreadyFought = false
						for _, v in ipairs(playerGui:GetDescendants()) do
							if (v:IsA("TextButton") or v:IsA("TextLabel")) and v.Text then
								local text = string.upper(string.match(v.Text, "^%s*(.-)%s*$") or "")
								if string.find(text, "ALREADY FOUGHT THE BOSS") and isGuiVisible(v) then
									alreadyFought = true
								end
								if text == "EQUIP BEST" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										equipBtn = btn
									end
								elseif text == "BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										battleBtn = btn
									end
								elseif text == getgenv().BossRaidDifficulty then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										diffBtn = btn
									end
								elseif text == "AUTO REPLAY" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										autoReplayBtn = btn
									end
								elseif text == "SHOW BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										showBattleBtn = btn
									end
								elseif text == "HIDE BATTLE" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										hideBattleBtn = btn
									end
								elseif text == "NEXT" or text == "NEXT FLOOR" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										nextBtn = btn
									end
								elseif text == "PLAY" then
									local btn = v:IsA("TextButton") and v
										or v:FindFirstAncestorWhichIsA("TextButton")
										or v:FindFirstAncestorWhichIsA("ImageButton")
									if btn and isGuiVisible(btn) then
										playBtn = btn
									end
								end
							end
						end
						if alreadyFought then
							getgenv().AutoBossRaid = false
							if AutoBossRaidToggle and AutoBossRaidToggle.Set then
								pcall(function()
									AutoBossRaidToggle:Set(false)
								end)
							end
							if WindUI and WindUI.Notify then
								WindUI:Notify({
									Title = "บอสเรด",
									Content = "คุณสู้บอสไปแล้วในชั่วโมงนี้! หยุดลงบอสเรด",
									Duration = 5,
								})
							end
							local character = game:GetService("Players").LocalPlayer.Character
							if getgenv().BossOriginalCFrame and character then
								character:PivotTo(getgenv().BossOriginalCFrame)
								getgenv().BossOriginalCFrame = nil
							end
							continue
						end
						local inBattle = equipBtn or battleBtn or autoReplayBtn or showBattleBtn
						if not inBattle then
							local bossPrompt
							local portalPrompt
							for _, p in ipairs(workspace:GetDescendants()) do
								if p:IsA("ProximityPrompt") then
									local pText = string.upper(
										p.ActionText .. " " .. p.ObjectText .. " " .. (p.Parent and p.Parent.Name or "")
									)
									if string.find(pText, "BOSS RAID") and string.find(pText, "TELEPORT") then
										portalPrompt = p
									elseif
										not string.find(pText, "SHOP")
										and not string.find(pText, "RETURN")
										and not string.find(pText, "BACK")
										and not string.find(pText, "TELEPORT")
									then
										if
											string.find(pText, "TITAN")
											or string.find(pText, "BOSS")
											or string.find(pText, "RAID")
											or string.find(pText, "FIGHT")
										then
											bossPrompt = p
										end
									end
								end
							end
							local targetPrompt = bossPrompt or portalPrompt
							if targetPrompt then
								pcall(function()
									local hrp = game:GetService("Players").LocalPlayer.Character
										and game:GetService("Players").LocalPlayer.Character
											:FindFirstChild("HumanoidRootPart")
									if hrp then
										local targetPos
										if targetPrompt.Parent:IsA("BasePart") then
											targetPos = targetPrompt.Parent.Position
										elseif targetPrompt.Parent:IsA("Attachment") then
											targetPos = targetPrompt.Parent.WorldPosition
										elseif targetPrompt.Parent:IsA("Model") and targetPrompt.Parent.PrimaryPart then
											targetPos = targetPrompt.Parent.PrimaryPart.Position
										end
										if targetPos then
											local character = game:GetService("Players").LocalPlayer.Character
											if (hrp.Position - targetPos).Magnitude > 15 then
												if not getgenv().BossOriginalCFrame then
													getgenv().BossOriginalCFrame = character:GetPivot()
												end
												character:PivotTo(CFrame.new(targetPos) + Vector3.new(0, 3, 0))
												task.wait(0.1)
											end
										end
									end
									targetPrompt.RequiresLineOfSight = false
									targetPrompt.MaxActivationDistance = 99999
									fireproximityprompt(targetPrompt)
								end)
								task.wait(0.5)
							end
						end
						if diffBtn and not (autoReplayBtn or showBattleBtn) then
							fireButton(diffBtn)
							task.wait(0.1)
						end
						if equipBtn then
							fireButton(equipBtn)
							task.wait(0.1)
						end
						if battleBtn then
							fireButton(battleBtn)
							task.wait(0.2)
							local character = game:GetService("Players").LocalPlayer.Character
							if getgenv().BossOriginalCFrame and character then
								character:PivotTo(getgenv().BossOriginalCFrame)
								getgenv().BossOriginalCFrame = nil
							end
						end
						if autoReplayBtn then
							local color = autoReplayBtn.BackgroundColor3
							if
								autoReplayBtn.BackgroundTransparency > 0.5
								and autoReplayBtn.Parent
								and autoReplayBtn.Parent:IsA("GuiObject")
							then
								color = autoReplayBtn.Parent.BackgroundColor3
							end
							if
								autoReplayBtn:IsA("ImageButton")
								and autoReplayBtn.ImageColor3 ~= Color3.new(1, 1, 1)
							then
								color = autoReplayBtn.ImageColor3
							end
							local isGreen = (color.G > color.R + 0.1)
							if isGreen then
								getgenv().AutoReplayToggledBoss = true
							elseif not getgenv().AutoReplayToggledBoss then
								fireButton(autoReplayBtn)
								getgenv().AutoReplayToggledBoss = true
								task.wait(0.2)
							end
						end
						if not (autoReplayBtn or showBattleBtn or hideBattleBtn) then
							getgenv().AutoReplayToggledBoss = false
						end
						if autoReplayBtn or showBattleBtn then
							local character = game:GetService("Players").LocalPlayer.Character
							if getgenv().BossOriginalCFrame and character then
								character:PivotTo(getgenv().BossOriginalCFrame)
								getgenv().BossOriginalCFrame = nil
							end
						end
						if hideBattleBtn then
							fireButton(hideBattleBtn)
							task.wait(0.2)
						end
						if nextBtn then
							fireButton(nextBtn)
							task.wait(0.2)
						end
						if playBtn then
							fireButton(playBtn)
							task.wait(0.2)
						end
					end
					task.wait(0.2)
				end
			end)
		else
			local character = game:GetService("Players").LocalPlayer.Character
			if getgenv().BossOriginalCFrame and character then
				character:PivotTo(getgenv().BossOriginalCFrame)
				getgenv().BossOriginalCFrame = nil
			end
		end
	end,
})
RaidTab:Button({
	Title = "เช็คคูลดาวน์บอสเรด",
	Callback = function()
		local currentMin = tonumber(os.date("%M"))
		local minToNextHour = 60 - currentMin
		local msg = string.format("คูลดาวน์: %d นาที", minToNextHour)
		if WindUI and WindUI.Notify then
			WindUI:Notify({ Title = "คูลดาวน์บอสเรด", Content = msg, Duration = 5 })
		end
	end,
})
local function GetPlayerNames()
	local names = {}
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		if p ~= game:GetService("Players").LocalPlayer then
			table.insert(names, p.Name)
		end
	end
	if #names == 0 then
		table.insert(names, "ไม่มีผู้เล่นอื่น")
	end
	return names
end
getgenv().SelectedTradePlayer = ""
local TradePlayerDropdown = TradeTab:Dropdown({
	Title = "เลือกผู้เล่นที่จะแลกเปลี่ยน",
	Value = "ไม่มีผู้เล่นอื่น",
	Values = GetPlayerNames(),
	Callback = function(Value)
		getgenv().SelectedTradePlayer = Value
	end,
})
TradeTab:Button({
	Title = "รีเฟรชรายชื่อผู้เล่น",
	Callback = function()
		if TradePlayerDropdown and TradePlayerDropdown.Refresh then
			pcall(function()
				TradePlayerDropdown:Refresh(GetPlayerNames())
			end)
		end
		if WindUI and WindUI.Notify then
			WindUI:Notify({ Title = "แลกเปลี่ยน", Content = "รีเฟรชรายชื่อผู้เล่นแล้ว!", Duration = 3 })
		end
	end,
})
TradeTab:Button({
	Title = "วาร์ปไปหาผู้เล่น",
	Callback = function()
		local targetName = getgenv().SelectedTradePlayer
		if targetName and targetName ~= "" and targetName ~= "ไม่มีผู้เล่นอื่น" then
			local targetPlayer = game:GetService("Players"):FindFirstChild(targetName)
			if
				targetPlayer
				and targetPlayer.Character
				and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			then
				local localChar = game:GetService("Players").LocalPlayer.Character
				if localChar and localChar:FindFirstChild("HumanoidRootPart") then
					localChar:PivotTo(targetPlayer.Character.HumanoidRootPart.CFrame)
					if WindUI and WindUI.Notify then
						WindUI:Notify({ Title = "แลกเปลี่ยน", Content = "วาร์ปไปหา " .. targetName, Duration = 3 })
					end
				end
			else
				if WindUI and WindUI.Notify then
					WindUI:Notify({ Title = "แลกเปลี่ยน", Content = "ไม่พบผู้เล่นหรือผู้เล่นตายแล้ว!", Duration = 3 })
				end
			end
		else
			if WindUI and WindUI.Notify then
				WindUI:Notify({ Title = "แลกเปลี่ยน", Content = "กรุณาเลือกผู้เล่นให้ถูกต้องก่อน!", Duration = 3 })
			end
		end
	end,
})

local function GetInventoryCardsForTrade()
	local player = game:GetService("Players").LocalPlayer
	local inventory = {}
	local function scanFolder(folder)
		if not folder then return end
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Tool") then
				local isCard = item:GetAttribute("CardName") ~= nil
				local isPack = item:GetAttribute("TemplateName") ~= nil
				if isCard or isPack then
					local rarityAttr = item:GetAttribute("Rarity") or item:GetAttribute("CardGrade")
					if not rarityAttr and item:FindFirstChild("Rarity") and item.Rarity:IsA("StringValue") then
						rarityAttr = item.Rarity.Value
					end
					if not rarityAttr then rarityAttr = "Unknown" end

					local mutation = item:GetAttribute("Mutation") or item:GetAttribute("CardMutation") or "Normal"
					if not item:GetAttribute("Mutation") and not item:GetAttribute("CardMutation") and item:FindFirstChild("Mutation") and item.Mutation:IsA("StringValue") then
						mutation = item.Mutation.Value
					end

					local key = tostring(rarityAttr) .. " | " .. tostring(mutation)
					if not inventory[key] then inventory[key] = 0 end
					inventory[key] = inventory[key] + 1
				end
			end
		end
	end
	pcall(function()
		scanFolder(player:FindFirstChild("Backpack"))
		if player.Character then scanFolder(player.Character) end
	end)

	local list = {}
	for key, count in pairs(inventory) do
		table.insert(list, key .. " (x" .. tostring(count) .. ")")
	end
	if #list == 0 then table.insert(list, "No cards found") end
	return list
end

getgenv().SelectedTradeCards = {}
local TradeCardsDropdown = TradeTab:Dropdown({
	Title = "เลือกการ์ดที่จะแลกเปลี่ยน",
	Multi = true,
	Value = {},
	Values = GetInventoryCardsForTrade(),
	Callback = function(Value)
		getgenv().SelectedTradeCards = {}
		if type(Value) == "table" then
			for k, v in pairs(Value) do
				if type(k) == "number" then
					getgenv().SelectedTradeCards[v] = true
				else
					getgenv().SelectedTradeCards[k] = v
				end
			end
		end
	end,
})

TradeTab:Button({
	Title = "รีเฟรชการ์ดในกระเป๋า",
	Callback = function()
		if TradeCardsDropdown and TradeCardsDropdown.Refresh then
			pcall(function()
				TradeCardsDropdown:Refresh(GetInventoryCardsForTrade())
			end)
		end
		if WindUI and WindUI.Notify then
			WindUI:Notify({ Title = "แลกเปลี่ยน", Content = "รีเฟรชการ์ดในกระเป๋าแล้ว!", Duration = 3 })
		end
	end,
})
getgenv().AutoGiftCards = false
TradeTab:Toggle({
	Title = "เทรดอัตโนมัติ",
	Value = getgenv().AutoGiftCards,
	Callback = function(state)
		getgenv().AutoGiftCards = state
		if state then
			task.spawn(function()
				while getgenv().AutoGiftCards do
					local targetName = getgenv().SelectedTradePlayer
					if targetName and targetName ~= "" and targetName ~= "ไม่มีผู้เล่นอื่น" then
						local targetPlayer = game:GetService("Players"):FindFirstChild(targetName)
						if
							targetPlayer
							and targetPlayer.Character
							and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
						then
							local localPlayer = game:GetService("Players").LocalPlayer
							local localChar = localPlayer.Character
							if localChar and localChar:FindFirstChild("Humanoid") then
								local function getGiftableTool()
									local function isSelected(t)
										if not next(getgenv().SelectedTradeCards) then return true end -- if nothing selected, trade all
										local rarityAttr = t:GetAttribute("Rarity") or t:GetAttribute("CardGrade")
										if not rarityAttr and t:FindFirstChild("Rarity") and t.Rarity:IsA("StringValue") then
											rarityAttr = t.Rarity.Value
										end
										if not rarityAttr then rarityAttr = "Unknown" end

										local mutation = t:GetAttribute("Mutation") or t:GetAttribute("CardMutation") or "Normal"
										if not t:GetAttribute("Mutation") and not t:GetAttribute("CardMutation") and t:FindFirstChild("Mutation") and t.Mutation:IsA("StringValue") then
											mutation = t.Mutation.Value
										end
										local key = tostring(rarityAttr) .. " | " .. tostring(mutation)
										for selectedText, _ in pairs(getgenv().SelectedTradeCards) do
											if selectedText:find(key, 1, true) then
												return true
											end
										end
										return false
									end

									local backpack = localPlayer:FindFirstChild("Backpack")
									if backpack then
										for _, t in ipairs(backpack:GetChildren()) do
											if
												t:IsA("Tool")
												and (
													t:GetAttribute("CardName") ~= nil
													or t:GetAttribute("TemplateName") ~= nil
												)
											then
												if isSelected(t) then return t end
											end
										end
									end
									for _, t in ipairs(localChar:GetChildren()) do
										if
											t:IsA("Tool")
											and (
												t:GetAttribute("CardName") ~= nil
												or t:GetAttribute("TemplateName") ~= nil
											)
										then
											if isSelected(t) then return t end
										end
									end
									return nil
								end
								local tool = getGiftableTool()
								if tool then
									localChar.Humanoid:EquipTool(tool)
									localChar:PivotTo(targetPlayer.Character.HumanoidRootPart.CFrame)
									task.wait(0.1)
									local promptFound = false
									for _, desc in ipairs(targetPlayer.Character:GetDescendants()) do
										if
											desc:IsA("ProximityPrompt")
											and desc:GetAttribute("IsGiftPrompt") == true
										then
											if fireproximityprompt then
												fireproximityprompt(desc)
												promptFound = true
											end
										end
									end
									if promptFound then
										local waitTime = 0
										while tool.Parent == localChar and waitTime < 15 and getgenv().AutoGiftCards do
											task.wait(0.1)
											waitTime = waitTime + 0.1
										end
									else
										task.wait(0.5)
									end
								else
									task.wait(1)
								end
							else
								task.wait(1)
							end
						else
							task.wait(1)
						end
					else
						task.wait(1)
					end
				end
			end)
		end
	end,
})
local MiscTab = Window:Tab({
	Title = "เบ็ดเตล็ด",
	Icon = "solar:settings-bold",
})
local HttpService = game:GetService("HttpService")
local ConfigFolder = "Dexq_AnimeCardFarm"
if not isfolder(ConfigFolder) then
	pcall(makefolder, ConfigFolder)
end
local function GetConfigs()
	local configs = {}
	if isfolder(ConfigFolder) then
		for _, file in ipairs(listfiles(ConfigFolder)) do
			if file:sub(-5) == ".json" and not file:find("_MainConfig.json") then
				local name = file:match("([^/\\]+)%.json$")
				if name then
					table.insert(configs, name)
				end
			end
		end
	end
	return configs
end
local ConfigData = {
	Autoload = "",
}
local function SaveMainConfig()
	if writefile then
		pcall(function()
			writefile(ConfigFolder .. "/_MainConfig.json", HttpService:JSONEncode(ConfigData))
		end)
	end
end
local function LoadMainConfig()
	if isfile and isfile(ConfigFolder .. "/_MainConfig.json") then
		local s, r = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigFolder .. "/_MainConfig.json"))
		end)
		if s and type(r) == "table" then
			ConfigData = r
		end
	end
end
LoadMainConfig()
getgenv().DiscordWebhook = ""
local WebhookInput = MiscTab:Input({
	Title = "URL Discord Webhook",
	PlaceholderText = "https://discord.com/api/webhooks/...",
	Callback = function(text)
		getgenv().DiscordWebhook = text
	end,
})
MiscTab:Keybind({
	Title = "ปุ่มเปิด/ปิด UI",
	Key = "RightControl",
	Callback = function()
		pcall(function()
			local toggled = false
			if Window and type(Window.Toggle) == "function" then
				Window:Toggle()
				toggled = true
			end
			if not toggled then
				for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
					if v:IsA("ScreenGui") and v:FindFirstChild("Main") and v.Main:IsA("Frame") then
						local titleLabel = v.Main:FindFirstChild("Topbar", true)
						if titleLabel or v.Name == "WindUI" or v.Name == "DexqUI" then
							v.Enabled = not v.Enabled
						end
					end
				end
			end
		end)
	end,
})
local function SaveConfig(name)
	local data = {
		Rarities = getgenv().SelectedRarities or {},
		Mutations = getgenv().SelectedMutations or {},
		AutoSpawn = getgenv().AutoSpawnPack or false,
		AutoBuy = getgenv().AutoBuyCards or false,
		AutoCarry = getgenv().AutoCarry or false,
		AutoSellBox = getgenv().AutoSellBox or false,
		AutoCarryDelay = getgenv().AutoCarryDelay or 5,
		AntiAfk = getgenv().AntiAfkState or false,
		AutoUseLuck = getgenv().AutoUseLuck or false,
		AutoTower = getgenv().AutoTower or false,
		Webhook = getgenv().DiscordWebhook or "",
	}
	if writefile then
		pcall(function()
			writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
			WindUI:Notify({ Title = "การตั้งค่า", Content = "บันทึกแล้ว: " .. name, Duration = 3 })
		end)
	end
end
local function LoadConfig(name)
	if isfile and isfile(ConfigFolder .. "/" .. name .. ".json") then
		local s, data = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. name .. ".json"))
		end)
		if s and type(data) == "table" then
			getgenv().SelectedRarities = data.Rarities or {}
			getgenv().SelectedMutations = data.Mutations or {}
			local function safeToggleSet(toggleObj, val)
				if not toggleObj then
					return
				end
				pcall(function()
					toggleObj:SetValue(val)
				end)
				pcall(function()
					toggleObj:Set(val)
				end)
				pcall(function()
					toggleObj.Value = val
				end)
			end
			safeToggleSet(AutoSpawnToggle, data.AutoSpawn or false)
			safeToggleSet(AutoBuyToggle, data.AutoBuy or false)
			safeToggleSet(AutoCarryToggle, data.AutoCarry or false)
			safeToggleSet(AutoSellBoxToggle, data.AutoSellBox or false)
			if data.AutoCarryDelay then
				getgenv().AutoCarryDelay = data.AutoCarryDelay
				pcall(function()
					AutoCarrySlider:SetValue(data.AutoCarryDelay)
				end)
				pcall(function()
					AutoCarrySlider:Set(data.AutoCarryDelay)
				end)
			end
			safeToggleSet(AntiAfkToggle, data.AntiAfk or false)
			safeToggleSet(AutoUseLuckToggle, data.AutoUseLuck or false)
			safeToggleSet(AutoTowerToggle, data.AutoTower or false)
			getgenv().DiscordWebhook = data.Webhook or ""
			pcall(function()
				WebhookInput:SetValue(getgenv().DiscordWebhook)
			end)
			if RarityDropdown then
				local arrR = {}
				local dictR = {}
				for _, v in ipairs(RaritiesList) do
					if getgenv().SelectedRarities[string.lower(v)] then
						table.insert(arrR, v)
						dictR[v] = true
					end
				end
				pcall(function()
					RarityDropdown:SetValue(dictR)
				end)
				pcall(function()
					RarityDropdown:SetValue(arrR)
				end)
				pcall(function()
					RarityDropdown:Set(dictR)
				end)
				pcall(function()
					RarityDropdown:Set(arrR)
				end)
				pcall(function()
					RarityDropdown:Select(arrR)
				end)
				pcall(function()
					RarityDropdown:Refresh(RaritiesList, arrR)
				end)
			end
			if MutationDropdown then
				local arrM = {}
				local dictM = {}
				for _, v in ipairs(MutationsList) do
					if getgenv().SelectedMutations[string.lower(v)] then
						table.insert(arrM, v)
						dictM[v] = true
					end
				end
				pcall(function()
					MutationDropdown:SetValue(dictM)
				end)
				pcall(function()
					MutationDropdown:SetValue(arrM)
				end)
				pcall(function()
					MutationDropdown:Set(dictM)
				end)
				pcall(function()
					MutationDropdown:Set(arrM)
				end)
				pcall(function()
					MutationDropdown:Select(arrM)
				end)
				pcall(function()
					MutationDropdown:Refresh(MutationsList, arrM)
				end)
			end
			WindUI:Notify({ Title = "การตั้งค่า", Content = "โหลดแล้ว: " .. name, Duration = 3 })
		else
			WindUI:Notify({ Title = "การตั้งค่า", Content = "โหลดไม่สำเร็จ: " .. name, Duration = 3 })
		end
	end
end
local ConfigNameInput = ""
MiscTab:Input({
	Title = "ชื่อการตั้งค่า",
	PlaceholderText = "ชื่อการตั้งค่า...",
	Callback = function(text)
		ConfigNameInput = text
	end,
})
local ConfigDropdown
MiscTab:Button({
	Title = "บันทึกการตั้งค่า",
	Callback = function()
		if ConfigNameInput ~= "" then
			SaveConfig(ConfigNameInput)
			if ConfigDropdown and ConfigDropdown.Refresh then
				pcall(function()
					ConfigDropdown:Refresh(GetConfigs())
				end)
			end
		else
			WindUI:Notify({ Title = "การตั้งค่า", Content = "กรุณาใส่ชื่อการตั้งค่า", Duration = 3 })
		end
	end,
})
local ConfigList = GetConfigs()
local SelectedConfig = ConfigData.Autoload
ConfigDropdown = MiscTab:Dropdown({
	Title = "การตั้งค่าที่บันทึก",
	Values = ConfigList,
	Value = ConfigData.Autoload,
	Callback = function(value)
		if type(value) == "table" then
			for k, v in pairs(value) do
				if type(k) == "number" then
					SelectedConfig = v
				else
					SelectedConfig = k
				end
			end
		else
			SelectedConfig = value
		end
	end,
})
MiscTab:Button({
	Title = "รีเฟรชรายการตั้งค่า",
	Callback = function()
		if ConfigDropdown and ConfigDropdown.Refresh then
			pcall(function()
				ConfigDropdown:Refresh(GetConfigs())
			end)
		end
		WindUI:Notify({ Title = "การตั้งค่า", Content = "รีเฟรชรายการตั้งค่าแล้ว", Duration = 3 })
	end,
})
MiscTab:Button({
	Title = "โหลดตั้งค่าที่เลือก",
	Callback = function()
		if SelectedConfig and SelectedConfig ~= "" then
			LoadConfig(SelectedConfig)
		end
	end,
})
MiscTab:Button({
	Title = "ลบตั้งค่าที่เลือก",
	Callback = function()
		if SelectedConfig and SelectedConfig ~= "" then
			if isfile and isfile(ConfigFolder .. "/" .. SelectedConfig .. ".json") then
				pcall(delfile, ConfigFolder .. "/" .. SelectedConfig .. ".json")
				if ConfigData.Autoload == SelectedConfig then
					ConfigData.Autoload = ""
					SaveMainConfig()
				end
				if ConfigDropdown and ConfigDropdown.Refresh then
					pcall(function()
						ConfigDropdown:Refresh(GetConfigs())
					end)
				end
				WindUI:Notify({ Title = "การตั้งค่า", Content = "ลบแล้ว: " .. SelectedConfig, Duration = 3 })
				SelectedConfig = ""
			else
				WindUI:Notify({ Title = "การตั้งค่า", Content = "ไม่พบการตั้งค่า!", Duration = 3 })
			end
		end
	end,
})
MiscTab:Toggle({
	Title = "โหลดการตั้งค่าอัตโนมัติ",
	Value = (ConfigData.Autoload ~= ""),
	Callback = function(state)
		if state then
			ConfigData.Autoload = SelectedConfig
		else
			ConfigData.Autoload = ""
		end
		SaveMainConfig()
	end,
})
if ConfigData.Autoload ~= "" then
	task.spawn(function()
		task.wait(1)
		LoadConfig(ConfigData.Autoload)
	end)
end
WindUI:Notify({
	Title = "พยาธิบอย กำลังโหลด",
	Content = "เรียกใช้งานสำเร็จ",
	Duration = 5,
})
