# Generic data structures to represent meshes read from some input file

# Elements
struct RawElements
    numbers::Vector{Int}
    topology::Matrix{Int}
end
RawElements(; numbers, topology) = RawElements(numbers, topology)

getnumbers(elements::RawElements) = elements.numbers
gettopology(elements::RawElements) = elements.topology

getnumelements(elements::RawElements) = length(getnumbers(elements))

# Nodes
struct RawNodes
    numbers::Vector{Int}
    coordinates::Matrix{Float64}
end
RawNodes(; numbers, coordinates) = RawNodes(numbers, coordinates)

getnumbers(nodes::RawNodes) = nodes.numbers
Ferrite.getcoordinates(nodes::RawNodes) = nodes.coordinates

getnumnodes(nodes::RawNodes) = length(getnumbers(nodes))
getdim(nodes::RawNodes) = size(getcoordinates(nodes), 1)
getcoordinate(nodes::RawNodes, number) = getcoordinates(nodes)[:, number]

# Complete mesh
struct RawMesh
    elementsdicts::Dict{String, RawElements}
    nodes::RawNodes
    elementsets::Dict{String, Vector{Int}}
    nodesets::Dict{String, Vector{Int}}
end
RawMesh(; elements, nodes, elementsets, nodesets) = RawMesh(elements, nodes, elementsets, nodesets)

Ferrite.getnodes(mesh::RawMesh) = mesh.nodes
getelementsdicts(mesh::RawMesh) = mesh.elementsdicts
Ferrite.getnodesets(mesh::RawMesh) = mesh.nodesets
getelementsets(mesh::RawMesh) = mesh.elementsets

getdim(mesh::RawMesh) = getdim(getnodes(mesh))
getnumelements(mesh::RawMesh) = sum(getnumelements.(values(getelementsdicts(mesh))))


# Verify that mesh is ok according to what is supported
function checkmesh(mesh::RawMesh)
    # Check that no node numbers are missing
    nodes = getnodes(mesh)
    minimum(getnumbers(nodes)) == 1 || throw(InvalidFileContent("Node numbering must start with 1"))
    maximum(getnumbers(nodes)) == getnumnodes(nodes) || throw(InvalidFileContent("No node numbers may be skipped"))
    # Check that no element numbers are missing
    eldicts = getelementsdicts(mesh)
    minelnum = 2
    maxelnum = 0
    for (_, elems) in eldicts
        minelnum = min(minelnum, minimum(getnumbers(elems)))
        maxelnum = max(maxelnum, maximum(getnumbers(elems)))
    end
    minelnum == 1 || throw(InvalidFileContent("Element numbering must start with 1"))
    maxelnum == getnumelements(mesh) || throw(InvalidFileContent("No element numbers may be skipped"))
end
