local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Buscar o crear automáticamente el evento de comunicación en ReplicatedStorage
local DamageEvent = ReplicatedStorage:FindFirstChild("BeeDamageEvent")
if not DamageEvent then
	DamageEvent = Instance.new("BindableEvent")
	DamageEvent.Name = "BeeDamageEvent"
	DamageEvent.Parent = ReplicatedStorage
end

print("[DamageVisuals]: Sistema de números de daño activo y escuchando...")

-- Función encargada de crear el efecto visual
local function createDamagePopup(enemy, damageAmount)
	if not enemy or not enemy.Parent then return end

	-- Buscamos la parte física del enemigo para anclar el texto
	local enemyPart = enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart", true)
	if not enemyPart then return end

	-- 1. CREACIÓN DEL CONTENEDOR (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageIndicator"
	billboard.Size = UDim2.new(3, 0, 1.5, 0) -- Tamaño del recuadro
	billboard.AlwaysOnTop = true             -- Se ve a través de las paredes
	billboard.Adornee = enemyPart

	-- Posición inicial (Un poco arriba del enemigo y con una ligera variación aleatoria hacia los lados)
	local randomX = math.random(-15, 15) / 10
	local randomZ = math.random(-15, 15) / 10
	billboard.StudsOffset = Vector3.new(randomX, 2.5, randomZ)
	billboard.Parent = workspace

	-- 2. CREACIÓN DEL TEXTO (TextLabel)
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1 -- Fondo invisible
	textLabel.Text = "-" .. tostring(damageAmount)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne -- Una fuente gruesa y estilo cartoon que queda genial

	-- Colores estilizados (Amarillo vibrante con borde negro)
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) 
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0 -- Borde completamente visible
	textLabel.Parent = billboard

	-- 3. ANIMACIÓN (Tweens)
	local duration = 0.6 -- Cuánto dura el número en pantalla antes de borrarse

	-- Destino de la animación: Subirá 3 studs más en el aire
	local targetOffset = billboard.StudsOffset + Vector3.new(0, 3, 0)

	-- Tween para mover el cartel hacia arriba de forma suave
	local moveTween = TweenService:Create(billboard, TweenInfo.new(duration, Enum.EasingStyle.OutQuad), {
		StudsOffset = targetOffset
	})

	-- Tween para desvanecer el texto (Fade Out) al mismo tiempo
	local fadeTween = TweenService:Create(textLabel, TweenInfo.new(duration, Enum.EasingStyle.InQuad), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	-- Ejecutar las animaciones
	moveTween:Play()
	fadeTween:Play()

	-- 4. LIMPIEZA: Borra el objeto del juego automáticamente cuando termina la animación
	Debris:AddItem(billboard, duration)
end

-- Conectar el evento para que reaccione cada vez que lo llamen
DamageEvent.Event:Connect(createDamagePopup)