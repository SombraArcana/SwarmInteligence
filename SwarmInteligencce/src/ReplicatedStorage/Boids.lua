-- Configurações gerais
local MAX_SPEED = 3
local MAX_FORCE = 0.5
local VIEW_RADIUS = 20

local REPULSION_RADIUS = 50
local TARGET_WEIGHT = 2  -- Peso da força de direção-alvo

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ponto de repulsão e direção inicial
local repulsionPoint = Vector3.new(0, 0, 0)
local currentDirection = Vector3.new(1, 0, 1).unit  -- Direção inicial para a manada

local function QueryRepulsors(pos)
    local nearestRepulsor
    for i,v in pairs(workspace.Repulsors:GetChildren()) do
        if (pos - v.Position).Magnitude < REPULSION_RADIUS then
            nearestRepulsor = v
            return nearestRepulsor
        end
    end
    return nil
end

-- Função para criar um Boid
function createBoid(position, Agent)
    local boid = {}

    boid.Position = position or Vector3.new(0, 0, 0)
    boid.Velocity = Vector3.new(math.random(), math.random(), math.random()).unit * MAX_SPEED
    boid.Acceleration = Vector3.new(0, 0, 0)
    boid.Agent = Agent
    boid.Model = Agent.Model
    local initialY = boid.Position.Y  -- Guarda o valor Y inicial

    -- Função de repulsão
    function boid:repulsion()
        local nearestRepulsor = QueryRepulsors(self.Position)
        if not nearestRepulsor then return end
        local distance = (self.Position - nearestRepulsor.Position).magnitude
        if distance < REPULSION_RADIUS then
            -- Direção para se afastar do ponto de repulsão
            currentDirection = (self.Position - repulsionPoint).unit
        end
    end

    -- Função para seguir a direção atual da manada
    function boid:followDirection()
        local steer = currentDirection * MAX_SPEED - self.Velocity
        steer = steer.unit * math.min(steer.magnitude, MAX_FORCE)
        return steer * TARGET_WEIGHT
    end

    -- Outras funções de separação, alinhamento e coesão
    function boid:separation(boids)
        local steer = Vector3.new(0, 0, 0)
        local count = 0

        for _, other in pairs(boids) do
            local distance = (self.Position - other.Position).magnitude
            if other ~= self and distance < VIEW_RADIUS then
                local diff = (self.Position - other.Position).unit / distance
                steer += diff
                count += 1
            end
        end

        if count > 0 then
            steer /= count
        end

        if steer.magnitude > 0 then
            steer = steer.unit * MAX_SPEED - self.Velocity
            steer = steer.unit * math.min(steer.magnitude, MAX_FORCE)
        end

        return steer
    end

    function boid:alignment(boids)
        local steer = Vector3.new(0, 0, 0)
        local count = 0

        for _, other in pairs(boids) do
            if other ~= self and (self.Position - other.Position).magnitude < VIEW_RADIUS then
                steer += other.Velocity
                count += 1
            end
        end

        if count > 0 then
            steer /= count
            steer = steer.unit * MAX_SPEED - self.Velocity
            steer = steer.unit * math.min(steer.magnitude, MAX_FORCE)
        end

        return steer
    end

    function boid:cohesion(boids)
        local centerOfMass = Vector3.new(0, 0, 0)
        local count = 0

        for _, other in pairs(boids) do
            if other ~= self and (self.Position - other.Position).magnitude < VIEW_RADIUS then
                centerOfMass += other.Position
                count += 1
            end
        end

        if count > 0 then
            centerOfMass /= count
            local steer = (centerOfMass - self.Position).unit * MAX_SPEED - self.Velocity
            steer = steer.unit * math.min(steer.magnitude, MAX_FORCE)
            return steer
        else
            return Vector3.new(0, 0, 0)
        end
    end

    -- Função para atualizar a posição e direção do boid
    function boid:update(boids)
        local sep = self:separation(boids) * 3
        local ali = self:alignment(boids) * 10
        local coh = self:cohesion(boids) * 1
        local tgt = self:followDirection()  -- Segue a direção atual

        -- Atualiza a direção caso encontre repulsor
        self:repulsion()

        -- Soma as forças
        self.Acceleration += sep
        self.Acceleration += ali
        self.Acceleration += coh
        self.Acceleration += tgt

        -- Atualiza velocidade e posição
        self.Velocity += self.Acceleration
        self.Velocity = self.Velocity.unit * math.min(self.Velocity.magnitude, MAX_SPEED)

        -- Atualiza a posição apenas no eixo X e Z
        self.Position += Vector3.new(self.Velocity.X, 0, self.Velocity.Z)
        self.Position = Vector3.new(self.Position.X, initialY, self.Position.Z)

        self.Acceleration = Vector3.new(0, 0, 0)

        -- Atualiza o modelo visual
        self.Model:SetPrimaryPartCFrame(CFrame.new(self.Position))
        -- self.Agent:Move(self.Position)
    end

    return boid
end

-- Lista de boids e inicialização
local boids = {}

local function initBoids(swarm)
    for i = 1, 20 do
        local agentModel = ReplicatedStorage.Clones.Agent:Clone()
        agentModel.Parent = workspace
        agentModel:SetPrimaryPartCFrame(CFrame.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50)))

        local boid = createBoid(agentModel.PrimaryPart.Position, agentModel)
        table.insert(boids, boid)
        table.insert(swarm.Agents, agentModel)
    end
end




return createBoid
