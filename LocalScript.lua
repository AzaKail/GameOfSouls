-- LocalScript inside StarterGui > LobbyGui
-- ========================================
-- МЕНЮ ВЫБОРА РОЛЕЙ (души/киллер) с левой карточкой и правым списками. "Надо доделать дизайн"
-- ========================================

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

--// Remotes
local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local SetChoice        = Remotes:WaitForChild("SetChoice")
local RequestProfile   = Remotes:WaitForChild("RequestProfile")
local LobbyStatus      = Remotes:FindFirstChild("LobbyStatus")

--// GUI roots
local gui         = script.Parent
local OpenMenu    = gui:WaitForChild("OpenMenu")
local SelectMenu  = gui:WaitForChild("SelectMenu")
local Tabs        = SelectMenu:WaitForChild("Tabs")
local KillersTab  = Tabs:WaitForChild("KillersTab")
local SurvivorsTab= Tabs:WaitForChild("SurvivorsTab")
local Pages       = SelectMenu:WaitForChild("Pages")
local KillerPage  = Pages:WaitForChild("KillerPage")
local SurvivorPage= Pages:WaitForChild("SurvivorPage")
local StatusLabel = gui:FindFirstChild("Status")

--// Left info panel (общая панелька дл душ и киллеров)
local InfoPanel        = SelectMenu:WaitForChild("InfoPanel")
local Scroll           = InfoPanel:WaitForChild("Scroll")
local Icon             = Scroll:WaitForChild("Icon")
local TitleLabel       = Scroll:WaitForChild("Title")
local DeskLabel        = Scroll:WaitForChild("Desk")
local StatsLabel       = Scroll:WaitForChild("Stats")
local ConfirmButton    = InfoPanel:WaitForChild("SelectSoul") -- одна кнопка на всё (Чатжпт)

--// Right lists (скролл-карточки)
-- ссылки на скроллы
local SoulList  = SurvivorPage:FindFirstChild("SoulList")
local KillerList = KillerPage:FindFirstChild("KillerList")


-- =====================================
-- БАЗОВОЕ ПОВЕДЕНИЕ МЕНЮ
-- ========================================

-- стартовые состояния
SelectMenu.Visible  = false
KillerPage.Visible  = true
SurvivorPage.Visible= false
InfoPanel.Visible   = false

-- прокрутка левой карточки
Scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
Scroll.ScrollingDirection      = Enum.ScrollingDirection.Y
Scroll.ScrollBarThickness      = 10
Scroll.VerticalScrollBarInset  = Enum.ScrollBarInset.ScrollBar

-- открыть-закрыть меню
local function setMenuActive(active)
	SelectMenu.Visible = active
	SelectMenu.Active  = active
end
OpenMenu.MouseButton1Click:Connect(function()
	setMenuActive(not SelectMenu.Visible)
end)

-- переключение вкладок
local function showKillers()
	KillerPage.Visible   = true
	SurvivorPage.Visible = false
	InfoPanel.Visible    = false
end
local function showSurvivors()
	KillerPage.Visible   = false
	SurvivorPage.Visible = true
	-- InfoPanel появится по клику на карточку
end
KillersTab.MouseButton1Click:Connect(showKillers)
SurvivorsTab.MouseButton1Click:Connect(showSurvivors)

-- статус из сервера (а надо ли)
if LobbyStatus and StatusLabel then
	LobbyStatus.OnClientEvent:Connect(function(text) StatusLabel.Text = text end)
end

-- =====================================
-- ДАННЫЕ (описания/иконки/цвета)
-- ========================================

local function ru(name)
	return (name == "Kindness" and "Доброта")
		or (name == "Patience" and "Терпение")
		or (name == "Justice" and "Справедливость")
		or (name == "Bravery" and "Храбрость")
		or (name == "Honesty" and "Честность")
		or (name == "Perseverance" and "Настойчивость")
		or (name == "Determination" and "Решительность")
		or name
end

local soulData = {
	Kindness      = { role="Саппорт",           desc="Прикрывает союзника (-урон), лечит (большой КД).",                          hp=80, atk=6,  def=12, stam=90 },
	Patience      = { role="Выживание",         desc="Защитная поза (нет урона), полупрозрачность (инвиз).",                      hp=40, atk=12, def=15, stam=110 },
	Justice       = { role="Контроль",          desc="Рывок: отталкивание/замедление/стан, усиливается при меньшем числе душ.",  hp=70, atk=16, def=10, stam=100 },
	Bravery       = { role="Атака",             desc="Стан убийцы (дл. КД). «Тонущий удар» ломает снаряды.",                      hp=40, atk=15, def=15, stam=100 },
	Honesty       = { role="Саппорт/контроль",  desc="Зона правды: жжёт стамину убийцы; трекинг следов 10с.",                      hp=50, atk=10, def=10, stam=120 },
	Perseverance  = { role="Выживание",         desc="DEF/STAM растут при низком HP; спринт.",                                   hp=60, atk=12, def=10, stam=100, extra="до 20 DEF / 120 STAM" },
	Determination = { role="Атака",             desc="Напор (стаки замедления), 1 раз возрождение.",                              hp=60, atk=12, def=10, stam=100 },
}
local soulOrder = {"Kindness","Patience","Justice","Bravery","Honesty","Perseverance","Determination"}
local soulColors = {
	Kindness=Color3.fromRGB( 90,200, 90), Patience=Color3.fromRGB(120,180,255),
	Justice=Color3.fromRGB(255,200, 60), Bravery =Color3.fromRGB(255, 90, 90),
	Honesty=Color3.fromRGB(200,200,200), Perseverance=Color3.fromRGB(160,120,255),
	Determination=Color3.fromRGB(255, 80, 80),
}
local soulIcons = { -- TODO: НЕ ЗАБУДЬ! позже подставить реальные assetId
	Kindness="rbxassetid://0", Patience="rbxassetid://0", Justice="rbxassetid://0",
	Bravery="rbxassetid://0",  Honesty="rbxassetid://0",  Perseverance="rbxassetid://0",
	Determination="rbxassetid://0",
}

local killerData = {
	Asgore = { title="Азгор  |  Убийца — давящий",
		desc="Королевский удар (ближний, высокий урон). Огненные шары (серии). Огненная земля (зона урона и замедления).",
		hp=3500, stam=100, extra="Бег тратит ~8/сек" }
}
local killerIcons = { Asgore = "rbxassetid://0" }
local killerColor = Color3.fromRGB(255,120,60)

-- =====================================
-- УТИЛИТЫ ДЛЯ UI
-- ========================================

-- мягкие рамки «выбрано»
local function ensureChosenStroke(frame: Instance)
	if not frame:FindFirstChild("ChosenStroke") then
		local s = Instance.new("UIStroke")
		s.Name = "ChosenStroke"
		s.Thickness = 3
		s.Transparency = 0.1
		s.Color = Color3.fromRGB(255,255,255)
		s.Enabled = false
		s.Parent = frame
	end
end
local function setChosenIn(container: Instance, selectedFrame: Instance)
	for _,ch in ipairs(container:GetChildren()) do
		local s = ch:FindFirstChild("ChosenStroke")
		if s then s.Enabled = false end
	end
	if selectedFrame then
		ensureChosenStroke(selectedFrame)
		selectedFrame.ChosenStroke.Enabled = true
	end
end

-- создаёт карточку 120x120 (иконка + подпись) и возвращает саму карточку
-- создаёт карточку 120x120 (иконка + подпись) и возвращает саму карточку
local function createCard(parent: Instance, id: string, display: string, imageId: string, tint: Color3)
	local card = Instance.new("Frame")
	card.Name = id
	card.Size = UDim2.new(0,120,0,120)
	card.BackgroundColor3 = Color3.fromRGB(245,245,245)
	card.BackgroundTransparency = 0.08
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke")
	stroke.Transparency = 0.7
	stroke.Parent = card

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(1, -12, 0, 82)
	icon.Position = UDim2.new(0, 6, 0, 6)
	icon.Image = imageId or "rbxassetid://0"
	icon.ImageColor3 = tint or Color3.new(1,1,1)
	icon.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Position = UDim2.new(0, 6, 1, -28)
	nameLbl.Size = UDim2.new(1, -12, 0, 22)
	nameLbl.Font = Enum.Font.GothamMedium
	nameLbl.TextScaled = true
	nameLbl.TextColor3 = Color3.fromRGB(20,20,20)
	nameLbl.Text = display
	nameLbl.Parent = card

	-- прозрачная кнопка по всей карточке
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1,0,1,0)
	hit.Text = ""
	hit.Parent = card

	-- рамка "выбрано"
	ensureChosenStroke(card)

	-- ХОВЕР/КЛИК анимаци
	local function hover(on)
		local ti = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(stroke, ti, {Transparency = on and 0.25 or 0.7}):Play()
		TweenService:Create(card,   ti, {BackgroundTransparency = on and 0 or 0.08}):Play()
	end
	hit.MouseEnter:Connect(function() hover(true) end)
	hit.MouseLeave:Connect(function() hover(false) end)
	hit.MouseButton1Down:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.06), {Size = UDim2.new(0,116,0,116)}):Play()
	end)
	hit.MouseButton1Up:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.08), {Size = UDim2.new(0,120,0,120)}):Play()
	end)

	card.Parent = parent
	return card
end


-- гарантируем наличие сетки у списка
local function ensureGrid(container: ScrollingFrame)
	local grid = container:FindFirstChildOfClass("UIGridLayout")
	if not grid then
		grid = Instance.new("UIGridLayout")
		grid.Parent = container
	end
	grid.CellSize = UDim2.new(0, 120, 0, 120)
	grid.CellPadding = UDim2.new(0, 12, 0, 18)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder

	container.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	container.ScrollingDirection     = Enum.ScrollingDirection.Y
	container.ScrollBarThickness     = 10
	container.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
end
ensureGrid(SoulList)
ensureGrid(KillerList)

-- =====================================
-- СОСТОЯНИЕ ВЫБОРА
-- ========================================

local currentMode      = "soul"  -- "soul" или "killer" — от этого зависит поведение ConfirmButton
local chosenSoul       = nil
local chosenKiller     = nil
local previewSoul,  previewSoulCard   = nil, nil
local previewKiller,previewKillerCard = nil, nil


-- включение/выключение кнопки подтверждения (кратко защита)
local function setConfirmEnabled(on)
	ConfirmButton.Active = on
	ConfirmButton.AutoButtonColor = on
	ConfirmButton.TextTransparency = on and 0 or 0.4
end
setConfirmEnabled(false)  -- по умолчанию нельзя нажать

-- включаем при показе карточек
-- setConfirmEnabled(true)



-- =====================================
-- ОТОБРАЖЕНИЕ КАРТОЧКИ СЛЕВА
-- ========================================

local function showPanel()
	if InfoPanel.Visible then return end
	InfoPanel.Visible = true
	InfoPanel.BackgroundTransparency = 1
	TweenService:Create(InfoPanel, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end

local function fillSoulCard(name)
	local d = soulData[name]; if not d then return end
	Icon.Image             = soulIcons[name] or "rbxassetid://0"
	Icon.BackgroundColor3  = soulColors[name] or Color3.fromRGB(180,180,180)
	TitleLabel.Text        = string.format("%s | %s", ru(name), d.role or "")
	DeskLabel.Text         = d.desc or ""
	local extra            = d.extra and ("  ["..d.extra.."]") or ""
	StatsLabel.Text        = string.format("HP %d   ATK %d   DEF %d   STAM %d%s", d.hp, d.atk, d.def, d.stam, extra)
end

local function fillKillerCard(name)
	local d = killerData[name]; if not d then return end
	Icon.Image             = killerIcons[name] or "rbxassetid://0"
	Icon.BackgroundColor3  = killerColor
	TitleLabel.Text        = d.title
	DeskLabel.Text         = d.desc
	StatsLabel.Text        = string.format("HP %d   STAM %d   %s", d.hp, d.stam, d.extra or "")
end

local function showSoulCard(name, card)
	currentMode         = "soul"
	previewSoul         = name
	previewSoulCard     = card
	fillSoulCard(name)
	ConfirmButton.Text  = (chosenSoul == name) and "Выбрано" or "Выбрать"
	showPanel()
end

local function showKillerCard(name, card)
	currentMode         = "killer"
	previewKiller       = name
	previewKillerCard   = card
	fillKillerCard(name)
	ConfirmButton.Text  = (chosenKiller == name) and "Выбрано" or "Выбрать"
	showPanel()
end

-- =====================================
-- ПОДТВЕРЖДЕНИЕ ВЫБОРА (одна кнопка на всё)
-- ========================================

ConfirmButton.MouseButton1Click:Connect(function()
	if currentMode == "soul" then
		if not previewSoul then return end
		chosenSoul = previewSoul
		SetChoice:FireServer("soul", chosenSoul)
		ConfirmButton.Text = "Выбрано"
		if previewSoulCard then setChosenIn(SoulList, previewSoulCard) end
	else -- killer
		if not previewKiller then return end
		chosenKiller = previewKiller
		SetChoice:FireServer("killer", chosenKiller)
		ConfirmButton.Text = "Выбрано"
		if previewKillerCard then setChosenIn(KillerList, previewKillerCard) end
	end
	-- лёгкий фидбек
	local t = TweenService:Create(ConfirmButton, TweenInfo.new(0.1), {TextTransparency = 0.3})
	t:Play(); t.Completed:Connect(function()
		TweenService:Create(ConfirmButton, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	end)
end)

-- ====================================
-- СБОРКА СПИСКОВ-КАРТОЧЕК
-- ========================================

-- Души
local soulCards = {}
for _,name in ipairs(soulOrder) do
	local card = createCard(SoulList, "S_"..name, ru(name), soulIcons[name], soulColors[name])
	card.Hit.MouseButton1Click:Connect(function() showSoulCard(name, card) end)
	soulCards[name] = card
end

-- Киллеры (пока один)
local killerCards = {}
do
	local name = "Asgore"
	local card = createCard(KillerList, "K_"..name, "Asgore", killerIcons[name], killerColor)
	card.Hit.MouseButton1Click:Connect(function() showKillerCard(name, card) end)
	killerCards[name] = card
end

-- =====================================
-- ЗАГРУЗКА ПРОФИЛЯ (подсветить сохранённый выбор)
-- ========================================

do
	local ok, prof = pcall(function() return RequestProfile:InvokeServer() end)
	if ok and type(prof) == "table" then
		chosenSoul   = tostring(prof.soul   or "Kindness")
		chosenKiller = tostring(prof.killer or "Asgore")

		-- рамки «выбрано»
		if soulCards[chosenSoul]   then setChosenIn(SoulList,   soulCards[chosenSoul])   end
		if killerCards[chosenKiller] then setChosenIn(KillerList, killerCards[chosenKiller]) end
	end
end

