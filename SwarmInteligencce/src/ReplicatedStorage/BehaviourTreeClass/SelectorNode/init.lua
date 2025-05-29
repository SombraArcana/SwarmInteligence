local BehaviorNode  = require(script.Parent)
local SelectorNode = setmetatable({}, BehaviorNode)
SelectorNode.__index = SelectorNode

function SelectorNode:new(Name)
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    node.Name = Name or "SelectorNode"
    return node
end

function SelectorNode:addChild(node)
    table.insert(self.children, node)
end

function SelectorNode:ShowChildrens()
    print(self.Name)
    for i, node in self.children do
        if not node.Type == "ActionNode" then
            node:ShowChildrens()
        else
            print(" ",node.Name)
        end
    end
end

function SelectorNode:execute(Agent)
    for _, child in ipairs(self.children) do
        local status, lastnode = child:execute(Agent)
        if status == "Success" then
            return "Success" , lastnode
        elseif status == "RUNNING" then
            return "RUNNING", lastnode
        elseif status == "Inactive" then
            return "Inactive", lastnode
        end
    end
    return "Failure", "Selector node Failure"
end

return SelectorNode