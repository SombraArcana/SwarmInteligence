local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Configurações iniciais
local numParticles = 5  
local numCities = 14     
local maxIterations = 50 
local speed = 150         

-- Criando cidades como Parts no mundo 3D
local cities = {}
local cidades = workspace.AgentProperty.Cities:GetChildren()

for i, cidade in pairs(cidades) do
    table.insert(cities, cidade)
end

-- **INPUT**: Seleção da cidade de origem e destino
local cityA = cities[1] -- Cidade inicial
local cityB = cities[13] -- Cidade final

-- Criando agentes (Swarm)
local particles = {}

function CreateRay(city1, city2)
    if not city1 or not city2 then return end
    local particula = ReplicatedStorage.Clones.Luz:Clone()
    particula.Parent = city1
    particula.Attachment0 = city1.AT
    particula.Attachment1 = city2.AT
    game.Debris:AddItem(particula, 0.02)
end

-- Função para gerar caminho inicial
function GroupParticles(pos, Agent, Cluster)
    local initialPath = {cityA} 
    local shuffledCities = {table.unpack(cities)}

    -- Remove `cityA` e `cityB` para evitar repetição
    table.remove(shuffledCities, table.find(shuffledCities, cityA))
    table.remove(shuffledCities, table.find(shuffledCities, cityB))

    -- Adiciona cidades intermediárias aleatórias
    for _, city in ipairs(shuffledCities) do
        table.insert(initialPath, city)
    end

    table.insert(initialPath, cityB) -- Finaliza em `cityB`

    Cluster[pos] = {
        object = Agent,
        position = initialPath,
        bestPosition = initialPath,
        bestCost = math.huge
    }
end

-- Inicializa partículas
for i = 1, numParticles do
    local agentModel = ReplicatedStorage.Clones.Agent:Clone()
    agentModel.Parent = workspace
    agentModel:SetPrimaryPartCFrame(CFrame.new(math.random(-441, 441), 5, math.random(-36, 36)))

    for _, v in pairs(agentModel:GetChildren()) do
        if v:IsA("Part") then
            v.CollisionGroup = "Swarm"
        end
    end
    agentModel.Humanoid.WalkSpeed = speed

    GroupParticles(i, agentModel, particles)
end

-- Função para calcular distância entre cidades no caminho
local function calculateCost(path)
    local totalDistance = 0
    for i = 1, #path - 1 do
        totalDistance = totalDistance + (path[i].Position - path[i+1].Position).magnitude
    end
    return totalDistance
end

-- Função para reduzir caminho removendo cidades desnecessárias
local function optimizePath(path)
    local optimizedPath = {cityA}
    for i = 2, #path - 1 do
        if calculateCost({optimizedPath[#optimizedPath], path[i], cityB}) < calculateCost({optimizedPath[#optimizedPath], cityB}) then
            table.insert(optimizedPath, path[i])
        end
    end
    table.insert(optimizedPath, cityB)
    return optimizedPath
end

-- Função para atualizar trajetória com PSO
local function updatePosition(particle, bestGlobalPosition)
    local inertia = 0.5
    local cognitive = 1.5
    local social = 1.5

    local newPath = {table.unpack(particle.position)}
    local a, b = math.random(2, #newPath - 1), math.random(2, #newPath - 1) -- Evita mexer em cityA e cityB

    if math.random() < inertia then
        newPath[a], newPath[b] = newPath[b], newPath[a]
    end

    if math.random() < cognitive then
        newPath = particle.bestPosition
    end

    if math.random() < social then
        newPath = bestGlobalPosition
    end

    return optimizePath(newPath) -- Agora retorna um caminho otimizado
end

-- Função para movimentar agentes
local function moveAgent(agent, targetPosition)
    local humanoid = agent:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:MoveTo(Vector3.new(targetPosition.Position.X, 4, targetPosition.Position.Z))
    end
end

-- Algoritmo PSO em ação
local bestGlobalPosition = cities
local bestGlobalCost = math.huge

for iteration = 1, maxIterations do
    print("Iteração:", iteration)

    for _, particle in ipairs(particles) do
        -- Atualiza trajetória e otimiza caminho
        local newPath = updatePosition(particle, bestGlobalPosition)

        -- Calcula custo do novo caminho
        local newCost = calculateCost(newPath)

        if newCost < particle.bestCost then
            particle.bestPosition = newPath
            particle.bestCost = newCost
        end

        -- Atualização global da melhor solução
        if newCost < bestGlobalCost then
            bestGlobalPosition = newPath
            bestGlobalCost = newCost
        end
        
        -- Movimentação dos agentes
        for i, city in ipairs(particle.bestPosition) do
            task.wait()
            CreateRay(particle.position[i], particle.position[i+1])
            moveAgent(particle.object, city)
        end
    end
end

-- Melhor solução encontrada
print(cities)
print("Melhor caminho de", cityA.Name, "→", cityB.Name, "passando por cidades essenciais:")
for _, city in ipairs(bestGlobalPosition) do
    print(city.Name)
end
print("Distância total:", math.floor(bestGlobalCost))