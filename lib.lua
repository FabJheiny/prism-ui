local GetService = game.GetService
local Connect = game.Loaded.Connect
local Wait = game.Loaded.Wait
local Clone = game.Clone
local Destroy = game.Destroy

if not game:IsLoaded() then
	Wait(game.Loaded)
end

local Setup = {
	Keybind = Enum.KeyCode.LeftControl,
	Transparency = 0.2,
	ThemeMode = "Dark",
	Size = nil,
}

local Theme = {
	Primary      = Color3.fromRGB(30, 30, 30),
	Secondary    = Color3.fromRGB(35, 35, 35),
	Component    = Color3.fromRGB(40, 40, 40),
	Interactables = Color3.fromRGB(45, 45, 45),
	Tab          = Color3.fromRGB(200, 200, 200),
	Title        = Color3.fromRGB(240, 240, 240),
	Description  = Color3.fromRGB(200, 200, 200),
	Shadow       = Color3.fromRGB(0, 0, 0),
	Outline      = Color3.fromRGB(40, 40, 40),
	Icon         = Color3.fromRGB(220, 220, 220),
}

local Type = nil
local LocalPlayer = GetService(game, "Players").LocalPlayer
local Services = {
	Insert = GetService(game, "InsertService"),
	Tween  = GetService(game, "TweenService"),
	Run    = GetService(game, "RunService"),
	Input  = GetService(game, "UserInputService"),
}

local Player = {
	Mouse = LocalPlayer:GetMouse(),
	GUI   = LocalPlayer.PlayerGui,
}

local Tween = function(Object, Speed, Properties, Info)
	local Style = Info and Info["EasingStyle"] or Enum.EasingStyle.Sine
	local Direction = Info and Info["EasingDirection"] or Enum.EasingDirection.Out
	return Services.Tween:Create(Object, TweenInfo.new(Speed, Style, Direction), Properties):Play()
end

local SetProperty = function(Object, Properties)
	for Index, Property in next, Properties do
		Object[Index] = Property
	end
	return Object
end

local Multiply = function(Value, Amount)
	return UDim2.new(
		Value.X.Scale * Amount,
		Value.X.Offset * Amount,
		Value.Y.Scale * Amount,
		Value.Y.Offset * Amount
	)
end

local Color = function(C, Factor, Mode)
	Mode = Mode or Setup.ThemeMode
	local r, g, b = C.R * 255, C.G * 255, C.B * 255
	if Mode == "Light" then
		return Color3.fromRGB(r - Factor, g - Factor, b - Factor)
	else
		return Color3.fromRGB(r + Factor, g + Factor, b + Factor)
	end
end

local Drag = function(Canvas)
	if not Canvas then return end
	local Dragging, DragInput, Start, StartPosition

	Connect(Canvas.InputBegan, function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Type then
			Dragging = true
			Start = Input.Position
			StartPosition = Canvas.Position
			Connect(Input.Changed, function()
				if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
			end)
		end
	end)

	Connect(Canvas.InputChanged, function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and not Type then
			DragInput = Input
		end
	end)

	Connect(Services.Input.InputChanged, function(Input)
		if Input == DragInput and Dragging and not Type then
			local delta = Input.Position - Start
			Canvas.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
		end
	end)
end

Resizing = {
	TopLeft     = { X = Vector2.new(-1, 0), Y = Vector2.new(0, -1) },
	TopRight    = { X = Vector2.new(1, 0),  Y = Vector2.new(0, -1) },
	BottomLeft  = { X = Vector2.new(-1, 0), Y = Vector2.new(0, 1)  },
	BottomRight = { X = Vector2.new(1, 0),  Y = Vector2.new(0, 1)  },
}

Resizeable = function(Tab, Minimum, Maximum)
	task.spawn(function()
		local MousePos, Size, UIPos = nil, nil, nil

		if Tab and Tab:FindFirstChild("Resize") then
			local Positions = Tab:FindFirstChild("Resize")
			for _, Types in next, Positions:GetChildren() do
				Connect(Types.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Type = Types
						MousePos = Vector2.new(Player.Mouse.X, Player.Mouse.Y)
						Size = Tab.AbsoluteSize
						UIPos = Tab.Position
					end
				end)
				Connect(Types.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then Type = nil end
				end)
			end
		end

		local Resize = function(Delta)
			if Type and MousePos and Size and UIPos and Tab:FindFirstChild("Resize")[Type.Name] == Type then
				local Mode = Resizing[Type.Name]
				local NewSize = Vector2.new(
					math.clamp(Size.X + Delta.X * Mode.X.X, Minimum.X, Maximum.X),
					math.clamp(Size.Y + Delta.Y * Mode.Y.Y, Minimum.Y, Maximum.Y)
				)
				local AnchorOffset    = Vector2.new(Tab.AnchorPoint.X * Size.X,    Tab.AnchorPoint.Y * Size.Y)
				local NewAnchorOffset = Vector2.new(Tab.AnchorPoint.X * NewSize.X, Tab.AnchorPoint.Y * NewSize.Y)
				local DeltaAnchor     = NewAnchorOffset - AnchorOffset

				Tab.Size = UDim2.new(0, NewSize.X, 0, NewSize.Y)
				Tab.Position = UDim2.new(
					UIPos.X.Scale, UIPos.X.Offset + DeltaAnchor.X * Mode.X.X,
					UIPos.Y.Scale, UIPos.Y.Offset + DeltaAnchor.Y * Mode.Y.Y
				)
			end
		end

		Connect(Player.Mouse.Move, function()
			if Type then Resize(Vector2.new(Player.Mouse.X, Player.Mouse.Y) - MousePos) end
		end)
	end)
end

if identifyexecutor then
	Screen = Services.Insert:LoadLocalAsset("rbxassetid://18490507748")
else
	Screen = script.Parent
end

Screen.Main.Visible = false

xpcall(function() Screen.Parent = game.CoreGui end, function() Screen.Parent = Player.GUI end)

local Animations = {}
local Components = Screen:FindFirstChild("Components")
local Library = {}
local StoredInfo = { ["Sections"] = {}, ["Tabs"] = {} }

function Animations:Open(Window, Transparency, UseCurrentSize)
	local Original = (UseCurrentSize and Window.Size) or Setup.Size
	local Shadow = Window:FindFirstChildOfClass("UIStroke")
	SetProperty(Shadow,  { Transparency = 1 })
	SetProperty(Window,  { Size = Multiply(Original, 1.1), GroupTransparency = 1, Visible = true })
	Tween(Shadow, .25, { Transparency = 0.5 })
	Tween(Window, .25, { Size = Original, GroupTransparency = Transparency or 0 })
end

function Animations:Close(Window)
	local Original = Window.Size
	local Shadow = Window:FindFirstChildOfClass("UIStroke")
	SetProperty(Window, { Size = Original })
	Tween(Shadow, .25, { Transparency = 1 })
	Tween(Window, .25, { Size = Multiply(Original, 1.1), GroupTransparency = 1 })
	task.wait(.25)
	Window.Size = Original
	Window.Visible = false
end

function Animations:Component(Component, Custom)
	Connect(Component.InputBegan, function()
		if Custom then Tween(Component, .25, { Transparency = .85 })
		else Tween(Component, .25, { BackgroundColor3 = Color(Theme.Component, 5, Setup.ThemeMode) }) end
	end)
	Connect(Component.InputEnded, function()
		if Custom then Tween(Component, .25, { Transparency = 1 })
		else Tween(Component, .25, { BackgroundColor3 = Theme.Component }) end
	end)
end

function Library:CreateWindow(Settings)
	local Window  = Clone(Screen:WaitForChild("Main"))
	local Sidebar = Window:FindFirstChild("Sidebar")
	local Holder  = Window:FindFirstChild("Main")
	local BG      = Window:FindFirstChild("BackgroundShadow")
	local Tab     = Sidebar:FindFirstChild("Tab")

	local Options  = {}
	local Examples = {}
	local Opened   = true
	local Maximized = false

	for _, Example in next, Window:GetDescendants() do
		if Example.Name:find("Example") and not Examples[Example.Name] then
			Examples[Example.Name] = Example
		end
	end

	Drag(Window)
	Resizeable(Window, Vector2.new(411, 271), Vector2.new(9e9, 9e9))
	Setup.Transparency = Settings.Transparency or 0
	Setup.Size         = Settings.Size
	Setup.ThemeMode    = Settings.Theme or "Dark"
	if Settings.MinimizeKeybind then Setup.Keybind = Settings.MinimizeKeybind end

	local TitleLabel = Instance.new("TextLabel")
	SetProperty(TitleLabel, {
		Text               = Settings.Title or "Menu",
		Font               = Enum.Font.GothamBold,
		TextSize           = 14,
		TextColor3         = Theme.Title,
		BackgroundTransparency = 1,
		Size               = UDim2.new(1, -16, 1, 0),
		Position           = UDim2.new(0, 8, 0, 0),
		TextXAlignment     = Enum.TextXAlignment.Left,
		Parent             = Sidebar.Top,
	})

	if Sidebar.Top:FindFirstChild("Buttons") then
		Destroy(Sidebar.Top.Buttons)
	end

	local Close = function()
		if Opened then
			Opened = false
			Animations:Close(Window)
			Window.Visible = false
		else
			Animations:Open(Window, Setup.Transparency)
			Opened = true
		end
	end

	Services.Input.InputBegan:Connect(function(Input, Focused)
		if (Input == Setup.Keybind or Input.KeyCode == Setup.Keybind) and not Focused then
			Close()
		end
	end)

	local FloatBtn = Instance.new("TextButton")
	SetProperty(FloatBtn, {
		Name             = "FloatButton",
		Text             = "×",
		Font             = Enum.Font.GothamBold,
		TextSize         = 22,
		TextColor3       = Color3.fromRGB(240, 240, 240),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		Size             = UDim2.new(0, 42, 0, 42),
		Position         = UDim2.new(0, 12, 1, -54),
		AnchorPoint      = Vector2.new(0, 0),
		AutoButtonColor  = false,
		ZIndex           = 999,
		Parent           = Screen,
	})
	SetProperty(Instance.new("UICorner", FloatBtn),  { CornerRadius = UDim.new(1, 0) })
	SetProperty(Instance.new("UIStroke", FloatBtn),  { Color = Color3.fromRGB(80, 80, 80), Thickness = 1.2 })

	local FBDragging, FBDragInput, FBStart, FBStartPos, FBMoved = false, nil, nil, nil, false

	Connect(FloatBtn.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			FBDragging, FBMoved = true, false
			FBStart, FBStartPos = Input.Position, FloatBtn.Position
			Connect(Input.Changed, function()
				if Input.UserInputState == Enum.UserInputState.End then FBDragging = false end
			end)
		end
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			Tween(FloatBtn, .2, { BackgroundColor3 = Color3.fromRGB(60, 60, 60) })
		end
	end)

	Connect(FloatBtn.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			FBDragInput = Input
		end
	end)

	Connect(FloatBtn.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			Tween(FloatBtn, .2, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) })
		end
	end)

	Connect(Services.Input.InputChanged, function(Input)
		if Input == FBDragInput and FBDragging then
			local Delta = Input.Position - FBStart
			if Delta.Magnitude > 4 then FBMoved = true end
			if FBMoved then
				FloatBtn.Position = UDim2.new(FBStartPos.X.Scale, FBStartPos.X.Offset + Delta.X, FBStartPos.Y.Scale, FBStartPos.Y.Offset + Delta.Y)
			end
		end
	end)

	local SyncFloatIcon = function() FloatBtn.Text = Opened and "×" or "+" end

	Connect(FloatBtn.MouseButton1Click, function()
		if FBMoved then return end
		Close(); SyncFloatIcon()
	end)

	Services.Input.InputBegan:Connect(function(Input, Focused)
		if (Input == Setup.Keybind or Input.KeyCode == Setup.Keybind) and not Focused then
			task.defer(SyncFloatIcon)
		end
	end)

	SyncFloatIcon()

	function Options:SetTab(Name)
		for _, Button in next, Tab:GetChildren() do
			if Button:IsA("TextButton") then
				local IsOpen, Same = Button.Value, (Button.Name == Name)
				local Padding = Button:FindFirstChildOfClass("UIPadding")
				if Same and not IsOpen.Value then
					Tween(Padding, .25, { PaddingLeft = UDim.new(0, 25) })
					Tween(Button,  .25, { BackgroundTransparency = 0.9, Size = UDim2.new(1, -15, 0, 30) })
					SetProperty(IsOpen, { Value = true })
				elseif not Same and IsOpen.Value then
					Tween(Padding, .25, { PaddingLeft = UDim.new(0, 20) })
					Tween(Button,  .25, { BackgroundTransparency = 1, Size = UDim2.new(1, -44, 0, 30) })
					SetProperty(IsOpen, { Value = false })
				end
			end
		end

		for _, Main in next, Holder:GetChildren() do
			if Main:IsA("CanvasGroup") then
				local IsOpen, Same = Main.Value, (Main.Name == Name)
				local Scroll = Main:FindFirstChild("ScrollingFrame")
				if Same and not IsOpen.Value then
					IsOpen.Value = true; Main.Visible = true
					Tween(Main,                  .3, { GroupTransparency = 0 })
					Tween(Scroll["UIPadding"],   .3, { PaddingTop = UDim.new(0, 5) })
				elseif not Same and IsOpen.Value then
					IsOpen.Value = false
					Tween(Main,                  .15, { GroupTransparency = 1 })
					Tween(Scroll["UIPadding"],   .15, { PaddingTop = UDim.new(0, 15) })
					task.delay(.2, function() Main.Visible = false end)
				end
			end
		end
	end

	function Options:AddTabSection(Settings)
		local Example = Examples["SectionExample"]
		local Section = Clone(Example)
		StoredInfo["Sections"][Settings.Name] = Settings.Order
		SetProperty(Section, { Parent = Example.Parent, Text = Settings.Name, Name = Settings.Name, LayoutOrder = Settings.Order, Visible = true })
	end

	function Options:AddTab(Settings)
		if StoredInfo["Tabs"][Settings.Title] then error("[UI LIB]: A tab with the same name has already been created") end

		local Example, MainExample = Examples["TabButtonExample"], Examples["MainExample"]
		local Section = StoredInfo["Sections"][Settings.Section]
		local Main = Clone(MainExample)
		local TabBtn = Clone(Example)

		if not Settings.Icon then Destroy(TabBtn["ICO"])
		else SetProperty(TabBtn["ICO"], { Image = Settings.Icon }) end

		StoredInfo["Tabs"][Settings.Title] = { TabBtn }
		SetProperty(TabBtn["TextLabel"], { Text = Settings.Title })
		SetProperty(Main,   { Parent = MainExample.Parent, Name = Settings.Title })
		SetProperty(TabBtn, { Parent = Example.Parent, LayoutOrder = Section or #StoredInfo["Sections"] + 1, Name = Settings.Title, Visible = true })

		TabBtn.MouseButton1Click:Connect(function() Options:SetTab(TabBtn.Name) end)

		return Main.ScrollingFrame
	end

	function Options:Notify(Settings)
		local Notification = Clone(Components["Notification"])
		local Title, Description = Options:GetLabels(Notification)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Notification, { Parent = Screen["Frame"] })

		task.spawn(function()
			local Duration = Settings.Duration or 2
			Animations:Open(Notification, Setup.Transparency, true)
			Tween(Notification["Timer"], Duration, { Size = UDim2.new(0, 0, 0, 4) })
			task.wait(Duration)
			Animations:Close(Notification)
			task.wait(1)
			Notification:Destroy()
		end)
	end

	function Options:GetLabels(Component)
		local Labels = Component:FindFirstChild("Labels")
		return Labels.Title, Labels.Description
	end

	function Options:AddSection(Settings)
		local Section = Clone(Components["Section"])
		SetProperty(Section, { Text = Settings.Name, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddButton(Settings)
		local Button = Clone(Components["Button"])
		local Title, Description = Options:GetLabels(Button)
		Connect(Button.MouseButton1Click, Settings.Callback)
		Animations:Component(Button)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Button, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddInput(Settings)
		local Input   = Clone(Components["Input"])
		local Title, Description = Options:GetLabels(Input)
		local TextBox = Input["Main"]["Input"]
		Connect(Input.MouseButton1Click, function() TextBox:CaptureFocus() end)
		Connect(TextBox.FocusLost, function() Settings.Callback(TextBox.Text) end)
		Animations:Component(Input)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Input, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddToggle(Settings)
		local Toggle = Clone(Components["Toggle"])
		local Title, Description = Options:GetLabels(Toggle)
		local On     = Toggle["Value"]
		local Main   = Toggle["Main"]
		local Circle = Main["Circle"]

		local Set = function(Value)
			if Value then
				Tween(Main,   .2, { BackgroundColor3 = Color3.fromRGB(153, 155, 255) })
				Tween(Circle, .2, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(1, -16, 0.5, 0) })
			else
				Tween(Main,   .2, { BackgroundColor3 = Theme.Interactables })
				Tween(Circle, .2, { BackgroundColor3 = Theme.Primary, Position = UDim2.new(0, 3, 0.5, 0) })
			end
			On.Value = Value
		end

		Connect(Toggle.MouseButton1Click, function()
			local Value = not On.Value
			Set(Value); Settings.Callback(Value)
		end)

		Animations:Component(Toggle)
		Set(Settings.Default)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Toggle, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddKeybind(Settings)
		local Dropdown = Clone(Components["Keybind"])
		local Title, Description = Options:GetLabels(Dropdown)
		local Bind  = Dropdown["Main"].Options
		local Mouse = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 }
		local Types = { ["Mouse"] = "Enum.UserInputType.MouseButton", ["Key"] = "Enum.KeyCode." }

		Connect(Dropdown.MouseButton1Click, function()
			local Finished
			SetProperty(Bind, { Text = "..." })
			Connect(game.UserInputService.InputBegan, function(Key, Focused)
				local InputType = Key.UserInputType
				if not Finished and not Focused then
					Finished = true
					if table.find(Mouse, InputType) then
						Settings.Callback(Key)
						SetProperty(Bind, { Text = tostring(InputType):gsub(Types.Mouse, "MB") })
					elseif InputType == Enum.UserInputType.Keyboard then
						Settings.Callback(Key)
						SetProperty(Bind, { Text = tostring(Key.KeyCode):gsub(Types.Key, "") })
					end
				end
			end)
		end)

		Animations:Component(Dropdown)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Dropdown, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddDropdown(Settings)
		local Dropdown = Clone(Components["Dropdown"])
		local Title, Description = Options:GetLabels(Dropdown)
		local Text = Dropdown["Main"].Options

		Connect(Dropdown.MouseButton1Click, function()
			local Example = Clone(Examples["DropdownExample"])

			if Example:FindFirstChild("Top") and Example.Top:FindFirstChild("Buttons") then
				Destroy(Example.Top.Buttons)
			end

			Tween(BG, .25, { BackgroundTransparency = 0.6 })
			SetProperty(Example, { Parent = Window })
			Animations:Open(Example, 0, true)

			for _, Option in next, Settings.Options do
				local Button = Clone(Examples["DropdownButtonExample"])
				local BTitle, BDesc = Options:GetLabels(Button)
				local Selected = Button["Value"]

				Animations:Component(Button)
				SetProperty(BTitle,  { Text = Option })
				SetProperty(Button,  { Parent = Example.ScrollingFrame, Visible = true })
				if BDesc then Destroy(BDesc) end

				Connect(Button.MouseButton1Click, function()
					local NewValue = not Selected.Value
					if NewValue then
						Tween(Button, .25, { BackgroundColor3 = Theme.Interactables })
						Settings.Callback(Option)
						Text.Text = Option
						for _, Others in next, Example:GetChildren() do
							if Others:IsA("TextButton") and Others ~= Button then
								Others.BackgroundColor3 = Theme.Component
							end
						end
					else
						Tween(Button, .25, { BackgroundColor3 = Theme.Component })
					end
					Selected.Value = NewValue
					Tween(BG, .25, { BackgroundTransparency = 1 })
					Animations:Close(Example)
					task.wait(2); Destroy(Example)
				end)
			end
		end)

		Animations:Component(Dropdown)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Dropdown, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddSlider(Settings)
		local Slider = Clone(Components["Slider"])
		local Title, Description = Options:GetLabels(Slider)
		local Main   = Slider["Slider"]
		local Amount = Main["Main"].Input
		local Slide  = Main["Slide"]
		local Fill   = Slide["Highlight"]
		local Active = false
		local Value  = 0

		local SetNumber = function(Number)
			if Settings.AllowDecimals then
				local Power = 10 ^ (Settings.DecimalAmount or 2)
				return math.floor(Number * Power + 0.5) / Power
			end
			return math.round(Number)
		end

		local Update = function(Number)
			local Scale = (Player.Mouse.X - Slide.AbsolutePosition.X) / Slide.AbsoluteSize.X
			Scale = math.clamp(Scale, 0, 1)
			if Number then Number = math.clamp(Number, 0, Settings.MaxValue) end
			Value = SetNumber(Number or (Scale * Settings.MaxValue))
			Amount.Text = Value
			Fill.Size = UDim2.fromScale((Number and Number / Settings.MaxValue) or Scale, 1)
			Settings.Callback(Value)
		end

		Connect(Amount.FocusLost, function() Update(tonumber(Amount.Text) or 0) end)
		Connect(Slide["Fire"].MouseButton1Down, function()
			Active = true
			repeat task.wait() Update() until not Active
		end)
		Connect(Services.Input.InputEnded, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Active = false
			end
		end)

		Fill.Size = UDim2.fromScale(Value, 1)
		Animations:Component(Slider)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Slider, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddParagraph(Settings)
		local Paragraph = Clone(Components["Paragraph"])
		local Title, Description = Options:GetLabels(Paragraph)
		SetProperty(Title,       { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Paragraph,   { Parent = Settings.Tab, Visible = true })
	end

	local Themes = {
		Names = {
			["Paragraph"] = function(L) if L:IsA("TextButton") then L.BackgroundColor3 = Color(Theme.Component, 5, "Dark") end end,
			["Title"]     = function(L) if L:IsA("TextLabel") then L.TextColor3 = Theme.Title end end,
			["Description"] = function(L) if L:IsA("TextLabel") then L.TextColor3 = Theme.Description end end,
			["Section"]   = function(L) if L:IsA("TextLabel") then L.TextColor3 = Theme.Title end end,
			["Options"]   = function(L) if L:IsA("TextLabel") and L.Parent.Name == "Main" then L.TextColor3 = Theme.Title end end,
			["Notification"] = function(L) if L:IsA("CanvasGroup") then L.BackgroundColor3 = Theme.Primary; L.UIStroke.Color = Theme.Outline end end,
			["TextLabel"] = function(L) if L:IsA("TextLabel") and L.Parent:FindFirstChild("List") then L.TextColor3 = Theme.Tab end end,
			["Main"] = function(L)
				if L:IsA("Frame") then
					if L.Parent == Window then L.BackgroundColor3 = Theme.Secondary
					elseif L.Parent:FindFirstChild("Value") then
						if not L.Parent.Value.Value then
							L.BackgroundColor3 = Theme.Interactables
							L.Circle.BackgroundColor3 = Theme.Primary
						end
					else L.BackgroundColor3 = Theme.Interactables end
				elseif L:FindFirstChild("Padding") then L.TextColor3 = Theme.Title end
			end,
			["Amount"]  = function(L) if L:IsA("Frame") then L.BackgroundColor3 = Theme.Interactables end end,
			["Slide"]   = function(L) if L:IsA("Frame") then L.BackgroundColor3 = Theme.Interactables end end,
			["Input"]   = function(L)
				if L:IsA("TextLabel") then L.TextColor3 = Theme.Title
				elseif L:FindFirstChild("Labels") then L.BackgroundColor3 = Theme.Component
				elseif L:IsA("TextBox") and L.Parent.Name == "Main" then L.TextColor3 = Theme.Title end
			end,
			["Outline"] = function(S) if S:IsA("UIStroke") then S.Color = Theme.Outline end end,
			["DropdownExample"] = function(L) L.BackgroundColor3 = Theme.Secondary end,
			["Underline"] = function(L) if L:IsA("Frame") then L.BackgroundColor3 = Theme.Outline end end,
		},
		Classes = {
			["ImageLabel"]     = function(L) if L.Image ~= "rbxassetid://6644618143" then L.ImageColor3 = Theme.Icon end end,
			["TextLabel"]      = function(L) if L:FindFirstChild("Padding") then L.TextColor3 = Theme.Title end end,
			["TextButton"]     = function(L) if L:FindFirstChild("Labels") then L.BackgroundColor3 = Theme.Component end end,
			["ScrollingFrame"] = function(L) L.ScrollBarImageColor3 = Theme.Component end,
		},
	}

	function Options:SetTheme(Info)
		Theme = Info or Theme
		Window.BackgroundColor3 = Theme.Primary
		Holder.BackgroundColor3 = Theme.Secondary
		Window.UIStroke.Color   = Theme.Shadow

		for _, Descendant in next, Screen:GetDescendants() do
			local Name  = Themes.Names[Descendant.Name]
			local Class = Themes.Classes[Descendant.ClassName]
			if Name then Name(Descendant) elseif Class then Class(Descendant) end
		end
	end

	function Options:SetSetting(Setting, Value)
		if Setting == "Size" then
			Window.Size = Value; Setup.Size = Value
		elseif Setting == "Transparency" then
			Window.GroupTransparency = Value; Setup.Transparency = Value
			for _, N in next, Screen:GetDescendants() do
				if N:IsA("CanvasGroup") and N.Name == "Notification" then N.GroupTransparency = Value end
			end
		elseif Setting == "Theme" and typeof(Value) == "table" then
			Options:SetTheme(Value)
		elseif Setting == "Keybind" then
			Setup.Keybind = Value
		else
			warn("Tried to change a setting that doesn't exist or isn't available to change.")
		end
	end

	SetProperty(Window, { Size = Settings.Size, Visible = true, Parent = Screen })
	Animations:Open(Window, Settings.Transparency or 0)

	return Options
end

return Library
