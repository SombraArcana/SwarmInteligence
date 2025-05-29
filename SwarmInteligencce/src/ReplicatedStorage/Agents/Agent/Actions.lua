local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)

local Actions = {
    subtrees = {},
    Nodes = {}
}
local Agents




Actions.Functions = {
    ["NearbyResources"] = function(Agent,Resource)
        for i,Recurso in pairs(Workspace.Recursos:GetChildren()) do
            if Recurso:GetAttribute("Recurso") == Resource and(Recurso.Position - Agent:GetPosition()).Magnitude < 100 then
                return "Success"
            end
        end
        return "Failure"
    end,
    ["CollectResources"] = function(Agent)
        local Order = Agent:GetActualOrder()
        local count = Order.Count
        local tipo = Order.Type
        local part = Order.Destination
        local Recurso = Order.Type
        Agent.Inventory[Recurso].Value = 0
        local tabeladevalores = {}
        
        while Agent.Inventory[Recurso].Value < count do
            local teste = workspace:GetServerTimeNow()
            task.wait(0.2)
            Agent.Inventory[Recurso].Value += 1
            task.spawn(function()
                Util.AddDisplay(part, Recurso.." + "..Agent.Inventory[Recurso].Value,2)
            end)
            
            local final = workspace:GetServerTimeNow()
            table.insert(tabeladevalores,(final - teste))
        end
        return "Success"
    end,
    ["Patrol"] = function(Agent)
        Agent:Move(Workspace.Poste.Position)
        task.wait(2)
        return "Success"
    end,
    ["PathFind"] = function(Agent)
        
    end,
    ["GetToDestination"] = function(Agent)
        local Destination = Agent:GetActualOrder().Path[Agent.Step]
        Agent:Move(Destination)
        local Beginning = tick()
        
        while (Destination - Agent:GetPosition()).Magnitude > 5 do
            -- print((  Agent.Position - Destination ).Magnitude)
            task.wait(0.1)
            if (tick() - Beginning) > 10 then
                print("O NPC ",Agent.Name ,"está preso, magnitude = ",(Destination - Agent:GetPosition()).Magnitude)
                return "Failure"
            end
        end
        Agent.Step += 1
        return "Success"
    end,
    ["GoCollect"] = function(Agent)
        Agent:Move(Agent.Orders.Path.Position)
        local Beginning = tick()
        while (Agent.Orders.Path.Position - Agent.Position).Magnitude > 1 do
            task.wait()
            if Beginning - tick() > 10 then
                return "Failure"
            end
        end
        return "Success"
    end,
    ["Idle"] = function(Agent)
        return "Inactive"
    end,
    ["HasOrder"] = function(Agent)
        if Agent.Orders == nil or #Agent.Orders == 0 then
            return "Failure"
        else
            return "Success"
        end
    end,
    ["DeliveryResources"] = function(Agent)
        for i,resource in Agent.Inventory do
            local recurso = Agent.Storage:GetAttribute(i.."Storage")
            
            Agent.Storage:SetAttribute(i.."Storage",recurso + resource.Value)
            task.delay(0.2, function()
                Util.AddDisplay(Agent.Storage, i.." + "..Agent.Storage:GetAttribute(i.."Storage"),2)
            end)
            Agent.Inventory[i].Value = 0
        end
    end,
    ["GetTaskTree"] = function(Agent)
        if Agent.Orders == nil or #Agent.Orders == 0 then
            return "Failure"

        elseif Agent.Status ~= "RUNNING" then
            Agent.Status = "RUNNING"
            Agent.TotalSteps = #Agent:GetActualOrder().Path
            Agent.Step = 1
            -- return Actions.subtrees[Agent:GetActualOrder().TaskType]():execute(Agent)
            return Actions.subtrees[Agent:GetActualOrder().TaskType]():execute(Agent)
        end
    end,
    ["CompleteOrder"] = function(Agent)
        table.remove(Agent.Orders,1)
    end
}

return Actions