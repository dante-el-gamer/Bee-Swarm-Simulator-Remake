local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(char)
	character = char
end)

local musicFolder = workspace:WaitForChild("Music")

local currentZone = nil
local currentSound = nil

local function isInside(part, position)
	local pos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2

	return math.abs(pos.X) <= half.X
		and math.abs(pos.Y) <= half.Y
		and math.abs(pos.Z) <= half.Z
end

local function getCorrectSound(zone)
	local day = zone:FindFirstChild("MusicDay")
	local night = zone:FindFirstChild("MusicNight")

	if day and night then
		if Lighting.ClockTime >= 18 or Lighting.ClockTime < 6 then
			return night
		else
			return day
		end
	end

	return zone:FindFirstChild("Music")
end

local function switchSound(newSound)
	if currentSound == newSound then
		return
	end

	local oldTime = 0

	if currentSound then
		oldTime = currentSound.TimePosition
		currentSound:Stop()
	end

	currentSound = newSound

	if currentSound then
		if currentSound.TimeLength > 0 then
			currentSound.TimePosition = math.min(oldTime, currentSound.TimeLength - 0.05)
		end

		currentSound:Play()
	end
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	if currentZone then
		switchSound(getCorrectSound(currentZone))
	end
end)

RunService.RenderStepped:Connect(function()

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local foundZone = nil

	for _, zone in ipairs(musicFolder:GetChildren()) do
		if zone:IsA("BasePart") then
			if isInside(zone, root.Position) then
				foundZone = zone
				break
			end
		end
	end

	if foundZone ~= currentZone then
		currentZone = foundZone

		if currentZone then
			switchSound(getCorrectSound(currentZone))
		else
			if currentSound then
				currentSound:Stop()
				currentSound = nil
			end
		end
	end

end)