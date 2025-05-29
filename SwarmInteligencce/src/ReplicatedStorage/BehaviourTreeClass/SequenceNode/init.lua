local BehaviorNode = require(script.Parent)
local SequenceNode = setmetatable({}, BehaviorNode)
SequenceNode.__index = SequenceNode

function SequenceNode:new(Name)
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    node.Name = Name or "SequenceNode"
    return node
end

function SequenceNode:addChild(node)
    table.insert(self.children, node)
end

function SequenceNode:ShowChildrens()
    print(self.Name)
    for i, node in self.children do
        if not node.Type == "ActionNode" then
            node:ShowChildrens()
        else
            print(" ",node.Name)
        end
    end
end

function SequenceNode:execute(Agent)
    for _, child in ipairs(self.children) do
        local status, lastnode = child:execute(Agent)
        if status == "Failure" then
            return "Failure", lastnode
        elseif status == "RUNNING" then
            return "RUNNING", lastnode
        elseif status == "Inactive" then
            return "Inactive", lastnode
        end
    end
    return "Success", "Sequence Node Success"
end

return SequenceNode