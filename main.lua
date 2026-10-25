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

local API_ALIASES = {
	window = {
		window = "win",
		CreateWindow = "win",
		tab = "tab",
		CreateTab = "tab",
		section = "section",
		CreateSection = "section",
		destroy = "destroy",
		Destroy = "destroy",
	},
	tab = {
		section = "section",
		CreateSection = "section",
		button = "button",
		btn = "button",
		CreateButton = "button",
		toggle = "toggle",
		tog = "toggle",
		CreateToggle = "toggle",
		dropdown = "dropdown",
		dd = "dropdown",
		CreateDropdown = "dropdown",
	},
	navigationSection = {
		tab = "tab",
		CreateTab = "tab",
	},
	section = {
		button = "button",
		btn = "button",
		CreateButton = "button",
		toggle = "toggle",
		tog = "toggle",
		CreateToggle = "toggle",
		dropdown = "dropdown",
		dd = "dropdown",
		CreateDropdown = "dropdown",
	},
}

local function applyAliases(target, aliases)
	for alias, method in pairs(aliases) do
		target[alias] = target[method]
	end
end

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
	local sound = window._sounds and window._sounds[soundName]
	if not sound then
		return
	end

	local now = os.clock()
	if now - (window._lastSoundAt[soundName] or 0) < 0.04 then
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

	local requestedSize = options.size or options.Size or UDim2.fromOffset(560, 420)
	local window = setmetatable({
		_screenGui = screenGui,
		_tabs = {},
		_navigationSections = {},
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
		_sounds = {},
		_lastSoundAt = {},
	}, self)

	for soundName, assetId in pairs({
		button = "9113744905",
		section = "9114083230",
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

	local sidebar = create("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 142, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.accent,
	}, body)
	addPadding(sidebar, 10, 13, 10, 12)
	local sidebarLayout = create("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	window._sidebar = sidebar
	window._sidebarLayout = sidebarLayout
	sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sidebar.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 25)
	end)

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
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = COLORS.surface,
		BackgroundTransparency = 0.08,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "↘",
		TextColor3 = COLORS.text,
		TextSize = 22,
	}, main)
	addCorner(resizeGrip, 11)

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
			local progressTween = TweenService:Create(
				self._progressFill,
				TweenInfo.new(remaining, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0.9, 0, 1, 0) }
			)
			progressTween:Play()
			task.wait(remaining)
			progressTween:Cancel()
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

function SimpleLib:_ensureDefaultNavigationSection()
	if self._navigationSections[1] then
		return self._navigationSections[1]
	end
	return self:section({ title = "Main" })
end

SimpleLib.NavigationSection = {}

function SimpleLib:section(options)
	if type(options) == "string" then
		options = { title = options }
	else
		options = options or {}
	end

	local sectionIndex = #self._navigationSections + 1
	local initiallyOpen = options.open
	if initiallyOpen == nil then
		initiallyOpen = options.Open
	end
	if initiallyOpen == nil then
		initiallyOpen = true
	end
	assert(type(initiallyOpen) == "boolean", "section open option must be a boolean")

	local container = create("Frame", {
		Name = "NavigationSection_" .. sectionIndex,
		Size = UDim2.new(1, 0, 0, 28),
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		LayoutOrder = sectionIndex,
	}, self._sidebar)
	create("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)
	local sectionTitle = options.title or options.Name or ("Section " .. sectionIndex)
	local sectionHeader = create("TextButton", {
		Name = "SectionHeader",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.GothamSemibold,
		Text = (initiallyOpen and "↑   " or "↓   ") .. sectionTitle,
		TextColor3 = COLORS.muted,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
	}, container)
	local tabContainer = create("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = initiallyOpen,
		LayoutOrder = 2,
	}, container)
	local tabContainerLayout = create("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabContainer)

	local section = setmetatable({
		_window = self,
		_container = container,
		_header = sectionHeader,
		_tabContainer = tabContainer,
		_tabs = {},
		_title = sectionTitle,
		_open = initiallyOpen,
		_animation = nil,
	}, { __index = SimpleLib.NavigationSection })
	function section:SetOpen(isOpen)
		assert(type(isOpen) == "boolean", "section open state must be a boolean")
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		self._open = isOpen
		self._header.Text = (isOpen and "↑   " or "↓   ") .. self._title
		playSound(self._window, "section")

		local tabsHeight = tabContainerLayout.AbsoluteContentSize.Y
		self._tabContainer.Visible = true
		if isOpen then
			self._tabContainer.Size = UDim2.new(1, 0, 0, 0)
		end
		local animation = tween(self._container, 0.22, {
			Size = UDim2.new(1, 0, 0, isOpen and (35 + tabsHeight) or 30),
		})
		self._animation = animation
		tween(self._tabContainer, 0.22, {
			Size = UDim2.new(1, 0, 0, isOpen and tabsHeight or 0),
		})
		animation.Completed:Connect(function(playbackState)
			if self._animation ~= animation then
				return
			end
			self._animation = nil
			if playbackState == Enum.PlaybackState.Completed and not self._open then
				self._tabContainer.Visible = false
			end
		end)
	end
	sectionHeader.Activated:Connect(function()
		section:SetOpen(not section._open)
	end)
	tabContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local tabsHeight = tabContainerLayout.AbsoluteContentSize.Y
		if section._open and not section._animation then
			tabContainer.Size = UDim2.new(1, 0, 0, tabsHeight)
			container.Size = UDim2.new(1, 0, 0, 35 + tabsHeight)
		end
		self._sidebar.CanvasSize = UDim2.new(
			0,
			0,
			0,
			self._sidebarLayout.AbsoluteContentSize.Y + 25
		)
	end)
	tabContainer.Size = UDim2.new(
		1,
		0,
		0,
		initiallyOpen and tabContainerLayout.AbsoluteContentSize.Y or 0
	)
	container.Size = UDim2.new(
		1,
		0,
		0,
		initiallyOpen and (35 + tabContainerLayout.AbsoluteContentSize.Y) or 30
	)
	table.insert(self._navigationSections, section)
	return section
end

function SimpleLib:tab(options)
	return self:_ensureDefaultNavigationSection():tab(options)
end

function SimpleLib.NavigationSection:tab(options)
	if type(options) == "string" then
		options = { title = options }
	else
		options = options or {}
	end
	local window = self._window
	local tabIndex = #window._tabs + 1
	local tabTitle = options.title or options.Name or ("Tab " .. tabIndex)

	local tabButton = create("TextButton", {
		Name = "Tab_" .. tabIndex,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = tabTitle,
		TextColor3 = COLORS.muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = #self._tabs + 1,
	}, self._tabContainer)
	addCorner(tabButton, 9)
	addPadding(tabButton, 10, 0, 8, 0)

	local page = create("ScrollingFrame", {
		Name = "BtnPart_" .. tabIndex,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.accent,
		Visible = false,
	}, self._pages)
	addPadding(page, 18, 18, 18, 18)
	local pageLayout = create("UIListLayout", {
		Padding = UDim.new(0, 17),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)
	local function updatePageCanvas()
		page.CanvasSize = UDim2.new(
			0,
			0,
			0,
			pageLayout.AbsoluteContentSize.Y + 36
		)
	end
	pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
	page:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePageCanvas)
	updatePageCanvas()

	local tab = setmetatable({
		_window = window,
		_navigationSection = self,
		_button = tabButton,
		_page = page,
		_sections = {},
		_title = tabTitle,
	}, { __index = SimpleLib.Tab })
	table.insert(self._tabs, tab)
	table.insert(window._tabs, tab)

	local function selectTab(shouldOpenSection)
		if shouldOpenSection and not self._open then
			self:SetOpen(true)
		end
		for _, existingTab in ipairs(window._tabs) do
			local selected = existingTab == tab
			existingTab._page.Visible = selected
			tween(existingTab._button, 0.15, {
				BackgroundColor3 = selected and COLORS.accent or COLORS.surface,
				TextColor3 = selected and COLORS.text or COLORS.muted,
			})
		end
	end
	tabButton.Activated:Connect(function()
		selectTab(true)
	end)
	if #window._tabs == 1 then
		selectTab(false)
	end

	return tab
end

applyAliases(SimpleLib.NavigationSection, API_ALIASES.navigationSection)

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
		_controlCount = 0,
	}, { __index = SimpleLib.Section })
	table.insert(self._sections, section)

	window:_updateLoadingProgress()
	return section
end

SimpleLib.Section = {}

local function createControlCard(section, options, controlName, accessoryWidth, isButton)
	local window = section._window
	window._buttons = window._buttons + 1
	section._controlCount = section._controlCount + 1

	local cardProperties = {
		Name = controlName .. "_" .. section._controlCount,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.surface,
		BorderSizePixel = 0,
		LayoutOrder = section._controlCount + 1,
	}
	if isButton then
		cardProperties.AutoButtonColor = false
		cardProperties.Text = ""
	end
	local card = create(isButton and "TextButton" or "Frame", cardProperties, section._container)
	addCorner(card, 10)
	addPadding(card, 13, 10, 13, 10)

	local scale = create("UIScale", {
		Scale = 1,
	}, card)
	local stroke = create("UIStroke", {
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
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, card)
	local title = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -(accessoryWidth or 0), 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Text = options.title or options.Name or controlName,
		TextColor3 = COLORS.text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Active = false,
	}, row)
	local description = create("TextLabel", {
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
	}, card)

	local function animatePress()
		if control._pressTween then
			control._pressTween:Cancel()
		end
		if control._strokeTween then
			control._strokeTween:Cancel()
		end
		if control._resetStrokeTask then
			task.cancel(control._resetStrokeTask)
		end

		local pressTween = tween(scale, 0.08, { Scale = 0.96 })
		control._pressTween = pressTween
		pressTween.Completed:Connect(function(playbackState)
			if playbackState ~= Enum.PlaybackState.Completed or control._pressTween ~= pressTween then
				return
			end
			if scale.Parent then
				control._pressTween = tween(scale, 0.16, { Scale = 1 })
			end
		end)
		control._strokeTween = tween(stroke, 0.12, { Color = COLORS.accent, Transparency = 0.12 })
		control._resetStrokeTask = task.delay(0.14, function()
			control._resetStrokeTask = nil
			if stroke.Parent then
				control._strokeTween = tween(stroke, 0.2, { Color = COLORS.border, Transparency = 0.45 })
			end
		end)
	end

	card.MouseEnter:Connect(function()
		tween(card, 0.14, { BackgroundColor3 = COLORS.surfaceHover })
	end)
	card.MouseLeave:Connect(function()
		tween(card, 0.14, { BackgroundColor3 = COLORS.surface })
	end)

	window:_updateLoadingProgress()
	return {
		card = card,
		row = row,
		title = title,
		description = description,
		scale = scale,
		stroke = stroke,
		animatePress = animatePress,
	}
end

local function getCallback(options)
	local callback = options.callback or options.Callback
	assert(callback == nil or type(callback) == "function", "control callback must be a function")
	return callback
end

function SimpleLib.Section:button(options)
	options = options or {}
	local callback = getCallback(options)
	local control = createControlCard(self, options, "Button", nil, true)
	control.card.Activated:Connect(function()
		playSound(self._window, "button")
		control.animatePress()
		if callback then
			callback()
		end
	end)
	return control.card
end

function SimpleLib.Section:toggle(options)
	options = options or {}
	local callback = getCallback(options)
	local control = createControlCard(self, options, "Toggle", 52)
	local isEnabled = options.default
	if isEnabled == nil then
		isEnabled = options.Default
	end
	if isEnabled == nil then
		isEnabled = options.value
	end
	if isEnabled == nil then
		isEnabled = options.Value
	end
	if isEnabled == nil then
		isEnabled = false
	end
	assert(type(isEnabled) == "boolean", "toggle default value must be a boolean")

	local switch = create("TextButton", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = isEnabled and COLORS.accent or COLORS.border,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, control.row)
	addCorner(switch, 10)
	local knob = create("Frame", {
		Name = "Knob",
		Position = UDim2.fromOffset(isEnabled and 20 or 2, 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = COLORS.text,
		BorderSizePixel = 0,
		Active = false,
	}, switch)
	addCorner(knob, 8)

	local toggle = {
		_value = isEnabled,
		_instance = control.card,
	}
	function toggle:Get()
		return self._value
	end
	function toggle:Set(value, shouldNotify)
		assert(type(value) == "boolean", "toggle value must be a boolean")
		self._value = value
		if self._switchTween then
			self._switchTween:Cancel()
		end
		if self._knobTween then
			self._knobTween:Cancel()
		end
		self._switchTween = tween(switch, 0.16, {
			BackgroundColor3 = value and COLORS.accent or COLORS.border,
		})
		self._knobTween = tween(knob, 0.16, {
			Position = UDim2.fromOffset(value and 20 or 2, 2),
		})
		if shouldNotify ~= false and callback then
			callback(value)
		end
	end
	function toggle:Destroy()
		if self._instance then
			self._instance:Destroy()
			self._instance = nil
		end
	end

	switch.Activated:Connect(function()
		playSound(self._window, "button")
		control.animatePress()
		toggle:Set(not toggle._value)
	end)
	return toggle
end

function SimpleLib.Section:dropdown(options)
	options = options or {}
	local callback = getCallback(options)
	local suppliedItems = options.items or options.Items or options.item or options.Item or options.options or options.Options or {}
	local items = {}
	if type(suppliedItems) == "table" then
		for index, item in ipairs(suppliedItems) do
			items[index] = item
		end
	else
		items[1] = suppliedItems
	end
	for index, item in ipairs(items) do
		assert(type(item) == "string" or type(item) == "number", "dropdown items must be strings or numbers")
		items[index] = tostring(item)
	end

	local control = createControlCard(self, options, "Dropdown", 132)
	local selected = options.default or options.Default or options.value or options.Value
	if selected ~= nil then
		selected = tostring(selected)
		assert(table.find(items, selected), "dropdown default must match one of its items")
	else
		selected = nil
	end

	local selectedLabel = create("TextLabel", {
		Name = "SelectedValue",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -19, 0.5, 0),
		Size = UDim2.new(0, 104, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = selected or "Chọn...",
		TextColor3 = selected and COLORS.text or COLORS.muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Active = false,
	}, control.row)
	local arrow = create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "⌄",
		TextColor3 = COLORS.muted,
		TextSize = 14,
		Active = false,
	}, control.row)
	control.title.Size = UDim2.new(1, -140, 1, 0)

	local rowButton = create("TextButton", {
		Name = "DropdownHeaderButton",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, control.row)
	rowButton.ZIndex = selectedLabel.ZIndex + 1

	local optionsList = create("Frame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ClipsDescendants = true,
		LayoutOrder = 3,
	}, control.card)
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, optionsList)
	local initiallyOpen = options.open
	if initiallyOpen == nil then
		initiallyOpen = options.Open
	end
	if initiallyOpen == nil then
		initiallyOpen = false
	end
	assert(type(initiallyOpen) == "boolean", "dropdown open option must be a boolean")

	local dropdown = {
		_window = self._window,
		_value = selected,
		_options = items,
		_instance = control.card,
		_open = false,
		_animation = nil,
	}
	local function getOptionsHeight()
		local optionCount = #dropdown._options
		return optionCount * 30 + math.max(0, optionCount - 1) * 4
	end
	function dropdown:Get()
		return self._value
	end
	function dropdown:Set(value, shouldNotify)
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
		if self._open == isOpen and not self._animation then
			return
		end
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		self._open = isOpen
		if isOpen then
			optionsList.Visible = true
			optionsList.Size = UDim2.new(1, 0, 0, 0)
		end
		arrow.Text = isOpen and "⌃" or "⌄"
		playSound(self._window, "dropdown")

		local targetHeight = isOpen and getOptionsHeight() or 0
		local animation = tween(optionsList, 0.2, {
			Size = UDim2.new(1, 0, 0, targetHeight),
		})
		self._animation = animation
		animation.Completed:Connect(function(playbackState)
			if self._animation ~= animation then
				return
			end
			self._animation = nil
			if playbackState == Enum.PlaybackState.Completed and not self._open then
				optionsList.Visible = false
			end
		end)
	end
	function dropdown:SetOptions(newItems)
		assert(type(newItems) == "table", "dropdown options must be a table")
		if self._animation then
			self._animation:Cancel()
			self._animation = nil
		end
		local previousValue = self._value
		self._options = {}
		for index, item in ipairs(newItems) do
			assert(type(item) == "string" or type(item) == "number", "dropdown items must be strings or numbers")
			self._options[index] = tostring(item)
		end
		self._value = nil
		selectedLabel.Text = "Chọn..."
		selectedLabel.TextColor3 = COLORS.muted
		for _, child in ipairs(optionsList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		optionsList.Size = UDim2.new(1, 0, 0, 0)
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
			optionButton.MouseEnter:Connect(function()
				tween(optionButton, 0.12, { BackgroundColor3 = COLORS.surfaceHover })
			end)
			optionButton.MouseLeave:Connect(function()
				tween(optionButton, 0.12, { BackgroundColor3 = COLORS.panel })
			end)
			optionButton.Activated:Connect(function()
				control.animatePress()
				playSound(self._window, "dropdown")
				self:Set(item)
				self:SetOpen(false)
			end)
		end
		if self._open then
			optionsList.Visible = true
			optionsList.Size = UDim2.new(1, 0, 0, 0)
			local animation = tween(optionsList, 0.2, {
				Size = UDim2.new(1, 0, 0, getOptionsHeight()),
			})
			self._animation = animation
			animation.Completed:Connect(function()
				if self._animation == animation then
					self._animation = nil
				end
			end)
		end
		if previousValue and table.find(self._options, previousValue) then
			self:Set(previousValue, false)
		end
	end
	function dropdown:Destroy()
		if self._instance then
			self._instance:Destroy()
			self._instance = nil
		end
	end

	rowButton.Activated:Connect(function()
		control.animatePress()
		dropdown:SetOpen(not dropdown._open)
	end)
	dropdown:SetOptions(items)
	if selected then
		dropdown:Set(selected, false)
	end
	if initiallyOpen then
		dropdown:SetOpen(true)
	end
	return dropdown
end

function SimpleLib.Tab:button(options)
	return self:section({ title = options and options.section or "Actions" }):button(options)
end

function SimpleLib.Tab:toggle(options)
	return self:section({ title = options and options.section or "Options" }):toggle(options)
end

function SimpleLib.Tab:dropdown(options)
	return self:section({ title = options and options.section or "Options" }):dropdown(options)
end

SimpleLib.Tab.CreateSection = SimpleLib.Tab.section
applyAliases(SimpleLib.Tab, API_ALIASES.tab)
applyAliases(SimpleLib.Section, API_ALIASES.section)

function SimpleLib:destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	for _, sound in pairs(self._sounds) do
		sound:Destroy()
	end
	table.clear(self._sounds)
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
	self._loadingOverlay = nil
	self._confirmDialog = nil
end

applyAliases(SimpleLib, API_ALIASES.window)

return SimpleLib
