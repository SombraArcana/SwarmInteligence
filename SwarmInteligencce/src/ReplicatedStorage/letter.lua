-- Configurações iniciais
local numParticles = 10  -- Número de agentes
local numCities = 5      -- Número de pontos a visitar
local maxIterations = 50 -- Quantidade de ciclos para convergência
local speed = 10         -- Velocidade de movimento dos agentes

-- Criando cidades como Parts no mundo 3D
local cities = {}
for i = 1, numCities do
    local city = Instance.new("Part")
    city.Size = Vector3.new(4, 4, 4)
    city.Position = Vector3.new(math.random(0, 100), 2, math.random(0, 100))
    city.Anchored = true
    city.Color = Color3.new(1, 0, 0) -- Vermelho para destaque
    city.Parent = workspace
    table.insert(cities, city)
end

-- Criando agentes (Swarm)
local particles = {}
for i = 1, numParticles do
    local agent = Instance.new("Part")
    agent.Size = Vector3.new(2, 2, 2)
    agent.Position = Vector3.new(math.random(0, 100), 2, math.random(0, 100))
    agent.Anchored = false
    agent.Color = Color3.new(0, 1, 0) -- Verde para representar agentes
    agent.Parent = workspace

    particles[i] = {
        object = agent,
        position = {table.unpack(cities)}, -- Rota inicial aleatória
        velocity = {},
        bestPosition = {},
        bestCost = math.huge
    }
end

-- Função para calcular distância entre dois pontos
local function distance(pos1, pos2)
    return (pos1 - pos2).magnitude
end

-- Função para calcular custo total do caminho
local function calculateCost(path)
    local totalDistance = 0
    for i = 1, #path - 1 do
        totalDistance = totalDistance + distance(path[i].Position, path[i+1].Position)
    end
    totalDistance = totalDistance + distance(path[#path].Position, path[1].Position)
    return totalDistance
end

-- Função para movimentar os agentes até a próxima cidade
local function moveAgent(agent, targetPosition)
    local direction = (targetPosition.Position - agent.Position).unit
    agent.Velocity = direction * speed
end

-- Algoritmo PSO em ação
for iteration = 1, maxIterations do
    for _, particle in ipairs(particles) do
        -- Embaralha trajeto para exploração
        local newPath = {table.unpack(particle.position)}
        local a, b = math.random(1, numCities), math.random(1, numCities)
        newPath[a], newPath[b] = newPath[b], newPath[a]

        -- Calcula custo do novo caminho
        local newCost = calculateCost(newPath)
        if newCost < particle.bestCost then
            particle.bestPosition = newPath
            particle.bestCost = newCost
        end
        
        -- Movimentação dos agentes no mundo 3D
        for i, city in ipairs(particle.bestPosition) do
            wait(1) -- Pequeno atraso para visualizar movimento
            moveAgent(particle.object, city)
        end
    end
end

-- Melhor solução encontrada
local bestParticle = particles[1]
for _, particle in ipairs(particles) do
    if particle.bestCost < bestParticle.bestCost then
        bestParticle = particle
    end
end

print("Melhor caminho encontrado:")
for _, city in ipairs(bestParticle.bestPosition) do
    print(city.Position)
end
print("Distância total:", bestParticle.bestCost)