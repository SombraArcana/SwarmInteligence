local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreeClass = ReplicatedStorage.BehaviourTreeClass

local BehaviourTreeClass = require(ReplicatedStorage.BehaviourTreeClass)

local SequenceNode = require(TreeClass.SequenceNode)
local SelectorNode = require(TreeClass.SelectorNode)
local ActionNode = require(TreeClass.ActionNode)
local Actions = require(script.Actions)


local Subtrees = {

}



Subtrees.Subarvores = {
    ["AdquirirRecursos"] =  function()
        local root = SequenceNode:new()

        local NearbyResources = ActionNode:new(Actions.Functions["NearbyResources"])
        local GatherResources = ActionNode:new(Actions.Functions["GatherResources"])
        local Patrol = ActionNode:new(Actions.Functions["Patrol"])
        root:addChild(NearbyResources)
        root:addChild(GatherResources)
        root:addChild(Patrol)
        return root
    end,
}

return Subtrees