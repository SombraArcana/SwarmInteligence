local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local agent = require(script.Agent)
local matematicas = require(ReplicatedStorage.Maths)


local tableAgetns = {

}


local otheragent = Workspace.Agents.Agent:Clone()
otheragent.HumanoidRootPart.Position = Vector3.new(0,0,0)


for i,Agent in pairs(Workspace.Agents:GetChildren()) do
    local NewAgent = agent.new(Agent)
    
    tableAgetns[Agent.Name] = NewAgent
end



for i,Agent in pairs(tableAgetns) do

    while true do
        task.wait(1)

        Agent:TickTree()
    end

end

