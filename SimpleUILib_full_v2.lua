-- SimpleUILib (Full ModuleScript)
-- Popup notification system (bottom-right) + Section:AddNotification rules for Toggle/Button
-- Usage:
-- local SimpleUILib = loadstring(game:HttpGet("RAW_LINK"))()
-- local Window = SimpleUILib:MakeWindow({Title="Title"})
-- local Section = Window:AddSection({Name="Main"})
-- Section:AddToggle({Name="Auto", Default=false, Callback=function(v) end})
-- Section:AddNotification({HeadText="Enabled", Text="Auto ON\n...", When="On"})
-- Section:AddNotification({HeadText="Disabled", Text="Auto OFF\n...", When="Off"})

local SimpleUILib = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LP = Players.LocalPlayer

local function getParent()
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local function clamp(v,a,b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function addCorner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
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
		if pad then y += pad.PaddingTop.Offset + pad.PaddingBottom.Offset end
		sf.CanvasSize = UDim2.new(0,0,0,y + 4)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(recalc)
	recalc()
end

--========================
-- Layout constants
--========================
local CORNER = 6
local TOP_H  = 30
local ITEM_H = 24
local SPACING = 6
local LEFT_W = 150
local FONT = Enum.Font.Gotham
local CONTROL_CORNER = 4
local CONTROL_GAP = 12

-- dropdown menu
local DROPDOWN_MAX_VISIBLE = 5
local DROPDOWN_GAP_Y = 4
local DROPDOWN_BORDER = 1

-- popup notification sizing (small)
local POP_W = 240
local POP_HEAD_H = 20
local POP_BODY_H = 28
local POP_PAD = 8

--========================
-- Themes
--========================
local THEMES = {
	Carbon = {MainBg=Color3.fromRGB(34,34,34),TopBar=Color3.fromRGB(24,24,24),LeftBg=Color3.fromRGB(28,28,28),Text=Color3.fromRGB(240,240,240),BtnBg=Color3.fromRGB(45,45,45),BtnBg2=Color3.fromRGB(52,52,52),Stroke=Color3.fromRGB(140,140,140),Active=Color3.fromRGB(65,65,65),DimText=Color3.fromRGB(210,210,210)},
	Light  = {MainBg=Color3.fromRGB(245,245,245),TopBar=Color3.fromRGB(230,230,230),LeftBg=Color3.fromRGB(235,235,235),Text=Color3.fromRGB(25,25,25),BtnBg=Color3.fromRGB(220,220,220),BtnBg2=Color3.fromRGB(210,210,210),Stroke=Color3.fromRGB(120,120,120),Active=Color3.fromRGB(190,210,255),DimText=Color3.fromRGB(70,70,70)},
	Ocean  = {MainBg=Color3.fromRGB(20,28,38),TopBar=Color3.fromRGB(16,22,30),LeftBg=Color3.fromRGB(18,26,36),Text=Color3.fromRGB(230,245,255),BtnBg=Color3.fromRGB(30,44,60),BtnBg2=Color3.fromRGB(36,52,72),Stroke=Color3.fromRGB(90,140,170),Active=Color3.fromRGB(45,110,140),DimText=Color3.fromRGB(170,210,230)},
	Forest = {MainBg=Color3.fromRGB(24,34,28),TopBar=Color3.fromRGB(18,26,20),LeftBg=Color3.fromRGB(22,32,24),Text=Color3.fromRGB(235,245,235),BtnBg=Color3.fromRGB(38,54,40),BtnBg2=Color3.fromRGB(44,62,46),Stroke=Color3.fromRGB(120,150,120),Active=Color3.fromRGB(60,110,70),DimText=Color3.fromRGB(190,220,190)},
	Rose   = {MainBg=Color3.fromRGB(40,28,34),TopBar=Color3.fromRGB(32,20,26),LeftBg=Color3.fromRGB(36,24,30),Text=Color3.fromRGB(255,240,245),BtnBg=Color3.fromRGB(60,36,46),BtnBg2=Color3.fromRGB(72,42,54),Stroke=Color3.fromRGB(170,110,130),Active=Color3.fromRGB(150,60,90),DimText=Color3.fromRGB(230,190,200)},
	Violet = {MainBg=Color3.fromRGB(32,28,44),TopBar=Color3.fromRGB(24,20,34),LeftBg=Color3.fromRGB(28,24,40),Text=Color3.fromRGB(245,240,255),BtnBg=Color3.fromRGB(52,44,80),BtnBg2=Color3.fromRGB(60,50,92),Stroke=Color3.fromRGB(150,130,200),Active=Color3.fromRGB(110,80,180),DimText=Color3.fromRGB(215,205,235)},
	Amber  = {MainBg=Color3.fromRGB(44,34,24),TopBar=Color3.fromRGB(34,24,16),LeftBg=Color3.fromRGB(40,30,20),Text=Color3.fromRGB(255,245,230),BtnBg=Color3.fromRGB(70,52,32),BtnBg2=Color3.fromRGB(82,60,36),Stroke=Color3.fromRGB(200,160,90),Active=Color3.fromRGB(200,120,40),DimText=Color3.fromRGB(230,210,170)},
	Nord   = {MainBg=Color3.fromRGB(46,52,64),TopBar=Color3.fromRGB(59,66,82),LeftBg=Color3.fromRGB(53,59,74),Text=Color3.fromRGB(236,239,244),BtnBg=Color3.fromRGB(67,76,94),BtnBg2=Color3.fromRGB(76,86,106),Stroke=Color3.fromRGB(136,192,208),Active=Color3.fromRGB(129,161,193),DimText=Color3.fromRGB(216,222,233)},
	Neon   = {MainBg=Color3.fromRGB(18,18,18),TopBar=Color3.fromRGB(10,10,10),LeftBg=Color3.fromRGB(14,14,14),Text=Color3.fromRGB(240,240,240),BtnBg=Color3.fromRGB(30,30,30),BtnBg2=Color3.fromRGB(40,40,40),Stroke=Color3.fromRGB(120,120,120),Active=Color3.fromRGB(0,255,160),DimText=Color3.fromRGB(170,170,170)},
	Mono   = {MainBg=Color3.fromRGB(22,22,22),TopBar=Color3.fromRGB(16,16,16),LeftBg=Color3.fromRGB(19,19,19),Text=Color3.fromRGB(235,235,235),BtnBg=Color3.fromRGB(36,36,36),BtnBg2=Color3.fromRGB(48,48,48),Stroke=Color3.fromRGB(165,165,165),Active=Color3.fromRGB(90,90,90),DimText=Color3.fromRGB(205,205,205)},
	Sunset = {MainBg=Color3.fromRGB(44,26,24),TopBar=Color3.fromRGB(34,18,16),LeftBg=Color3.fromRGB(40,22,20),Text=Color3.fromRGB(255,242,235),BtnBg=Color3.fromRGB(66,34,30),BtnBg2=Color3.fromRGB(78,38,34),Stroke=Color3.fromRGB(220,150,120),Active=Color3.fromRGB(180,90,70),DimText=Color3.fromRGB(235,205,195)},
	Midnight={MainBg=Color3.fromRGB(16,18,26),TopBar=Color3.fromRGB(12,14,20),LeftBg=Color3.fromRGB(14,16,24),Text=Color3.fromRGB(235,240,255),BtnBg=Color3.fromRGB(26,30,44),BtnBg2=Color3.fromRGB(32,36,52),Stroke=Color3.fromRGB(120,140,200),Active=Color3.fromRGB(70,85,120),DimText=Color3.fromRGB(190,200,230)},
	Mint   ={MainBg=Color3.fromRGB(22,36,34),TopBar=Color3.fromRGB(16,28,26),LeftBg=Color3.fromRGB(20,32,30),Text=Color3.fromRGB(235,255,250),BtnBg=Color3.fromRGB(34,56,52),BtnBg2=Color3.fromRGB(40,64,60),Stroke=Color3.fromRGB(120,220,200),Active=Color3.fromRGB(60,110,100),DimText=Color3.fromRGB(190,235,225)},
}
local THEME_NAMES = {"Carbon","Light","Ocean","Forest","Rose","Violet","Amber","Nord","Neon","Mono","Sunset","Midnight","Mint"}

--========================
-- Main
--========================
function SimpleUILib:MakeWindow(cfg)
	cfg = cfg or {}
	local titleText = tostring(cfg.Title or "Title of the library")
	local themeName = tostring(cfg.Theme or "Carbon")
	if not THEMES[themeName] then themeName = "Carbon" end
	local THEME = THEMES[themeName]
	local DEFAULT_NOTIFY_DURATION = tonumber(cfg.NotificationDuration) or 5

	-- destroy previous
	pcall(function()
		local old = getParent():FindFirstChild("SimpleUILib_Window")
		if old then old:Destroy() end
	end)

	-- theme bindings
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
		themeName = name
		THEME = t

		for i = #binds, 1, -1 do
			local b = binds[i]
			if (not b.o) or (b.o.Parent == nil) then
				table.remove(binds, i)
			else
				local v = THEME[b.k]
				if v ~= nil then pcall(function() b.o[b.p] = v end) end
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
	gui.DisplayOrder = 9999
	gui.Parent = getParent()

	local shell = Instance.new("Frame")
	shell.Size = UDim2.new(0, 520, 0, 320)
	shell.Position = UDim2.new(0.5, -260, 0.5, -160)
	shell.BorderSizePixel = 0
	shell.Active = true
	shell.Parent = gui
	addCorner(shell, CORNER)
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
	addCorner(clip, CORNER)
	bindColor(clip, "BackgroundColor3", "MainBg")

	-- Overlay for dropdowns
	local overlay = Instance.new("Frame")
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1,0,1,0)
	overlay.ZIndex = 500
	overlay.Parent = gui

	--========================
	-- Popup notifications (bottom-right)
	--========================
	local notifyHolder = Instance.new("Frame")
	notifyHolder.Name = "PopupNotifications"
	notifyHolder.BackgroundTransparency = 1
	notifyHolder.Size = UDim2.new(1,0,1,0)
	notifyHolder.ZIndex = 100000
	notifyHolder.Parent = gui

	local notifyPad = Instance.new("UIPadding")
	notifyPad.PaddingRight = UDim.new(0, 14)
	notifyPad.PaddingBottom = UDim.new(0, 14)
	notifyPad.Parent = notifyHolder

	local notifyList = Instance.new("UIListLayout")
	notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifyList.Padding = UDim.new(0, 8)
	notifyList.Parent = notifyHolder

	local function popupNotify(spec)
		spec = spec or {}
		local headText = tostring(spec.HeadText or "Notification")
		local bodyText = tostring(spec.Text or "")
		local duration = (spec.Duration ~= nil and tonumber(spec.Duration)) or DEFAULT_NOTIFY_DURATION

		local totalH = POP_HEAD_H + 6 + POP_BODY_H + POP_PAD*2

		local box = Instance.new("Frame")
		box.AnchorPoint = Vector2.new(1,1)
		box.Size = UDim2.new(0, POP_W, 0, totalH)
		box.Position = UDim2.new(1, 30, 1, -12)
		box.BorderSizePixel = 0
		box.BackgroundTransparency = 1
		box.ClipsDescendants = true
		box.ZIndex = 100001
		box.Parent = notifyHolder
		addCorner(box, 7)
		bindColor(box, "BackgroundColor3", "BtnBg")

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Transparency = 1
		stroke.Parent = box
		bindColor(stroke, "Color", "Stroke")

		local inner = Instance.new("Frame")
		inner.BackgroundTransparency = 1
		inner.Position = UDim2.new(0, POP_PAD, 0, POP_PAD)
		inner.Size = UDim2.new(1, -POP_PAD*2, 1, -POP_PAD*2)
		inner.ZIndex = 100002
		inner.Parent = box

		local head = Instance.new("TextLabel")
		head.BackgroundTransparency = 1
		head.Size = UDim2.new(1,0,0,POP_HEAD_H)
		head.Font = Enum.Font.GothamBold
		head.TextSize = 13
		head.TextXAlignment = Enum.TextXAlignment.Left
		head.TextYAlignment = Enum.TextYAlignment.Center
		head.Text = headText
		head.ZIndex = 100003
		head.Parent = inner
		bindColor(head, "TextColor3", "Text")

		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.new(0,0,0,POP_HEAD_H + 6)
		body.Size = UDim2.new(1,0,0,POP_BODY_H)
		body.Font = FONT
		body.TextSize = 11
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Text = bodyText
		body.ZIndex = 100003
		body.Parent = inner
		bindColor(body, "TextColor3", "DimText")

		TweenService:Create(box, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -12, 1, -12),
			BackgroundTransparency = 0
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.4
		}):Play()

		task.delay(duration, function()
			local out = TweenService:Create(box, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 30, 1, -12),
				BackgroundTransparency = 1
			})
			local outS = TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
			out:Play()
			outS:Play()
			out.Completed:Connect(function()
				if box and box.Parent then box:Destroy() end
			end)
		end)
	end

	--========================
	-- Topbar
	--========================
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1,0,0,TOP_H)
	top.BorderSizePixel = 0
	top.ZIndex = 5
	top.Parent = clip
	addCorner(top, CORNER)
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
		addCorner(b, CONTROL_CORNER)
		bindColor(b, "BackgroundColor3", "BtnBg")
		bindColor(b, "TextColor3", "Text")
		return b
	end

	local minBtn = makeTopBtn("-", 10)
	local closeBtn = makeTopBtn("X", 40)

	--========================
	-- Body split
	--========================
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0,0,0,TOP_H)
	body.Size = UDim2.new(1,0,1,-TOP_H)
	body.Parent = clip

	local left = Instance.new("Frame")
	left.BorderSizePixel = 0
	left.Size = UDim2.new(0, LEFT_W, 1, 0)
	left.Parent = body
	addCorner(left, CORNER)
	bindColor(left, "BackgroundColor3", "LeftBg")

	local right = Instance.new("Frame")
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(0, LEFT_W, 0, 0)
	right.Size = UDim2.new(1, -LEFT_W, 1, 0)
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

	--========================
	-- Dropdown manager
	--========================
	local openDrop = nil
	local followConn = nil
	local function closeDropdown()
		if openDrop then
			if openDrop.menu and openDrop.menu.Parent then openDrop.menu:Destroy() end
			if openDrop.blocker and openDrop.blocker.Parent then openDrop.blocker:Destroy() end
			openDrop = nil
		end
		if followConn then followConn:Disconnect(); followConn=nil end
	end

	--========================
	-- Slider drag global
	--========================
	local sliderDrag = nil
	local sliderMouseConn = nil
	local function stopSliderDrag()
		sliderDrag = nil
		if sliderMouseConn then sliderMouseConn:Disconnect(); sliderMouseConn=nil end
		pcall(function() content.ScrollingEnabled = true end)
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

	--========================
	-- Helpers for rows
	--========================
	local function makeRow(h)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1,0,0,h or ITEM_H)
		row.ZIndex = 16
		row.Parent = content
		return row
	end

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

	--========================
	-- Renderers
	--========================
	local function renderLabel(it)
		local row = makeRow((ITEM_H*2)+2)
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
		pad.PaddingLeft = UDim.new(0,8)
		pad.PaddingRight = UDim.new(0,8)
		pad.PaddingTop = UDim.new(0,4)
		pad.PaddingBottom = UDim.new(0,4)
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
		lbl.Text = tostring(it.Text or "")
		lbl.ZIndex = row.ZIndex + 1
		lbl.Parent = box

		lbl.TextTransparency = it.Transparency ~= nil and clamp(it.Transparency,0,1) or 0.15
		if it.Color then lbl.TextColor3 = it.Color else bindColor(lbl, "TextColor3", "DimText") end
	end

	local function renderHeadText(it)
		local text = tostring(it.Text or "-----")
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

		lbl.TextTransparency = it.Transparency ~= nil and clamp(it.Transparency,0,1) or 0
		if it.Color then lbl.TextColor3 = it.Color else bindColor(lbl, "TextColor3", "Text") end

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
			local labelW = clamp(math.floor(tSize.X + 18), 60, math.floor(rowW*0.6))

			lbl.Size = UDim2.new(0,labelW,1,0)
			lbl.Position = UDim2.new(0.5,-labelW/2,0,0)

			local gap = 8
			local sideW = math.max(0, math.floor(rowW/2 - labelW/2 - gap))
			lineL.Size = UDim2.new(0, sideW, 0, 1)
			lineL.Position = UDim2.new(0, 0, 0.5, 0)
			lineR.Size = UDim2.new(0, sideW, 0, 1)
			lineR.Position = UDim2.new(1, -sideW, 0.5, 0)
		end)
	end

	local function renderTextbox(it)
		local boxW = 160
		local row = makeRow(ITEM_H)
		makeLeftLabel(row, it.Name or "Textbox", boxW)

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
		tb.ClearTextOnFocus = it.ClearTextOnFocus == true
		tb.PlaceholderText = it.Placeholder or "Type..."
		tb.ZIndex = row.ZIndex + 2
		tb.Parent = frame
		bindColor(tb, "TextColor3", "Text")
		bindColor(tb, "PlaceholderColor3", "DimText")

		tb.Text = tostring(it.Value or "")
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			it.Value = tb.Text
		end)
		tb.FocusLost:Connect(function(enter)
			it.Value = tb.Text
			if type(it.Callback) == "function" then pcall(it.Callback, tb.Text, enter) end
		end)
	end

	local function renderButton(it, registerKeybindFn)
		local row = makeRow(ITEM_H)
		makeLeftLabelWithKeybind(row, it.Name or "Button", 78, it.Keybind or "")

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 78, 0, ITEM_H)
		btn.Position = UDim2.new(1, -78, 0, 0)
		btn.BorderSizePixel = 0
		btn.Font = FONT
		btn.TextSize = 11
		btn.Text = "Button"
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")
		bindColor(btn, "TextColor3", "Text")

		local function fireClickRules()
			if it._notifyRules then
				for _, r in ipairs(it._notifyRules) do
					local w = tostring(r.When or "Click")
					if w == "Click" or w == "Both" then
						popupNotify({HeadText=r.HeadText, Text=r.Text, Duration=r.Duration})
					end
				end
			end
		end

		local function run()
			if type(it.Callback) == "function" then pcall(it.Callback) end
			fireClickRules()
		end

		btn.MouseButton1Click:Connect(run)

		if it.Keybind and it.Keybind ~= "" then
			registerKeybindFn(it.Keybind, run)
		end
	end

	local function renderToggle(it, registerKeybindFn)
		local W = 56
		local row = makeRow(ITEM_H)
		makeLeftLabelWithKeybind(row, it.Name or "Toggle", W, it.Keybind or "")

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, W, 0, ITEM_H)
		btn.Position = UDim2.new(1, -W, 0, 0)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")

		local state = (it.Value ~= nil) and (it.Value == true) or (it.Default == true)
		it.Value = state

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

			if instant then
				knob.Position = knobGoal
			else
				TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = knobGoal}):Play()
			end
		end

		local function fireToggleRules()
			if it._notifyRules then
				for _, r in ipairs(it._notifyRules) do
					local w = tostring(r.When or "Both")
					if w == "Both" or (w == "On" and state == true) or (w == "Off" and state == false) then
						popupNotify({HeadText=r.HeadText, Text=r.Text, Duration=r.Duration})
					end
				end
			end
		end

		local function toggle()
			state = not state
			it.Value = state
			render(false)
			if type(it.Callback) == "function" then pcall(it.Callback, state) end
			fireToggleRules()
		end

		btn.MouseButton1Click:Connect(toggle)
		if it.Keybind and it.Keybind ~= "" then registerKeybindFn(it.Keybind, toggle) end

		render(true)
	end

	local function renderSlider(it)
		local minV = it.Min or 0
		local maxV = it.Max or 100
		local step = it.Increment or 1

		if it.Value == nil then it.Value = (it.Default ~= nil) and it.Default or minV end
		local value = it.Value

		local totalW = 170
		local valueW = 48
		local gap = 6
		local barW = totalW - valueW - gap

		local row = makeRow(ITEM_H)
		makeLeftLabel(row, it.Name or "Slider", totalW)

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
		valText.TextXAlignment = Enum.TextXAlignment.Center
		valText.TextYAlignment = Enum.TextYAlignment.Center
		valText.ZIndex = row.ZIndex + 3
		valText.Parent = valBox
		bindColor(valText, "TextColor3", "Text")

		local function updateText()
			if it.ValueName and it.ValueName ~= "" then
				valText.Text = tostring(value).." "..tostring(it.ValueName)
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

		-- bigger invisible hit zone
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
			v = clamp(math.floor((v/step) + 0.5) * step, minV, maxV)
			value = v
			it.Value = value
			updateText()

			local ratio = (value - minV) / (maxV - minV)
			ratio = clamp(ratio, 0, 1)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knobHit.Position = UDim2.new(ratio, -HIT/2, 0.5, -HIT/2)

			if call and type(it.Callback) == "function" then pcall(it.Callback, value) end
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
			pcall(function() content.ScrollingEnabled = false end)
			if input.UserInputType == Enum.UserInputType.Touch then
				sliderDrag = {mode="touch", setFromX=setFromX}
				setFromX(input.Position.X)
			else
				sliderDrag = {mode="mouse", setFromX=setFromX}
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

	local function renderDropdown(it)
		local options = it.Options or {}
		if it.Value == nil or it.Value == "" then
			it.Value = it.Default or options[1] or ""
		end

		local selected = it.Value
		local controlW = 140
		local row = makeRow(ITEM_H)
		makeLeftLabel(row, it.Name or "Dropdown", controlW)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, controlW, 0, ITEM_H)
		btn.Position = UDim2.new(1, -controlW, 0, 0)
		btn.BorderSizePixel = 0
		btn.Font = FONT
		btn.TextSize = 11
		btn.TextYAlignment = Enum.TextYAlignment.Center
		btn.Text = tostring(selected).."  v"
		btn.ZIndex = row.ZIndex + 1
		btn.Parent = row
		addCorner(btn, CONTROL_CORNER)
		bindColor(btn, "BackgroundColor3", "BtnBg2")
		bindColor(btn, "TextColor3", "Text")

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

			local pad2 = Instance.new("UIPadding")
			pad2.PaddingRight = UDim.new(0, list.ScrollBarThickness + 2)
			pad2.Parent = list

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
					it.Value = opt
					it.Default = opt
					btn.Text = tostring(selected).."  v"
					closeDropdown()
					if type(it.Callback) == "function" then pcall(it.Callback, selected) end
				end)
			end

			blocker.MouseButton1Click:Connect(closeDropdown)

			local function updatePos()
				if not btn.Parent or not outer.Parent then closeDropdown() return end
				local nx,ny = compute()
				outer.Position = UDim2.fromOffset(nx,ny)
			end
			updatePos()
			followConn = RunService.RenderStepped:Connect(updatePos)

			openDrop = {blocker=blocker, menu=outer}
		end

		btn.MouseButton1Click:Connect(function()
			if openDrop then closeDropdown() else openMenu() end
		end)
	end

	--========================
	-- Sections / items
	--========================
	local sections = {}
	local sectionButtons = {}
	local activeSection = nil
	local activeBtn = nil
	local hasUserSection = false

	local function refreshSectionButtons()
		for _, b in ipairs(sectionButtons) do
			if b and b.Parent then
				b.BackgroundColor3 = (b == activeBtn) and THEME.Active or THEME.BtnBg
			end
		end
	end

	local function showSection(sec, registerKeybindFn)
		closeDropdown()
		clearContent()
		activeSection = sec

		for _, it in ipairs(sec.Items) do
			if it.Type == "Label" then
				renderLabel(it)
			elseif it.Type == "HeadText" then
				renderHeadText(it)
			elseif it.Type == "Textbox" then
				renderTextbox(it)
			elseif it.Type == "Button" then
				renderButton(it, registerKeybindFn)
			elseif it.Type == "Toggle" then
				renderToggle(it, registerKeybindFn)
			elseif it.Type == "Slider" then
				renderSlider(it)
			elseif it.Type == "Dropdown" then
				renderDropdown(it)
			end
			-- NotificationRule not rendered (popup rules only)
		end
	end

	local function createSectionButton(name, order)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,ITEM_H)
		b.BorderSizePixel = 0
		b.Font = FONT
		b.TextSize = 12
		b.TextYAlignment = Enum.TextYAlignment.Center
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.Text = "  "..tostring(name)
		b.LayoutOrder = order
		b.ZIndex = 20
		b.Parent = secList
		addCorner(b, CONTROL_CORNER)
		bindColor(b, "TextColor3", "Text")
		b.BackgroundColor3 = THEME.BtnBg
		table.insert(sectionButtons, b)
		return b
	end

	-- Themes section always last (normal)
	local themesSection = {
		Name = "Themes",
		Items = {
			{Type="Dropdown", Name="Theme", Options=THEME_NAMES, Default=themeName, Value=themeName, Callback=function(name) applyTheme(name) end}
		}
	}

	local themesBtn = createSectionButton("Themes", 999999)
	table.insert(sections, themesSection)

	local Window = {}

	function Window:Notify(spec) popupNotify(spec) end
	function Window:SetTheme(name) applyTheme(name) end
	function Window:SetNotificationDuration(seconds)
		DEFAULT_NOTIFY_DURATION = tonumber(seconds) or DEFAULT_NOTIFY_DURATION
	end
	function Window:Destroy() closeDropdown(); gui:Destroy() end

	themesBtn.MouseButton1Click:Connect(function()
		activeBtn = themesBtn
		refreshSectionButtons()
		showSection(themesSection, registerKeybind)
	end)

	function Window:AddSection(cfg2)
		cfg2 = cfg2 or {}
		local name = tostring(cfg2.Name or "Section")
		local sec = {Name=name, Items={}}
		table.insert(sections, #sections, sec) -- before themes
		local order = #sections - 1

		local btn = createSectionButton(name, order)
		themesBtn.LayoutOrder = 999999

		btn.MouseButton1Click:Connect(function()
			activeBtn = btn
			refreshSectionButtons()
			showSection(sec, registerKeybind)
		end)

		if not hasUserSection then
			hasUserSection = true
			activeBtn = btn
			refreshSectionButtons()
			showSection(sec, registerKeybind)
		else
			refreshSectionButtons()
		end

		local lastInteractive = nil

		local Section = {}

		function Section:AddButton(spec)
			spec = spec or {}
			local item = {Type="Button", Name=spec.Name or "Button", Callback=spec.Callback, Keybind=tostring(spec.Keybind or ""), _notifyRules={}}
			table.insert(sec.Items, item)
			lastInteractive = item
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddToggle(spec)
			spec = spec or {}
			local def = spec.Default == true
			local item = {Type="Toggle", Name=spec.Name or "Toggle", Default=def, Value=def, Callback=spec.Callback, Keybind=tostring(spec.Keybind or ""), _notifyRules={}}
			table.insert(sec.Items, item)
			lastInteractive = item
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddSlider(spec)
			spec = spec or {}
			local minV = spec.Min or 0
			local def = spec.Default
			if def == nil then def = minV end
			local item = {Type="Slider", Name=spec.Name or "Slider", Min=minV, Max=spec.Max or 100, Default=def, Value=def, Increment=spec.Increment or 1, ValueName=spec.ValueName, Callback=spec.Callback}
			table.insert(sec.Items, item)
			lastInteractive = item
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddTextbox(spec)
			spec = spec or {}
			local def = spec.Default or ""
			local item = {Type="Textbox", Name=spec.Name or "Textbox", Default=def, Value=def, Placeholder=spec.Placeholder or "Type...", ClearTextOnFocus=spec.ClearTextOnFocus==true, Callback=spec.Callback}
			table.insert(sec.Items, item)
			lastInteractive = item
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddDropDown(spec)
			spec = spec or {}
			local def = spec.Default
			if def == nil and spec.Options and spec.Options[1] ~= nil then def = spec.Options[1] end
			local item = {Type="Dropdown", Name=spec.Name or "Dropdown", Options=spec.Options or {}, Default=def, Value=def, Callback=spec.Callback}
			table.insert(sec.Items, item)
			lastInteractive = item
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddLabel(spec)
			spec = spec or {}
			local item = {Type="Label", Text=spec.Text or "", Color=spec.Color, Transparency=spec.Transparency}
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		function Section:AddHeadText(spec)
			spec = spec or {}
			local item = {Type="HeadText", Text=spec.Text or "-----", Color=spec.Color, Transparency=spec.Transparency}
			table.insert(sec.Items, item)
			if activeSection == sec then showSection(sec, registerKeybind) end
			return item
		end

		-- KeyBind modifies lastInteractive but does NOT become lastInteractive itself
		function Section:AddKeyBind(spec)
			spec = spec or {}
			local key = tostring(spec.Default or "")
			if key == "" then return nil end
			if not lastInteractive then return nil end
			lastInteractive.Keybind = key
			if type(spec.Callback) == "function" then
				lastInteractive.Callback = spec.Callback
			end
			if activeSection == sec then showSection(sec, registerKeybind) end
			return true
		end

		-- Popup notification rule; does NOT become lastInteractive
		-- Toggle: When = "On"|"Off"|"Both"
		-- Button: When = "Click"|"Both"
		function Section:AddNotification(spec)
			spec = spec or {}
			if not lastInteractive then return nil end

			local rule = {
				Type="NotificationRule",
				HeadText=tostring(spec.HeadText or "Notification"),
				Text=tostring(spec.Text or ""),
				Duration=(spec.Duration ~= nil and tonumber(spec.Duration)) or DEFAULT_NOTIFY_DURATION,
			}

			if lastInteractive.Type == "Toggle" then
				rule.When = tostring(spec.When or "Both")
				table.insert(lastInteractive._notifyRules, rule)
			elseif lastInteractive.Type == "Button" then
				rule.When = tostring(spec.When or "Click")
				table.insert(lastInteractive._notifyRules, rule)
			else
				-- other types: show once immediately unless disabled
				rule.When = "Now"
				if spec.ShowNow ~= false then
					popupNotify({HeadText=rule.HeadText, Text=rule.Text, Duration=rule.Duration})
				end
			end

			table.insert(sec.Items, rule) -- stored but not rendered
			return rule
		end

		return Section
	end

	--========================
	-- Minimize / close
	--========================
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

	-- Drag window
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

	-- initial view: Themes until first user section created; first user section auto-opens on AddSection
	activeBtn = themesBtn
	refreshSectionButtons()
	showSection(themesSection, registerKeybind)

	addRef(shell, function() refreshSectionButtons() end)

	return Window
end

return SimpleUILib
