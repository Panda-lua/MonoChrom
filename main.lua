local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
Bg = Color3.fromRGB(8, 8, 8),
Panel = Color3.fromRGB(17, 17, 17),
PanelHi = Color3.fromRGB(30, 30, 30),
Line = Color3.fromRGB(46, 46, 46),
Text = Color3.fromRGB(242, 242, 242),
TextDim = Color3.fromRGB(126, 126, 126),
White = Color3.fromRGB(255, 255, 255),
Off = Color3.fromRGB(44, 44, 44),
}

local DEFAULTS = {
ShowPlayerNames = true,
ShowDistance = false,
ShowHealth = true,
ShowHighlights = false,
ShowSkeleton = false,
ShowCrosshair = true,
ShowFOVCircle = false,
FOVRadius = 120,
CrosshairSize = 18,
MaxDistance = 750,
UIKey = "RightShift",
Animations = true,

AimEnabled = false,
AimActivation = "Hold key",
AimKey = "E",
AimMethod = "Camera",
AimTargetPart = "Head",
AimFOV = 120,
AimSyncFOV = true,
AimSmoothness = 30,
AimMaxDistance = 750,
AimPrediction = 0,
AimTeamCheck = true,
AimVisibleCheck = false,
AimSticky = true,
AimShowMarker = true,

LabelH = 0, LabelS = 0, LabelV = 1, LabelA = 1,
HlFillH = 0, HlFillS = 0, HlFillV = 1, HlFillA = 0.2,
HlOutlineH = 0, HlOutlineS = 0, HlOutlineV = 1, HlOutlineA = 1,
SkeletonH = 0, SkeletonS = 0, SkeletonV = 1, SkeletonA = 1,
CrosshairH = 0, CrosshairS = 0, CrosshairV = 1, CrosshairA = 1,
FOVH = 0, FOVS = 0, FOVV = 1, FOVA = 1,
AimH = 0, AimS = 0, AimV = 1, AimA = 1,


}

local Config = table.clone(DEFAULTS)
local Connections = {}
local Controls = {}
local Destroyed = false

local function cfgColor(prefix)
return Color3.fromHSV(
math.clamp(tonumber(Config[prefix .. "H"]) or 0, 0, 1),
math.clamp(tonumber(Config[prefix .. "S"]) or 0, 0, 1),
math.clamp(tonumber(Config[prefix .. "V"]) or 1, 0, 1)
)
end

local function cfgAlpha(prefix)
return math.clamp(tonumber(Config[prefix .. "A"]) or 1, 0, 1)
end

local function connect(signal, callback)
local connection = signal:Connect(callback)
table.insert(Connections, connection)
return connection
end

local function create(className, properties)
local instance = Instance.new(className)
for key, value in pairs(properties or {}) do
if key ~= "Parent" then
instance[key] = value
end
end
if properties and properties.Parent then
instance.Parent = properties.Parent
end
return instance
end

local function animate(instance, properties, duration)
if not Config.Animations then
for key, value in pairs(properties) do
instance[key] = value
end
return
end
local ok, tween = pcall(function()
return TweenService:Create(
instance,
TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
properties
)
end)
if ok and tween then tween:Play() end
end

local function addCorner(parent, radius)
return create("UICorner", {
CornerRadius = UDim.new(0, radius or 4),
Parent = parent,
})
end

local function addStroke(parent, color, thickness)
return create("UIStroke", {
Color = color or COLORS.Line,
Thickness = thickness or 1,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent = parent,
})
end

local function addPadding(parent, amount)
return create("UIPadding", {
PaddingTop = UDim.new(0, amount),
PaddingBottom = UDim.new(0, amount),
PaddingLeft = UDim.new(0, amount),
PaddingRight = UDim.new(0, amount),
Parent = parent,
})
end

local oldGui = PlayerGui:FindFirstChild("MonochromeUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = create("ScreenGui", {
Name = "Monochrome",
ResetOnSpawn = false,
IgnoreGuiInset = true,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
DisplayOrder = 100,
Enabled = true,
Parent = PlayerGui,
})

local AimLocked = false

local oldOverlay = PlayerGui:FindFirstChild("MonochromeOverlay")
if oldOverlay then oldOverlay:Destroy() end
local OverlayGui = create("ScreenGui", {
Name = "MonochromeOverlay", ResetOnSpawn = false, IgnoreGuiInset = true,
DisplayOrder = 99, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PlayerGui,
})
local FOVCircle = create("Frame", {
Name = "FOVCircle", AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(Config.FOVRadius * 2, Config.FOVRadius * 2),
BackgroundTransparency = 1, BorderSizePixel = 0, Visible = Config.ShowFOVCircle, Parent = OverlayGui,
})
addCorner(FOVCircle, 999)
addStroke(FOVCircle, COLORS.White, 1)
local Crosshair = create("Frame", {
Name = "Crosshair", AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
BackgroundTransparency = 1, BorderSizePixel = 0, Visible = Config.ShowCrosshair, Parent = OverlayGui,
})
create("Frame", {Name = "Horizontal", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = COLORS.White, BorderSizePixel = 0, Parent = Crosshair})
create("Frame", {Name = "Vertical", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = COLORS.White, BorderSizePixel = 0, Parent = Crosshair})

local AimMarker = create("Frame", {
Name = "AimTarget", AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26),
BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = OverlayGui,
})
addCorner(AimMarker, 2)
local AimMarkerStroke = addStroke(AimMarker, COLORS.White, 1)

connect(game:GetService("RunService").RenderStepped, function()
if not OverlayGui.Parent then return end
Crosshair.Visible = Config.ShowCrosshair
FOVCircle.Visible = Config.ShowFOVCircle
local radius = Config.AimSyncFOV and Config.AimFOV or Config.FOVRadius
local diameter = math.clamp(tonumber(radius) or 120, 20, 600) * 2
FOVCircle.Size = UDim2.fromOffset(diameter, diameter)
local crosshairSize = math.clamp(tonumber(Config.CrosshairSize) or 18, 6, 60)
Crosshair.Size = UDim2.fromOffset(crosshairSize, crosshairSize)
local crossColor, crossAlpha = cfgColor("Crosshair"), cfgAlpha("Crosshair")
for _, child in ipairs(Crosshair:GetChildren()) do
child.BackgroundColor3 = crossColor
child.BackgroundTransparency = 1 - crossAlpha
end
local fovStroke = FOVCircle:FindFirstChildOfClass("UIStroke")
if fovStroke then

if AimLocked then
fovStroke.Color = cfgColor("Aim")
fovStroke.Transparency = 1 - cfgAlpha("Aim")
else
fovStroke.Color = cfgColor("FOV")
fovStroke.Transparency = 1 - cfgAlpha("FOV")
end
end
end)

local WINDOW_W, WINDOW_H = 540, 360
local Window = create("Frame", {
Name = "Window",
Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
Position = UDim2.new(0.5, -WINDOW_W / 2, 0.5, -WINDOW_H / 2),
BackgroundColor3 = COLORS.Bg,
BorderSizePixel = 0,
ClipsDescendants = false,
Parent = ScreenGui,
})
addCorner(Window, 8)
addStroke(Window, COLORS.Line, 1)

local TitleBar = create("Frame", {
Name = "TitleBar",
Size = UDim2.new(1, 0, 0, 34),
BackgroundColor3 = COLORS.Panel,
BorderSizePixel = 0,
Parent = Window,
})
addCorner(TitleBar, 8)

create("Frame", {
Size = UDim2.new(1, 0, 0, 1),
Position = UDim2.new(0, 0, 1, -1),
BackgroundColor3 = COLORS.Line,
BorderSizePixel = 0,
Parent = TitleBar,
})

create("TextLabel", {
Text = "M O N O C H R O M E",
Font = Enum.Font.GothamBold,
TextSize = 11,
TextColor3 = COLORS.Text,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Position = UDim2.new(0, 14, 0, 0),
Size = UDim2.new(1, -100, 1, 0),
Parent = TitleBar,
})

local Sidebar, Content

local function titleButton(text, xOffset, callback)
local button = create("TextButton", {
Text = text,
Font = Enum.Font.GothamBold,
TextSize = 12,
TextColor3 = COLORS.TextDim,
BackgroundColor3 = COLORS.Panel,
BackgroundTransparency = 1,
BorderSizePixel = 0,
AutoButtonColor = false,
Size = UDim2.fromOffset(26, 22),
Position = UDim2.new(1, xOffset, 0.5, -11),
Parent = TitleBar,
})
addCorner(button, 4)
connect(button.MouseEnter, function()
animate(button, {BackgroundTransparency = 0, TextColor3 = COLORS.White})
end)
connect(button.MouseLeave, function()
animate(button, {BackgroundTransparency = 1, TextColor3 = COLORS.TextDim})
end)
connect(button.Activated, callback)
return button
end

local minimized = false
titleButton("-", -66, function()
minimized = not minimized
Sidebar.Visible = not minimized
Content.Visible = not minimized
animate(Window, {Size = UDim2.fromOffset(WINDOW_W, minimized and 34 or WINDOW_H)})
end)
titleButton("X", -36, function()
ScreenGui.Enabled = false
end)

local SIDEBAR_W = 124
Sidebar = create("Frame", {
Name = "Sidebar",
Size = UDim2.new(0, SIDEBAR_W, 1, -34),
Position = UDim2.new(0, 0, 0, 34),
BackgroundColor3 = COLORS.Bg,
BorderSizePixel = 0,
Parent = Window,
})
create("Frame", {
Size = UDim2.new(0, 1, 1, 0),
Position = UDim2.new(1, -1, 0, 0),
BackgroundColor3 = COLORS.Line,
BorderSizePixel = 0,
Parent = Sidebar,
})

local TabList = create("Frame", {
Size = UDim2.new(1, 0, 1, -34),
Position = UDim2.new(0, 0, 0, 8),
BackgroundTransparency = 1,
Parent = Sidebar,
})
addPadding(TabList, 6)
create("UIListLayout", {
Padding = UDim.new(0, 3),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = TabList,
})

local SidebarStatus = create("TextLabel", {
Text = "READY",
Font = Enum.Font.GothamBold,
TextSize = 9,
TextColor3 = COLORS.TextDim,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Position = UDim2.new(0, 12, 1, -25),
Size = UDim2.new(1, -20, 0, 16),
Parent = Sidebar,
})

Content = create("Frame", {
Name = "Content",
Size = UDim2.new(1, -SIDEBAR_W, 1, -34),
Position = UDim2.new(0, SIDEBAR_W, 0, 34),
BackgroundColor3 = COLORS.Bg,
BorderSizePixel = 0,
ClipsDescendants = true,
Parent = Window,
})

local dragging, dragStart, dragOrigin = false, nil, nil
connect(TitleBar.InputBegan, function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
dragOrigin = Window.Position
end
end)
connect(UserInputService.InputChanged, function(input)
if not dragging then return end
if input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch then
local delta = input.Position - dragStart
Window.Position = UDim2.new(
dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X,
dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y
)
end
end)
connect(UserInputService.InputEnded, function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
dragging = false
end
end)

local Pages, TabButtons, Indicators = {}, {}, {}
local ActiveTab

local function switchTab(name)
for tabName, page in pairs(Pages) do
page.Visible = tabName == name
end
for tabName, button in pairs(TabButtons) do
local active = tabName == name
button.TextColor3 = active and COLORS.White or COLORS.TextDim
button.BackgroundColor3 = active and COLORS.Panel or COLORS.Bg
button.BackgroundTransparency = active and 0 or 1
local indicator = Indicators[tabName]
if indicator then indicator.BackgroundTransparency = active and 0 or 1 end
end
ActiveTab = name
end

local function createTab(name)
local button = create("TextButton", {
Name = name .. "Tab",
Text = name,
Font = Enum.Font.GothamMedium,
TextSize = 12,
TextColor3 = COLORS.TextDim,
BackgroundColor3 = COLORS.Bg,
BackgroundTransparency = 1,
BorderSizePixel = 0,
AutoButtonColor = false,
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.new(1, 0, 0, 28),
Parent = TabList,
})
addCorner(button, 4)
addPadding(button, 10)


local indicator = create("Frame", {
    Size = UDim2.fromOffset(2, 14),
    Position = UDim2.new(0, -6, 0.5, -7),
    BackgroundColor3 = COLORS.White,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = button,
})
Indicators[name] = indicator

connect(button.MouseEnter, function()
    if ActiveTab ~= name then animate(button, {TextColor3 = COLORS.Text}) end
end)
connect(button.MouseLeave, function()
    if ActiveTab ~= name then animate(button, {TextColor3 = COLORS.TextDim}) end
end)
connect(button.Activated, function() switchTab(name) end)

local page = create("ScrollingFrame", {
    Name = name .. "Page",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.Line,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Visible = false,
    Parent = Content,
})
addPadding(page, 14)
create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = page,
})

Pages[name], TabButtons[name] = page, button
return page


end

local function section(parent, text)
return create("TextLabel", {
Text = string.upper(text),
Font = Enum.Font.GothamBold,
TextSize = 9,
TextColor3 = COLORS.TextDim,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 22),
Parent = parent,
})
end

local function divider(parent)
return create("Frame", {
Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = COLORS.Line,
BorderSizePixel = 0,
Parent = parent,
})
end

local function toggle(parent, key, label)
local row = create("TextButton", {
Text = "",
BackgroundTransparency = 1,
AutoButtonColor = false,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 26),
Parent = parent,
})
local text = create("TextLabel", {
Text = label,
Font = Enum.Font.Gotham,
TextSize = 12,
TextColor3 = COLORS.Text,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Size = UDim2.new(1, -46, 1, 0),
Parent = row,
})
local track = create("Frame", {
Size = UDim2.fromOffset(34, 16),
Position = UDim2.new(1, -34, 0.5, -8),
BackgroundColor3 = Config[key] and COLORS.White or COLORS.Off,
BorderSizePixel = 0,
Parent = row,
})
addCorner(track, 8)
local knob = create("Frame", {
Size = UDim2.fromOffset(12, 12),
Position = Config[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
BackgroundColor3 = Config[key] and COLORS.Bg or COLORS.TextDim,
BorderSizePixel = 0,
Parent = track,
})
addCorner(knob, 6)


local function set(value)
    Config[key] = value == true
    animate(track, {BackgroundColor3 = Config[key] and COLORS.White or COLORS.Off})
    animate(knob, {
        Position = Config[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = Config[key] and COLORS.Bg or COLORS.TextDim,
    })
end
connect(row.MouseEnter, function() animate(text, {TextColor3 = COLORS.White}) end)
connect(row.MouseLeave, function() animate(text, {TextColor3 = COLORS.Text}) end)
connect(row.Activated, function() set(not Config[key]) end)
Controls[key] = {Set = set}
set(Config[key])


end

local function slider(parent, key, label, minimum, maximum, decimals, suffix, onChange)
local row = create("Frame", {
Size = UDim2.new(1, 0, 0, 34),
BackgroundTransparency = 1,
Parent = parent,
})
create("TextLabel", {
Text = label,
Font = Enum.Font.Gotham,
TextSize = 12,
TextColor3 = COLORS.Text,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Size = UDim2.new(0.6, 0, 0, 16),
Parent = row,
})
local valueLabel = create("TextLabel", {
Text = "",
Font = Enum.Font.GothamBold,
TextSize = 11,
TextColor3 = COLORS.TextDim,
TextXAlignment = Enum.TextXAlignment.Right,
BackgroundTransparency = 1,
Size = UDim2.new(0.4, 0, 0, 16),
Position = UDim2.new(0.6, 0, 0, 0),
Parent = row,
})
local bar = create("Frame", {
Size = UDim2.new(1, 0, 0, 4),
Position = UDim2.new(0, 0, 0, 24),
BackgroundColor3 = COLORS.Off,
BorderSizePixel = 0,
Parent = row,
})
addCorner(bar, 2)
local fill = create("Frame", {
Size = UDim2.fromScale(0, 1),
BackgroundColor3 = COLORS.White,
BorderSizePixel = 0,
Parent = bar,
})
addCorner(fill, 2)
local knob = create("Frame", {
Size = UDim2.fromOffset(9, 9),
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
BackgroundColor3 = COLORS.White,
BorderSizePixel = 0,
ZIndex = 2,
Parent = bar,
})
addCorner(knob, 5)
local hit = create("TextButton", {
Text = "",
BackgroundTransparency = 1,
AutoButtonColor = false,
Size = UDim2.new(1, 0, 0, 18),
Position = UDim2.new(0, 0, 0.5, -9),
ZIndex = 3,
Parent = bar,
})


local function set(value)
    value = math.clamp(tonumber(value) or minimum, minimum, maximum)
    local pct = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
    local scale = 10 ^ (decimals or 0)
    value = math.floor(value * scale + 0.5) / scale
    Config[key] = value
    pct = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
    fill.Size = UDim2.fromScale(pct, 1)
    knob.Position = UDim2.new(pct, 0, 0.5, 0)
    valueLabel.Text = string.format("%." .. tostring(decimals or 0) .. "f", value) .. (suffix or "")
    if onChange then onChange(value) end
end
local active = false
local function updateFromX(x)
    local width = bar.AbsoluteSize.X
    if width <= 0 then return end
    local pct = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
    set(minimum + pct * (maximum - minimum))
end
connect(hit.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        active = true
        updateFromX(input.Position.X)
    end
end)
connect(UserInputService.InputChanged, function(input)
    if active and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        updateFromX(input.Position.X)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        active = false
    end
end)
Controls[key] = {Set = set}
set(Config[key])


end

local function dropdown(parent, key, label, options)
local row = create("Frame", {
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
ClipsDescendants = false,
Parent = parent,
})
create("TextLabel", {
Text = label,
Font = Enum.Font.Gotham,
TextSize = 12,
TextColor3 = COLORS.Text,
TextXAlignment = Enum.TextXAlignment.Left,
BackgroundTransparency = 1,
Size = UDim2.new(0.5, 0, 1, 0),
Parent = row,
})
local button = create("TextButton", {
Text = tostring(Config[key]) .. " ▾",
Font = Enum.Font.Gotham,
TextSize = 11,
TextColor3 = COLORS.Text,
BackgroundColor3 = COLORS.Panel,
BorderSizePixel = 0,
AutoButtonColor = false,
Size = UDim2.fromOffset(126, 22),
Position = UDim2.new(1, -126, 0, 3),
ZIndex = 10,
Parent = row,
})
addCorner(button, 4)
addStroke(button, COLORS.Line, 1)


local menu = create("Frame", {
    Size = UDim2.fromOffset(126, 0),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 30,
    Parent = ScreenGui,
})
addCorner(menu, 4)
addStroke(menu, COLORS.Line, 1)
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = menu,
})

local expanded = false
local function close()
    expanded = false
    menu.Visible = false
end
local function set(value)
    if table.find(options, value) then
        Config[key] = value
        button.Text = tostring(value) .. "  ▾"
    end
    close()
end
for _, option in ipairs(options) do
    local optionButton = create("TextButton", {
        Text = tostring(option),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = COLORS.TextDim,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        ZIndex = 31,
        Parent = menu,
    })
    connect(optionButton.MouseEnter, function()
        optionButton.BackgroundColor3 = COLORS.PanelHi
        optionButton.BackgroundTransparency = 0
        optionButton.TextColor3 = COLORS.White
    end)
    connect(optionButton.MouseLeave, function()
        optionButton.BackgroundTransparency = 1
        optionButton.TextColor3 = COLORS.TextDim
    end)
    connect(optionButton.Activated, function() set(option) end)
end
connect(button.Activated, function()
    expanded = not expanded
    if expanded then
        local pos = button.AbsolutePosition
        menu.Position = UDim2.fromOffset(pos.X, pos.Y + button.AbsoluteSize.Y + 2)
        menu.Size = UDim2.fromOffset(126, #options * 24)
        menu.Visible = true
    else
        close()
    end
end)
connect(ScreenGui:GetPropertyChangedSignal("Enabled"), function()
    if not ScreenGui.Enabled then close() end
end)
Controls[key] = {Set = set}


end

local function actionButton(parent, label, callback)
local button = create("TextButton", {
Text = label,
Font = Enum.Font.GothamMedium,
TextSize = 12,
TextColor3 = COLORS.Text,
BackgroundColor3 = COLORS.Panel,
BorderSizePixel = 0,
AutoButtonColor = false,
Size = UDim2.new(1, 0, 0, 28),
Parent = parent,
})
addCorner(button, 4)
addStroke(button, COLORS.Line, 1)
connect(button.MouseEnter, function() animate(button, {BackgroundColor3 = COLORS.PanelHi}) end)
connect(button.MouseLeave, function() animate(button, {BackgroundColor3 = COLORS.Panel}) end)
connect(button.Activated, function()
local ok, err = pcall(callback)
if not ok then warn("[Monochrome] Button error: " .. tostring(err)) end
end)
end

local GuiService = game:GetService("GuiService")

local function isPointer(input)
return input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerMove(input)
return input.UserInputType == Enum.UserInputType.MouseMovement
or input.UserInputType == Enum.UserInputType.Touch
end

local function bindDrag(hit, onDrag)
local active = false
local function update(position)
local y = position.Y + GuiService:GetGuiInset().Y
local size = hit.AbsoluteSize
if size.X <= 0 or size.Y <= 0 then return end
local px = math.clamp((position.X - hit.AbsolutePosition.X) / size.X, 0, 1)
local py = math.clamp((y - hit.AbsolutePosition.Y) / size.Y, 0, 1)
onDrag(px, py)
end
connect(hit.InputBegan, function(input)
if isPointer(input) then
active = true
update(input.Position)
end
end)
connect(UserInputService.InputChanged, function(input)
if active and isPointerMove(input) then update(input.Position) end
end)
connect(UserInputService.InputEnded, function(input)
if isPointer(input) then active = false end
end)
end

local function hitArea(parent)
return create("TextButton", {
Text = "",
BackgroundTransparency = 1,
AutoButtonColor = false,
BorderSizePixel = 0,
Size = UDim2.fromScale(1, 1),
ZIndex = 5,
Parent = parent,
})
end

local function colorGroup(parent, prefix, label)
local keyH, keyS, keyV, keyA = prefix .. "H", prefix .. "S", prefix .. "V", prefix .. "A"


local container = create("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Parent = parent,
})
create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = container,
})

local header = create("TextButton", {
    Text = "",
    BackgroundTransparency = 1,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 26),
    LayoutOrder = 1,
    Parent = container,
})
local text = create("TextLabel", {
    Text = label,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -70, 1, 0),
    Parent = header,
})
local arrow = create("TextLabel", {
    Text = "▾",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = COLORS.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -56, 0, 0),
    Size = UDim2.fromOffset(16, 26),
    Parent = header,
})
local swatch = create("Frame", {
    Size = UDim2.fromOffset(34, 16),
    Position = UDim2.new(1, -34, 0.5, -8),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    Parent = header,
})
addCorner(swatch, 4)
addStroke(swatch, COLORS.Line, 1)

local body = create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    LayoutOrder = 2,
    Parent = container,
})
create("UIPadding", {
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 8),
    Parent = body,
})
create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = body,
})

local sv = create("Frame", {
    Size = UDim2.new(1, 0, 0, 110),
    BackgroundColor3 = Color3.fromHSV(0, 1, 1),
    BorderSizePixel = 0,
    LayoutOrder = 1,
    Parent = body,
})
addCorner(sv, 4)
local whiteLayer = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    Parent = sv,
})
addCorner(whiteLayer, 4)
create("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = whiteLayer,
})
local blackLayer = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BorderSizePixel = 0,
    Parent = sv,
})
addCorner(blackLayer, 4)
create("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }),
    Parent = blackLayer,
})
local svCursor = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(12, 12),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = sv,
})
addCorner(svCursor, 6)
addStroke(svCursor, COLORS.White, 2)
local svHit = hitArea(sv)

local hue = create("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    Parent = body,
})
addCorner(hue, 4)
local hueKeys = {}
for step = 0, 6 do
    hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(step / 6, Color3.fromHSV(step / 6, 1, 1))
end
create("UIGradient", {Color = ColorSequence.new(hueKeys), Parent = hue})
local hueKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(8, 20),
    Position = UDim2.fromScale(0, 0.5),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = hue,
})
addCorner(hueKnob, 3)
addStroke(hueKnob, COLORS.White, 2)
local hueHit = hitArea(hue)

local alpha = create("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = Color3.fromRGB(150, 150, 150),
    BorderSizePixel = 0,
    LayoutOrder = 3,
    Parent = body,
})
addCorner(alpha, 4)
local alphaOverlay = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = alpha,
})
addCorner(alphaOverlay, 4)
create("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }),
    Parent = alphaOverlay,
})
local alphaKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(8, 20),
    Position = UDim2.fromScale(1, 0.5),
    BackgroundColor3 = COLORS.White,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = alpha,
})
addCorner(alphaKnob, 3)
addStroke(alphaKnob, COLORS.White, 2)
local alphaHit = hitArea(alpha)

local checkerBuilt = false
local function buildChecker()
    if checkerBuilt then return end
    checkerBuilt = true
    local columns = 54
    for row = 0, 1 do
        for column = 0, columns - 1 do
            if (row + column) % 2 == 0 then
                create("Frame", {
                    Size = UDim2.new(1 / columns, 0, 0.5, 0),
                    Position = UDim2.new(column / columns, 0, row * 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(235, 235, 235),
                    BorderSizePixel = 0,
                    Parent = alpha,
                })
            end
        end
    end
end

local function refresh()
    local h = math.clamp(tonumber(Config[keyH]) or 0, 0, 1)
    local s = math.clamp(tonumber(Config[keyS]) or 0, 0, 1)
    local v = math.clamp(tonumber(Config[keyV]) or 1, 0, 1)
    local a = math.clamp(tonumber(Config[keyA]) or 1, 0, 1)
    local color = Color3.fromHSV(h, s, v)
    swatch.BackgroundColor3 = color
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svCursor.Position = UDim2.fromScale(s, 1 - v)
    svCursor.BackgroundColor3 = color
    hueKnob.Position = UDim2.fromScale(h, 0.5)
    hueKnob.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    alphaOverlay.BackgroundColor3 = color
    alphaKnob.Position = UDim2.fromScale(a, 0.5)
    alphaKnob.BackgroundColor3 = color
end

bindDrag(svHit, function(px, py)
    Config[keyS] = px
    Config[keyV] = 1 - py
    refresh()
end)
bindDrag(hueHit, function(px)
    Config[keyH] = px
    refresh()
end)
bindDrag(alphaHit, function(px)
    Config[keyA] = px
    refresh()
end)

for _, key in ipairs({keyH, keyS, keyV, keyA}) do
    Controls[key] = {
        Set = function(value)
            Config[key] = value
            refresh()
        end,
    }
end

connect(header.MouseEnter, function() animate(text, {TextColor3 = COLORS.White}) end)
connect(header.MouseLeave, function() animate(text, {TextColor3 = COLORS.Text}) end)
connect(header.Activated, function()
    buildChecker()
    body.Visible = not body.Visible
    arrow.Text = body.Visible and "▴" or "▾"
end)

refresh()


end

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PlayerInfo = {}

local R15_BONES = {
{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6_BONES = {
{"Head", "Torso"},
{"Torso", "Left Arm"}, {"Torso", "Right Arm"},
{"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function getRoot(character)
return character and (character:FindFirstChild("HumanoidRootPart")
or character:FindFirstChild("Head")
or character.PrimaryPart)
end

local function removeInfo(player)
local entry = PlayerInfo[player]
if not entry then return end
if entry.Billboard then entry.Billboard:Destroy() end
if entry.Highlight then entry.Highlight:Destroy() end
if entry.SkeletonFolder then entry.SkeletonFolder:Destroy() end
PlayerInfo[player] = nil
end

local function buildInfo(player, character, root, humanoid)
removeInfo(player)


local billboard = create("BillboardGui", {
    Name = "MonochromeInfo",
    Adornee = root,
    AlwaysOnTop = true,
    Size = UDim2.fromOffset(160, 46),
    StudsOffset = Vector3.new(0, 3.2, 0),
    LightInfluence = 0,
    ResetOnSpawn = false,
    Enabled = false,
    Parent = PlayerGui,
})
local label = create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = COLORS.White,
    TextStrokeTransparency = 0.4,
    TextStrokeColor3 = COLORS.Bg,
    TextWrapped = true,
    Text = "",
    Parent = billboard,
})
local highlight = create("Highlight", {
    Name = "MonochromeHighlight",
    Adornee = character,
    FillColor = COLORS.White,
    FillTransparency = 0.8,
    OutlineColor = COLORS.White,
    OutlineTransparency = 0,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    Enabled = false,
    Parent = character,
})

local bones = humanoid.RigType == Enum.HumanoidRigType.R15 and R15_BONES or R6_BONES
local folder = create("Folder", {Name = "Skeleton_" .. player.Name, Parent = OverlayGui})
local lines = {}
for index = 1, #bones do
    lines[index] = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLORS.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(0, 2),
        Visible = false,
        Parent = folder,
    })
end

PlayerInfo[player] = {
    Billboard = billboard,
    Label = label,
    Highlight = highlight,
    SkeletonFolder = folder,
    Lines = lines,
    Bones = bones,
    Character = character,
    Humanoid = humanoid,
    Root = root,
    RigType = humanoid.RigType,
}


end

local function hideSkeleton(entry)
for _, line in ipairs(entry.Lines) do line.Visible = false end
end

local function drawSkeleton(entry, camera, color, transparency)
for index, bone in ipairs(entry.Bones) do
local line = entry.Lines[index]
local partA = entry.Character:FindFirstChild(bone[1])
local partB = entry.Character:FindFirstChild(bone[2])
if partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
local a, b = camera:WorldToViewportPoint(partA.Position), camera:WorldToViewportPoint(partB.Position)
if a.Z > 0 and b.Z > 0 then
local p1, p2 = Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y)
local delta = p2 - p1
line.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
line.Size = UDim2.fromOffset(delta.Magnitude, 2)
line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
line.BackgroundColor3 = color
line.BackgroundTransparency = transparency
line.Visible = true
else
line.Visible = false
end
else
line.Visible = false
end
end
end

local function syncPlayers()
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer then
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = getRoot(character)
if character and humanoid and root then
local entry = PlayerInfo[player]
if not entry
or entry.Character ~= character
or entry.Root ~= root
or entry.RigType ~= humanoid.RigType
or not entry.Billboard.Parent then
buildInfo(player, character, root, humanoid)
end
else
removeInfo(player)
end
end
end
end

connect(Players.PlayerRemoving, removeInfo)

local lastSync = 0
connect(RunService.RenderStepped, function()
if Destroyed then return end
local now = os.clock()
if now - lastSync >= 0.25 then
lastSync = now
syncPlayers()
end


local camera = Workspace.CurrentCamera
if not camera then return end
local myRoot = getRoot(LocalPlayer.Character)
local origin = myRoot and myRoot.Position or camera.CFrame.Position
local maxDistance = tonumber(Config.MaxDistance) or 750
local labelColor, labelAlpha = cfgColor("Label"), cfgAlpha("Label")
local hlFill, hlFillAlpha = cfgColor("HlFill"), cfgAlpha("HlFill")
local hlOutline, hlOutlineAlpha = cfgColor("HlOutline"), cfgAlpha("HlOutline")
local skeletonColor, skeletonAlpha = cfgColor("Skeleton"), cfgAlpha("Skeleton")

for player, entry in pairs(PlayerInfo) do
    local humanoid, root = entry.Humanoid, entry.Root
    if not entry.Character.Parent or humanoid.Health <= 0 or not root.Parent then
        entry.Billboard.Enabled = false
        entry.Highlight.Enabled = false
        hideSkeleton(entry)
    else
        local distance = (origin - root.Position).Magnitude
        local inRange = distance <= maxDistance

        local lines = {}
        if Config.ShowPlayerNames then
            table.insert(lines, player.DisplayName)
        end
        if Config.ShowHealth then
            table.insert(lines, string.format("HP %d/%d",
                math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5)))
        end
        if Config.ShowDistance then
            table.insert(lines, string.format("%d studs", math.floor(distance + 0.5)))
        end

        entry.Label.Text = table.concat(lines, "\n")
        entry.Billboard.Enabled = inRange and #lines > 0
        entry.Highlight.Enabled = inRange and Config.ShowHighlights
        entry.Label.TextColor3 = labelColor
        entry.Label.TextTransparency = 1 - labelAlpha
        entry.Highlight.FillColor = hlFill
        entry.Highlight.FillTransparency = 1 - hlFillAlpha
        entry.Highlight.OutlineColor = hlOutline
        entry.Highlight.OutlineTransparency = 1 - hlOutlineAlpha

        if inRange and Config.ShowSkeleton then
            drawSkeleton(entry, camera, skeletonColor, 1 - skeletonAlpha)
        else
            hideSkeleton(entry)
        end
    end
end


end)

local Aim = {
held = false,
toggled = false,
target = nil, -- { Player, Part, Offset, Distance }
}

local aimRayParams = RaycastParams.new()
local okFilter = pcall(function()
aimRayParams.FilterType = Enum.RaycastFilterType.Exclude
end)
if not okFilter then
pcall(function()
aimRayParams.FilterType = Enum.RaycastFilterType.Blacklist
end)
end

local function aimParts(character)
local list = {}
local function add(name)
local part = character:FindFirstChild(name)
if part and part:IsA("BasePart") then
table.insert(list, part)
end
end
if Config.AimTargetPart == "Nearest" then
add("Head")
add("UpperTorso")
add("Torso")
add("HumanoidRootPart")
else
add(Config.AimTargetPart)
if #list == 0 then add("HumanoidRootPart") end
end
return list
end

local function hasLineOfSight(origin, part)
local filter = {}
if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
if part.Parent then table.insert(filter, part.Parent) end
aimRayParams.FilterDescendantsInstances = filter
local result = Workspace:Raycast(origin, part.Position - origin, aimRayParams)
return result == nil
end

local function canTarget(player, origin, maxDistance)
if player == LocalPlayer then return nil end
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = getRoot(character)
if not (character and humanoid and root and root.Parent) then return nil end
if humanoid.Health <= 0 then return nil end
if Config.AimTeamCheck and player.Team ~= nil and player.Team == LocalPlayer.Team then return nil end
local distance = (origin - root.Position).Magnitude
if distance > maxDistance then return nil end
return character, distance
end

local function acquireTarget(camera, center, fov, maxDistance)
local origin = camera.CFrame.Position
local best, bestScore = nil, nil
for _, player in ipairs(Players:GetPlayers()) do
local character, distance = canTarget(player, origin, maxDistance)
if character then
for _, part in ipairs(aimParts(character)) do
local screen = camera:WorldToViewportPoint(part.Position)
if screen.Z > 0 then
local offset = (Vector2.new(screen.X, screen.Y) - center).Magnitude
if offset <= fov and (bestScore == nil or offset < bestScore) then
if not Config.AimVisibleCheck or hasLineOfSight(origin, part) then
best = { Player = player, Part = part, Offset = offset, Distance = distance }
bestScore = offset
end
end
end
end
end
end
return best
end

local function stillValid(target, camera, center, fov, maxDistance)
if not target then return false end
local character = target.Player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if not (character and humanoid and humanoid.Health > 0) then return false end
local part = target.Part
if not (part and part.Parent) then return false end
local origin = camera.CFrame.Position
if (origin - part.Position).Magnitude > maxDistance then return false end
local screen = camera:WorldToViewportPoint(part.Position)
if screen.Z <= 0 then return false end
return (Vector2.new(screen.X, screen.Y) - center).Magnitude <= fov
end

local function aimStep(dt)
if Destroyed then return end
local camera = Workspace.CurrentCamera
if not camera then return end


local active = Config.AimEnabled == true
if active then
    if Config.AimActivation == "Hold key" then
        active = Aim.held
    elseif Config.AimActivation == "Toggle key" then
        active = Aim.toggled
    end
end
if active and UserInputService:GetFocusedTextBox() then
    active = false
end

if not active then
    Aim.target = nil
    AimLocked = false
    AimMarker.Visible = false
    return
end

local center = camera.ViewportSize * 0.5
local fov = math.clamp(tonumber(Config.AimFOV) or 120, 5, 2000)
local maxDistance = math.clamp(tonumber(Config.AimMaxDistance) or 750, 10, 10000)

local target
if Config.AimSticky and stillValid(Aim.target, camera, center, fov, maxDistance) then
    target = Aim.target
else
    target = acquireTarget(camera, center, fov, maxDistance)
end

if not target then
    Aim.target = nil
    AimLocked = false
    AimMarker.Visible = false
    return
end

Aim.target = target
AimLocked = true

local part = target.Part
local aimPosition = part.Position
local lead = math.clamp(tonumber(Config.AimPrediction) or 0, 0, 1)
if lead > 0 then
    local velocity = part.AssemblyLinearVelocity
    if velocity then
        aimPosition = aimPosition + velocity * lead
    end
end

local screen = camera:WorldToViewportPoint(aimPosition)
if screen.Z > 0 and Config.AimShowMarker then
    AimMarker.Position = UDim2.fromOffset(screen.X, screen.Y)
    AimMarkerStroke.Color = cfgColor("Aim")
    AimMarkerStroke.Transparency = 1 - cfgAlpha("Aim")
    AimMarker.Visible = true
else
    AimMarker.Visible = false
end

local smooth = math.clamp(tonumber(Config.AimSmoothness) or 0, 0, 95) / 100
local alpha = smooth <= 0 and 1
    or 1 - (1 - smooth) ^ (math.clamp(dt, 0.001, 0.25) * 60)

if Config.AimMethod == "Mouse" and type(mousemoverel) == "function" then
    local delta = Vector2.new(screen.X, screen.Y) - center
    if delta.Magnitude > 0.5 then
        mousemoverel(delta.X * alpha, delta.Y * alpha)
    end
else
    camera.CFrame = camera.CFrame:Lerp(
        CFrame.new(camera.CFrame.Position, aimPosition),
        alpha
    )
end


end

RunService:BindToRenderStep("MonochromeAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
local ok, err = pcall(aimStep, dt)
if not ok then warn("[Monochrome] Aim error: " .. tostring(err)) end
end)

local function inputName(input)
if input.UserInputType == Enum.UserInputType.Keyboard then
return input.KeyCode.Name
end
return input.UserInputType.Name
end

connect(UserInputService.InputBegan, function(input)
if inputName(input) ~= Config.AimKey then return end
if Config.AimActivation == "Toggle key" then
Aim.toggled = not Aim.toggled
elseif Config.AimActivation == "Hold key" then
Aim.held = true
end
end)
connect(UserInputService.InputEnded, function(input)
if inputName(input) ~= Config.AimKey then return end
if Config.AimActivation == "Hold key" then
Aim.held = false
end
end)

local visualPage = createTab("VISUALS")
section(visualPage, "Display options")
toggle(visualPage, "ShowPlayerNames", "Player names")
toggle(visualPage, "ShowDistance", "Distance labels")
toggle(visualPage, "ShowHealth", "Health labels")
toggle(visualPage, "ShowHighlights", "Highlights")
toggle(visualPage, "ShowSkeleton", "Skeleton")
toggle(visualPage, "ShowCrosshair", "Show center crosshair")
toggle(visualPage, "ShowFOVCircle", "Show FOV circle")
slider(visualPage, "FOVRadius", "FOV circle radius", 20, 600, 0, " px")
slider(visualPage, "CrosshairSize", "Crosshair size", 6, 60, 0, " px")
section(visualPage, "Range")
slider(visualPage, "MaxDistance", "Maximum distance", 50, 3000, 0, " studs")
divider(visualPage)

local aimPage = createTab("AIM")
section(aimPage, "Aimbot")
toggle(aimPage, "AimEnabled", "Enable aimbot")
dropdown(aimPage, "AimActivation", "Activation", {"Hold key", "Toggle key", "Always on"})
dropdown(aimPage, "AimKey", "Aim key", {"E", "Q", "C", "T", "LeftAlt", "MouseButton2"})
dropdown(aimPage, "AimMethod", "Aim method", {"Camera", "Mouse"})
dropdown(aimPage, "AimTargetPart", "Target part", {"Head", "HumanoidRootPart", "UpperTorso", "Nearest"})
section(aimPage, "Behaviour")
slider(aimPage, "AimFOV", "Field of view", 20, 600, 0, " px")
toggle(aimPage, "AimSyncFOV", "Draw FOV circle at aimbot radius")
slider(aimPage, "AimSmoothness", "Smoothing", 0, 90, 0, "%")
slider(aimPage, "AimMaxDistance", "Maximum distance", 50, 3000, 0, " studs")
slider(aimPage, "AimPrediction", "Velocity prediction", 0, 0.5, 2, " s")
section(aimPage, "Filters")
toggle(aimPage, "AimTeamCheck", "Ignore teammates")
toggle(aimPage, "AimVisibleCheck", "Require line of sight")
toggle(aimPage, "AimSticky", "Keep current target")
toggle(aimPage, "AimShowMarker", "Show target marker")

local colorsPage = createTab("COLORS")
section(colorsPage, "Player overlay")
colorGroup(colorsPage, "Label", "Label text")
colorGroup(colorsPage, "HlFill", "Highlight fill")
colorGroup(colorsPage, "HlOutline", "Highlight outline")
colorGroup(colorsPage, "Skeleton", "Skeleton")
section(colorsPage, "Screen overlay")
colorGroup(colorsPage, "Crosshair", "Crosshair")
colorGroup(colorsPage, "FOV", "FOV circle")
colorGroup(colorsPage, "Aim", "Aim target marker")

local settingsPage = createTab("SETTINGS")
section(settingsPage, "Interface")
toggle(settingsPage, "Animations", "Enable animations")
dropdown(settingsPage, "UIKey", "Toggle interface key", {
"RightShift", "Insert", "Home", "End",
})
actionButton(settingsPage, "Reset to defaults", function()
for key, value in pairs(DEFAULTS) do
Config[key] = value
if Controls[key] then Controls[key].Set(value) end
end
end)
actionButton(settingsPage, "Print config to console", function()
print("[Monochrome] Config:")
for key, value in pairs(Config) do
print(string.format(" %s = %s", key, tostring(value)))
end
end)

actionButton(settingsPage, "Save config (.COCK)", function()
    local HttpService = game:GetService("HttpService")

    if type(writefile) ~= "function" then
        warn("[Monochrome] Speichern nicht verfügbar: writefile wird in dieser Umgebung nicht unterstützt.")
        SidebarStatus.Text = "SAVE NOT SUPPORTED"
        return
    end

    local ok, result = pcall(function()
        local encoded = HttpService:JSONEncode(Config)
        writefile("Monochrome.COCK", encoded)
        return #encoded
    end)

    if ok then
        SidebarStatus.Text = "CONFIG SAVED"
        print("[Monochrome] Config gespeichert: Monochrome.COCK (" .. tostring(result) .. " Bytes)")
    else
        SidebarStatus.Text = "SAVE FAILED"
        warn("[Monochrome] Config konnte nicht gespeichert werden: " .. tostring(result))
    end
end)
section(settingsPage, "Information")
create("TextLabel", {
Text = "UI key toggles the menu. Aim key locks onto the closest target inside the FOV circle. Camera method works everywhere, Mouse method needs mousemoverel support. Player labels/highlights require integration in a game you own.",
Font = Enum.Font.Gotham,
TextSize = 11,
TextColor3 = COLORS.TextDim,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Top,
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 60),
Parent = settingsPage,
})

connect(UserInputService.InputBegan, function(input, gameProcessed)
if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
if input.KeyCode.Name ~= Config.UIKey then return end
if UserInputService:GetFocusedTextBox() then return end
ScreenGui.Enabled = not ScreenGui.Enabled
end)

ScreenGui.Enabled = true
ScreenGui.DisplayOrder = 100

switchTab("VISUALS")

local API = {}
function API.Show() if not Destroyed then ScreenGui.Enabled = true end end
function API.Hide() if not Destroyed then ScreenGui.Enabled = false end end
function API.Toggle() if not Destroyed then ScreenGui.Enabled = not ScreenGui.Enabled end end
function API.GetConfig() return Config end
function API.SetAimEnabled(value)
Config.AimEnabled = value == true
if Controls.AimEnabled then Controls.AimEnabled.Set(Config.AimEnabled) end
end
function API.GetAimTarget()
return Aim.target and Aim.target.Player or nil
end
function API.Destroy()
if Destroyed then return end
Destroyed = true
pcall(function() RunService:UnbindFromRenderStep("MonochromeAim") end)
for _, connection in ipairs(Connections) do
if connection.Connected then connection:Disconnect() end
end
table.clear(Connections)
for player in pairs(PlayerInfo) do removeInfo(player) end
ScreenGui:Destroy()
if OverlayGui then OverlayGui:Destroy() end
end

_G.Monochrome = API
print("[Monochrome] Loaded. UI key: " .. Config.UIKey .. " | Aim key: " .. Config.AimKey)