local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TwS = game:GetService("TweenService")
local Maths = {}

local function ReturnRandom(x,y)
	return math.random(x,y)
end
local Fila = {}
Fila.__index = Fila



function Fila.new()
    local self = setmetatable({}, Fila)
    self.items = {}
    return self
end


function Fila:enqueue(item)
    table.insert(self.items, item)
    
    -- Configuração do tween para o efeito de fade out e movimento
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out) -- 1 segundo de duração

    -- Loop para aplicar o efeito nos itens, com delay entre eles
    for i, v in ipairs(self.items) do
        if v.ClassName == "TextLabel" or v.ClassName == "Frame" then
            -- Definir a nova posição e a transparência alvo
            local targetPosition = UDim2.new(0, 0, (i / 10) * -1, 0) -- Movendo para cima
            local tweenGoal = {
                Position = targetPosition,
                TextTransparency = 1, -- Para TextLabel (transparência completa)
                BackgroundTransparency = 1 -- Para Frame (transparência completa)
            }

            -- Criar o tween
            local tween = TwS:Create(v, tweenInfo, tweenGoal)

            -- Esperar 0.1 segundo antes de iniciar o próximo tween
            task.wait(0.1)

            -- Reproduzir o tween
            tween:Play()

            -- Remover o item após o efeito se concluir
            
        end
    end
end

function Fila:dequeue()
    if self:isEmpty() then
        return nil
    end
    return table.remove(self.items, 1)
end

function Fila:isEmpty()
    return #self.items == 0
end

function Fila:peek()
    if self:isEmpty() then
        return nil
    end
    return self.items[1]
end

function Fila:size()
    return #self.items
end






function Maths.ReturnRandomVector() : Vector3
	local value = Vector3.new(ReturnRandom(1,5),0,ReturnRandom(1,5))
	print(value)
	return value
end

function Maths.AddDisplay(Parent,text,felay) 
    print("sfkkbghzslkofjakçdjalçsdkasdasdasd")
    local Delay = felay or 0.3
	local Display = Parent:FindFirstChild("DisplayGui")
    local Queue
    if Display:FindFirstChild("Queue") ~= nil then
        print("kgkhdsfsadfasd")
        Queue = require(Display:FindFirstChild("Queue"))
    else
        print("kgkhdsfsadfasd")
        local clone = script.ModuleScript:Clone()
        clone.Parent = Display
        clone.Name = "Queue"
        Queue = require(clone)
    end
    print(Queue)
    local fila
    if Queue["Queue"] ~= nil then
        fila = Queue["Queue"]
    else
        Queue["Queue"] = Fila.new()
        fila = Queue["Queue"]
    end
    local Textframe = Instance.new("TextLabel",Display)
    Textframe.AnchorPoint = Vector2.new(0,0)
    Textframe.Size = UDim2.new(1,0,0.5,0)
    Textframe.BackgroundTransparency = 1
    Textframe.TextScaled = true

    
    Textframe.Text = text
    Textframe.Parent = Display
    fila:enqueue(Textframe)
    
    Debris:AddItem(Textframe,Delay)

end


return Maths