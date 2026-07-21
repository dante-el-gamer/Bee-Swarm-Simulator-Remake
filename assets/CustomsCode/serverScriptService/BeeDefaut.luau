local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[AbejaScript]: Iniciando script inteligente de combate...")

-- MODO DE DEPURACIÓN (Muestra mensajes en la consola para saber qué pasa)
local DEBUG_MODE = true

local folder = ReplicatedStorage:WaitForChild("AllPlayersDefaut", 10)
if not folder then
	warn("[AbejaScript ERROR]: No se encontró la carpeta 'AllPlayersDefaut'.")
	return
end

local BeeTemplate = folder:WaitForChild("Demo Bee", 10)
if not BeeTemplate then
	warn("[AbejaScript ERROR]: No se encontró 'Demo Bee'.")
	return
end

local EnemyFolder = workspace:WaitForChild("Enemy", 10)
if not EnemyFolder then
	warn("[AbejaScript ERROR]: No se encontró la carpeta 'Enemy' en el Workspace.")
	return
end

-- CONFIGURACIÓN AJUSTADA
local MIN_RADIUS = 5  
local MAX_RADIUS = 15 
local DETECT_ENEMY_RADIUS = 50 -- ¡Aumentado a 50 para mayor rango de visión!
local ATTACK_DURATION = 0.6    
local ATTACK_COOLDOWN = 1.2    
local DAMAGE_AMOUNT = 2        

local Bees = {}

-- Función auxiliar para obtener la vida de un modelo sin importar cómo esté configurada
local function getEnemyHealth(model)
	-- 1. Intenta por Atributo
	local attrHealth = model:GetAttribute("Health")
	if attrHealth then return attrHealth, "Attribute" end

	-- 2. Intenta por Humanoid (BeeEnemy o cualquiera)
	local hum = model:FindFirstChild("BeeEnemy") or model:FindFirstChildWhichIsA("Humanoid")
	if hum then return hum.Health, "Humanoid", hum end

	-- 3. Intenta por Objeto de Valor (IntValue / NumberValue)
	local val = model:FindFirstChild("Health")
	if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
		return val.Value, "ValueObject", val
	end

	return nil, nil, nil
end

-- Función para aplicar daño dinámicamente según el sistema que use el enemigo
local function applyDamageToEnemy(model, currentHealth, hpType, extraComponent)
	local newHealth = math.max(0, currentHealth - DAMAGE_AMOUNT)

	if hpType == "Attribute" then
		model:SetAttribute("Health", newHealth)
		if newHealth <= 0 then model:Destroy() end

	elseif hpType == "Humanoid" and extraComponent then
		extraComponent:TakeDamage(DAMAGE_AMOUNT)
		if extraComponent.Health <= 0 then model:Destroy() end

	elseif hpType == "ValueObject" and extraComponent then
		extraComponent.Value = newHealth
		if newHealth <= 0 then model:Destroy() end
	end

	if DEBUG_MODE then
		print("[Combate]: Abeja infligió -" .. DAMAGE_AMOUNT .. " de daño vía [" .. hpType .. "]. Vida restante: " .. newHealth)
	end
end

-- Buscador de enemigos optimizado y recursivo
local function findClosestEnemy(playerPosition)
	local closestEnemy = nil
	local shortestDistance = DETECT_ENEMY_RADIUS
	local enemiesFoundInFolder = #EnemyFolder:GetChildren()

	if DEBUG_MODE and enemiesFoundInFolder == 0 then
		print("[Debug Abeja]: La carpeta 'Enemy' está vacía. Coloca tus modelos ahí.")
	end

	for _, child in pairs(EnemyFolder:GetChildren()) do
		if child:IsA("Model") then
			local health, hpType, _ = getEnemyHealth(child)
			-- Búsqueda recursiva (true) de partes físicas por si no tiene PrimaryPart asignado
			local enemyPart = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)

			if not health then
				if DEBUG_MODE then 
					warn("[Debug Abeja]: Se detectó el modelo '" .. child.Name .. "' pero no tiene Atributo 'Health', ni Humanoid, ni ValueObject.") 
				end
				continue
			end

			if not enemyPart then
				if DEBUG_MODE then 
					warn("[Debug Abeja]: El modelo '" .. child.Name .. "' no tiene ninguna parte física (BasePart) para que la abeja lo detecte.") 
				end
				continue
			end

			if health > 0 then
				local distance = (playerPosition - enemyPart.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestEnemy = child
				end
			end
		end
	end
	return closestEnemy
end

local function getGroundY(targetX, targetZ, character)
	local rayOrigin = Vector3.new(targetX, character.HumanoidRootPart.Position.Y + 20, targetZ)
	local rayDirection = Vector3.new(0, -60, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character, folder, EnemyFolder} 

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then return result.Position.Y else return character.HumanoidRootPart.Position.Y - 2 end
end

local function createBee(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local bee = BeeTemplate:Clone()
	bee.Name = player.Name .. "_Bee"
	bee.Parent = workspace

	local primary = bee.PrimaryPart or bee:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		warn("[AbejaScript ERROR]: La abeja clonada no tiene partes válidas.")
		bee:Destroy()
		return
	end
	bee.PrimaryPart = primary
	bee:PivotTo(hrp.CFrame)

	for _, part in pairs(bee:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true       
			part.CanCollide = false    
			part.CanTouch = false      
			part.CanQuery = false      
		end
	end

	Bees[player] = { 
		Model = bee, 
		Target = hrp.Position + Vector3.new(MIN_RADIUS, 0, 0), 
		LastUpdate = 0,
		NextUpdate = 0,
		LookRotation = CFrame.Identity,

		State = "Following",       
		CurrentEnemy = nil,
		AttackTimer = 0,
		CooldownTimer = 0,
		DamageDealt = false,
		AttackStartPos = Vector3.zero
	}
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		if Bees[player] then Bees[player].Model:Destroy() end
		createBee(player, character)
	end)
	if player.Character then
		task.wait(1)
		createBee(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	if Bees[player] then Bees[player].Model:Destroy() Bees[player] = nil end
end)

for _, player in pairs(Players:GetPlayers()) do onPlayerAdded(player) end

RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(Bees) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart

			if data.CooldownTimer > 0 then
				data.CooldownTimer -= dt
			end

			---------------------------------------------------------
			-- ESTADO: ATACANDO
			---------------------------------------------------------
			if data.State == "Attacking" then
				local enemy = data.CurrentEnemy
				local health, hpType, extraComponent = getEnemyHealth(enemy)

				if enemy and enemy.Parent and health and health > 0 then
					local enemyPart = enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart", true)
					data.AttackTimer += dt
					local progress = math.clamp(data.AttackTimer / ATTACK_DURATION, 0, 1)

					local targetPos = enemyPart.Position + Vector3.new(0, 1, 0)
					local linearPos = data.AttackStartPos:Lerp(targetPos, progress)

					local arcHeight = math.sin(progress * math.pi) * 4
					local finalPos = linearPos + Vector3.new(0, arcHeight, 0)

					local direction = targetPos - data.AttackStartPos
					if direction.Magnitude > 0.1 then
						data.LookRotation = CFrame.lookAt(Vector3.zero, direction)
					end

					local flipAngle = -math.rad(progress * 360)
					local flipRotation = CFrame.Angles(flipAngle, 0, 0)

					data.Model:PivotTo(CFrame.new(finalPos) * data.LookRotation * flipRotation)

					-- Aplicar daño dinámico a mitad del giro
					if progress >= 0.4 and not data.DamageDealt then
						data.DamageDealt = true
						applyDamageToEnemy(enemy, health, hpType, extraComponent)
					end

					if progress >= 1 then
						data.State = "Following"
						data.CooldownTimer = ATTACK_COOLDOWN
						data.LastUpdate = 0
						data.NextUpdate = 0 
					end
				else
					data.State = "Following"
					data.CooldownTimer = 0.5
				end

				---------------------------------------------------------
				-- ESTADO: SEGUIR JUGADOR
				---------------------------------------------------------
			elseif data.State == "Following" then
				if data.CooldownTimer <= 0 then
					local targetEnemy = findClosestEnemy(hrp.Position)
					if targetEnemy then
						if DEBUG_MODE then print("[Combate]: ¡Enemigo fijado! Iniciando Backflip hacia " .. targetEnemy.Name) end
						data.State = "Attacking"
						data.CurrentEnemy = targetEnemy
						data.AttackTimer = 0
						data.DamageDealt = false
						data.AttackStartPos = data.Model.PrimaryPart.Position
						continue 
					end
				end

				data.LastUpdate += dt
				if data.LastUpdate >= data.NextUpdate then
					data.LastUpdate = 0
					data.NextUpdate = math.random(15, 30) / 10 

					local angle = math.random() * math.pi * 2
					local distance = MIN_RADIUS + (math.random() * (MAX_RADIUS - MIN_RADIUS))
					local targetX = hrp.Position.X + math.cos(angle) * distance
					local targetZ = hrp.Position.Z + math.sin(angle) * distance
					local groundY = getGroundY(targetX, targetZ, character)

					data.Target = Vector3.new(targetX, groundY + 1.5, targetZ)
				end

				local currentPos = data.Model.PrimaryPart.Position
				local newPos = currentPos:Lerp(data.Target, 0.08)

				local direction = data.Target - newPos
				if direction.Magnitude > 0.05 then
					data.LookRotation = CFrame.lookAt(Vector3.zero, direction)
				end

				local anguloGrados = math.sin(os.clock() * 6) * 5 
				local anguloRadianes = math.rad(anguloGrados)
				local balanceo = CFrame.Angles(0, 0, anguloRadianes)

				data.Model:PivotTo(CFrame.new(newPos) * data.LookRotation * balanceo)
			end

		end
	end
end)