local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)
local TaskClasses = require(script.Parent.TaskClasses)



local Actions = {
}


local possibles = {
    "Success",
    "Failure",
    "RUNNING",
    "Inactive"
}

Actions.Functions = {
    ["HasEveryoneHouses"] = function(Swarm)
         
        local Houses = Swarm:GetNumberConstructions("House")
        if Houses >= #Swarm.Agents then
            
            return "Success", "HasEveryoneHouses"
        end
        
        return "Failure" , "HasEveryoneHouses"
    end,

    ["CreateTask"] = function(Swarm)
        print("A função CreateTask foi chamada")
        -- local tarefa = TaskClasses.GatherTask.new("CollectWood", {Type = "Wood", Count = 50})
        -- local tarefa2 = TaskClasses.GatherTask.new("CollectStone", {Type = "Stone", Count = 100})
        -- Swarm:SetOrders(tarefa)
        -- Swarm:SetOrders(tarefa2)
        return "Success", "CreateTask"
    end,

    ["HasTask"] = function(Swarm)
         
        local orders = Swarm:GetOrders()
        if #orders > 0 then
            
            return "Success", "HasTask"
        end
        
        return "Failure", "HasTask"
    end,
    ["HasNoTask"] = function(Swarm)
         
        local orders = Swarm:GetOrders()
        if #orders > 0 then
            
            return "Failure", "HasTask"
        end
        
        return "Success", "HasTask"
    end,

    ["ExecuteTask"] = function(Swarm)
        local idleNPC = Swarm:GetIdleAgent()
        if idleNPC then
            
            Swarm:DelegateOrder(idleNPC)

            idleNPC:TickTree()
            return "Success", "ExecuteTask"
        end
        return "Failure", "ExecuteTask"
    end,

    ["HaveChurch"] = function(Swarm)
         
        local Church = Swarm:GetNumberConstructions("Church")
        if Church >= 1 then
            return "Success", "HaveChurch"
        end
        return "Failure", "HaveChurch"
    end,

    ["HaveResources"] = function(Swarm)
        print("") 
        -- logic for HaveResources function
    end,

    ["HaveTaskResources"] = function(Swarm)
        print("") 
        -- logic for HaveTaskResources function
    end,

    ["CollectResources"] = function(Swarm)
        print("") 
        -- logic for CollectResources function
    end,

    ["LocateArea"] = function(Swarm)
        print("") 
        -- logic for LocateArea function
    end,

    ["DelimitArea"] = function(Swarm)
        print("") 
        -- logic for DelimitArea function
    end,

    ["HaveResourcesInArea"] = function(Swarm)
        print("") 
        -- logic for HaveResourcesInArea function
    end,

    ["TransportResources"] = function(Swarm)
        print("") 
        -- logic for TransportResources function
    end,

    ["GoConstruct"] = function(Swarm)
        print("") 
        -- pathfinding and construction logic
    end,
}


return Actions