# Generic data structures to represent meshes read from some input file

# Elements
struct RawElements
    numbers::Vector{Int}
    topology::Matrix{Int}
end
RawElements(;numbers, topology) = RawElements(numbers, topology)

getnumbers(elements::RawElements) = elements.numbers
gettopology(elements::RawElements) = elements.topology

getnumelements(elements::RawElements) = length(getnumbers(elements))

# Nodes
struct RawNodes
    numbers::Vector{Int}
    coordinates::Matrix{Float64}
end
RawNodes(;numbers, coordinates) = RawNodes(numbers, coordinates) 

getnodenums(nodes::RawNodes) = nodes.numbers
Ferrite.getcoordinates(nodes::RawNodes) = nodes.coordinates

getnumnodes(nodes::RawNodes) = length(getnodenums(nodes))
getdim(nodes::RawNodes) = size(getcoordinates(nodes),1)
getcoordinate(nodes::RawNodes, number) = getcoordinates(nodes)[:,number]

# Complete mesh
struct RawMesh
    elementsdicts::Dict{String, RawElements}
    nodes::RawNodes
    elementsets::Dict{String, Vector{Int}}
    nodesets::Dict{String, Vector{Int}}
end
RawMesh(;elements,nodes,elementsets,nodesets) = RawMesh(elements,nodes,elementsets,nodesets)

Ferrite.getnodes(mesh::RawMesh) = mesh.nodes
getelementsdicts(mesh::RawMesh) = mesh.elementsdicts
Ferrite.getnodesets(mesh::RawMesh) = mesh.nodesets
getelementsets(mesh::RawMesh) = mesh.elementsets

getdim(mesh::RawMesh) = getdim(getnodes(mesh))