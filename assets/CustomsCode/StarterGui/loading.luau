local TITLE_MODE = "IMAGE"
local GAME_NAME = "Bee Swarm Simulator Remake"
local TITLE_IMAGE_ID = "rbxassetid://74082348161682"
local IMAGE_WIDTH_SCALE = 0.55
local IMAGE_HEIGHT_SCALE = 0.24

-- vertical position of the title/image (0..1)
local TITLE_POSITION_Y = 0.45   -- smaller = higher, larger = lower

-- bar
local MIN_LOADING_TIME = 2
local BAR_WIDTH_SCALE = 0.5
local BAR_HEIGHT_SCALE = 0.04
local BAR_POSITION_Y = 0.62

-- colors / gradients
local BAR_COLOR = Color3.fromRGB(0,170,255)
local BAR_GRADIENT_ENABLED = true
local BAR_GRADIENT_COLORS = {Color3.fromRGB(0,170,255), Color3.fromRGB(0,85,255)}

local BAR_BG_COLOR = Color3.fromRGB(40,40,40)
local BAR_BG_GRADIENT_ENABLED = false
local BAR_BG_GRADIENT_COLORS = {Color3.fromRGB(60,60,60), Color3.fromRGB(30,30,30)}

local BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)
local BACKGROUND_GRADIENT_ENABLED = true
local BACKGROUND_GRADIENT_COLORS = {Color3.fromRGB(18, 18, 18), Color3.fromRGB(30, 30, 30)}

-- corners / strokes
local BAR_CORNER_RADIUS = 0.3        -- 0..1
local BAR_BG_CORNER_RADIUS = 1

local BAR_STROKE_ENABLED = true
local BAR_STROKE_COLOR = Color3.fromRGB(0,130,200)
local BAR_STROKE_THICKNESS = 1

local BAR_BG_STROKE_ENABLED = false
local BAR_BG_STROKE_COLOR = Color3.fromRGB(80,80,80)
local BAR_BG_STROKE_THICKNESS = 1

-- title text stroke
local TEXT_COLOR = Color3.new(1,1,1)
local TEXT_FONT = Enum.Font.Montserrat
local TEXT_STROKE_ENABLED = false
local TEXT_STROKE_COLOR = Color3.new(0,0,0)
local TEXT_STROKE_THICKNESS = 0

-- SKIP BUTTON (enabled or not)
local SKIP_BUTTON_ENABLED = true
local SKIP_TEXT = " Skip "
local SKIP_TEXT_COLOR = Color3.fromRGB(170,170,170)
local SKIP_WIDTH_SCALE = 0.2
local SKIP_HEIGHT_SCALE = 0.05
-- offset under the bar (in screen fraction)
local SKIP_OFFSET_Y = 0.06 -- distance below the bar (positive pushes it down)

-- skip appearance
local SKIP_BG_COLOR = Color3.fromRGB(30,30,30)
local SKIP_GRADIENT_ENABLED = false
local SKIP_GRADIENT_COLORS = {Color3.fromRGB(80,80,80), Color3.fromRGB(40,40,40)}
local SKIP_CORNER_RADIUS = 0.3
local SKIP_STROKE_ENABLED = true
local SKIP_STROKE_COLOR = Color3.fromRGB(150,150,150)
local SKIP_STROKE_THICKNESS = 1

-- fade / tween
local FADE_OUT_ENABLED = true
local FADE_OUT_TIME = 0.28
local TWEEN_TIME = 0.14

--------------------
-- SERVICES
--------------------
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------
-- STATE
--------------------
local active = true
local skipped = false

local function safeClamp(n) return math.clamp(n or 0, 0, 1) end

--------------------
-- BUILD GUI
--------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local background = Instance.new("Frame")
background.Size = UDim2.new(1,0,1,0)
background.Position = UDim2.new(0,0,0,0)
background.BackgroundColor3 = BACKGROUND_COLOR
background.BorderSizePixel = 0
background.Parent = gui

if BACKGROUND_GRADIENT_ENABLED then
	local gg = Instance.new("UIGradient")
	gg.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, BACKGROUND_GRADIENT_COLORS[1]),
		ColorSequenceKeypoint.new(1, BACKGROUND_GRADIENT_COLORS[2])
	}
	gg.Rotation = -90
	gg.Parent = background
end


-- TITLE (TEXT or IMAGE) ; configurable position
local titleY = TITLE_POSITION_Y

if TITLE_MODE == "TEXT" then
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6,0,0.08,0)
	title.Position = UDim2.new(0.5,0,titleY,0)
	title.AnchorPoint = Vector2.new(0.5,0.5)
	title.Text = GAME_NAME
	title.TextScaled = true
	title.BackgroundTransparency = 1
	title.TextColor3 = TEXT_COLOR
	title.Font = TEXT_FONT
	title.Parent = background
	if TEXT_STROKE_ENABLED then
		local s = Instance.new("UIStroke")
		s.Parent = title
		s.Color = TEXT_STROKE_COLOR
		s.Thickness = TEXT_STROKE_THICKNESS
	end
else
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(IMAGE_WIDTH_SCALE,0,IMAGE_HEIGHT_SCALE,0)
	img.Position = UDim2.new(0.5,0,titleY,0)
	img.AnchorPoint = Vector2.new(0.5,0.5)
	img.Image = TITLE_IMAGE_ID
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = background
end

-- BAR BACKGROUND (track)
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(BAR_WIDTH_SCALE,0,BAR_HEIGHT_SCALE,0)
barBg.Position = UDim2.new(0.5,0,BAR_POSITION_Y,0)
barBg.AnchorPoint = Vector2.new(0.5,0.5)
barBg.BackgroundColor3 = BAR_BG_COLOR
barBg.BorderSizePixel = 0
barBg.Parent = background

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(BAR_BG_CORNER_RADIUS, 0)
bgCorner.Parent = barBg

if BAR_BG_GRADIENT_ENABLED then
	local gbg = Instance.new("UIGradient")
	gbg.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, BAR_BG_GRADIENT_COLORS[1]),
		ColorSequenceKeypoint.new(1, BAR_BG_GRADIENT_COLORS[2])
	}
	gbg.Parent = barBg
end

if BAR_BG_STROKE_ENABLED then
	local s = Instance.new("UIStroke")
	s.Parent = barBg
	s.Color = BAR_BG_STROKE_COLOR
	s.Thickness = math.max(0.5, BAR_BG_STROKE_THICKNESS)
end

-- PROGRESS BAR
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.Position = UDim2.new(0,0,0,0)
bar.BackgroundColor3 = BAR_COLOR
bar.BorderSizePixel = 0
bar.Parent = barBg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(BAR_CORNER_RADIUS, 0)
barCorner.Parent = bar

if BAR_GRADIENT_ENABLED then
	local gbar = Instance.new("UIGradient")
	gbar.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, BAR_GRADIENT_COLORS[1]),
		ColorSequenceKeypoint.new(1, BAR_GRADIENT_COLORS[2])
	}
	gbar.Parent = bar
end

if BAR_STROKE_ENABLED then
	local s = Instance.new("UIStroke")
	s.Parent = bar
	s.Color = BAR_STROKE_COLOR
	s.Thickness = math.max(0.5, BAR_STROKE_THICKNESS)
end

-- SKIP BUTTON (centered below the bar)
local skipButton
if SKIP_BUTTON_ENABLED then
	skipButton = Instance.new("TextButton")
	skipButton.Size = UDim2.new(SKIP_WIDTH_SCALE,0,SKIP_HEIGHT_SCALE,0)
	-- CENTERED under the bar
	skipButton.Position = UDim2.new(0.5,0,BAR_POSITION_Y + SKIP_OFFSET_Y,0)
	skipButton.AnchorPoint = Vector2.new(0.5,0.5)
	skipButton.Text = SKIP_TEXT
	skipButton.TextScaled = true
	skipButton.BackgroundColor3 = SKIP_BG_COLOR
	skipButton.TextColor3 = SKIP_TEXT_COLOR
	skipButton.Parent = background
	skipButton.AutoButtonColor = true
	skipButton.Font = Enum.Font.Montserrat

	local scorner = Instance.new("UICorner")
	scorner.CornerRadius = UDim.new(SKIP_CORNER_RADIUS,0)
	scorner.Parent = skipButton

	if SKIP_GRADIENT_ENABLED then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, SKIP_GRADIENT_COLORS[1]),
			ColorSequenceKeypoint.new(1, SKIP_GRADIENT_COLORS[2])
		}
		g.Parent = skipButton
	end

	if SKIP_STROKE_ENABLED then
		local s = Instance.new("UIStroke")
		s.Parent = skipButton
		s.Color = SKIP_STROKE_COLOR
		s.Thickness = math.max(0.5, SKIP_STROKE_THICKNESS)
	end
end

--------------------
-- UTILS / SAFETY
--------------------
local function setProgress(progress)
	if not active or not bar or not bar.Parent then return end
	progress = safeClamp(progress)
	local goal = { Size = UDim2.new(progress, 0, 1, 0) }
	TweenService:Create(bar, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function finishAndClose()
	if not active then return end
	active = false
	-- force 100%
	setProgress(1)
	-- fade out
	if FADE_OUT_ENABLED and background then
		local bgTween = TweenService:Create(background, TweenInfo.new(FADE_OUT_TIME), { BackgroundTransparency = 1 })
		bgTween:Play()
		local function tryFade(obj)
			pcall(function()
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					TweenService:Create(obj, TweenInfo.new(FADE_OUT_TIME), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
				elseif obj:IsA("Frame") or obj:IsA("ImageLabel") then
					TweenService:Create(obj, TweenInfo.new(FADE_OUT_TIME), { BackgroundTransparency = 1 }):Play()
				end
			end)
			for _,c in ipairs(obj:GetChildren()) do
				tryFade(c)
			end
		end
		tryFade(background)
		task.wait(FADE_OUT_TIME + 0.02)
	end
	pcall(function() gui:Destroy() end)
end

-- skip handler
if skipButton then
	skipButton.MouseButton1Click:Connect(function()
		if skipped then return end
		skipped = true
		finishAndClose()
	end)
end

--------------------
-- PRELOAD (ContentProvider)
--------------------
local assets = {}
for _,v in ipairs(game:GetDescendants()) do
	if v:IsA("Decal") or v:IsA("Texture") or v:IsA("Sound")
		or v:IsA("MeshPart") or v:IsA("ImageLabel")
		or v:IsA("ImageButton") or v:IsA("Animation") or v:IsA("Mesh") then
		table.insert(assets, v)
	end
end

local total = math.max(#assets, 1)
local loaded = 0
local startTime = os.clock()

-- per-item callback
ContentProvider:PreloadAsync(assets, function()
	loaded = loaded + 1
	-- if skipped or GUI destroyed, stop animating
	if not active or skipped then return end
	local progress = loaded / total
	setProgress(progress)
end)

-- minimal wait, abortable by skip
local elapsed = os.clock() - startTime
if elapsed < MIN_LOADING_TIME and not skipped then
	local remaining = MIN_LOADING_TIME - elapsed
	local waited = 0
	while waited < remaining and not skipped do
		local step = math.min(0.05, remaining - waited)
		task.wait(step)
		waited = waited + step
	end
end

if not skipped then
	finishAndClose()
end
