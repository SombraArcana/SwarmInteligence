local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreeClass = ReplicatedStorage.BehaviourTreeClass

local BehaviourTreeClass = require(ReplicatedStorage.BehaviourTreeClass)

local SequenceNode = require(TreeClass.SequenceNode)
local SelectorNode = require(TreeClass.SelectorNode)
local ActionNode = require(TreeClass.ActionNode)
local Actions = require(script.Parent.Actions)


local Subtrees = {

}


-- local function UnpackTask(Tarefa)
--     Tupla = table.unpack(Tarefa)
--     return Tupla
-- end
local function GetSubtree(Agent,Subtree)
    if not Subtree then
        return ActionNode:new(function()
            return "Failure"
        end)
    end
    return Subtrees.Subarvores[Subtree](Agent)
end


Subtrees.Subarvores = {
    ["AdquirirRecursos"] =  function()
        local root = SequenceNode:new("AdquirirRecursos")

        local NearbyResources = ActionNode:new(Actions.Functions["NearbyResources"], "NearbyResources")
        local GatherResources = ActionNode:new(Actions.Functions["GatherResources"])
        local Patrol = ActionNode:new(Actions.Functions["Patrol"])
        root:addChild(NearbyResources)
        root:addChild(GatherResources)
        root:addChild(Patrol)
        return root
    end,
    ["GatherTask"] = function()

        local root = SequenceNode:new("GatherTask")

        local GoCollect = ActionNode:new(Actions.Functions["GetToDestination"],"GetToDestination")
        local CollectResources = ActionNode:new(Actions.Functions["CollectResources"],"CollectResources")
        local GoToStorage = ActionNode:new(Actions.Functions["GetToDestination"],"GetToDestination")
        local DeliveryResources = ActionNode:new(Actions.Functions["DeliveryResources"],"DeliveryResources")
        local GoToCampfire = ActionNode:new(Actions.Functions["GetToDestination"],"GetToDestination")
        local CompleteOrder = ActionNode:new(Actions.Functions["CompleteOrder"],"CompleteOrder")

        root:addChild(GoCollect)
        root:addChild(CollectResources)
        root:addChild(GoToStorage)
        root:addChild(DeliveryResources)
        root:addChild(GoToCampfire)
        root:addChild(CompleteOrder)

        return root

    end,
    ["WaitForTasks"] = function()
        local root = SelectorNode:new("WaitForTasks")

        local HasTask = ActionNode:new(Actions.Functions["HasOrder"],"HasOrder")
        
        -- local CollectResources = Subtrees.Subarvores[Agent.Orders.TaskType](Agent)
        local CollectResources = ActionNode:new(Actions.Functions["GetTaskTree"],"GetTaskTree")
        

        local Idle = ActionNode:new(Actions.Functions["Idle"],"Idle")

        local TaskSequence = SequenceNode:new("HasTask --> CollectResources")
        TaskSequence:addChild(HasTask)
        TaskSequence:addChild(CollectResources)

        root:addChild(TaskSequence)
        root:addChild(Idle)
        
        return root
    end
}

Actions.subtrees = Subtrees.Subarvores
Actions.Nodes = {
    SequenceNode = SequenceNode,
    SelectorNode = SelectorNode,
    ActionNode = ActionNode
}

return Subtrees