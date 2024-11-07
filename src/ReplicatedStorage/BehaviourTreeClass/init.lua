local BehavirouTreeClass = {
}
BehavirouTreeClass.__index = BehavirouTreeClass

function BehavirouTreeClass:new()
    local node = setmetatable({}, self)
    return node
end

function BehavirouTreeClass:execute()
    -- Esta função será sobrescrita pelas subclasses
end
return BehavirouTreeClass