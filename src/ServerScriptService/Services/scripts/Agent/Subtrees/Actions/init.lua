local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Util = require(ReplicatedStorage.Maths)

local Actions = {

}
local Agents




Actions.Functions = {
    ["NearbyResources"] = function(Agent)
        print("a função: NearbyResources foi disparada")
        for i,Recurso in pairs(Workspace.Recursos:GetChildren()) do
            if (Recurso.Position - Agent:GetPosition()).Magnitude < 100 then
                return true
            end
        end
        return false
    end,
    ["GatherResources"] = function(Agent)
        print("a função: GatherResources foi disparada")
        local part
        for i,Recurso in pairs(Workspace.Recursos:GetChildren()) do
            if (Recurso.Position - Agent:GetPosition()).Magnitude < 100 then
                part = Recurso
            end
        end
        local coordinates = part.Position
        local Recurso = part:GetAttribute("Recurso")
        Agent:Move(coordinates)
        task.wait(3)
        Agent:GetInv()[Recurso] = 0
        while Agent:GetInv()[Recurso] < 10 do
            task.wait(1)
            Agent:GetInv()[Recurso] += 1
            Util.AddDisplay(part, "Pedra + "..Agent:GetInv()[Recurso],2)
        end
        Agent:Move(Agent.Storage.Position)
        task.wait(5)
        local atual = Workspace.AgentProperty.Storage:GetAttribute("StoneStorage")
        atual += Agent:GetInv()[Recurso]
        Agent:GetInv()[Recurso] = 0
        Util.AddDisplay(Workspace.AgentProperty.Storage, "Pedra +"..atual, 2)
        Workspace.AgentProperty.Storage:SetAttribute("StoneStorage",atual)
        return "Success"
    end,
    ["Patrol"] = function(Agent)
        print("a função: Patrol foi disparada")
        Agent:Move(Workspace.Poste.Position)
        task.wait(2)
        return "Success"
    end,
    ["PathFind"] = function(Agent,Destination)
        
    end,
    ["GetToDestination"] = function()
        
    end,
}

return Actions