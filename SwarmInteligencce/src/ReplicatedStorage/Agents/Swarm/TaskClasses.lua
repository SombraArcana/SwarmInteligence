local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)

-- Criando o módulo Task
local Task = {}
Task.__index = Task

-- Função para criar uma nova tarefa geral (base)
function Task.new(name: string)
    local self = setmetatable({}, Task)
    self.name = name
    self.Satisfaction = 0
    return self
end

function Task:DeleteResources()
end

function Task:Destroy()
    self:Destroy()
end

-- Task para Construção
local ConstructionTask = setmetatable({}, Task)
ConstructionTask.__index = ConstructionTask

function ConstructionTask.new(name: string, resourcesRequired: table)
    local self = setmetatable(Task.new(name), ConstructionTask)
    self.Type = "ConstructionTask"
    self.ResourcesRequired = resourcesRequired.Count
    self.ResourceType = resourcesRequired.Type
    return self
end

function ConstructionTask:DeleteResources(count, tipo)
    for i,v in self.ResourcesRequired do
        if v.Type == tipo then
            v.Count -= count
        end
        if v.Count <= 0 then
            table.remove(self.ResourcesRequired,i)
        end
    end
end

-- Task para Coleta de Recursos
local GatherTask = setmetatable({}, Task)
GatherTask.__index = GatherTask

function GatherTask.new(name: string, resources : table)
    local self = setmetatable(Task.new(name), GatherTask)
    self.Type = "GatherTask"
    self.ResourscersType = resources.Type
    self.RemainResources = resources.Count
    self.Total = resources.Count
    self.ResourscersEnqueued = 0

    return self
end

function GatherTask:GatherResources(Number)
    self.ResourscersEnqueued += Number
    print("maths = ",self.ResourscersEnqueued,"/",self.Total)
    self.Satisfaction += Number/self.Total
    return {TaskType = self.Type, Count = Number, Type = self.ResourscersType}
end

return {
    Task = Task,
    ConstructionTask = ConstructionTask,
    GatherTask = GatherTask,
}
