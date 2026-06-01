-- ==========================================
-- УЛУЧШЕННЫЙ СКРИПТ: 2D ESP (Стиль как в читах) + Aimbot + Menu
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Поиск безопасного места для интерфейса
local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or localPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- НАСТРОЙКИ
-- ==========================================
local Settings = {
	Aim = {
		Active = false,
		Speed = 15,
		FOV = 150,
		WallCheck = true
	},
	ESP = {
		Box = false,
		HealthBar = false,
		Name = false,
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
-- ФУНКЦИИ АИМА И ПРОВЕРОК
-- ==========================================
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
	local shortestDist = Settings.Aim.FOV
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local targetPart = player.Character.HumanoidRootPart
				local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				
				if onScreen then
					local distToCenter = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
					if distToCenter < shortestDist then
						if not Settings.Aim.WallCheck or isVisible(targetPart) then
							shortestDist = distToCenter
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
-- СОЗДАНИЕ ИНТЕРФЕЙСА (MENU + ESP CONTAINER)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenu_2DESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

-- Контейнер для всех 2D ESP элементов (чтобы не засорять меню)
local ESPContainer = Instance.new("Folder", ScreenGui)

-- Главное меню
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
MainFrame.BackgroundColor3 = Settings.UI.Themes[1].Bg
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Menu | Theme: " .. Settings.UI.Themes[1].Name
Title.TextColor3 = Settings.UI.Themes[1].Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, 0, 1, -40)
Container.Position = UDim2.new(0, 0, 0, 40)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 0, 500)
Container.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ToggleMenuBtn = Instance.new("TextButton", ScreenGui)
ToggleMenuBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleMenuBtn.Position = UDim2.new(0, 20, 0, 20)
ToggleMenuBtn.BackgroundColor3 = Settings.UI.Themes[1].Bg
ToggleMenuBtn.TextColor3 = Settings.UI.Themes[1].Accent
ToggleMenuBtn.Text = "MENU"
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 14
ToggleMenuBtn.Active = true
ToggleMenuBtn.Draggable = true
Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 8)

ToggleMenuBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local allUIElements = {MainFrame, ToggleMenuBtn, Title}

local function applyTheme()
	local theme = Settings.UI.Themes[Settings.UI.ThemeIndex]
	MainFrame.BackgroundColor3 = theme.Bg
	ToggleMenuBtn.BackgroundColor3 = theme.Bg
	ToggleMenuBtn.TextColor3 = theme.Accent
	Title.TextColor3 = theme.Accent
	Title.Text = "Menu | Theme: " .. theme.Name
	for _, elem in ipairs(allUIElements) do
		if elem:IsA("TextButton") or elem:IsA("TextBox") then
			if elem.Name ~= "ToggleMenuBtn" then elem.TextColor3 = theme.Accent end
		end
	end
end

local function createToggle(text, category, key)
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
		Settings[category][key] = not Settings[category][key]
		local state = Settings[category][key]
		btn.Text = text .. (state and ": ON" or ": OFF")
		btn.BackgroundColor3 = state and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(40, 40, 40)
	end)
end

local function createInput(text, default, category, key)
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
		if val then Settings[category][key] = val else box.Text = tostring(Settings[category][key]) end
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
createInput("Aim Speed", Settings.Aim.Speed, "Aim", "Speed")

createToggle("2D Box ESP", "ESP", "Box")
createToggle("Health Bar", "ESP", "HealthBar")
createToggle("Nicknames", "ESP", "Name")
createToggle("Distance", "ESP", "Distance")

createInput("Speed", Settings.Player.Speed, "Player", "Speed")
createInput("Jump", Settings.Player.Jump, "Player", "Jump")


-- ==========================================
-- СИСТЕМА СОЗДАНИЯ UI ДЛЯ ИГРОКОВ (Отрисовка)
-- ==========================================
local playerDrawings = {}

local function createPlayerESP(player)
	local drawings = {}
	
	-- Сам бокс
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.Visible = false
	box.Parent = ESPContainer
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(255, 25, 25)
	boxStroke.Thickness = 1.5
	drawings.Box = box
	drawings.BoxStroke = boxStroke

	-- Задний фон полоски ХП (черный)
	local hpBg = Instance.new("Frame")
	hpBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hpBg.BorderSizePixel = 0
	hpBg.Visible = false
	hpBg.Parent = ESPContainer
	drawings.HpBg = hpBg

	-- Сама полоска ХП (зеленая/красная)
	local hpFill = Instance.new("Frame")
	hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	drawings.HpFill = hpFill

	-- Текст (Никнейм и инфа)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0 -- Черная обводка текста
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.Visible = false
	nameLabel.Parent = ESPContainer
	drawings.Name = nameLabel

	playerDrawings[player] = drawings
end

local function removePlayerESP(player)
	if playerDrawings[player] then
		for _, drawing in pairs(playerDrawings[player]) do
			if typeof(drawing) == "Instance" then drawing:Destroy() end
		end
		playerDrawings[player] = nil
	end
end

for _, p in pairs(Players:GetPlayers()) do
	if p ~= localPlayer then createPlayerESP(p) end
end
Players.PlayerAdded:Connect(function(p) createPlayerESP(p) end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)


-- ==========================================
-- ОСНОВНОЙ ИГРОВОЙ ЦИКЛ (КАЖДЫЙ КАДР)
-- ==========================================
RunService.RenderStepped:Connect(function()
	-- 1. Настройки игрока
	local myChar = localPlayer.Character
	if myChar then
		local hum = myChar:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Settings.Player.Speed
			hum.UseJumpPower = true
			hum.JumpPower = Settings.Player.Jump
		end
	end

	-- 2. Аимбот
	if Settings.Aim.Active then
		local target = getClosestPlayerToCenter()
		if target then
			local targetCFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
			local alpha = math.clamp(Settings.Aim.Speed / 100, 0.01, 1)
			camera.CFrame = camera.CFrame:Lerp(targetCFrame, alpha)
		end
	end

	-- 3. 2D ESP (С математикой как в экзекуторах)
	local themeColor = Settings.UI.Themes[Settings.UI.ThemeIndex].Accent

	for player, drawings in pairs(playerDrawings) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		
		-- Проверка: жив ли игрок и существует ли он
		if char and hum and root and hum.Health > 0 then
			-- Расчет 2D координат из 3D мира
			local size = char:GetExtentsSize()
			local cf = root.CFrame
			
			local top, topOnScreen = camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y/2, 0)).Position)
			local bottom, bottomOnScreen = camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)
			
			-- Если игрок в поле зрения экрана
			if topOnScreen or bottomOnScreen then
				local dist = (root.Position - camera.CFrame.Position).Magnitude
				
				-- Вычисляем размеры бокса на экране
				local height = bottom.Y - top.Y
				local width = height * 0.65 -- Пропорция ширины
				local boxPos = Vector2.new(top.X - width/2, top.Y)
				
				-- 1. Рисуем 2D Бокс
				if Settings.ESP.Box then
					drawings.Box.Size = UDim2.new(0, width, 0, height)
					drawings.Box.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
					drawings.BoxStroke.Color = themeColor
					drawings.Box.Visible = true
				else
					drawings.Box.Visible = false
				end
				
				-- 2. Рисуем полоску здоровья (слева от бокса)
				if Settings.ESP.HealthBar then
					local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
					local barWidth = 3
					local barSpacing = 4 -- отступ от бокса
					
					drawings.HpBg.Size = UDim2.new(0, barWidth, 0, height)
					drawings.HpBg.Position = UDim2.new(0, boxPos.X - barWidth - barSpacing, 0, boxPos.Y)
					
					drawings.HpFill.Size = UDim2.new(1, 0, hpPercent, 0)
					drawings.HpFill.Position = UDim2.new(0, 0, 1 - hpPercent, 0)
					drawings.HpFill.BackgroundColor3 = Color3.fromRGB(255 - (255 * hpPercent), 255 * hpPercent, 0)
					
					drawings.HpBg.Visible = true
				else
					drawings.HpBg.Visible = false
				end
				
				-- 3. Рисуем текст (Ник, ХП, Дистанция сверху)
				if Settings.ESP.Name or Settings.ESP.Distance then
					local txt = ""
					if Settings.ESP.Name then txt = txt .. player.Name end
					if Settings.ESP.Distance then txt = txt .. " [" .. math.floor(dist) .. "m]" end
					if Settings.ESP.HealthBar then txt = txt .. "\n" .. math.floor(hum.Health) .. " HP" end
					
					drawings.Name.Text = txt
					drawings.Name.TextColor3 = themeColor
					-- Позиционируем прямо над боксом, по центру
					drawings.Name.Size = UDim2.new(0, width, 0, 20)
					drawings.Name.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y - (Settings.ESP.HealthBar and 30 or 15))
					drawings.Name.Visible = true
				else
					drawings.Name.Visible = false
				end
				
			else
				-- Скрываем если игрок за спиной камеры
				drawings.Box.Visible = false
				drawings.HpBg.Visible = false
				drawings.Name.Visible = false
			end
		else
			-- Скрываем если игрок мертв/не прогрузился
			drawings.Box.Visible = false
			drawings.HpBg.Visible = false
			drawings.Name.Visible = false
		end
	end
end)
