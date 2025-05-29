local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)
local Tree = require(script.Subtrees)
local createboid = require(ReplicatedStorage.Boids)

local Agent = require(script.Parent.Agent)



local Swarm = {}
Swarm.__index = Swarm


function Swarm.new()
	local self = setmetatable({},Swarm)
	self.Tree = Tree.Subarvores["Tribal"]()
	self.Name = "Swarm"
    self.StateMachine = "Tribal"
	self.SwarmEvent = Instance.new("BindableEvent",ReplicatedStorage.NpcUtil)
	self.AgentTickIndex = 1
	self.AgentBatchSize = 10
	self.LastNode = nil
	self.lastResult = nil
	self.Manada = {}
	self.Orders = {}
	self.Resources = {}
    self.Agents = {}

	self.AgentsLimits = {
		CarryCap = 10
	}
	self.Storage = Workspace.AgentProperty.Storage
	self.Property = Workspace.AgentProperty
	-- for i,v in pairs(Workspace.AgentProperty:GetChildren()) do
	-- 	self.Property[v.Name] = v
	-- end
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




function Swarm:GetNumberConstructions(name)
	local count = 0
	for i,Construction in pairs(self.Property:GetChildren()) do
		if Construction.Name == name then
			count += 1
		end
	end
	return count , #self.Property:GetChildren()
end

function Swarm:GetIdleAgent()
	for i,npc in self.Agents do
		if npc.Status == "Inactive" and #npc.Orders < 1 then
			return npc
		end
	end
	return nil
end

function Swarm:GetActualOrder(number)
	local order = self.Orders[number]
	if not order then return nil end
	if order.ResourscersEnqueued == order.Total then
		return self:GetActualOrder(number + 1)
	else
		return order
	end
	-- return self.Orders[1]
end

function Swarm:GetOrders()
	return self.Orders
end

function Swarm:SetOrders(order)

	table.insert(self.Orders, order)
end

function Swarm:RemoveOrder(order)
	if table.find(self.Orders, order) ~= nil then
		table.remove(self.Orders, table.find(self.Orders, order))
	end
end

function Swarm:GetDestination(ResourceType)
	local Campfire = self.Property["Campfire"].Position
	local Chosen
	for i,Recurso in pairs(Workspace.Recursos:GetChildren()) do
		if Recurso:GetAttribute("Recurso") == ResourceType then
			if (Recurso.Position - Campfire).Magnitude < 100 then
				Chosen = Recurso
			end
		end
	end
	return Chosen
end

function Swarm:DelegateOrder(Agent)
	local Order = self:GetActualOrder(1)
	if not Order then return
	end
	print("#######################################################")
	print("All Orders",self.Orders)
	print("DelegateOrder")
	print(Agent:GetName())
	print("Task = ",Order.Type)
	print("All Task = ", Order)
	local delegated
	if Order.RemainResources > 0 then
		
		if Order.RemainResources >= 10 then
			delegated = Order:GatherResources(10)
		else
			delegated = Order:GatherResources(Order.RemainResources)
		end
		delegated.Destination = self:GetDestination(Order.ResourscersType)
		delegated.Path = {self:GetDestination(Order.ResourscersType).Position,self.Storage.Position,self.Property.Campfire.Position}
		Agent:SetOrders(delegated)
		Order.RemainResources -= delegated.Count
	end
	print("#######################################################")
end

function Swarm:GetTree()
	return self.Tree
end

function Swarm:SetTree(NewTree)
	self.Tree = NewTree
end

function Swarm:TickTree()
	if self.StateMachine == "Primitivo" then
        self.Tree:execute(self)
	elseif self.StateMachine == "Tribal" then
		self.Tree:execute(self)
	elseif self.StateMachine == "Colonial" then

    end
end

function Swarm:CreateAgents(Number, Folderinit)
	for i = 1, Number do
		local AgentModel = ReplicatedStorage.Clones.Agent:Clone()
		AgentModel.HumanoidRootPart.Position = self.Property.Campfire.Position + Vector3.new(0,2,-(i*3))
		AgentModel.Name = "Agent" .. i
		AgentModel.Parent = Folderinit
		AgentModel.BillboardGui.TextLabel.Text = AgentModel.Name
		local agent = Agent.new(AgentModel, self.SwarmEvent)
		table.insert(self.Agents, agent)
	end
end

function Swarm:TickAgentsBatch()
	-- Processa um lote de agentes por vez
	local startIndex = self.AgentTickIndex
	local endIndex = math.min(startIndex + self.AgentBatchSize - 1, #self.Agents)
	
	for i = startIndex, endIndex do
		local agent = self.Agents[i]
		agent:TickTree()
	end
	
	-- Atualiza o índice para o próximo lote
	self.AgentTickIndex = endIndex + 1
	if self.AgentTickIndex > #self.Agents then
		self.AgentTickIndex = 1 -- Reinicia para o primeiro agente
	end
end

function Swarm:Init()
	local SwarmFolder = Instance.new("Folder", workspace)
	SwarmFolder.Name = "SwarmFolder"
	self:CreateAgents(50, SwarmFolder)
	
	-- Conecta o loop de processamento de lotes no Heartbeat
	RunService.Heartbeat:Connect(function(deltaTime)
		self:TickAgentsBatch()
		self:TickTree()
	end)
end



return Swarm