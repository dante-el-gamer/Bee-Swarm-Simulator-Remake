local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Configuración
local DAY_DURATION = 63      -- 1 minuto y 3 segundos
local NIGHT_DURATION = 40    -- 40 segundos

local DAY_START = 6
local NIGHT_START = 18

Lighting.ClockTime = DAY_START

while true do

	-- Día (06:00 -> 18:00)
	local start = tick()

	repeat
		local alpha = math.clamp((tick() - start) / DAY_DURATION, 0, 1)
		Lighting.ClockTime = DAY_START + (12 * alpha)
		RunService.Heartbeat:Wait()
	until alpha >= 1

	Lighting.ClockTime = NIGHT_START

	-- Noche (18:00 -> 06:00)
	start = tick()

	repeat
		local alpha = math.clamp((tick() - start) / NIGHT_DURATION, 0, 1)

		local time = NIGHT_START + (12 * alpha)

		if time >= 24 then
			time -= 24
		end

		Lighting.ClockTime = time

		RunService.Heartbeat:Wait()
	until alpha >= 1

	Lighting.ClockTime = DAY_START

end