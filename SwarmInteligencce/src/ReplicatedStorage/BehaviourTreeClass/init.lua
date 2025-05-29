local BehavirouTreeClass = {
}
BehavirouTreeClass.__index = BehavirouTreeClass

function BehavirouTreeClass:new(Name)
    local node = setmetatable({}, self)
    node.Name = Name
    return node
end

function BehavirouTreeClass:execute()
    -- Esta função será sobrescrita pelas subclasses
end


return BehavirouTreeClass