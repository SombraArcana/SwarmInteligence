local BehaviorNode = require(script.Parent)
local SequenceNode = setmetatable({}, BehaviorNode)
SequenceNode.__index = SequenceNode

function SequenceNode:new()
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    return node
end

function SequenceNode:addChild(node)
    table.insert(self.children, node)
end

function SequenceNode:execute(Agent)
    for _, child in ipairs(self.children) do
        local status = child:execute(Agent)
        if status == "Failure" then
            return "Failure"
        elseif status == "RUNNING" then
            return "RUNNING"
        end
    end
    return "Sucess"
end

return SequenceNode