local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)
local Tree = require(script.Subtrees)



local Agent = {}
Agent.__index = Agent



function Agent.new(agent : Model)
	local self = setmetatable({},Agent)
	self.RootPart = agent.HumanoidRootPart
	self.Humanoid = agent:FindFirstChild("Humanoid")
	self.Health =  self.Humanoid.Health
	self.StateMachine = nil
	self.Tree = Tree.Subarvores["AdquirirRecursos"]()
	self.Orders = {}
	self.Inventory = {}
	self.Storage = Workspace.AgentProperty.Storage
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

function Agent:GetPosition() : Vector3
	print(self.RootPart)
	return self.RootPart.Position
end

function Agent:GetOrders()
	return self.Inventory
end
function Agent:SetOrders(order)
	table.insert(self.Orders, order)
end
function Agent:RemoveOrder(order)
	if table.find(self.Orders, order) ~= nil then
		table.remove(self.Orders, table.find(self.Orders, order))
	end
end


function Agent:Move(Vetor : Vector3)
	self.Humanoid:MoveTo(Vetor)
end

function Agent:GetTree()
	return self.Tree
end

function Agent:TickTree()
	
	self.Tree:execute(self)
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