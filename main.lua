local Players = game:GetService("Players")
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

	local requestedSize = options.size or options.Size or UDim2.fromOffset(560, 420)
	local window = setmetatable({
		_screenGui = screenGui,
		_tabs = {},
		_sections = 0,
		_buttons = 0,
		_loadingOptions = options.loading,
		_loadingStartedAt = os.clock(),
		_loadingFinished = false,
		_loadingProgress = 0.12,
		_minimized = false,
		_confirmDialog = nil,
		_interaction = nil,
		_connections = {},
	}, self)

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
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, main)
	window._header = header
	create("Frame", {
		Name = "HeaderDivider",
		Position = UDim2.new(0, 20, 1, -1),
		Size = UDim2.new(1, -40, 0, 1),
		BackgroundColor3 = COLORS.border,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	}, header)

	local title = create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(22, 10),
		Size = UDim2.new(1, -154, 0, 25),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = options.title or options.Name or "Simple Lib",
		TextColor3 = COLORS.text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	window._title = title

	local description = create("TextLabel", {
		Name = "Description",
		Position = UDim2.fromOffset(23, 36),
		Size = UDim2.new(1, -154, 0, 17),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = options.desc or options.Description or "A clean space for your tools",
		TextColor3 = COLORS.muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	window._description = description

	local minimizeButton = create("TextButton", {
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -58, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "-",
		TextColor3 = COLORS.text,
		TextSize = 18,
	}, header)
	addCorner(minimizeButton, 9)
	minimizeButton.MouseEnter:Connect(function()
		tween(minimizeButton, 0.15, { BackgroundColor3 = COLORS.surfaceHover })
	end)
	minimizeButton.MouseLeave:Connect(function()
		tween(minimizeButton, 0.15, { BackgroundColor3 = COLORS.surface })
	end)

	local closeButton = create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "×",
		TextColor3 = COLORS.muted,
		TextSize = 20,
	}, header)
	addCorner(closeButton, 9)
	closeButton.MouseEnter:Connect(function()
		tween(closeButton, 0.15, {
			BackgroundColor3 = Color3.fromRGB(105, 48, 59),
			TextColor3 = COLORS.text,
		})
	end)
	closeButton.MouseLeave:Connect(function()
		tween(closeButton, 0.15, {
			BackgroundColor3 = COLORS.surface,
			TextColor3 = COLORS.muted,
		})
	end)

	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
	}, main)
	window._body = body

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 142, 1, 0),
		BackgroundTransparency = 1,
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
		Text = "",
	}, main)
	create("Frame", {
		Position = UDim2.new(1, -15, 1, -8),
		Size = UDim2.fromOffset(9, 2),
		Rotation = -45,
		BackgroundColor3 = COLORS.muted,
		BorderSizePixel = 0,
		Active = false,
	}, resizeGrip)
	create("Frame", {
		Position = UDim2.new(1, -9, 1, -8),
		Size = UDim2.fromOffset(5, 2),
		Rotation = -45,
		BackgroundColor3 = COLORS.muted,
		BorderSizePixel = 0,
		Active = false,
	}, resizeGrip)

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
			description.Visible = true
			minimizeButton.Text = "-"
			tween(main, 0.22, { Size = restoreSize })
		else
			restoreSize = main.Size
			window._minimized = true
			body.Visible = false
			resizeGrip.Visible = false
			description.Visible = false
			minimizeButton.Text = "+"
			tween(main, 0.22, { Size = UDim2.new(restoreSize.X.Scale, restoreSize.X.Offset, 0, 54) })
		end
	end)

	closeButton.Activated:Connect(function()
		if window._confirmDialog then
			return
		end

		local dialogOverlay = create("Frame", {
			Name = "ConfirmCloseOverlay",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(5, 6, 9),
			BackgroundTransparency = 0.32,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 20,
		}, main)
		addCorner(dialogOverlay, 13)
		window._confirmDialog = dialogOverlay

		local dialog = create("Frame", {
			Name = "Dialog",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(310, 158),
			BackgroundColor3 = COLORS.panel,
			BorderSizePixel = 0,
			ZIndex = 21,
		}, dialogOverlay)
		addCorner(dialog, 13)
		create("UIStroke", {
			Color = COLORS.border,
			Transparency = 0.1,
			Thickness = 1,
		}, dialog)

		create("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(20, 18),
			Size = UDim2.new(1, -40, 0, 23),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Text = "Đóng menu?",
			TextColor3 = COLORS.text,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 22,
		}, dialog)

		create("TextLabel", {
			Name = "Description",
			Position = UDim2.fromOffset(20, 47),
			Size = UDim2.new(1, -40, 0, 38),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = "Bạn có muốn gỡ menu khỏi màn hình không?",
			TextColor3 = COLORS.muted,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 22,
		}, dialog)

		local cancelButton = create("TextButton", {
			Name = "Cancel",
			Position = UDim2.new(0, 20, 1, -48),
			Size = UDim2.new(0.5, -26, 0, 32),
			BackgroundColor3 = COLORS.surface,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = "Hủy",
			TextColor3 = COLORS.text,
			TextSize = 12,
			ZIndex = 22,
		}, dialog)
		addCorner(cancelButton, 8)

		local confirmButton = create("TextButton", {
			Name = "Confirm",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20, 1, -48),
			Size = UDim2.new(0.5, -26, 0, 32),
			BackgroundColor3 = Color3.fromRGB(170, 63, 76),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = "Xóa menu",
			TextColor3 = COLORS.text,
			TextSize = 12,
			ZIndex = 22,
		}, dialog)
		addCorner(confirmButton, 8)

		cancelButton.Activated:Connect(function()
			if window._confirmDialog then
				window._confirmDialog:Destroy()
				window._confirmDialog = nil
			end
		end)
		confirmButton.Activated:Connect(function()
			window:destroy()
		end)
		cancelButton.MouseEnter:Connect(function()
			tween(cancelButton, 0.14, { BackgroundColor3 = COLORS.surfaceHover })
		end)
		cancelButton.MouseLeave:Connect(function()
			tween(cancelButton, 0.14, { BackgroundColor3 = COLORS.surface })
		end)
		confirmButton.MouseEnter:Connect(function()
			tween(confirmButton, 0.14, { BackgroundColor3 = Color3.fromRGB(195, 70, 83) })
		end)
		confirmButton.MouseLeave:Connect(function()
			tween(confirmButton, 0.14, { BackgroundColor3 = Color3.fromRGB(170, 63, 76) })
		end)
	end)

	if window._loadingOptions then
		local loading = window._loadingOptions
		local overlay = create("Frame", {
			Name = "LoadingOverlay",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = COLORS.background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 10,
		}, main)
		addCorner(overlay, 13)
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
	end

	if window._loadingOverlay and window._loadingOptions.autoFinish ~= false then
		task.defer(function()
			window:finishLoading()
		end)
	end

	return window
end

SimpleLib.window = SimpleLib.win
SimpleLib.CreateWindow = SimpleLib.win

function SimpleLib:_updateLoadingProgress()
	if not self._progressFill or self._loadingFinished then
		return
	end

	self._loadingProgress = math.min(0.16 + (self._sections * 0.1) + (self._buttons * 0.07), 0.88)
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

function SimpleLib:_ensureDefaultTab()
	if self._tabs[1] then
		return self._tabs[1]
	end
	return self:tab({ title = "Main" })
end

function SimpleLib:section(options)
	return self:_ensureDefaultTab():section(options)
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
		_sections = {},
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

SimpleLib.CreateTab = SimpleLib.tab

SimpleLib.Tab = {}

function SimpleLib.Tab:section(options)
	if type(options) == "string" then
		options = { title = options }
	else
		options = options or {}
	end
	local window = self._window
	window._sections = window._sections + 1
	local sectionIndex = #self._sections + 1

	local container = create("Frame", {
		Name = "Section_" .. sectionIndex,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = sectionIndex,
	}, self._page)
	create("UIListLayout", {
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)

	local heading = create("TextLabel", {
		Name = "SectionTitle",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Text = options.title or options.Name or "Section",
		TextColor3 = COLORS.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, container)

	local section = setmetatable({
		_window = window,
		_container = container,
		_tab = self,
		_buttons = {},
	}, { __index = SimpleLib.Section })
	table.insert(self._sections, section)

	window:_updateLoadingProgress()
	return section
end

SimpleLib.Tab.CreateSection = SimpleLib.Tab.section

function SimpleLib.Tab:button(options)
	return self:section({ title = options and options.section or "Actions" }):button(options)
end

SimpleLib.Tab.btn = SimpleLib.Tab.button
SimpleLib.Tab.CreateButton = SimpleLib.Tab.button

SimpleLib.Section = {}

function SimpleLib.Section:button(options)
	options = options or {}
	local callback = options.callback or options.Callback
	assert(callback == nil or type(callback) == "function", "button callback must be a function")
	local window = self._window
	window._buttons = window._buttons + 1
	local buttonIndex = #self._buttons + 1

	local button = create("TextButton", {
		Name = "Button_" .. buttonIndex,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = buttonIndex + 1,
	}, self._container)
	addCorner(button, 10)
	addPadding(button, 13, 10, 13, 10)
	local buttonScale = create("UIScale", {
		Scale = 1,
	}, button)
	create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, button)
	local buttonStroke = create("UIStroke", {
		Color = COLORS.border,
		Transparency = 0.45,
		Thickness = 1,
	}, button)
	create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Text = options.title or options.Name or "Button",
		TextColor3 = COLORS.text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Active = false,
	}, button)

	create("TextLabel", {
		Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = options.desc or options.Description or "",
		TextColor3 = COLORS.muted,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		Active = false,
	}, button)

	button.MouseEnter:Connect(function()
		tween(button, 0.14, { BackgroundColor3 = COLORS.surfaceHover })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.14, { BackgroundColor3 = COLORS.surface })
	end)
	button.Activated:Connect(function()
		tween(buttonScale, 0.08, { Scale = 0.97 }).Completed:Connect(function()
			if buttonScale.Parent then
				tween(buttonScale, 0.16, { Scale = 1 })
			end
		end)
		tween(buttonStroke, 0.12, { Color = COLORS.accent, Transparency = 0.12 })
		task.delay(0.14, function()
			if buttonStroke.Parent then
				tween(buttonStroke, 0.2, { Color = COLORS.border, Transparency = 0.45 })
			end
		end)
		if callback then
			callback()
		end
	end)

	table.insert(self._buttons, button)
	window:_updateLoadingProgress()
	return button
end

SimpleLib.Section.btn = SimpleLib.Section.button
SimpleLib.Section.CreateButton = SimpleLib.Section.button

function SimpleLib:destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
	self._loadingOverlay = nil
	self._confirmDialog = nil
end

SimpleLib.CreateSection = SimpleLib.section
SimpleLib.Destroy = SimpleLib.destroy

return SimpleLib
