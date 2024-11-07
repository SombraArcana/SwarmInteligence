
--Classe de Arvore de Comportamento
-- Classe de Nó Base
local Tree = {
    BehaviorNode = {},
    ActionNode = {},
    SequenceNode = {},
    SelectorNode = {}
}
local BehaviorNode = Tree.BehaviorNode
BehaviorNode.__index = BehaviorNode

function Tree.BehaviorNode:new()
    local node = setmetatable({}, self)
    return node
end

function BehaviorNode:execute()
    -- Esta função será sobrescrita pelas subclasses
end

-- Classe de Nó de Ação
local ActionNode = setmetatable({}, BehaviorNode)
ActionNode.__index = ActionNode

function Tree.ActionNode:new(action)
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.action = action
    node.Status = "Failure"
    return node
end

function ActionNode:execute(agent)
    return self.action(agent)
end

-- Classe de Nó Sequencial (executa os filhos em sequência)
local SequenceNode = Tree.SequenceNode
SequenceNode = setmetatable({}, BehaviorNode)
SequenceNode.__index = SequenceNode

function SequenceNode:new()
    local node = Tree.BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    return node
end
local oi = SequenceNode:new()
print(oi)

function SequenceNode:addChild(node)
    table.insert(self.children, node)
end

function SequenceNode:execute()
    for _, child in ipairs(self.children) do
        local status = child:execute()
        if status == "Failure" then
            return "Failure"
        elseif status == "RUNNING" then
            return "RUNNING"
        end
    end
    return "Sucess"
end


-- Classe de Nó de Seleção (seleciona o primeiro filho que retornar verdadeiro)
local SelectorNode = setmetatable({}, BehaviorNode)
SelectorNode.__index = SelectorNode

function Tree.SelectorNode:new()
    local node = BehaviorNode:new()
    setmetatable(node, self)
    node.children = {}
    return node
end

function SelectorNode:addChild(node)
    table.insert(self.children, node)
end

function SelectorNode:execute()
    for _, child in ipairs(self.children) do
        if child:execute() then
            return true
        end
    end
    return false
end

-- Exemplo de uso
local function isEnemyClose()
    -- Lógica para detectar inimigo próximo
    print("Verificando se há inimigo próximo")
    return true -- Exemplo
end

local function attackEnemy()
    -- Lógica para atacar o inimigo
    print("Atacando o inimigo")
    return true
end

local root = SequenceNode:new()
local checkEnemy = ActionNode:new(isEnemyClose)
local attack = ActionNode:new(attackEnemy)

-- Executa a árvore de comportamento



-- ####################################################################################################################################################################################
-- StateMachine
-- Máquina de Estados
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new()
    local sm = setmetatable({}, self)
    sm.states = {}
    sm.currentState = nil
    return sm
end

function StateMachine:addState(name, state)
    self.states[name] = state
end

function StateMachine:setState(name)
    if self.states[name] then
        self.currentState = self.states[name]
        print("Mudando para o estado: " .. name)
    end
end

function StateMachine:update()
    if self.currentState and self.currentState.update then
        self.currentState:update()
    end
end

-- Exemplo de Estados
local function idleState()
    local state = {}
    function state:update()
        print("Personagem está parado.")
    end
    return state
end

local function attackState()
    local state = {}
    function state:update()
        print("Personagem está atacando.")
    end
    return state
end

local sm = StateMachine:new()

-- Adicionando estados


-- Alternando estados


-- Alterar estado para "Attack"

return Tree
