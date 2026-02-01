--// SimpleUILib (Orion-like API)
--// Fixes included:
--// 1) Label: ровно 4 строки (5-я режется)
--// 2) Первая пользовательская секция автоматически открывается при создании
--// 3) ВСЕ состояния сохраняются между переключениями секций:
--//    Toggle/Slider/Textbox/Dropdown -> item.Value

local SimpleUILib = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

local function getParent()
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function addCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
	return c
end

local function enableAutoCanvas(sf)
	local ok = pcall(function()
		sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end)
	if ok then
		sf.CanvasSize = UDim2.new(0,0,0,0)
		return
	end

	local layout = sf:FindFirstChildOfClass("UIListLayout")
	if not layout then return end
	local pad = sf:FindFirstChildOfClass("UIPadding")

	local function recalc()
		local y = layout.AbsoluteContentSize.Y
		if pad then
			y += pad.PaddingTop.Offset + pad.PaddingBottom.Offset
		end
		sf.CanvasSize = UDim2.new(0,0,0,y + 4)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(recalc)
	recalc()
end

--========================
-- Base geometry
--========================
local CORNER = 6
local TOP_H  = 30
local ITEM_H = 24
local SPACING = 6
local LEFT_W = 150
local FONT   = Enum.Font.Gotham

local CONTROL_CORNER = 4
local CONTROL_GAP = 10

-- Dropdown
local DROPDOWN_MAX_VISIBLE = 5
local DROPDOWN_GAP_Y = 4
local DROPDOWN_BORDER = 1

--========================
-- Themes
--========================
local THEMES = {
	Carbon = {
		MainBg   = Color3.fromRGB(34, 34, 34),
		TopBar   = Color3.fromRGB(24, 24, 24),
		LeftBg   = Color3.fromRGB(28, 28, 28),
		Text     = Color3.fromRGB(240, 240, 240),
		BtnBg    = Color3.fromRGB(45, 45, 45),
		BtnBg2   = Color3.fromRGB(52, 52, 52),
		Stroke   = Color3.fromRGB(140, 140, 140),
		Active   = Color3.fromRGB(65, 65, 65),
		DimText  = Color3.fromRGB(210, 210, 210),
	},
	Light = {
		MainBg   = Color3.fromRGB(245, 245, 245),
		TopBar   = Color3.fromRGB(230, 230, 230),
		LeftBg   = Color3.fromRGB(235, 235, 235),
		Text     = Color3.fromRGB(25, 25, 25),
		BtnBg    = Color3.fromRGB(220, 220, 220),
		BtnBg2   = Color3.fromRGB(210, 210, 210),
		Stroke   = Color3.fromRGB(120, 120, 120),
		Active   = Color3.fromRGB(190, 210, 255),
		DimText  = Color3.fromRGB(70, 70, 70),
	},
	Ocean = {MainBg=Color3.fromRGB(20,28,38),TopBar=Color3.fromRGB(16,22,30),LeftBg=Color3.fromRGB(18,26,36),Text=Color3.fromRGB(230,245,255),BtnBg=Color3.fromRGB(30,44,60),BtnBg2=Color3.fromRGB(36,52,72),Stroke=Color3.fromRGB(90,140,170),Active=Color3.fromRGB(45,110,140),DimText=Color3.fromRGB(170,210,230)},
	Forest = {MainBg=Color3.fromRGB(24,34,28),TopBar=Color3.fromRGB(18,26,20),LeftBg=Color3.fromRGB(22,32,24),Text=Color3.fromRGB(235,245,235),BtnBg=Color3.fromRGB(38,54,40),BtnBg2=Color3.fromRGB(44,62,46),Stroke=Color3.fromRGB(120,150,120),Active=Color3.fromRGB(60,110,70),DimText=Color3.fromRGB(190,220,190)},
	Rose = {MainBg=Color3.fromRGB(40,28,34),TopBar=Color3.fromRGB(32,20,26),LeftBg=Color3.fromRGB(36,24,30),Text=Color3.fromRGB(255,240,245),BtnBg=Color3.fromRGB(60,36,46),BtnBg2=Color3.fromRGB(72,42,54),Stroke=Color3.fromRGB(170,110,130),Active=Color3.fromRGB(150,60,90),DimText=Color3.fromRGB(230,190,200)},
	Violet = {MainBg=Color3.fromRGB(32,28,44),TopBar=Color3.fromRGB(24,20,34),LeftBg=Color3.fromRGB(28,24,40),Text=Color3.fromRGB(245,240,255),BtnBg=Color3.fromRGB(52,44,80),BtnBg2=Color3.fromRGB(60,50,92),Stroke=Color3.fromRGB(150,130,200),Active=Color3.fromRGB(110,80,180),DimText=Color3.fromRGB(215,205,235)},
	Amber = {MainBg=Color3.fromRGB(44,34,24),TopBar=Color3.fromRGB(34,24,16),LeftBg=Color3.fromRGB(40,30,20),Text=Color3.fromRGB(255,245,230),BtnBg=Color3.fromRGB(70,52,32),BtnBg2=Color3.fromRGB(82,60,36),Stroke=Color3.fromRGB(200,160,90),Active=Color3.fromRGB(200,120,40),DimText=Color3.fromRGB(230,210,170)},
	Nord = {MainBg=Color3.fromRGB(46,52,64),TopBar=Color3.fromRGB(59,66,82),LeftBg=Color3.fromRGB(53,59,74),Text=Color3.fromRGB(236,239,244),BtnBg=Color3.fromRGB(67,76,94),BtnBg2=Color3.fromRGB(76,86,106),Stroke=Color3.fromRGB(136,192,208),Active=Color3.fromRGB(129,161,193),DimText=Color3.fromRGB(216,222,233)},
	Neon = {MainBg=Color3.fromRGB(18,18,18),TopBar=Color3.fromRGB(10,10,10),LeftBg=Color3.fromRGB(14,14,14),Text=Color3.fromRGB(240,240,240),BtnBg=Color3.fromRGB(30,30,30),BtnBg2=Color3.fromRGB(40,40,40),Stroke=Color3.fromRGB(120,120,120),Active=Color3.fromRGB(0,255,160),DimText=Color3.fromRGB(170,170,170)},
	Mono = {MainBg=Color3.fromRGB(22,22,22),TopBar=Color3.fromRGB(16,16,16),LeftBg=Color3.fromRGB(19,19,19),Text=Color3.fromRGB(235,235,235),BtnBg=Color3.fromRGB(36,36,36),BtnBg2=Color3.fromRGB(48,48,48),Stroke=Color3.fromRGB(165,165,165),Active=Color3.fromRGB(90,90,90),DimText=Color3.fromRGB(205,205,205)},
	Sunset = {MainBg=Color3.fromRGB(44,26,24),TopBar=Color3.fromRGB(34,18,16),LeftBg=Color3.fromRGB(40,22,20),Text=Color3.fromRGB(255,242,235),BtnBg=Color3.fromRGB(66,34,30),BtnBg2=Color3.fromRGB(78,38,34),Stroke=Color3.fromRGB(220,150,120),Active=Color3.fromRGB(180,90,70),DimText=Color3.fromRGB(235,205,195)},
	Midnight={MainBg=Color3.fromRGB(16,18,26),TopBar=Color3.fromRGB(12,14,20),LeftBg=Color3.fromRGB(14,16,24),Text=Color3.fromRGB(235,240,255),BtnBg=Color3.fromRGB(26,30,44),BtnBg2=Color3.fromRGB(32,36,52),Stroke=Color3.fromRGB(120,140,200),Active=Color3.fromRGB(70,85,120),DimText=Color3.fromRGB(190,200,230)},
	Mint={MainBg=Color3.fromRGB(22,36,34),TopBar=Color3.fromRGB(16,28,26),LeftBg=Color3.fromRGB(20,32,30),Text=Color3.fromRGB(235,255,250),BtnBg=Color3.fromRGB(34,56,52),BtnBg2=Color3.fromRGB(40,64,60),Stroke=Color3.fromRGB(120,220,200),Active=Color3.fromRGB(60,110,100),DimText=Color3.fromRGB(190,235,225)},
	Cherry={MainBg=Color3.fromRGB(38,18,26),TopBar=Color3.fromRGB(28,12,18),LeftBg=Color3.fromRGB(34,16,22),Text=Color3.fromRGB(255,235,242),BtnBg=Color3.fromRGB(60,26,40),BtnBg2=Color3.fromRGB(72,30,48),Stroke=Color3.fromRGB(230,120,160),Active=Color3.fromRGB(110,50,80),DimText=Color3.fromRGB(235,190,210)},
	Sand={MainBg=Color3.fromRGB(46,42,34),TopBar=Color3.fromRGB(36,32,26),LeftBg=Color3.fromRGB(42,38,30),Text=Color3.fromRGB(255,250,235),BtnBg=Color3.fromRGB(70,64,50),BtnBg2=Color3.fromRGB(82,74,58),Stroke=Color3.fromRGB(210,190,140),Active=Color3.fromRGB(105,95,70),DimText=Color3.fromRGB(235,225,190)},
	Ice={MainBg=Color3.fromRGB(22,28,34),TopBar=Color3.fromRGB(16,20,26),LeftBg=Color3.fromRGB(20,24,30),Text=Color3.fromRGB(235,248,255),BtnBg=Color3.fromRGB(34,44,54),BtnBg2=Color3.fromRGB(40,52,64),Stroke=Color3.fromRGB(150,210,230),Active=Color3.fromRGB(75,95,110),DimText=Color3.fromRGB(200,235,245)},
	Cyber={MainBg=Color3.fromRGB(18,16,22),TopBar=Color3.fromRGB(12,10,14),LeftBg=Color3.fromRGB(16,14,18),Text=Color3.fromRGB(245,240,255),BtnBg=Color3.fromRGB(34,28,44),BtnBg2=Color3.fromRGB(42,34,56),Stroke=Color3.fromRGB(170,120,255),Active=Color3.fromRGB(80,70,110),DimText=Color3.fromRGB(200,190,230)},
	Coffee={MainBg=Color3.fromRGB(36,28,24),TopBar=Color3.fromRGB(26,20,16),LeftBg=Color3.fromRGB(32,24,20),Text=Color3.fromRGB(255,245,235),BtnBg=Color3.fromRGB(56,42,34),BtnBg2=Color3.fromRGB(66,50,40),Stroke=Color3.fromRGB(200,170,140),Active=Color3.fromRGB(95,75,60),DimText=Color3.fromRGB(230,210,190)},
	Lime={MainBg=Color3.fromRGB(24,34,20),TopBar=Color3.fromRGB(16,24,14),LeftBg=Color3.fromRGB(20,30,18),Text=Color3.fromRGB(245,255,235),BtnBg=Color3.fromRGB(38,56,30),BtnBg2=Color3.fromRGB(46,66,34),Stroke=Color3.fromRGB(170,230,110),Active=Color3.fromRGB(70,95,55),DimText=Color3.fromRGB(210,240,190)},
	Slate={MainBg=Color3.fromRGB(30,34,38),TopBar=Color3.fromRGB(22,26,30),LeftBg=Color3.fromRGB(26,30,34),Text=Color3.fromRGB(240,245,250),BtnBg=Color3.fromRGB(44,50,56),BtnBg2=Color3.fromRGB(52,60,66),Stroke=Color3.fromRGB(160,180,200),Active=Color3.fromRGB(70,80,90),DimText=Color3.fromRGB(205,220,235)},
}

local THEME_NAMES = {
	"Carbon","Light","Ocean","Forest","Rose","Violet","Amber","Nord","Neon","Mono",
	"Sunset","Midnight","Mint","Cherry","Sand","Ice","Cyber","Coffee","Lime","Slate"
}

function SimpleUILib:MakeWindow(cfg)
	cfg = cfg or {}
	local titleText = tostring(cfg.Title or "Title of the library")
	local CURRENT_THEME_NAME = tostring(cfg.Theme or "Carbon")
	if not THEMES[CURRENT_THEME_NAME] then CURRENT_THEME_NAME = "Carbon" end
	local THEME = THEMES[CURRENT_THEME_NAME]

	pcall(function()
		local old = getParent():FindFirstChild("SimpleUILib_Window")
		if old then old:Destroy() end
	end)

	-- theme binding
	local binds = {}
	local refreshers = {}

	local function bindColor(obj, prop, key)
		binds[#binds+1] = {o=obj, p=prop, k=key}
		obj[prop] = THEME[key]
	end

	local function addRef(obj, fn)
		refreshers[#refreshers+1] = {o=obj, fn=fn}
	end

	local function applyTheme(name)
		local t = THEMES[name]
		if not t then return end
		CURRENT_THEME_NAME = name
		THEME = t

		for i = #binds, 1, -1 do
			local b = binds[i]
			if (not b.o) or (b.o.Parent == nil) then
				table.remove(binds, i)
			else
				local v = THEME[b.k]
				if v ~= nil then
					pcall(function() b.o[b.p] = v end)
				end
			end
		end

		for i = #refreshers, 1, -1 do
			local r = refreshers[i]
			if (not r.o) or (r.o.Parent == nil) then
				table.remove(refreshers, i)
			else
				pcall(r.fn)
			end
		end
	end

	-- keybind system
	local keybindMap = {}
	local function keycodeFromString(s)
		if not s or s == "" then return nil end
		if #s == 1 then s = string.upper(s) end
		return Enum.KeyCode[s] or Enum.KeyCode[string.upper(s)]
	end

	UIS.InputBegan:Connect(function(input, processed)
		if processed then return end
		if UIS:GetFocusedTextBox() then return end
		local list = keybindMap[input.KeyCode]
		if list then
			for _, cb in ipairs(list) do pcall(cb) end
		end
	end)

	local function registerKeybind(keyStr, cb)
		if not keyStr or keyStr == "" then return end
		if type(cb) ~= "function" then return end
		local kc = keycodeFromString(keyStr)
		if not kc then return end
		keybindMap[kc] = keybindMap[kc] or {}
		table.insert(keybindMap[kc], cb)
	end

	-- GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "SimpleUILib_Window"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = getParent()

	local shell = Instance.new("Frame")
	shell.Size = UDim2.new(0, 520, 0, 320)
	shell.Position = UDim2.new(0.5, -260, 0.5, -160)
	shell.BorderSizePixel = 0
	shell.Active = true
	shell.Parent = gui
	addCorner(shell, 6)
	bindColor(shell, "BackgroundColor3", "MainBg")

	local shellStroke = Instance.new("UIStroke")
	shellStroke.Thickness = 0.5
	shellStroke.Transparency = 0.55
	shellStroke.Parent = shell
	bindColor(shellStroke, "Color", "Stroke")

	local clip = Instance.new("Frame")
	clip.Size = UDim2.new(1,0,1,0)
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Parent = shell
	addCorner(clip, 6)
	bindColor(clip, "BackgroundColor3", "MainBg")

	local overlay = Instance.new("Frame")
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1,0,1,0)
	overlay.ZIndex = 500
	overlay.Parent = gui

	-- Topbar
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1,0,0,30)
	top.BorderSizePixel = 0
	top.ZIndex = 5
	top.Parent = clip
	addCorner(top, 6)
	bindColor(top, "BackgroundColor3", "TopBar")

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 12, 0, 0)
	title.Size = UDim2.new(1, -90, 1, 0)
	title.Font = FONT
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Text = titleText
	title.ZIndex = 6
	title.Parent = top
	bindColor(title, "TextColor3", "Text")

	local btnHolder = Instance.new("Frame")
	btnHolder.BackgroundTransparency = 1
	btnHolder.Size = UDim2.new(0, 70, 1, 0)
	btnHolder.Position = UDim2.new(1, -70, 0, 0)
	btnHolder.ZIndex = 6
	btnHolder.Parent = top

	local function makeTopBtn(txt, x)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 24, 0, 24)
		b.Position = UDim2.new(0, x, 0.5, -12)
		b.BorderSizePixel = 0
		b.Font = FONT
		b.TextSize = 12
		b.Text = txt
		b.ZIndex = 7
		b.Parent = btnHolder
		addCorner(b, 4)
		bindColor(b, "BackgroundColor3", "BtnBg")
		bindColor(b, "TextColor3", "Text")
		return b
	end

	local minBtn = makeTopBtn("-", 10)
	local closeBtn = makeTopBtn("X", 40)

	-- Body
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0,0,0,30)
	body.Size = UDim2.new(1,0,1,-30)
	body.Parent = clip

	local left = Instance.new("Frame")
	left.BorderSizePixel = 0
	left.Size = UDim2.new(0, 150, 1, 0)
	left.Parent = body
	addCorner(left, 6)
	bindColor(left, "BackgroundColor3", "LeftBg")

	local right = Instance.new("Frame")
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(0, 150, 0, 0)
	right.Size = UDim2.new(1, -150, 1, 0)
	right.Parent = body

	local secList = Instance.new("ScrollingFrame")
	secList.BackgroundTransparency = 1
	secList.BorderSizePixel = 0
	secList.Size = UDim2.new(1,0,1,0)
	secList.ScrollBarThickness = 2
	secList.ScrollBarImageTransparency = 0.5
	secList.ZIndex = 15
	secList.Parent = left
	bindColor(secList, "ScrollBarImageColor3", "Stroke")

	local secPad = Instance.new("UIPadding")
	secPad.PaddingTop = UDim.new(0, SPACING)
	secPad.PaddingLeft = UDim.new(0, 6)
	secPad.PaddingRight = UDim.new(0, 6)
	secPad.PaddingBottom = UDim.new(0, 6)
	secPad.Parent = secList

	local secLayout = Instance.new("UIListLayout")
	secLayout.Padding = UDim.new(0, SPACING)
	secLayout.SortOrder = Enum.SortOrder.LayoutOrder
	secLayout.Parent = secList

	enableAutoCanvas(secList)

	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1,0,1,0)
	content.ScrollBarThickness = 3
	content.ScrollBarImageTransparency = 0.2
	content.ZIndex = 15
	content.Parent = right
	bindColor(content, "ScrollBarImageColor3", "Stroke")

	local cPad = Instance.new("UIPadding")
	cPad.PaddingTop = UDim.new(0, SPACING)
	cPad.PaddingLeft = UDim.new(0, 10)
	cPad.PaddingRight = UDim.new(0, 10)
	cPad.PaddingBottom = UDim.new(0, 10)
	cPad.Parent = content

	local cLayout = Instance.new("UIListLayout")
	cLayout.Padding = UDim.new(0, SPACING)
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Parent = content

	enableAutoCanvas(content)

	local function clearContent()
		for _, ch in ipairs(content:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
	end

	local function setContentScrolling(enabled)
		pcall(function() content.ScrollingEnabled = enabled end)
	end

	-- dropdown manager
	local openDrop = nil
	local followConn = nil
	local function closeDropdown()
		if openDrop then
			if openDrop.setArrow then pcall(openDrop.setArrow, false) end
			if openDrop.menu and openDrop.menu.Parent then openDrop.menu:Destroy() end
			if openDrop.blocker and openDrop.blocker.Parent then openDrop.blocker:Destroy() end
			openDrop = nil
		end
		if followConn then followConn:Disconnect(); followConn=nil end
	end

	-- Left label helpers
	local function makeLeftLabel(row, text, rightW)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0,0,0,0)
		lbl.Size = UDim2.new(1, -(rightW + CONTROL_GAP), 1, 0)
		lbl.Font = FONT
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.Text = tostring(text)
		lbl.ZIndex = row.ZIndex + 1
		lbl.Parent = row
		bindColor(lbl, "TextColor3", "Text")
		return lbl
	end

	local function makeLeftLabelWithKeybind(row, text, rightW, keyStr)
		local area = Instance.new("Frame")
		area.BackgroundTransparency = 1
		area.Position = UDim2.new(0,0,0,0)
		area.Size = UDim2.new(1, -(rightW + CONTROL_GAP), 1, 0)
		area.ZIndex = row.ZIndex + 1
		area.Parent = row

		local ll = Instance.new("UIListLayout")
		ll.FillDirection = Enum.FillDirection.Horizontal
		ll.VerticalAlignment = Enum.VerticalAlignment.Center
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Padding = UDim.new(0, 6)
		ll.Parent = area

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.AutomaticSize = Enum.AutomaticSize.X
		lbl.Font = FONT
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.Text = tostring(text)
		lbl.ZIndex = row.ZIndex + 2
		lbl.Parent = area
		bindColor(lbl, "TextColor3", "Text")

		if keyStr and keyStr ~= "" then
			local s = keyStr
			if #s == 1 then s = string.upper(s) end
			local kb = Instance.new("TextLabel")
			kb.BackgroundTransparency = 1
			kb.AutomaticSize = Enum.AutomaticSize.X
			kb.Font = FONT
			kb.TextSize = 11
			kb.Text = "[ " .. s .. " ]"
			kb.TextTransparency = 0.45
			kb.ZIndex = row.ZIndex + 2
			kb.Parent = area
			bindColor(kb, "TextColor3", "DimText")
		end

		return lbl
	end

	-- Elements
	local function makeRow(height)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1,0,0,height or ITEM_H)
		row.ZIndex = 16
		row.Parent = content
		return row
	end

	-- Label: ровно 4 строки
	local function makeLabel(item)
		local text = tostring(item.Text or "")
		local row = makeRow((ITEM_H * 2) + 2)

		local box = Instance.new("Frame")
		box.BorderSizePixel = 0
		box.Size = UDim2.new(1,0,1,0)
		box.ZIndex = row.ZIndex
		box.Parent = row
		addCorner(box, CONTROL_CORNER)

		bindColor(box, "BackgroundColor3", "BtnBg")

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Transparency = 0.6
		stroke.Parent = box
		bindColor(stroke, "Color", "Stroke")

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 4)
		pad.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.Font = FONT
		lbl.TextSize = 11
		lbl.LineHeight = 0.92
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.TextWrapped = true
		lbl.Text = text
		lbl.ZIndex = row.ZIndex + 1
		lbl.Parent = box

		lbl.TextTransparency = item.Transparency ~= nil and clamp(item.Transparency, 0, 1) or 0.15
		if item.Color then
			lbl.TextColor3 = item.Color
		else
			bindColor(lbl, "TextColor3", "DimText")
		end
	end

	local function makeHeadText(item)
		local text = tostring(item.Text or "-----")
		local row = makeRow(ITEM_H)

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Font = FONT
		lbl.TextSize = 12
		lbl.Text = text
		lbl.TextXAlignment = Enum.TextXAlignment.Center
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.ZIndex = row.ZIndex + 1
		lbl.Parent = row
		lbl.TextTransparency = item.Transparency ~= nil and clamp(item.Transparency,0,1) or 0
		if item.Color then lbl.TextColor3 = item.Color else bindColor(lbl, "TextColor3", "Text") end

		local lineL = Instance.new("Frame")
		lineL.BorderSizePixel = 0
		lineL.BackgroundTransparency = 0.7
		lineL.ZIndex = row.ZIndex + 1
		lineL.Parent = row
		bindColor(lineL, "BackgroundColor3", "Stroke")

		local lineR = Instance.new("Frame")
		lineR.BorderSizePixel = 0
		lineR.BackgroundTransparency = 0.7
		lineR.ZIndex = row.ZIndex + 1
		lineR.Parent = row
		bindColor(lineR, "BackgroundColor3", "Stroke")

		task.defer(function()
			local rowW = row.AbsoluteSize.X
			local tSize = TextService:GetTextSize(text, 12, FONT, Vector2.new(1000, ITEM_H))
			local labelW = clamp(math.floor(tSize.X + 18), 60, math.floor(rowW * 0.6))

			lbl.Size = UDim2.new(0, labelW, 1, 0)
			lbl.Position = UDim2.new(0.5, -labelW/2, 0, 0)

			local gap = 8
			local sideW = math.max(0, math.floor(rowW/2 - labelW/2 - gap))

			lineL.Size = UDim2.new(0, sideW, 0, 1)
			lineL.Position = UDim2.new(0, 0, 0.5, 0)

			lineR.Size = UDim2.new(0, sideW, 0, 1)
			lineR.Position = UDim2.new(1, -sideW, 0.5, 0)
		end)
	end


	
	-- Notification (inline message box; does NOT affect keybind attachment)
	local function tween(o, ti, props)
		local t = TweenService:Create(o, ti, props)
		t:Play()
		return t
	end

	local function makeNotification(item)
		local headText = tostring(item.HeadText or item.Title or "Notice")
		local bodyText = tostring(item.Text or "")
		local when = tostring(item.When or item.ShowOn or "Both") -- "On" / "Off" / "Both"

		-- fixed height: 1 head line + 2 body lines
		local rowH = 44
		local row = makeRow(rowH)

		local box = Instance.new("Frame")
		box.BorderSizePixel = 0
		box.Size = UDim2.new(1, 0, 1, 0)
		box.ZIndex = row.ZIndex
		box.Parent = row
		addCorner(box, CONTROL_CORNER)
		bindColor(box, "BackgroundColor3", "BtnBg")

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Transparency = 0.6
		stroke.Parent = box
		bindColor(stroke, "Color", "Stroke")

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.Parent = box

		local head = Instance.new("TextLabel")
		head.BackgroundTransparency = 1
		head.Size = UDim2.new(1, 0, 0, 18)
		head.Font = Enum.Font.GothamBold
		head.TextSize = 13
		head.TextXAlignment = Enum.TextXAlignment.Left
		head.TextYAlignment = Enum.TextYAlignment.Center
		head.Text = headText
		head.ZIndex = row.ZIndex + 1
		head.Parent = box
		bindColor(head, "TextColor3", "Text")

		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.new(0, 0, 0, 20)
		body.Size = UDim2.new(1, 0, 0, 18)
		body.Font = FONT
		body.TextSize = 11
		body.LineHeight = 0.92
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Text = bodyText
		body.TextTransparency = 0.15
		body.ZIndex = row.ZIndex + 1
		body.Parent = box
		bindColor(body, "TextColor3", "DimText")

		-- animation helpers (for toggle-bound notifications)
		local function setCollapsed(collapsed)
			if collapsed then
				row.Size = UDim2.new(1, 0, 0, 0)
				row.Visible = false
				box.BackgroundTransparency = 1
				stroke.Transparency = 1
				head.TextTransparency = 1
				body.TextTransparency = 1
			else
				row.Visible = true
				row.Size = UDim2.new(1, 0, 0, rowH)
				box.BackgroundTransparency = 0
				stroke.Transparency = 0.6
				head.TextTransparency = 0
				body.TextTransparency = 0.15
			end
		end

		local function showAnimated()
			row.Visible = true
			row.Size = UDim2.new(1, 0, 0, 0)
			box.BackgroundTransparency = 1
			stroke.Transparency = 1
			head.TextTransparency = 1
			body.TextTransparency = 1

			tween(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,rowH)})
			tween(box, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
			tween(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.6})
			tween(head, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			tween(body, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.15})
		end

		local function hideAnimated()
			if not row.Visible then return end
			local t = tween(row, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1,0,0,0)})
			tween(box, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
			tween(stroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
			tween(head, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
			tween(body, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
			t.Completed:Connect(function()
				row.Visible = false
			end)
		end

		item._ui = {Row = row, When = when, Show = showAnimated, Hide = hideAnimated, Collapse = setCollapsed}

		-- If this notification is bound to a Toggle, it should only appear on matching state.
		if item.Target and item.Target.Type == "Toggle" then
			local tItem = item.Target
			tItem._toggleNotifs = tItem._toggleNotifs or {}
			table.insert(tItem._toggleNotifs, item)

			-- initial collapse; then immediately show/hide based on current toggle state
			setCollapsed(true)
			local st = (tItem.Value == true)
			local shouldShow = (when == "Both") or (when == "On" and st) or (when == "Off" and (not st))
			if shouldShow then
				showAnimated()
			end
		end
	end
	
		-- Button: right text always "Button"
	local function makeButtonRow(item)
		local row = makeRow(ITEM_H)
		makeLeftLabelWithKeybind(row, item.Name or "Button", 78, item.Keybind or "")

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 78, 0, ITEM_H)
		btn.Position = UDim2.new(1, -78, 0, 0)
		btn.BorderSizePixel = 0
		btn.Font = FONT
		btn.TextSize = 11
		btn.Text = "Button"
		btn.TextYAlignment = Enum.TextYAlignment.Center
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")
		bindColor(btn, "TextColor3", "Text")

		btn.MouseButton1Click:Connect(function()
			if type(item.Callback) == "function" then pcall(item.Callback) end
		end)

		if item.Keybind and item.Keybind ~= "" then
			registerKeybind(item.Keybind, function()
				if type(item.Callback) == "function" then pcall(item.Callback) end
			end)
		end
	end

	-- Toggle (STATE -> item.Value)
	local function makeToggle(item)
		local W = 56
		local row = makeRow(ITEM_H)

		makeLeftLabelWithKeybind(row, item.Name or "Toggle", W, item.Keybind or "")

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, W, 0, ITEM_H)
		btn.Position = UDim2.new(1, -W, 0, 0)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")

		local state
		if item.Value ~= nil then
			state = item.Value == true
		else
			state = item.Default == true
			item.Value = state
		end

		local knobSize = 12
		local pad = 6

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, knobSize, 0, knobSize)
		knob.BorderSizePixel = 0
		knob.ZIndex = row.ZIndex + 3
		knob.Parent = btn
		addCorner(knob, CONTROL_CORNER)
		bindColor(knob, "BackgroundColor3", "Text")

		local labelState = Instance.new("TextLabel")
		labelState.BackgroundTransparency = 1
		labelState.Font = FONT
		labelState.TextSize = 10
		labelState.TextYAlignment = Enum.TextYAlignment.Center
		labelState.TextXAlignment = Enum.TextXAlignment.Center
		labelState.ZIndex = row.ZIndex + 2
		labelState.Parent = btn
		bindColor(labelState, "TextColor3", "Text")
		labelState.TextTransparency = 0.25

		local function render(instant)
			btn.BackgroundColor3 = state and THEME.Active or THEME.BtnBg2

			local knobX = state and (W - knobSize - pad) or pad
			local knobGoal = UDim2.new(0, knobX, 0.5, -knobSize/2)

			if state then
				local freeStart = pad
				local freeEnd = knobX
				local freeW = math.max(0, freeEnd - freeStart)
				labelState.Text = "ON"
				labelState.Position = UDim2.new(0, freeStart, 0, 0)
				labelState.Size = UDim2.new(0, freeW, 1, 0)
			else
				local freeStart = knobX + knobSize
				local freeEnd = W - pad
				local freeW = math.max(0, freeEnd - freeStart)
				labelState.Text = "OFF"
				labelState.Position = UDim2.new(0, freeStart, 0, 0)
				labelState.Size = UDim2.new(0, freeW, 1, 0)
			end

			-- toggle-bound notifications (can be multiple; supports When = "On"/"Off"/"Both")
			if item._toggleNotifs then
				for _, n in ipairs(item._toggleNotifs) do
					local ui = n._ui
					local w = tostring((ui and ui.When) or n.When or n.ShowOn or "Both")
					local shouldShow = (w == "Both") or (w == "On" and state) or (w == "Off" and (not state))
					if ui then
						if shouldShow then
							if ui.Show then ui.Show() end
						else
							if ui.Hide then ui.Hide() end
						end
					end
				end
			end

			if instant then
				knob.Position = knobGoal
			else
				TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = knobGoal}):Play()
			end
		end

		render(true)

		btn.MouseButton1Click:Connect(function()
			state = not state
			item.Value = state
			render(false)
			if type(item.Callback) == "function" then pcall(item.Callback, state) end
		end)

		if item.Keybind and item.Keybind ~= "" then
			registerKeybind(item.Keybind, function()
				state = not state
				item.Value = state
				render(false)
				if type(item.Callback) == "function" then pcall(item.Callback, state) end
			end)
		end
	end

	-- Slider drag
	local sliderDrag = nil
	local sliderMouseConn = nil
	local function stopSliderDrag()
		sliderDrag = nil
		if sliderMouseConn then sliderMouseConn:Disconnect(); sliderMouseConn=nil end
		setContentScrolling(true)
	end
	UIS.InputEnded:Connect(function(input)
		if sliderDrag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			stopSliderDrag()
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if sliderDrag and sliderDrag.mode == "touch" and input.UserInputType == Enum.UserInputType.Touch then
			sliderDrag.setFromX(input.Position.X)
		end
	end)

	-- Slider (STATE -> item.Value)
	local function makeSlider(item)
		local minV = item.Min or 0
		local maxV = item.Max or 100
		local step = item.Increment or 1

		if item.Value == nil then
			if item.Default ~= nil then item.Value = item.Default else item.Value = minV end
		end
		local value = item.Value
		local valueName = item.ValueName

		local totalW = 170
		local valueW = 48
		local gap = 6
		local barW = totalW - valueW - gap

		local row = makeRow(ITEM_H)
		makeLeftLabel(row, item.Name or "Slider", totalW)

		local wrap = Instance.new("Frame")
		wrap.BackgroundTransparency = 1
		wrap.Size = UDim2.new(0, totalW, 0, ITEM_H)
		wrap.Position = UDim2.new(1, -totalW, 0, 0)
		wrap.ZIndex = row.ZIndex + 1
		wrap.Parent = row

		local valBox = Instance.new("Frame")
		valBox.Size = UDim2.new(0, valueW, 0, ITEM_H)
		valBox.Position = UDim2.new(1, -valueW, 0, 0)
		valBox.BorderSizePixel = 0
		valBox.ZIndex = row.ZIndex + 2
		valBox.Parent = wrap
		addCorner(valBox, CONTROL_CORNER)
		bindColor(valBox, "BackgroundColor3", "BtnBg2")

		local valText = Instance.new("TextLabel")
		valText.BackgroundTransparency = 1
		valText.Size = UDim2.new(1,0,1,0)
		valText.Font = FONT
		valText.TextSize = 11
		valText.TextYAlignment = Enum.TextYAlignment.Center
		valText.TextXAlignment = Enum.TextXAlignment.Center
		valText.ZIndex = row.ZIndex + 3
		valText.Parent = valBox
		bindColor(valText, "TextColor3", "Text")

		local function updateValueText()
			if valueName and valueName ~= "" then
				valText.Text = tostring(value) .. " " .. tostring(valueName)
			else
				valText.Text = tostring(value)
			end
		end

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, barW, 0, 6)
		bar.Position = UDim2.new(0, 0, 0.5, -3)
		bar.BorderSizePixel = 0
		bar.ZIndex = row.ZIndex + 2
		bar.Parent = wrap
		addCorner(bar, CONTROL_CORNER)
		bindColor(bar, "BackgroundColor3", "BtnBg")

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0,0,1,0)
		fill.BorderSizePixel = 0
		fill.ZIndex = row.ZIndex + 3
		fill.Parent = bar
		addCorner(fill, CONTROL_CORNER)
		bindColor(fill, "BackgroundColor3", "Active")

		local HIT = 20
		local knobHit = Instance.new("TextButton")
		knobHit.Size = UDim2.new(0, HIT, 0, HIT)
		knobHit.BackgroundTransparency = 1
		knobHit.BorderSizePixel = 0
		knobHit.Text = ""
		knobHit.AutoButtonColor = false
		knobHit.ZIndex = row.ZIndex + 4
		knobHit.Parent = bar

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 10, 0, 10)
		knob.Position = UDim2.new(0.5,-5,0.5,-5)
		knob.BorderSizePixel = 0
		knob.ZIndex = row.ZIndex + 5
		knob.Parent = knobHit
		addCorner(knob, CONTROL_CORNER)
		bindColor(knob, "BackgroundColor3", "Text")

		local function applyValue(v, call)
			v = clamp(v, minV, maxV)
			v = clamp(math.floor((v / step) + 0.5) * step, minV, maxV)
			value = v
			item.Value = value
			updateValueText()

			local ratio = (value - minV) / (maxV - minV)
			ratio = clamp(ratio, 0, 1)

			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knobHit.Position = UDim2.new(ratio, -HIT/2, 0.5, -HIT/2)

			if call and type(item.Callback) == "function" then
				pcall(item.Callback, value)
			end
		end

		local function setFromX(screenX)
			local absX = bar.AbsolutePosition.X
			local w = bar.AbsoluteSize.X
			if w <= 1 then return end
			local ratio = clamp((screenX - absX) / w, 0, 1)
			local v = minV + ratio * (maxV - minV)
			applyValue(v, true)
		end

		local function startDrag(input)
			setContentScrolling(false)
			if input.UserInputType == Enum.UserInputType.Touch then
				sliderDrag = { mode = "touch", setFromX = setFromX }
				setFromX(input.Position.X)
			else
				sliderDrag = { mode = "mouse", setFromX = setFromX }
				if sliderMouseConn then sliderMouseConn:Disconnect() end
				sliderMouseConn = RunService.RenderStepped:Connect(function()
					if sliderDrag and sliderDrag.mode == "mouse" then
						setFromX(UIS:GetMouseLocation().X)
					end
				end)
				setFromX(UIS:GetMouseLocation().X)
			end
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				startDrag(input)
			end
		end)
		knobHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				startDrag(input)
			end
		end)

		applyValue(value, false)
	end

	-- Textbox (STATE -> item.Value)
	local function makeTextbox(item)
		local boxW = 160
		local row = makeRow(ITEM_H)
		makeLeftLabel(row, item.Name or "Textbox", boxW)

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, boxW, 0, ITEM_H)
		frame.Position = UDim2.new(1, -boxW, 0, 0)
		frame.BorderSizePixel = 0
		frame.ZIndex = row.ZIndex + 1
		frame.Parent = row
		addCorner(frame, CONTROL_CORNER)
		bindColor(frame, "BackgroundColor3", "BtnBg2")

		local tb = Instance.new("TextBox")
		tb.BackgroundTransparency = 1
		tb.Position = UDim2.new(0, 8, 0, 0)
		tb.Size = UDim2.new(1, -16, 1, 0)
		tb.Font = FONT
		tb.TextSize = 11
		tb.TextXAlignment = Enum.TextXAlignment.Left
		tb.TextYAlignment = Enum.TextYAlignment.Center
		tb.ClearTextOnFocus = item.ClearTextOnFocus == true
		tb.PlaceholderText = item.Placeholder or "Type..."
		tb.ZIndex = row.ZIndex + 2
		tb.Parent = frame
		bindColor(tb, "TextColor3", "Text")
		bindColor(tb, "PlaceholderColor3", "DimText")

		if item.Value == nil then item.Value = item.Default or "" end
		tb.Text = tostring(item.Value)

		tb.FocusLost:Connect(function(enter)
			item.Value = tb.Text
			if type(item.Callback) == "function" then
				pcall(item.Callback, tb.Text, enter)
			end
		end)
	end

	-- Dropdown (STATE -> item.Value)
	local function makeDropdown(item)
		local options = item.Options or {}

		local selected = item.Value
		if selected == nil or selected == "" then
			selected = item.Default or options[1] or ""
			item.Value = selected
		end

		local controlW = 140
		local row = makeRow(ITEM_H)
		makeLeftLabel(row, item.Name or "Dropdown", controlW)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, controlW, 0, ITEM_H)
		btn.Position = UDim2.new(1, -controlW, 0, 0)
		btn.BorderSizePixel = 0
		btn.Font = FONT
		btn.TextSize = 11
		btn.TextYAlignment = Enum.TextYAlignment.Center
		btn.Text = tostring(selected) .. "  v"
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")
		bindColor(btn, "TextColor3", "Text")

		local function setArrow(open)
			btn.Text = tostring(selected) .. (open and "  ^" or "  v")
		end

		local function openMenu()
			closeDropdown()

			local blocker = Instance.new("TextButton")
			blocker.BackgroundTransparency = 1
			blocker.BorderSizePixel = 0
			blocker.Text = ""
			blocker.AutoButtonColor = false
			blocker.Size = UDim2.new(1,0,1,0)
			blocker.ZIndex = 600
			blocker.Parent = overlay

			local function compute()
				local base = overlay.AbsolutePosition
				local scr = overlay.AbsoluteSize
				local a = btn.AbsolutePosition
				local s = btn.AbsoluteSize

				local x = a.X - base.X
				local y = (a.Y - base.Y) + s.Y + DROPDOWN_GAP_Y
				local w = s.X

				local availableBelow = (scr.Y - 4) - y
				local maxFit = math.floor((availableBelow - (DROPDOWN_BORDER*2)) / ITEM_H)
				maxFit = clamp(maxFit, 1, DROPDOWN_MAX_VISIBLE)

				local count = #options
				local slots = math.min(count, DROPDOWN_MAX_VISIBLE, maxFit)
				local showHalf = (count > slots) and (slots >= 2)
				local viewportH = (showHalf and ((slots - 0.5) * ITEM_H) or (slots * ITEM_H))
				local h = viewportH + (DROPDOWN_BORDER*2)

				if x + w > scr.X - 4 then x = scr.X - w - 4 end
				if x < 4 then x = 4 end
				if y + h > scr.Y - 4 then y = scr.Y - h - 4 end
				if y < 4 then y = 4 end

				return x,y,w,h
			end

			local x,y,w,h = compute()

			local outer = Instance.new("Frame")
			outer.BorderSizePixel = 0
			outer.ClipsDescendants = true
			outer.Size = UDim2.fromOffset(w,h)
			outer.Position = UDim2.fromOffset(x,y)
			outer.ZIndex = 601
			outer.Parent = overlay
			addCorner(outer, CONTROL_CORNER)
			bindColor(outer, "BackgroundColor3", "Stroke")

			local list = Instance.new("ScrollingFrame")
			list.BorderSizePixel = 0
			list.Position = UDim2.fromOffset(DROPDOWN_BORDER, DROPDOWN_BORDER)
			list.Size = UDim2.new(1, -(DROPDOWN_BORDER*2), 1, -(DROPDOWN_BORDER*2))
			list.ClipsDescendants = true
			list.ZIndex = 602
			list.Parent = outer
			addCorner(list, CONTROL_CORNER)
			bindColor(list, "BackgroundColor3", "BtnBg2")

			list.ScrollBarThickness = 3
			list.ScrollBarImageTransparency = 0
			bindColor(list, "ScrollBarImageColor3", "Stroke")

			local pad = Instance.new("UIPadding")
			pad.PaddingRight = UDim.new(0, list.ScrollBarThickness + 2)
			pad.Parent = list

			local ll = Instance.new("UIListLayout")
			ll.SortOrder = Enum.SortOrder.LayoutOrder
			ll.Padding = UDim.new(0,0)
			ll.Parent = list

			list.CanvasSize = UDim2.new(0,0,0,#options * ITEM_H)

			for i,opt in ipairs(options) do
				local o = Instance.new("TextButton")
				o.BorderSizePixel = 0
				o.Size = UDim2.new(1,0,0,ITEM_H)
				o.Font = FONT
				o.TextSize = 11
				o.TextYAlignment = Enum.TextYAlignment.Center
				o.Text = tostring(opt)
				o.AutoButtonColor = false
				o.ZIndex = 603
				o.LayoutOrder = i
				o.Parent = list

				bindColor(o, "BackgroundColor3", "BtnBg2")
				bindColor(o, "TextColor3", "Text")

				o.MouseEnter:Connect(function() o.BackgroundColor3 = THEME.Active end)
				o.MouseLeave:Connect(function() o.BackgroundColor3 = THEME.BtnBg2 end)

				o.MouseButton1Click:Connect(function()
					selected = opt
					item.Value = opt
					item.Default = opt
					btn.Text = tostring(selected) .. "  v"
					closeDropdown()
					if type(item.Callback) == "function" then pcall(item.Callback, selected) end
				end)
			end

			blocker.MouseButton1Click:Connect(closeDropdown)

			local function updatePos()
				if not btn.Parent or not outer.Parent then closeDropdown() return end
				local nx,ny = compute()
				outer.Position = UDim2.fromOffset(nx,ny)
			end

			setArrow(true)
			openDrop = { blocker=blocker, menu=outer, setArrow=setArrow }
			updatePos()
			followConn = RunService.RenderStepped:Connect(updatePos)
		end

		btn.MouseButton1Click:Connect(function()
			if openDrop then closeDropdown() else openMenu() end
		end)

		addRef(btn, function()
			selected = item.Value or item.Default or ""
			btn.Text = tostring(selected) .. "  v"
		end)
	end

	local function makeItem(it)
		if it.Type == "Label" then makeLabel(it)
		elseif it.Type == "HeadText" then makeHeadText(it)
		elseif it.Type == "Notification" then makeNotification(it)
		elseif it.Type == "Button" then makeButtonRow(it)
		elseif it.Type == "Toggle" then makeToggle(it)
		elseif it.Type == "Slider" then makeSlider(it)
		elseif it.Type == "Textbox" then makeTextbox(it)
		elseif it.Type == "Dropdown" then makeDropdown(it)
		end
	end

	-- Sections
	local sections = {}
	local sectionButtons = {}
	local activeSection = nil
	local activeBtn = nil

	local function refreshSectionButtons()
		for _, b in ipairs(sectionButtons) do
			if b and b.Parent then
				b.BackgroundColor3 = (b == activeBtn) and THEME.Active or THEME.BtnBg
			end
		end
	end

	local function showSection(sec)
		closeDropdown()
		clearContent()
		activeSection = sec
		for _, it in ipairs(sec.Items) do makeItem(it) end
	end

	local function createSectionButton(name, order)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,ITEM_H)
		b.BorderSizePixel = 0
		b.Font = FONT
		b.TextSize = 12
		b.TextYAlignment = Enum.TextYAlignment.Center
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.Text = "  " .. tostring(name)
		b.LayoutOrder = order
		b.ZIndex = 20
		b.Parent = secList
		addCorner(b, CONTROL_CORNER)
		bindColor(b, "TextColor3", "Text")
		b.BackgroundColor3 = THEME.BtnBg
		table.insert(sectionButtons, b)
		return b
	end

	-- Themes section (always last)
	local themesSection = {
		Name = "Themes",
		Items = {
			{
				Type="Dropdown",
				Name="Theme",
				Options=THEME_NAMES,
				Default=CURRENT_THEME_NAME,
				Value=CURRENT_THEME_NAME,
				Callback=function(name)
					applyTheme(name)
					themesSection.Items[1].Default = name
					themesSection.Items[1].Value = name
					if activeSection == themesSection then
						showSection(themesSection)
					end
				end
			}
		}
	}

	local themesBtn = createSectionButton("Themes", 999999)
	table.insert(sections, themesSection)

	local function keepThemesLast()
		themesBtn.LayoutOrder = 999999
	end

	themesBtn.MouseButton1Click:Connect(function()
		activeBtn = themesBtn
		refreshSectionButtons()
		showSection(themesSection)
	end)

	local Window = {}
	local hasUserSection = false

	function Window:AddSection(cfg2)
		cfg2 = cfg2 or {}
		local name = tostring(cfg2.Name or "Section")

		local sec = { Name=name, Items={} }
		table.insert(sections, #sections, sec) -- before themes
		local order = #sections - 1

		local btn = createSectionButton(name, order)
		keepThemesLast()

		btn.MouseButton1Click:Connect(function()
			activeBtn = btn
			refreshSectionButtons()
			showSection(sec)
		end)

		if not hasUserSection then
			hasUserSection = true
			activeBtn = btn
			refreshSectionButtons()
			showSection(sec)
		else
			refreshSectionButtons()
		end

		local Section = {}
		local lastBindable = nil

		function Section:AddButton(spec)
			spec = spec or {}
			local item = { Type="Button", Name=spec.Name or "Button", Keybind=spec.Keybind or "", Callback=spec.Callback }
			table.insert(sec.Items, item)
			lastBindable = item
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddToggle(spec)
			spec = spec or {}
			local item = {
				Type="Toggle",
				Name=spec.Name or "Toggle",
				Default=spec.Default==true,
				Value=spec.Default==true,
				Keybind=spec.Keybind or "",
				Callback=spec.Callback
			}
			table.insert(sec.Items, item)
			lastBindable = item
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddSlider(spec)
			spec = spec or {}
			local minV = spec.Min or 0
			local item = {
				Type="Slider",
				Name=spec.Name or "Slider",
				Min=minV,
				Max=spec.Max or 100,
				Default=spec.Default,
				Value=(spec.Default ~= nil and spec.Default or minV),
				Increment=spec.Increment or 1,
				ValueName=spec.ValueName,
				Callback=spec.Callback
			}
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddTextbox(spec)
			spec = spec or {}
			local item = {
				Type="Textbox",
				Name=spec.Name or "Textbox",
				Default=spec.Default or "",
				Value=spec.Default or "",
				Placeholder=spec.Placeholder or "Type...",
				ClearTextOnFocus=spec.ClearTextOnFocus==true,
				Callback=spec.Callback
			}
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddLabel(spec)
			spec = spec or {}
			local item = { Type="Label", Text=spec.Text or "", Color=spec.Color, Transparency=spec.Transparency }
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddHeadText(spec)
			spec = spec or {}
			local item = { Type="HeadText", Text=spec.Text or "-----", Color=spec.Color, Transparency=spec.Transparency }
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec) end
			return item
		end
		
		function Section:AddNotification(spec)
			spec = spec or {}
			local item = {
				Type = "Notification",
				HeadText = spec.HeadText or spec.Title or "Notice",
				Text = spec.Text or "",
				When = spec.When or spec.ShowOn or "Both", -- for Toggle: "On"/"Off"/"Both"
				Target = lastBindable, -- IMPORTANT: binds to the last bindable element (Button/Toggle). KeyBind/Notification do not change it.
			}
			table.insert(sec.Items, item)
			if active then makeItem(item) end
			-- IMPORTANT: notification should NOT change lastBindable / keybind attachment
			return item
		end
		
		

		function Section:AddDropDown(spec)
			spec = spec or {}
			local def = spec.Default
			if def == nil and spec.Options and spec.Options[1] ~= nil then
				def = spec.Options[1]
			end
			local item = {
				Type="Dropdown",
				Name=spec.Name or "Dropdown",
				Options=spec.Options or {},
				Default=def,
				Value=def,
				Callback=spec.Callback
			}
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec) end
			return item
		end

		function Section:AddKeyBind(spec)
			spec = spec or {}
			local key = tostring(spec.Default or "")
			if key == "" then return nil end
			if not lastBindable then return nil end

			lastBindable.Keybind = key
			if type(spec.Callback) == "function" then
				lastBindable.Callback = spec.Callback
			end

			if activeSection == sec then showSection(sec) end
			return true
		end

		return Section
	end

	function Window:SetTheme(name)
		applyTheme(name)
		themesSection.Items[1].Default = name
		themesSection.Items[1].Value = name
		if activeSection == themesSection then showSection(themesSection) end
	end

	function Window:Destroy()
		closeDropdown()
		gui:Destroy()
	end

	-- Minimize
	local mini = Instance.new("Frame")
	mini.Visible = false
	mini.BorderSizePixel = 0
	mini.Size = UDim2.new(0, 120, 0, 26)
	mini.Position = UDim2.new(0.5, -60, 0, 32)
	mini.ZIndex = 100
	mini.Parent = gui
	addCorner(mini, 6)
	bindColor(mini, "BackgroundColor3", "TopBar")

	local miniStroke = Instance.new("UIStroke")
	miniStroke.Thickness = 0.5
	miniStroke.Transparency = 0.55
	miniStroke.Parent = mini
	bindColor(miniStroke, "Color", "Stroke")

	local miniBtn = Instance.new("TextButton")
	miniBtn.BackgroundTransparency = 1
	miniBtn.Size = UDim2.new(1,0,1,0)
	miniBtn.Font = FONT
	miniBtn.TextSize = 12
	miniBtn.Text = "Open UI"
	miniBtn.ZIndex = 101
	miniBtn.Parent = mini
	bindColor(miniBtn, "TextColor3", "Text")

	minBtn.MouseButton1Click:Connect(function()
		closeDropdown()
		shell.Visible = false
		mini.Visible = true
	end)
	miniBtn.MouseButton1Click:Connect(function()
		shell.Visible = true
		mini.Visible = false
	end)
	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Drag
	do
		local dragging, dragInput, dragStart, startPos
		local function updateDrag(input)
			local delta = input.Position - dragStart
			shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end

		top.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = shell.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)

		top.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if input == dragInput and dragging then updateDrag(input) end
		end)
	end

	-- default view: themes (until first section created)
	activeBtn = themesBtn
	refreshSectionButtons()
	showSection(themesSection)

	addRef(shell, function() refreshSectionButtons() end)
	return Window
end

return SimpleUILib
