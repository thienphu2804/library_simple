local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SimpleLib = {}
SimpleLib.__index = SimpleLib

local COLORS = {
	background = Color3.fromRGB(16, 18, 24),
	panel = Color3.fromRGB(22, 25, 33),
	surface = Color3.fromRGB(29, 33, 43),
	surfaceHover = Color3.fromRGB(37, 42, 54),
	accent = Color3.fromRGB(144, 117, 255),
	text = Color3.fromRGB(242, 243, 248),
	muted = Color3.fromRGB(145, 151, 167),
	border = Color3.fromRGB(47, 52, 66),
}

local function create(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function addCorner(parent, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, parent)
end

local function addPadding(parent, left, top, right, bottom)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
	}, parent)
end

local function tween(object, duration, properties)
	local animation = TweenService:Create(
		object,
		TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		properties
	)
	animation:Play()
	return animation
end

local function playSound(window, soundName)
	local sound = window._sounds[soundName]
	local now = os.clock()
	if not sound or now - (window._lastSoundAt[soundName] or 0) < 0.04 then
		return
	end
	window._lastSoundAt[soundName] = now
	sound:Stop()
	sound.TimePosition = 0
	sound:Play()
end

function SimpleLib:win(options)
	options = options or {}

	local player = Players.LocalPlayer
	assert(player, "Simple Lib must be used from a LocalScript")

	local screenGui = create("ScreenGui", {
		Name = "SimpleLib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))

	local requestedSize = options.size or UDim2.fromOffset(560, 420)
	local window = setmetatable({
		_screenGui = screenGui,
		_tabs = {},
		_buttons = 0,
		_loadingOptions = options.loading,
		_loadingStartedAt = os.clock(),
		_loadingFinished = false,
		_loadingProgress = 0.12,
		_minimized = false,
		_interaction = nil,
		_connections = {},
		_sounds = {},
		_lastSoundAt = {},
	}, self)

	for soundName, assetId in pairs({
		button = "9113744905",
		dropdown = "9114083230",
	}) do
		window._sounds[soundName] = create("Sound", {
			Name = "SimpleLib_" .. soundName,
			SoundId = "rbxassetid://" .. assetId,
			Volume = 0.35,
		}, SoundService)
	end

	local main = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = requestedSize,
		BackgroundColor3 = COLORS.background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, screenGui)
	window._main = main
	addCorner(main, 14)
	create("UIStroke", {
		Color = COLORS.border,
		Transparency = 0.18,
		Thickness = 1,
	}, main)

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
	}, main)
	window._header = header

	local title = create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(22, 14),
		Size = UDim2.new(1, -112, 0, 27),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = options.title or "Simple Lib",
		TextColor3 = COLORS.text,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	window._title = title

	create("TextLabel", {
		Name = "Description",
		Position = UDim2.fromOffset(23, 42),
		Size = UDim2.new(1, -112, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = options.desc or "A clean space for your tools",
		TextColor3 = COLORS.muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)

	local minimizeButton = create("TextButton", {
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "-",
		TextColor3 = COLORS.text,
		TextSize = 20,
	}, header)
	addCorner(minimizeButton, 10)
	minimizeButton.MouseEnter:Connect(function()
		tween(minimizeButton, 0.15, { BackgroundColor3 = COLORS.surfaceHover })
	end)
	minimizeButton.MouseLeave:Connect(function()
		tween(minimizeButton, 0.15, { BackgroundColor3 = COLORS.surface })
	end)

	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 76),
		Size = UDim2.new(1, 0, 1, -76),
		BackgroundTransparency = 1,
	}, main)
	window._body = body

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 142, 1, 0),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
	}, body)
	addPadding(sidebar, 10, 13, 10, 12)
	create("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	window._sidebar = sidebar

	local pages = create("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 142, 0, 0),
		Size = UDim2.new(1, -142, 1, 0),
		BackgroundTransparency = 1,
	}, body)
	window._pages = pages

	local resizeGrip = create("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		Text = "◢",
		TextColor3 = COLORS.muted,
		TextSize = 12,
	}, main)

	local interaction = window._interaction
	local dragStart
	local startPosition
	local startSize
	local activeInput

	local function beginInteraction(mode, input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		interaction = mode
		window._interaction = mode
		dragStart = input.Position
		startPosition = main.Position
		startSize = main.AbsoluteSize
		activeInput = input
	end

	header.InputBegan:Connect(function(input)
		beginInteraction("drag", input)
	end)

	resizeGrip.InputBegan:Connect(function(input)
		if not window._minimized then
			beginInteraction("resize", input)
		end
	end)

	table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
		local isPointerMovement = input.UserInputType == Enum.UserInputType.MouseMovement
			or input == activeInput
		if not interaction or not isPointerMovement then
			return
		end

		local delta = input.Position - dragStart
		if interaction == "drag" then
			main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		elseif interaction == "resize" then
			local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
			local maxWidth = viewport and math.max(360, math.min(1200, viewport.X - 24)) or 1200
			local maxHeight = viewport and math.max(280, math.min(900, viewport.Y - 24)) or 900
			local width = math.clamp(startSize.X + delta.X, 360, maxWidth)
			local height = math.clamp(startSize.Y + delta.Y, 280, maxHeight)
			main.Size = UDim2.fromOffset(width, height)
		end
	end))

	table.insert(window._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input == activeInput then
			interaction = nil
			window._interaction = nil
			activeInput = nil
		end
	end))

	local restoreSize = requestedSize
	minimizeButton.Activated:Connect(function()
		if window._minimized then
			window._minimized = false
			body.Visible = true
			resizeGrip.Visible = true
			minimizeButton.Text = "-"
			tween(main, 0.22, { Size = restoreSize })
		else
			restoreSize = main.Size
			window._minimized = true
			body.Visible = false
			resizeGrip.Visible = false
			minimizeButton.Text = "+"
			tween(main, 0.22, { Size = UDim2.new(restoreSize.X.Scale, restoreSize.X.Offset, 0, 76) })
		end
	end)

	if window._loadingOptions then
		local loading = window._loadingOptions
		local overlay = create("Frame", {
			Name = "LoadingOverlay",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = COLORS.background,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, main)
		addCorner(overlay, 14)
		window._loadingOverlay = overlay

		local loadingTitle = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.42, 0),
			Size = UDim2.new(1, -64, 0, 30),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = loading.title or "Loading Simple Lib",
			TextColor3 = COLORS.text,
			TextSize = 18,
			TextWrapped = true,
			ZIndex = 11,
		}, overlay)

		create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.51, 0),
			Size = UDim2.new(1, -72, 0, 42),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = loading.desc or "Preparing your interface...",
			TextColor3 = COLORS.muted,
			TextSize = 12,
			TextWrapped = true,
			ZIndex = 11,
		}, overlay)

		local progressTrack = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.64, 0),
			Size = UDim2.new(1, -72, 0, 6),
			BackgroundColor3 = COLORS.surface,
			BorderSizePixel = 0,
			ZIndex = 11,
		}, overlay)
		addCorner(progressTrack, 4)

		local progressFill = create("Frame", {
			Name = "Progress",
			Size = UDim2.new(window._loadingProgress, 0, 1, 0),
			BackgroundColor3 = COLORS.accent,
			BorderSizePixel = 0,
			ZIndex = 12,
		}, progressTrack)
		addCorner(progressFill, 4)
		window._progressFill = progressFill

		create("TextLabel", {
			Name = "LoadingStatus",
			Position = UDim2.new(0, 36, 0.64, 11),
			Size = UDim2.new(1, -72, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = "Building interface",
			TextColor3 = COLORS.muted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 11,
		}, overlay)
		if loading.autoFinish ~= false then
			task.defer(function()
				window:finishLoading()
			end)
		end
	end

	return window
end

function SimpleLib:_updateLoadingProgress()
	if not self._progressFill or self._loadingFinished then
		return
	end

	self._loadingProgress = math.min(0.16 + (self._buttons * 0.07), 0.88)
	tween(self._progressFill, 0.2, {
		Size = UDim2.new(self._loadingProgress, 0, 1, 0),
	})
end

function SimpleLib:finishLoading()
	if not self._loadingOverlay or self._loadingFinished then
		return
	end

	self._loadingFinished = true
	local loadingOptions = self._loadingOptions
	local minimumDuration = loadingOptions.minDuration
	if minimumDuration == nil then
		minimumDuration = 3
	end

	task.spawn(function()
		local remaining = minimumDuration - (os.clock() - self._loadingStartedAt)
		if remaining > 0 then
			task.wait(remaining)
		end
		if not self._loadingOverlay or not self._loadingOverlay.Parent then
			return
		end

		tween(self._progressFill, 0.28, {
			Size = UDim2.new(1, 0, 1, 0),
		})
		task.wait(0.3)
		tween(self._loadingOverlay, 0.22, {
			BackgroundTransparency = 1,
		})
		for _, child in ipairs(self._loadingOverlay:GetDescendants()) do
			if child:IsA("GuiObject") then
				local properties = { BackgroundTransparency = 1 }
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					properties.TextTransparency = 1
				end
				tween(child, 0.18, properties)
			end
		end
		task.wait(0.23)
		if self._loadingOverlay and self._loadingOverlay.Parent then
			self._loadingOverlay:Destroy()
		end
		self._loadingOverlay = nil
	end)
end

function SimpleLib:tab(options)
	if type(options) == "string" then
		options = { title = options }
	else
		options = options or {}
	end
	local tabIndex = #self._tabs + 1
	local tabTitle = options.title or options.Name or ("Tab " .. tabIndex)

	local tabButton = create("TextButton", {
		Name = "Tab_" .. tabIndex,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = tabTitle,
		TextColor3 = COLORS.muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = tabIndex,
	}, self._sidebar)
	addCorner(tabButton, 9)
	addPadding(tabButton, 12, 0, 8, 0)

	local page = create("ScrollingFrame", {
		Name = "Page_" .. tabIndex,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.accent,
		Visible = tabIndex == 1,
	}, self._pages)
	addPadding(page, 18, 18, 18, 18)
	local pageLayout = create("UIListLayout", {
		Padding = UDim.new(0, 17),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	local tab = setmetatable({
		_window = self,
		_button = tabButton,
		_page = page,
		_controls = {},
		_title = tabTitle,
	}, { __index = SimpleLib.Tab })
	table.insert(self._tabs, tab)

	local function selectTab()
		for _, existingTab in ipairs(self._tabs) do
			local selected = existingTab == tab
			existingTab._page.Visible = selected
			tween(existingTab._button, 0.15, {
				BackgroundColor3 = selected and COLORS.surface or COLORS.panel,
				TextColor3 = selected and COLORS.text or COLORS.muted,
			})
		end
	end
	tabButton.Activated:Connect(selectTab)
	if tabIndex == 1 then
		tabButton.BackgroundColor3 = COLORS.surface
		tabButton.TextColor3 = COLORS.text
	end

	pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 36)
	end)
	return tab
end

SimpleLib.Tab = {}

local function createControlCard(tab, options, kind, accessoryWidth)
	options = options or {}
	local window = tab._window
	local controlIndex = #tab._controls + 1
	window._buttons = window._buttons + 1

	local card = create(kind == "button" and "TextButton" or "Frame", {
		Name = kind .. "_" .. controlIndex,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = controlIndex,
	}, tab._page)
	addCorner(card, 10)
	addPadding(card, 13, 10, 13, 10)
	create("UIStroke", {
		Color = COLORS.border,
		Transparency = 0.45,
		Thickness = 1,
	}, card)
	create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	local row = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, card)
	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -(accessoryWidth or 0), 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Text = options.title or options.Name or kind,
		TextColor3 = COLORS.text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Active = false,
	}, row)
	local descriptionText = options.desc or options.Description or ""
	if descriptionText ~= "" then
		create("TextLabel", {
			Name = "Description",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = descriptionText,
			TextColor3 = COLORS.muted,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
			Active = false,
		}, card)
	end

	card.MouseEnter:Connect(function()
		tween(card, 0.14, { BackgroundColor3 = COLORS.surfaceHover })
	end)
	card.MouseLeave:Connect(function()
		tween(card, 0.14, { BackgroundColor3 = COLORS.surface })
	end)
	table.insert(tab._controls, card)
	window:_updateLoadingProgress()
	return card, row
end

function SimpleLib.Tab:button(options)
	options = options or {}
	local button = createControlCard(self, options, "Button")
	local callback = options.callback or options.Callback
	assert(callback == nil or type(callback) == "function", "button callback must be a function")
	button.Activated:Connect(function()
		playSound(self._window, "button")
		tween(button, 0.08, { BackgroundColor3 = COLORS.accent })
		task.delay(0.1, function()
			if button.Parent then
				tween(button, 0.16, { BackgroundColor3 = COLORS.surface })
			end
		end)
		if callback then
			callback()
		end
	end)
	return button
end

function SimpleLib.Tab:toggle(options)
	options = options or {}
	local value = options.default
	if value == nil then
		value = options.CurrentValue
	end
	if value == nil then
		value = options.Default
	end
	if value == nil then
		value = false
	end
	assert(type(value) == "boolean", "toggle default value must be a boolean")
	local callback = options.callback or options.Callback
	assert(callback == nil or type(callback) == "function", "toggle callback must be a function")

	local card, row = createControlCard(self, options, "Toggle", 52)
	local switch = create("TextButton", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = value and COLORS.accent or COLORS.border,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, row)
	addCorner(switch, 10)
	local knob = create("Frame", {
		Name = "Knob",
		Position = UDim2.fromOffset(value and 20 or 2, 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = COLORS.text,
		BorderSizePixel = 0,
		Active = false,
	}, switch)
	addCorner(knob, 8)

	local toggle = { _value = value, _instance = card }
	function toggle:Get()
		return self._value
	end
	function toggle:Set(newValue, shouldNotify)
		assert(type(newValue) == "boolean", "toggle value must be a boolean")
		self._value = newValue
		if self._switchTween then
			self._switchTween:Cancel()
		end
		if self._knobTween then
			self._knobTween:Cancel()
		end
		self._switchTween = tween(switch, 0.16, {
			BackgroundColor3 = newValue and COLORS.accent or COLORS.border,
		})
		self._knobTween = tween(knob, 0.16, {
			Position = UDim2.fromOffset(newValue and 20 or 2, 2),
		})
		if shouldNotify ~= false and callback then
			callback(newValue)
		end
	end
	function toggle:Destroy()
		if self._instance then
			self._instance:Destroy()
			self._instance = nil
		end
	end
	switch.Activated:Connect(function()
		playSound(self._window or card, "button")
		toggle:Set(not toggle._value)
	end)
	toggle._window = self._window
	return toggle
end

function SimpleLib.Tab:dropdown(options)
	options = options or {}
	local items = options.items or options.Items or options.options or options.Options or {}
	assert(type(items) == "table", "dropdown items must be a table")
	local values = {}
	for index, item in ipairs(items) do
		assert(type(item) == "string" or type(item) == "number", "dropdown items must be strings or numbers")
		values[index] = tostring(item)
	end
	local callback = options.callback or options.Callback
	assert(callback == nil or type(callback) == "function", "dropdown callback must be a function")
	local defaultValue = options.default
	if defaultValue == nil then
		defaultValue = options.CurrentOption
	end
	if defaultValue == nil then
		defaultValue = options.Default
	end
	if type(defaultValue) == "table" then
		defaultValue = defaultValue[1]
	end
	if defaultValue ~= nil then
		defaultValue = tostring(defaultValue)
		assert(table.find(values, defaultValue), "dropdown default must match one of its items")
	end
	local initiallyOpen = options.open
	if initiallyOpen == nil then
		initiallyOpen = options.Open
	end
	if initiallyOpen == nil then
		initiallyOpen = false
	end
	assert(type(initiallyOpen) == "boolean", "dropdown open option must be a boolean")

	local card, row = createControlCard(self, options, "Dropdown", 142)
	local selectedLabel = create("TextLabel", {
		Name = "SelectedValue",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -22, 0.5, 0),
		Size = UDim2.new(0, 112, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = defaultValue or "Chọn...",
		TextColor3 = defaultValue and COLORS.text or COLORS.muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Active = false,
	}, row)
	local arrow = create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = initiallyOpen and "⌃" or "⌄",
		TextColor3 = COLORS.muted,
		TextSize = 16,
		Active = false,
	}, row)
	local optionsList = create("Frame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ClipsDescendants = true,
		LayoutOrder = 3,
	}, card)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, optionsList)

	local dropdown = {
		_window = self._window,
		_value = defaultValue,
		_options = values,
		_instance = card,
		_open = false,
		_animation = nil,
	}
	function dropdown:Get()
		return self._value
	end
	function dropdown:Set(value, shouldNotify)
		if type(value) == "table" then
			value = value[1]
		end
		if value ~= nil then
			value = tostring(value)
			assert(table.find(self._options, value), "dropdown value must match one of its items")
		end
		self._value = value
		selectedLabel.Text = value or "Chọn..."
		selectedLabel.TextColor3 = value and COLORS.text or COLORS.muted
		if shouldNotify ~= false and callback then
			callback(value, value and table.find(self._options, value) or nil)
		end
	end
	function dropdown:SetOpen(isOpen)
		assert(type(isOpen) == "boolean", "dropdown open state must be a boolean")
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		self._open = isOpen
		optionsList.Visible = true
		arrow.Text = isOpen and "⌃" or "⌄"
		playSound(self._window, "dropdown")
		local height = isOpen and (#self._options * 30 + math.max(0, #self._options - 1) * 4) or 0
		local animation = tween(optionsList, 0.2, { Size = UDim2.new(1, 0, 0, height) })
		self._animation = animation
		animation.Completed:Connect(function(state)
			if self._animation ~= animation then
				return
			end
			self._animation = nil
			if state == Enum.PlaybackState.Completed and not self._open then
				optionsList.Visible = false
			end
		end)
	end
	function dropdown:SetOptions(newItems)
		assert(type(newItems) == "table", "dropdown options must be a table")
		local updatedOptions = {}
		for index, item in ipairs(newItems) do
			assert(type(item) == "string" or type(item) == "number", "dropdown items must be strings or numbers")
			updatedOptions[index] = tostring(item)
		end
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		self._options = updatedOptions
		if self._value and not table.find(updatedOptions, self._value) then
			self:Set(nil, false)
		end
		for _, child in ipairs(optionsList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for index, item in ipairs(self._options) do
			local optionButton = create("TextButton", {
				Name = "Option_" .. index,
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = COLORS.panel,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Font = Enum.Font.Gotham,
				Text = item,
				TextColor3 = COLORS.text,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = index,
			}, optionsList)
			addCorner(optionButton, 7)
			addPadding(optionButton, 10, 0, 10, 0)
			optionButton.Activated:Connect(function()
				self:Set(item)
				self:SetOpen(false)
			end)
		end
		if self._open then
			optionsList.Size = UDim2.new(1, 0, 0, 0)
			local animation = tween(optionsList, 0.2, {
				Size = UDim2.new(1, 0, 0, #self._options * 30 + math.max(0, #self._options - 1) * 4),
			})
			self._animation = animation
			animation.Completed:Connect(function()
				if self._animation == animation then
					self._animation = nil
				end
			end)
		end
	end
	function dropdown:Destroy()
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		if self._instance then
			self._instance:Destroy()
			self._instance = nil
		end
	end

	local rowButton = create("TextButton", {
		Name = "DropdownHeaderButton",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)
	rowButton.ZIndex = selectedLabel.ZIndex + 1
	selectedLabel.ZIndex = rowButton.ZIndex + 1
	arrow.ZIndex = rowButton.ZIndex + 1
	rowButton.Activated:Connect(function()
		dropdown:SetOpen(not dropdown._open)
	end)
	dropdown:SetOptions(values)
	if initiallyOpen then
		dropdown:SetOpen(true)
	end
	return dropdown
end

SimpleLib.Tab.btn = SimpleLib.Tab.button
SimpleLib.Tab.tog = SimpleLib.Tab.toggle
SimpleLib.Tab.dd = SimpleLib.Tab.dropdown
SimpleLib.Tab.CreateButton = SimpleLib.Tab.button
SimpleLib.Tab.CreateToggle = SimpleLib.Tab.toggle
SimpleLib.Tab.CreateDropdown = SimpleLib.Tab.dropdown
SimpleLib.window = SimpleLib.win
SimpleLib.CreateWindow = SimpleLib.win
SimpleLib.CreateTab = SimpleLib.tab

function SimpleLib:destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
	for _, sound in pairs(self._sounds) do
		sound:Destroy()
	end
	table.clear(self._sounds)
	self._loadingOverlay = nil
end

SimpleLib.Destroy = SimpleLib.destroy

return SimpleLib
