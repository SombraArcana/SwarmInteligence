local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Configurações iniciais
local numParticles = 5  -- Número de agentes
local numCities = 14      -- Número de pontos a visitar
local maxIterations = 150 -- Quantidade de ciclos para convergência
local speed = 150         -- Velocidade de movimento dos agentes

-- Criando cidades como Parts no mundo 3D
local cities = {}
local primeirocusto
local cidades = workspace.AgentProperty.Cities:GetChildren()

function CreateRay(city1,city2)
    if not city1 then return end
    if not city2 then return end
    local particula = ReplicatedStorage.Clones.Luz:Clone()
    particula.Parent = city1
    particula.Attachment0 = city1.AT
    particula.Attachment1 = city2.AT
    game.Debris:AddItem(particula, 0.02)
end

for i, cidade in pairs(cidades) do
    table.insert(cities, cidade)
end

-- Criando agentes (Swarm)
local particles = {}

function GroupParticles(pos, Agent, Cluster)
    Cluster[pos] = {
        object = Agent,
        position = {table.unpack(cities)}, -- Rota inicial aleatória
        velocity = {}, -- Velocidade fictícia (não usada diretamente)
        bestPosition = {table.unpack(cities)}, -- Melhor caminho inicial
        bestCost = math.huge -- Definição inicial para melhor custo
    }
end

for i = 1, numParticles do
    local agentModel = ReplicatedStorage.Clones.Agent:Clone()
    agentModel.Parent = workspace
    agentModel:SetPrimaryPartCFrame(CFrame.new(math.random((-441 -150), (-441 + 150)), 5, math.random((36-150), (36+150))))

    for _, v in pairs(agentModel:GetChildren()) do
        if v:IsA("Part") then
            v.CollisionGroup = "Swarm"
        end
    end
    agentModel.Humanoid.WalkSpeed = speed

    GroupParticles(i, agentModel, particles)
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

-- Função para atualizar a trajetória com PSO melhorado
local function updatePosition(particle, bestGlobalPosition)
    local inertia = 0.5
    local cognitive = 1.5
    local social = 1.5

    local newPath = {table.unpack(particle.position)}
    local a, b = math.random(1, numCities), math.random(1, numCities)

    -- Aplicação de PSO: Influência individual, global e exploração
    if math.random() < inertia then
        print("A e B serão trocados")
        print("Valor A = ",a)
        print("Valor B = ",b)
        newPath[a], newPath[b] = newPath[b], newPath[a]
    end

    -- if math.random() < cognitive then
    --     newPath = particle.bestPosition
    -- end

    -- if math.random() < social then
    --     newPath = bestGlobalPosition
    -- end

    return newPath
end

-- Função para movimentar os agentes até a próxima cidade
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
    print("===================================================")
    print("Iteração:", iteration)
    print("===================================================")

    for _, particle in ipairs(particles) do
        
        -- Atualiza posição da partícula com PSO
        local newPath = updatePosition(particle, bestGlobalPosition)

        -- Calcula custo do novo caminho
        local newCost = calculateCost(newPath)
        if iteration == 1 and _ == 1 then
            primeirocusto = newCost
        end
        
        if newCost < particle.bestCost then
            particle.bestPosition = newPath
            particle.bestCost = newCost
        end

        -- Atualização global da melhor solução
        if newCost < bestGlobalCost then
            bestGlobalPosition = newPath
            bestGlobalCost = newCost
        end
        if _ == 1 then
            print("agent nº",_,":")
            print("melhor custo: ",particle.bestCost)
            print("newPath ",newPath," < particle.bestCost = ", math.floor(particle.bestCost)," -- globalcost = ",math.floor(bestGlobalCost))
        end
        

        -- Movimentação dos agentes no mundo 3D

        for i, city in ipairs(particle.position) do
            task.wait()
            CreateRay(particle.position[i], particle.position[i+1])
            moveAgent(particle.object, city)

        end
    end
end

-- Melhor solução encontrada
print("######################################--Fim--#########################################")
print("primeirocusto = ", primeirocusto)
print("PrimeiraCombinação = ", cidades)
print("Melhor caminho encontrado:")
for _, city in ipairs(bestGlobalPosition) do
    print(city)
end
print("Distância total:", math.floor(bestGlobalCost))