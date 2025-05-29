local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)
local Subtree = require(script.Subtrees)



local Agent = {}
Agent.__index = Agent


local tabelaPokemon = {
	id = 0,
	nome = "charizander",
	elemento = 1,
}



function Agent.new(agent : Model, Event : BindableEvent)
	local newagent = agent or ReplicatedStorage.Clones.Agent:Clone()
	local self = setmetatable({},Agent)
	self.Model = newagent
	self:SetCollisionGroup()
	self.Name = self.Model.Name
	self.RootPart = newagent.PrimaryPart
	self.Humanoid = newagent:FindFirstChild("Humanoid")
	self.Position = self.RootPart.Position
	self.Health =  self.Humanoid.Health
	self.Comunicator = Event
	self.StateMachine = nil
	self.Orders = {}
	self.Status = "Inactive"
	self.TotalSteps = 0
	self.Step = 0
	self.Inventory = {
		Wood = {
			Value = 0
		},
		Stone = {
			Value = 0
		},
	}
	self.Storage = Workspace.AgentProperty.Storage
	self.Campfire = Workspace.AgentProperty.Campfire
	self.Tree = nil
	self:SetTree("WaitForTasks")
	return self
end


-- local lista = {
--     ["TarefaConstrirAcampamento"] = {
--         ["FazerFogueira"] = function(agent)
--             agent:GatherResources("pedra", 10)
--             agent:GatherResources("madeiras", 10)
--         end,
--         ["FazerCabana"] = function()
            
--         end,
--     }
-- }
-- for i,v in pairs(lista) do
    
-- end

function Agent:GetHealth()
	return self.Health
end

function Agent:GetInv()
	return self.Inventory
end

function Agent:GetName()
	return self.Name
end

function Agent:GetPosition() : Vector3
	return self.RootPart.Position
end

function Agent:GetOrders()
	return self.Orders
end

function Agent:GetActualOrder()
	return self.Orders[1]
end

function Agent:SetOrders(order)
	table.insert(self.Orders, order)
end

function Agent:SetParent(Parent)
	self.Model.Parent = Parent
end

function Agent:AddTask(Task)
	self.Orders = Task
end
function Agent:RemoveOrder(order)
	if table.find(self.Orders, order) ~= nil then
		table.remove(self.Orders, table.find(self.Orders, order))
	end
end


function Agent:SetCollisionGroup()
	for i,v in pairs(self.Model:GetChildren()) do
		if v.ClassName == "Part" then
			v.CollisionGroup = "Swarm"
			print(v)
		end
	end
end

function Agent:Move(Vetor : Vector3)
	self.Humanoid:MoveTo(Vetor)
end

function Agent:GetTree()
	return self.Tree
end

function Agent:SetTree(arvore)
	print("SetTree")
	self.Tree = Subtree.Subarvores[arvore](self)
end

function Agent:TickTree()
	if self.Status == "RUNNING" then return end
	local retorno = self.Tree:execute(self)
	self.Status = retorno
end

function Agent:IsIdle() -- Retorna Se O agente está idle
	if self.Status == "Inactive" then 
		return true
	else
		return false
	end
end

function Agent:GatherResources(part : Part)
	local coordinates = part.Position
	local Recurso = part:GetAttribute("Recurso")
	self:Move(coordinates)
	task.wait(3)
	self:GetInv()[Recurso] = 0
	while self:GetInv()[Recurso] < 10 do
		task.wait(1)
		self:GetInv()[Recurso] += 1
        Util.AddDisplay(part, "Pedra + "..self:GetInv()[Recurso])
	end
	self:Move(self.Storage.Position)
	task.wait(5)
	local atual = Workspace.AgentProperty.Storage:GetAttribute("StoneStorage")
	atual += self:GetInv()[Recurso]
	self:GetInv()[Recurso] = 0
    Util.AddDisplay(Workspace.AgentProperty.Storage, "Pedra +"..atual, 2)
	Workspace.AgentProperty.Storage:SetAttribute("StoneStorage",atual)
end


return Agent