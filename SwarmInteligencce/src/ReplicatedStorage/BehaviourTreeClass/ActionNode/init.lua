local BehaviorNode  = require(script.Parent)

local ActionNode = setmetatable({}, BehaviorNode)
ActionNode.__index = ActionNode

function ActionNode:new(action,Name)
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.action = action
    node.Type = "ActionNode"
    node.Name = Name or "ActionNode"
    return node
end

function ActionNode:execute(agent)
    return self.action(agent)
end

return ActionNode