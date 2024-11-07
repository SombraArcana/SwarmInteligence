local BehaviorNode  = require(script.Parent)
local SelectorNode = setmetatable({}, BehaviorNode)
SelectorNode.__index = SelectorNode

function SelectorNode:new()
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    return node
end

function SelectorNode:addChild(node)
    table.insert(self.children, node)
end

function SelectorNode:execute(Agent)
    for _, child in ipairs(self.children) do
        if child:execute(Agent) then
            return true
        end
    end
    return false
end

return SelectorNode