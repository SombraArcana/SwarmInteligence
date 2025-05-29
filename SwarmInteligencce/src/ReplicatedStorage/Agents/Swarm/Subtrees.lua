local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreeClass = ReplicatedStorage.BehaviourTreeClass

local BehaviourTreeClass = require(ReplicatedStorage.BehaviourTreeClass)

local SequenceNode = require(TreeClass.SequenceNode)
local SelectorNode = require(TreeClass.SelectorNode)
local ActionNode = require(TreeClass.ActionNode)
local Actions = require(script.Parent.Actions)


local Subtrees = {

}



Subtrees.Subarvores = {
    ["HasEveryoneHouses"] = function()
        local root = SelectorNode:new("Subtree_HasEveryoneHouses")

        local HasEveryoneHouses = ActionNode:new(Actions.Functions["HasEveryoneHouses"],"HasEveryoneHouses")
        
        local HasTask = ActionNode:new(Actions.Functions["HasTask"],"HasTask")
        local HasNoTask = ActionNode:new(Actions.Functions["HasNoTask"],"HasNoTask")
        local ExecuteTask = ActionNode:new(Actions.Functions["ExecuteTask"],"ExecuteTask")
        local selector01 = SelectorNode:new("Seletor1") -- need help here
        local selector1 = SequenceNode:new("Tem tarefa --> Executa tarefa")
        selector1:addChild(HasTask)
        selector1:addChild(ExecuteTask)
        local selector2 = SelectorNode:new("selector2")
        selector2:addChild(HasEveryoneHouses)
        
        local CreateAndExecute = SequenceNode:new("Criar --> Executar")
        local CreateTask = ActionNode:new(Actions.Functions["CreateTask"],"CreateTask")
        CreateAndExecute:addChild(HasNoTask)
        CreateAndExecute:addChild(CreateTask)
        CreateAndExecute:addChild(ExecuteTask)
        selector2:addChild(CreateAndExecute)
        --
        selector01:addChild(selector1)
        selector01:addChild(selector2)
        root:addChild(HasEveryoneHouses)
        root:addChild(selector01)

        return root
    end,
    ["HasChurch"] = function()
        local root = SequenceNode:new("Subtree_HasChurch")

        local HasNoTask = ActionNode:new(Actions.Functions["HasTask"],"HasTask")
        root:addChild(HasNoTask)
        return root
    end,
    ["Primitivo"] = function()
        
    end,
    ["Tribal"] = function()
        local root = SequenceNode:new("Tribal")

        local SubTreeHasEveryoneHouses = Subtrees.Subarvores["HasEveryoneHouses"]()
        local SubTreeGasChurch = Subtrees.Subarvores["HasChurch"]()
        root:addChild(SubTreeHasEveryoneHouses)
        root:addChild(SubTreeGasChurch)


        return root
    end,
}

return Subtrees