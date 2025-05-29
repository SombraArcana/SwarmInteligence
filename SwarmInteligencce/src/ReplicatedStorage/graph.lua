-- Módulo de grafos em Luau para Roblox
local Graph = {}
Graph.__index = Graph

-- Função para criar um novo grafo
function Graph.new()
    local self = setmetatable({}, Graph)
    self.adjList = {} -- Lista de adjacência
    return self
end

-- Adicionar vértice ao grafo
function Graph:addVertice(vertex)
    if not self.adjList[vertex] then
        self.adjList[vertex] = {}
    end
end

-- Adicionar aresta entre dois vértices
function Graph:addAresta(v1, v2)
    self:addVertex(v1)
    self:addVertex(v2)
    table.insert(self.adjList[v1], v2)
    table.insert(self.adjList[v2], v1) -- Grafo não-direcionado
end

-- Busca em profundidade (DFS)
function Graph:DFS(startVertex, visited)
    visited = visited or {}
    if visited[startVertex] then return end

    print("Visitando:", startVertex)
    visited[startVertex] = true

    for _, neighbor in ipairs(self.adjList[startVertex]) do
        self:DFS(neighbor, visited)
    end
end

-- -- Criar e testar o grafo
-- local g = Graph.new()
-- g:addEdge("A", "B")
-- g:addEdge("A", "C")
-- g:addEdge("B", "D")
-- g:addEdge("C", "E")

-- print("Executando DFS:")
-- g:DFS("A")

return Graph