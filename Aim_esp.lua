-- Улучшенный скрипт (ESP, Aimbot, Управление, Темы меню)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Пытаемся поместить GUI в CoreGui (защита от обнаружения), если нет прав — в PlayerGui
local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or localPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- НАСТРОЙКИ
-- ==========================================
local Settings = {
	Aim = {
		Active = false,
		Speed = 15,
		FOV = 150, -- Радиус захвата на экране
		WallCheck = true
	},
	ESP = {
		Box = false,
		Lines = false,
		Name = false,
		HP = false,
		Distance = false
	},
	Player = {
		Speed = 16,
		Jump = 50
	},
	UI = {
		ThemeIndex = 1,
		Themes = {
			{Name = "Black", Bg = Color3.fromRGB(20, 20, 20), Accent = Color3.fromRGB(255, 255, 255)},
			{Name = "Green", Bg = Color3.fromRGB(15, 35, 15), Accent = Color3.fromRGB(50, 255, 50)},
			{Name = "Blue",  Bg = Color3.fromRGB(15, 25, 45), Accent = Color3.fromRGB(50, 150, 255)}
		}
	}
}

-- ==========================================
-- ФУНКЦИИ ESP И АИМА
-- ==========================================
local function safeDestroy(instance)
	if instance and instance.Parent then pcall(function() instance:Destroy() end) end
end

local function isVisible(targetPart)
	local myChar = localPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return false end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {myChar, targetPart.Parent}
	
	local rayResult = Workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, rayParams)
	return rayResult == nil
end

local function getClosestPlayerToCenter()
	local closestPlayer = nil
	local shortestDistance = Settings.Aim.FOV
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPart = player.Character.HumanoidRootPart
				local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				
				if onScreen then
					local distToCenter = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
					if distToCenter < shortestDistance then
						if not Settings.Aim.WallCheck or isVisible(targetPart) then
							shortestDistance = distToCenter
							closestPlayer = targetPart
						end
					end
				end
			end
		end
	end
	return closestPlayer
end

-- ==========================================
-- СОЗДАНИЕ ИНТЕРФЕЙСА
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 480)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -240)
MainFrame.BackgroundColor3 = Settings.UI.Themes[1].Bg
MainFrame.Active = true
MainFrame.Draggable = true -- Делает меню плавающим
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Mod Menu | Theme: " .. Settings.UI.Themes[1].Name
Title.TextColor3 = Settings.UI.Themes[1].Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, 0, 1, -40)
Container.Position = UDim2.new(0, 0, 0, 40)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 0, 600)
Container.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ToggleMenuBtn = Instance.new("TextButton", ScreenGui)
ToggleMenuBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleMenuBtn.Position = UDim2.new(0, 20, 0, 20)
ToggleMenuBtn.BackgroundColor3 = Settings.UI.Themes[1].Bg
ToggleMenuBtn.TextColor3 = Settings.UI.Themes[1].Accent
ToggleMenuBtn.Text = "OPEN MENU"
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 14
ToggleMenuBtn.Active = true
ToggleMenuBtn.Draggable = true -- Кнопку тоже можно таскать
Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 8)

ToggleMenuBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)

-- Динамические элементы UI
local allUIElements = {MainFrame, ToggleMenuBtn, Title}

local function applyTheme()
	local theme = Settings.UI.Themes[Settings.UI.ThemeIndex]
	MainFrame.BackgroundColor3 = theme.Bg
	ToggleMenuBtn.BackgroundColor3 = theme.Bg
	ToggleMenuBtn.TextColor3 = theme.Accent
	Title.TextColor3 = theme.Accent
	Title.Text = "Mod Menu | Theme: " .. theme.Name
	
	for _, elem in ipairs(allUIElements) do
		if elem:IsA("TextButton") or elem:IsA("TextBox") then
			if elem.Name ~= "ToggleMenuBtn" then
				elem.TextColor3 = theme.Accent
			end
		end
	end
end

local function createToggle(text, configCategory, configKey)
	local btn = Instance.new("TextButton", Container)
	btn.Size = UDim2.new(0.9, 0, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent
	btn.Text = text .. ": OFF"
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 14
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	table.insert(allUIElements, btn)
	
	btn.MouseButton1Click:Connect(function()
		Settings[configCategory][configKey] = not Settings[configCategory][configKey]
		local state = Settings[configCategory][configKey]
		btn.Text = text .. (state and ": ON" or ": OFF")
		btn.BackgroundColor3 = state and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(40, 40, 40)
	end)
end

local function createInput(text, default, configCategory, configKey)
	local frame = Instance.new("Frame", Container)
	frame.Size = UDim2.new(0.9, 0, 0, 35)
	frame.BackgroundTransparency = 1
	
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextSize = 14
	
	local box = Instance.new("TextBox", frame)
	box.Size = UDim2.new(0.35, 0, 1, 0)
	box.Position = UDim2.new(0.65, 0, 0, 0)
	box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	box.TextColor3 = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent
	box.Text = tostring(default)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	table.insert(allUIElements, box)
	
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then Settings[configCategory][configKey] = val else box.Text = tostring(Settings[configCategory][configKey]) end
	end)
end

local ThemeBtn = Instance.new("TextButton", Container)
ThemeBtn.Size = UDim2.new(0.9, 0, 0, 35)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeBtn.Text = "Change Theme"
ThemeBtn.Font = Enum.Font.GothamBold
ThemeBtn.TextSize = 14
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 6)
ThemeBtn.MouseButton1Click:Connect(function()
	Settings.UI.ThemeIndex = (Settings.UI.ThemeIndex % #Settings.UI.Themes) + 1
	applyTheme()
end)

createToggle("Aimbot", "Aim", "Active")
createInput("Aimbot FOV", Settings.Aim.FOV, "Aim", "FOV")
createInput("Aimbot Smoothness", Settings.Aim.Speed, "Aim", "Speed")

createToggle("ESP Boxes", "ESP", "Box")
createToggle("ESP Lines", "ESP", "Lines")
createToggle("ESP Nicknames", "ESP", "Name")
createToggle("ESP HP", "ESP", "HP")
createToggle("ESP Distance", "ESP", "Distance")

createInput("WalkSpeed", Settings.Player.Speed, "Player", "Speed")
createInput("JumpPower", Settings.Player.Jump, "Player", "Jump")

-- ==========================================
-- ОСНОВНОЙ ИГРОВОЙ ЦИКЛ (КАЖДЫЙ КАДР)
-- ==========================================
RunService.RenderStepped:Connect(function()
	-- 1. Управление скоростью и прыжком
	local myChar = localPlayer.Character
	if myChar then
		local hum = myChar:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Settings.Player.Speed
			hum.UseJumpPower = true
			hum.JumpPower = Settings.Player.Jump
		end
	end

	-- 2. Аимбот (с поддержкой FOV и проверки стен)
	if Settings.Aim.Active then
		local target = getClosestPlayerToCenter()
		if target then
			local targetCFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
			local alpha = math.clamp(Settings.Aim.Speed / 100, 0.01, 1)
			camera.CFrame = camera.CFrame:Lerp(targetCFrame, alpha)
		end
	end

	-- 3. ESP (Обновление каждый кадр)
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer then
			local char = otherPlayer.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
				local root = char.HumanoidRootPart
				local hum = char:FindFirstChildOfClass("Humanoid")
				
				-- ESP BOX (Боксы)
				local box = char:FindFirstChild("ModESP_Box")
				if Settings.ESP.Box and hum.Health > 0 then
					if not box then
						box = Instance.new("SelectionBox")
						box.Name = "ModESP_Box"
						box.LineThickness = 0.05
						box.Color3 = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent
						box.AlwaysOnTop = true
						box.Adornee = char
						box.Parent = char
					else
						box.Color3 = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent
					end
				else safeDestroy(box) end

				-- ESP LINES (Линии)
				local beam = char:FindFirstChild("ModESP_Beam")
				local targetAtt = root:FindFirstChild("ModESP_Att")
				if Settings.ESP.Lines and hum.Health > 0 and myChar and myChar:FindFirstChild("HumanoidRootPart") then
					if not targetAtt then
						targetAtt = Instance.new("Attachment", root)
						targetAtt.Name = "ModESP_Att"
					end
					
					local myRoot = myChar.HumanoidRootPart
					local myAtt = myRoot:FindFirstChild("ModESP_MyAtt") or Instance.new("Attachment", myRoot)
					myAtt.Name = "ModESP_MyAtt"
					
					if not beam then
						beam = Instance.new("Beam")
						beam.Name = "ModESP_Beam"
						beam.Width0 = 0.05
						beam.Width1 = 0.05
						beam.FaceCamera = true
						beam.Attachment0 = myAtt
						beam.Attachment1 = targetAtt
						beam.Parent = char
					end
					beam.Color = ColorSequence.new(Settings.UI.Themes[Settings.UI.ThemeIndex].Accent)
					beam.Attachment0 = myAtt
				else
					safeDestroy(beam)
					safeDestroy(targetAtt)
				end

				-- ESP TEXT (Ник, ХП, Дистанция)
				local bGui = char:FindFirstChild("ModESP_Text")
				local needsText = (Settings.ESP.Name or Settings.ESP.HP or Settings.ESP.Distance) and hum.Health > 0
				
				if needsText then
					if not bGui then
						bGui = Instance.new("BillboardGui", char)
						bGui.Name = "ModESP_Text"
						bGui.Size = UDim2.new(0, 200, 0, 50)
						bGui.StudsOffset = Vector3.new(0, 3, 0)
						bGui.AlwaysOnTop = true
						bGui.Adornee = char:FindFirstChild("Head") or root
						
						local lbl = Instance.new("TextLabel", bGui)
						lbl.Name = "Text"
						lbl.Size = UDim2.new(1, 0, 1, 0)
						lbl.BackgroundTransparency = 1
						lbl.Font = Enum.Font.GothamBold
						lbl.TextSize = 12
						lbl.TextStrokeTransparency = 0
					end
					
					local lbl = bGui:FindFirstChild("Text")
					if lbl then
						lbl.TextColor3 = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent
						local txt = ""
						if Settings.ESP.Name then txt = txt .. otherPlayer.Name .. "\n" end
						if Settings.ESP.Distance and myChar and myChar:FindFirstChild("HumanoidRootPart") then
							local dist = math.floor((root.Position - myChar.HumanoidRootPart.Position).Magnitude)
							txt = txt .. "[" .. dist .. "m] "
						end
						if Settings.ESP.HP then
							txt = txt .. "HP: " .. math.floor(hum.Health)
						end
						lbl.Text = txt
					end
				else safeDestroy(bGui) end
			else
				-- Очистка если игрок мертв или не прогружен
				safeDestroy(char and char:FindFirstChild("ModESP_Box"))
				safeDestroy(char and char:FindFirstChild("ModESP_Beam"))
				safeDestroy(char and char:FindFirstChild("ModESP_Text"))
			end
		end
	end
end)
