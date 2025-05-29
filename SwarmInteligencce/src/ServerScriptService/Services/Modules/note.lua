--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ====================================================================
-- CONFIGURAÇÕES GLOBAIS
-- ====================================================================

local MAX_SPEED = 8.0
local MAX_FORCE = 2.0
local VIEW_RADIUS = 5.0
local REPULSION_RADIUS = 50.0
local TARGET_WEIGHT = 2.0

local NUM_ANTS = 50 -- Número de formigas para a pesquisa ACO
local MAX_ACO_ITERATIONS = 500 -- Número de iterações do algoritmo ACO
local EVAPORATION_RATE = 0.05 -- Taxa de evaporação do feromônio
local Q_FACTOR = 100.0 -- Fator de quantidade de feromônio
local ALPHA = 1.0 -- Importância do feromônio
local BETA = 1.5 -- Importância da heurística (1/distância)

-- Ajustes para velocidade e visualização
local UPDATE_DELAY = 0.02 -- Atraso padrão para a simulação de boids (movimento final)
local ACO_VISUALIZATION_DELAY = 0.001 -- REDUZIDO DRÁSTICAMENTE para acelerar a pesquisa

-- ====================================================================
-- ESTRUTURA DE DADOS
-- ====================================================================

local allBoids: {any} = {}
local cities: {Part} = {}
local cityMap: {[string]: Part} = {}

local pheromoneTrails: {[Part]: {[Part]: number}} = {}

-- Flag para controlar se os boids devem se mover (durante ACO vs. movimento final)
local boidsMovementEnabled = false

-- Referência para o caminho visual do "melhor caminho" atual
local currentBestPathVisual: {Part} = {} -- Agora armazena as partes visuais (partículas)

-- ====================================================================
-- FUNÇÕES AUXILIARES (Boids)
-- ====================================================================

local function QueryRepulsors(pos: Vector3): Part?
	for _, v in pairs(Workspace.Repulsors:GetChildren()) do
		if (pos - v.Position).Magnitude < REPULSION_RADIUS then
			return v :: Part
		end
	end
	return nil
end

local function createBoid(position: Vector3, agentModel: Model): {
	Position: Vector3,
	Velocity: Vector3,
	Acceleration: Vector3,
	Agent: Model,
	Model: Model,
	InitialY: number,
	TargetPath: {Part},
	CurrentWaypointIndex: number,
	CurrentIndividualTarget: Vector3?,
	IsAtDestination: boolean,
	repulsion: (self: any) -> (),
	followTarget: (self: any) -> Vector3,
	separation: (self: any, boids_list: {any}) -> Vector3,
	alignment: (self: any, boids_list: {any}) -> Vector3,
	cohesion: (self: any, boids_list: {any}) -> Vector3,
	update: (self: any, boids_list: {any}) -> ()
	}
	local boid = {
		Position = position,
		Velocity = Vector3.new(0, 0, 0), -- Inicia parado
		Acceleration = Vector3.new(0, 0, 0), -- Inicia parado
		Agent = agentModel,
		Model = agentModel,
		InitialY = position.Y,
		TargetPath = {},
		CurrentWaypointIndex = 1,
		CurrentIndividualTarget = nil,
		IsAtDestination = true -- Inicia como "chegou ao destino" para não se mover
	}

	function boid:repulsion()
		local nearestRepulsor = QueryRepulsors(self.Position)
		if not nearestRepulsor then return end

		local distance = (self.Position - nearestRepulsor.Position).Magnitude
		if distance < REPULSION_RADIUS and distance > 0.1 then
			local repelForce = (self.Position - nearestRepulsor.Position).Unit / distance * MAX_SPEED
			self.Acceleration += repelForce
		end
	end

	function boid:followTarget(): Vector3
		if self.CurrentIndividualTarget then
			local desired = (self.CurrentIndividualTarget - self.Position).Unit * MAX_SPEED
			local steer = desired - self.Velocity
			steer = steer.Unit * math.min(steer.Magnitude, MAX_FORCE)

			if (self.Position - self.CurrentIndividualTarget).Magnitude < (MAX_SPEED * 0.5) then
				self.CurrentIndividualTarget = nil
			end
			return steer * TARGET_WEIGHT
		end

		if not self.TargetPath or #self.TargetPath == 0 then
			return Vector3.new(0, 0, 0)
		end

		local targetWaypoint = self.TargetPath[self.CurrentWaypointIndex]
		if not targetWaypoint then
			return Vector3.new(0, 0, 0)
		end

		local desired = (targetWaypoint.Position - self.Position).Unit * MAX_SPEED
		local steer = desired - self.Velocity
		steer = steer.Unit * math.min(steer.Magnitude, MAX_FORCE)

		if (self.Position - targetWaypoint.Position).Magnitude < (MAX_SPEED * 0.5) then
			if self.CurrentWaypointIndex < #self.TargetPath then
				self.CurrentWaypointIndex += 1
			else
				-- Chegou ao destino final
				self.Velocity = Vector3.new(0,0,0)
				self.Acceleration = Vector3.new(0,0,0)
				self.IsAtDestination = true
				return Vector3.new(0,0,0)
			end
		end

		return steer * TARGET_WEIGHT
	end

	function boid:separation(boids_list: {any}): Vector3
		local steer = Vector3.new(0, 0, 0)
		local count = 0

		for _, other in ipairs(boids_list) do
			if other ~= self and (self.Position - other.Position).Magnitude < VIEW_RADIUS and not other.IsAtDestination then
				local distance = (self.Position - other.Position).Magnitude
				if distance > 0.1 then
					local diff = (self.Position - other.Position).Unit / distance
					steer += diff
					count += 1
				end
			end
		end

		if count > 0 then
			steer = steer / count
		end

		if steer.Magnitude > 0 then
			steer = steer.Unit * MAX_SPEED - self.Velocity
			steer = steer.Unit * math.min(steer.Magnitude, MAX_FORCE)
		end

		return steer
	end

	function boid:alignment(boids_list: {any}): Vector3
		local steer = Vector3.new(0, 0, 0)
		local count = 0

		for _, other in ipairs(boids_list) do
			if other ~= self and (self.Position - other.Position).Magnitude < VIEW_RADIUS and not other.IsAtDestination then
				steer += other.Velocity
				count += 1
			end
		end

		if count > 0 then
			steer = steer / count
			steer = steer.Unit * MAX_SPEED - self.Velocity
			steer = steer.Unit * math.min(steer.Magnitude, MAX_FORCE)
		end

		return steer
	end

	function boid:cohesion(boids_list: {any}): Vector3
		local centerOfMass = Vector3.new(0, 0, 0)
		local count = 0

		for _, other in ipairs(boids_list) do
			if other ~= self and (self.Position - other.Position).Magnitude < VIEW_RADIUS and not other.IsAtDestination then
				centerOfMass += other.Position
				count += 1
			end
		end

		if count > 0 then
			centerOfMass = centerOfMass / count
			local desired = (centerOfMass - self.Position).Unit * MAX_SPEED
			local steer = desired - self.Velocity
			steer = steer.Unit * math.min(steer.Magnitude, MAX_FORCE)
			return steer
		else
			return Vector3.new(0, 0, 0)
		end
	end

	function boid:update(boids_list: {any})

		if not boidsMovementEnabled then return end
		if self.IsAtDestination then return end

		local sep = self:separation(boids_list) * 3
		local ali = self:alignment(boids_list) * 10
		local coh = self:cohesion(boids_list) * 1
		local targetSteer = self:followTarget()

		self:repulsion()

		self.Acceleration += sep
		self.Acceleration += ali
		self.Acceleration += coh
		self.Acceleration += targetSteer

		self.Velocity += self.Acceleration
		self.Velocity = self.Velocity.Unit * math.min(self.Velocity.Magnitude, MAX_SPEED)

		self.Position += Vector3.new(self.Velocity.X, 0, self.Velocity.Z)
		self.Position = Vector3.new(self.Position.X, self.InitialY, self.Position.Z)

		self.Acceleration = Vector3.new(0, 0, 0)

		if self.Model and self.Model.PrimaryPart then
			self.Model:SetPrimaryPartCFrame(CFrame.new(self.Position))
		else
			warn("Boid", self.Agent.Name, "perdeu o PrimaryPart ou o Modelo. Removendo da simulação.")
			self.IsAtDestination = true
		end
	end

	return boid
end

-- ====================================================================
-- FUNÇÕES AUXILIARES (ACO)
-- ====================================================================

local function getDistance(city1: Part, city2: Part): number
	return (city1.Position - city2.Position).Magnitude

end

local function calculatePathCost(path: {Part}): number
	local totalDistance = 0
	for i = 1, #path - 1 do
		totalDistance += getDistance(path[i], path[i+1])
	end
	return totalDistance
end

local function initializePheromones()
	for _, city1 in ipairs(cities) do
		pheromoneTrails[city1] = {}
		for _, city2 in ipairs(cities) do
			if city1 ~= city2 then
				pheromoneTrails[city1][city2] = 0.1
			end
		end
	end
end

local function evaporatePheromone()
	for _, city1 in ipairs(cities) do
		for _, city2 in ipairs(cities) do
			if city1 ~= city2 and pheromoneTrails[city1][city2] then
				pheromoneTrails[city1][city2] *= (1 - EVAPORATION_RATE)
			end
		end
	end
end

local function depositPheromone(path: {Part}, pathCost: number)
	local pheromoneAmount = Q_FACTOR / pathCost
	for i = 1, #path - 1 do
		local city1 = path[i]
		local city2 = path[i+1]
		pheromoneTrails[city1][city2] = (pheromoneTrails[city1][city2] or 0) + pheromoneAmount
		pheromoneTrails[city2][city1] = (pheromoneTrails[city2][city1] or 0) + pheromoneAmount
	end
end

local function selectNextCity(currentCity: Part, visitedCities: {[Part]: boolean}, endCity: Part): Part?
	local probabilities = {}
	local totalProbability = 0
	local unvisitedCitiesTable = {} -- Use uma tabela para coletar as cidades não visitadas

	-- Populate unvisitedCitiesTable
	for _, city in ipairs(cities) do
		if not visitedCities[city] then
			table.insert(unvisitedCitiesTable, city)
		end
	end

	local unvisitedCitiesCount = #unvisitedCitiesTable

	-- Special handling for the last step: if only 'endCity' is unvisited, go there directly.
	if unvisitedCitiesCount == 1 and unvisitedCitiesTable[1] == endCity then
		local pheromone = pheromoneTrails[currentCity][endCity] or 0.0001
		local distance = getDistance(currentCity, endCity)
		if distance == 0 then distance = 0.0001 end
		local heuristic = 1 / distance
		-- High probability to ensure path completes
		local prob = (pheromone ^ ALPHA) * (heuristic ^ BETA) * 100000000 -- Significantly increased
		table.insert(probabilities, {city = endCity, prob = prob})
		totalProbability += prob
	else
		-- Normal selection: pick from truly unvisited cities (excluding the endCity if it's not the last one)
		for _, nextCity in ipairs(unvisitedCitiesTable) do -- Iterate only over truly unvisited cities
			if nextCity == currentCity then continue end -- Skip current city (already visited)

			-- If it's the endCity, and we haven't visited all *other* cities yet,
			-- give it a lower chance unless it's the only one left (handled above)
			if nextCity == endCity and unvisitedCitiesCount > 1 then
				continue -- Don't select endCity unless it's the absolute last unvisited city
			end

			local pheromone = pheromoneTrails[currentCity][nextCity] or 0.0001
			local distance = getDistance(currentCity, nextCity)
			if distance == 0 then distance = 0.0001 end

			local heuristic = 1 / distance
			local prob = (pheromone ^ ALPHA) * (heuristic ^ BETA)
			table.insert(probabilities, {city = nextCity, prob = prob})
			totalProbability += prob
		end
	end

	if totalProbability == 0 then
		-- This means no valid unvisited cities were found to move to.
		return nil
	end

	local rand = math.random() * totalProbability
	local cumulativeProb = 0
	for _, entry in ipairs(probabilities) do
		cumulativeProb += entry.prob
		if rand <= cumulativeProb then
			return entry.city
		end
	end

	return nil -- Should ideally not be reached if totalProbability > 0
end


local function buildAntPath(antIndex: number, startCity: Part, endCity: Part): {Part}?
	local currentCity = startCity
	local path = {currentCity}
	local visitedCities = {[currentCity] = true} -- Mark startCity as visited

	local numTotalCities = #cities

	-- Não reposiciona ou move o boid visualmente durante a fase ACO,
	-- Apenas garante que ele está no lugar certo para o movimento final.
	local boid = allBoids[antIndex]
	if boid and boid.Model and boid.Model.PrimaryPart then
		-- Apenas posiciona o modelo, mas não o move na simulação boid por enquanto.
		boid.Model:SetPrimaryPartCFrame(CFrame.new(startCity.Position + Vector3.new(math.random() * 5 - 2.5, 5, math.random() * 5 - 2.5)))
		boid.IsAtDestination = true -- Garante que ele continua parado
	end


	-- Loop principal: a formiga deve visitar todas as cidades antes de tentar ir para 'endCity'
	-- O caminho deve conter todas as cidades.
	while #path < numTotalCities do -- Loop until all cities are in the path
		local nextCity = selectNextCity(currentCity, visitedCities, endCity)

		if nextCity then
			-- Verifica se a próxima cidade já foi visitada como uma cidade intermediária.
			-- Para um TSP "puro", cada cidade é visitada apenas uma vez.
			-- Se tentar revisitar e não for o endCity, o caminho é inválido.
			if visitedCities[nextCity] and nextCity ~= endCity then
				warn("Ant trying to revisit city: ", nextCity.Name, " - Path will be invalid.")
				return nil -- Caminho inválido
			end

			-- Desenha o raio temporário para visualizar o caminho da formiga
			local particula = ReplicatedStorage.Clones.Luz:Clone()
			particula.Parent = Workspace
			particula.Attachment0 = currentCity:FindFirstChild("AT")
			particula.Attachment1 = nextCity:FindFirstChild("AT")
			particula.Color = ColorSequence.new(Color3.fromRGB(0, 0, 255)) -- Azul para caminhos temporários
			game.Debris:AddItem(particula, 0.1) -- Tempo de vida curto para visualização instantânea

			table.insert(path, nextCity)
			visitedCities[nextCity] = true
			currentCity = nextCity

			-- Pequeno atraso para permitir que a visualização ocorra
			task.wait(ACO_VISUALIZATION_DELAY)

		else
			-- A formiga ficou presa: não consegue encontrar a próxima cidade válida.
			warn(string.format("Ant got stuck from %s. Path length: %d. Total cities: %d",
				currentCity.Name, #path, numTotalCities))
			return nil -- Caminho incompleto/inválido
		end
	end

	-- Após o loop, todas as cidades (exceto talvez endCity se ela também for a startCity e já estiver na lista)
	-- devem estar em 'path'. A última cidade no caminho deve ser a 'endCity'.
	if path[#path] ~= endCity then
		local endCityFoundInPath = false
		for _, cityInPath in ipairs(path) do
			if cityInPath == endCity then
				endCityFoundInPath = true
				break
			end
		end

		if not endCityFoundInPath then
			-- Se a endCity não foi visitada (acontece se todas as outras foram e ela é a última a ser adicionada)
			table.insert(path, endCity)
			visitedCities[endCity] = true
			-- Desenha o último raio para a endCity
			local particula = ReplicatedStorage.Clones.Luz:Clone()
			particula.Parent = Workspace
			particula.Attachment0 = currentCity:FindFirstChild("AT")
			particula.Attachment1 = endCity:FindFirstChild("AT")
			particula.Color = ColorSequence.new(Color3.fromRGB(0, 0, 255))
			game.Debris:AddItem(particula, 0.1) -- Tempo de vida curto
			task.wait(ACO_VISUALIZATION_DELAY)
		else
			-- endCity foi visitada, mas não é a última. Isso não é TSP puro para Start->All->End.
			warn("Path completed, but did not end at the target city correctly. Path length:", #path, "Total cities:", numTotalCities)
			return nil
		end
	end

	-- Final check: Ensure all cities were included in the path and it ends at endCity
	if #path < numTotalCities then
		warn("Not all cities were included in the path! Path length:", #path, "Expected:", numTotalCities)
		return nil
	end

	if path[#path] ~= endCity then
		warn("Path completed, but did not end at the target city: ", endCity.Name, ". Final city was: ", path[#path].Name)
		return nil -- Path invalid if it doesn't end at endCity
	end


	return path
end

-- ====================================================================
-- INICIALIZAÇÃO DO SISTEMA
-- ====================================================================

-- Função para limpar os raios visuais do melhor caminho anterior
local function ClearCurrentBestPathVisual()
	for _, part in ipairs(currentBestPathVisual) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	table.clear(currentBestPathVisual) -- Limpa a tabela
end

-- Função para desenhar o melhor caminho global
local function DrawBestGlobalPath(path: {Part}, color: Color3)
	ClearCurrentBestPathVisual() -- Limpa o caminho anterior antes de desenhar o novo

	for i = 1, #path - 1 do
		local particula = ReplicatedStorage.Clones.Luz:Clone()
		particula.Parent = Workspace
		particula.Attachment0 = path[i]:FindFirstChild("AT")
		particula.Attachment1 = path[i+1]:FindFirstChild("AT")
		particula.Color = ColorSequence.new(color)
		if not particula.Attachment0 or not particula.Attachment1 then
			warn("Erro: Cidades precisam de Attachments nomeados 'AT' para DrawBestGlobalPath funcionar.")
			particula:Destroy()
			continue
		end
		table.insert(currentBestPathVisual, particula) -- Armazena a referência para poder limpar depois
	end
end

local function loadCities()
	local loadedCities = {}
	local cityParts = Workspace.AgentProperty.Cities:GetChildren()
	if #cityParts == 0 then
		warn("Nenhuma cidade encontrada em 'workspace.AgentProperty.Cities'.")
		return nil
	end

	-- Ordena as cidades numericamente para garantir a ordem Cidade1, Cidade2, etc.
	table.sort(cityParts, function(a, b)
		local numA = tonumber(a.Name:gsub("%D", ""))
		local numB = tonumber(b.Name:gsub("%D", ""))
		if numA and numB then
			return numA < numB
		else
			return a.Name < b.Name
		end
	end)

	for _, cidade in ipairs(cityParts) do
		if cidade:IsA("BasePart") then
			table.insert(loadedCities, cidade)
			cityMap[cidade.Name] = cidade
			-- Garante que cada cidade tenha um Attachment 'AT' para os raios
			if not cidade:FindFirstChild("AT") then
				local att = Instance.new("Attachment")
				att.Name = "AT"
				att.Parent = cidade
			end
		end
	end
	return loadedCities
end

local function initBoids(numToCreate: number)
	local agentTemplate = ReplicatedStorage.Clones.Agent
	if not agentTemplate then
		error("Modelo 'Agent' não encontrado em ReplicatedStorage.Clones.")
	end
	if not agentTemplate:IsA("Model") then
		error("Modelo 'Agent' em ReplicatedStorage.Clones não é um Model.")
	end
	local primaryPart = agentTemplate.PrimaryPart
	if not primaryPart then
		error("O modelo 'Agent' não tem uma PrimaryPart definida!")
	end
	local humanoid = agentTemplate:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		error("O modelo 'Agent' não tem um Humanoid!")
	end

	for i = 1, numToCreate do
		local agentModel = agentTemplate:Clone()
		agentModel.Name = "Agent_" .. i
		agentModel.Parent = Workspace
		-- Posiciona os boids aleatoriamente no início, mas os deixa parados
		agentModel:SetPrimaryPartCFrame(CFrame.new(math.random(-50, 50), 5, math.random(-50, 50)))

		local agentHumanoid = agentModel:FindFirstChildOfClass("Humanoid")
		if agentHumanoid then
			agentHumanoid.WalkSpeed = MAX_SPEED
			agentHumanoid.UseJumpPower = false
			agentHumanoid.AutoRotate = false
		end

		for _, part in ipairs(agentModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Swarm" -- Impede colisões entre os boids
			end
		end

		local boid = createBoid(agentModel.PrimaryPart.Position, agentModel)
		table.insert(allBoids, boid)
	end
end

local function runACO(startCity: Part, endCity: Part): {Part}
	initializePheromones()
	local bestGlobalPath: {Part} = {}
	local bestGlobalCost = math.huge

	print("Iniciando busca de caminho com ACO (visitando todas as cidades)...")
	for iteration = 1, MAX_ACO_ITERATIONS do
		local iterationBestPath: {Part}? = nil
		local iterationBestCost = math.huge

		-- Cada formiga constrói e explora seu caminho nesta iteração
		for ant = 1, NUM_ANTS do
			local path = buildAntPath(ant, startCity, endCity) -- Passa o índice da formiga para visualização
			if path then
				local cost = calculatePathCost(path)

				if cost < iterationBestCost then
					iterationBestCost = cost
					iterationBestPath = path
				end
			end
			
		end -- Fecha o for ant

		evaporatePheromone() -- Evapora o feromônio antes de depositar novo

		-- Deposita feromônio com base nos melhores caminhos encontrados
		if iterationBestPath then
			depositPheromone(iterationBestPath, iterationBestCost)
			if iterationBestCost < bestGlobalCost then
				bestGlobalCost = iterationBestCost
				bestGlobalPath = iterationBestPath
				print(string.format("Iteração %d: Novo melhor caminho encontrado com custo %d", iteration, math.floor(bestGlobalCost)))
				DrawBestGlobalPath(bestGlobalPath, Color3.fromRGB(255, 0, 0)) -- Desenha o NOVO melhor caminho em VERMELHO
			end
		end
		-- Reforça o melhor caminho global, mesmo se não houve melhora nesta iteração
		-- Isso ajuda a solidificar o melhor caminho encontrado até o momento.
		if #bestGlobalPath > 0 and (not iterationBestPath or iterationBestCost >= bestGlobalCost) then
			depositPheromone(bestGlobalPath, bestGlobalCost)
		end
	end -- Fecha o for iteration

	print("\nBusca de Caminho com ACO Concluída!")
	if #bestGlobalPath > 0 then
		print("Melhor caminho (visitando todas as cidades) de", startCity.Name, "->", endCity.Name, "encontrado:")
		for _, city in ipairs(bestGlobalPath) do
			print(city.Name)
		end
		print("Distância total:", math.floor(bestGlobalCost))
	else
		warn("ACO não conseguiu encontrar um caminho válido visitando todas as cidades. Retornando caminho direto (start -> end) como fallback.")
		return {startCity, endCity} -- Retorna um caminho direto como fallback
	end

	return bestGlobalPath
end

-- ====================================================================
-- FUNÇÃO PRINCIPAL DE EXECUÇÃO
-- ====================================================================

local function main()
	-- Inicializa pastas essenciais para o ambiente
	if not Workspace:FindFirstChild("Repulsors") then
		local folder = Instance.new("Folder")
		folder.Name = "Repulsors"
		folder.Parent = Workspace
	end
	if not Workspace:FindFirstChild("AgentProperty") then
		local folder = Instance.new("Folder")
		folder.Name = "AgentProperty"
		folder.Parent = Workspace
	end
	if not Workspace.AgentProperty:FindFirstChild("Cities") then
		local folder = Instance.new("Folder")
		folder.Name = "Cities"
		folder.Parent = Workspace.AgentProperty
	end

	-- Configura o grupo de colisão para os boids
	local physicsService = game:GetService("PhysicsService")
	physicsService:CollisionGroupSetCollidable("Swarm", "Swarm", false)

	cities = loadCities() -- Carrega as cidades do Workspace
	if not cities or #cities < 2 then
		error("É necessário ter pelo menos 2 cidades em 'workspace.AgentProperty.Cities'.")
	end

	local startCity = cities[1] -- Define a cidade de início (primeira da lista ordenada)
	local endCity = cities[#cities] -- Define a cidade de fim (última da lista ordenada)

	initBoids(NUM_ANTS) -- Cria as formigas (boids) visuais (mas elas estarão paradas inicialmente)

	-- Executa o algoritmo ACO para encontrar o melhor caminho
	local bestGlobalPath = runACO(startCity, endCity)

	-- Após o ACO, habilita o movimento dos boids e os direciona para seguir o melhor caminho global encontrado
	boidsMovementEnabled = true -- Habilita o movimento dos boids
	for _, boid in ipairs(allBoids) do
		boid.TargetPath = bestGlobalPath
		boid.CurrentWaypointIndex = 1
		-- Reposiciona a formiga para a cidade de partida do melhor caminho
		boid.Position = startCity.Position + Vector3.new(math.random() * 5 - 2.5, 0, math.random() * 5 - 2.5)
		boid.InitialY = boid.Position.Y
		boid.IsAtDestination = false -- Garante que ela vai começar a seguir o caminho
		if boid.Model and boid.Model.PrimaryPart then
			boid.Model:SetPrimaryPartCFrame(CFrame.new(boid.Position, boid.Position + boid.Velocity))
		end
	end



	-- Loop principal de atualização dos boids (movimento)
	local lastUpdateTime = 0
	RunService.Stepped:Connect(function()
		local currentTime = os.clock()
		if currentTime - lastUpdateTime >= UPDATE_DELAY then
			local activeBoids = {}
			-- Filtra os boids que ainda estão ativos (não chegaram ao destino ou foram removidos)
			for i = #allBoids, 1, -1 do
				local boid = allBoids[i]
				if not boid.IsAtDestination then
					table.insert(activeBoids, 1, boid)
				else
					-- Limpa o modelo do boid se ele já chegou ao destino
					if boid.Model then
						boid.Model:Destroy()
						boid.Model = nil
					end
					table.remove(allBoids, i)
				end
			end

			-- Atualiza o comportamento de cada boid ativo
			for _, boid in ipairs(activeBoids) do
				boid:update(activeBoids)
			end
			lastUpdateTime = currentTime
		end
	end)
end

main()