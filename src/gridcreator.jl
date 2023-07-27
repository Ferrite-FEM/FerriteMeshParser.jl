function create_grid(mesh::RawMesh, format, user_elements)
    dim = getdim(mesh)
    cells = create_cells(getelementsdicts(mesh), user_elements, format)
    nodes = create_nodes(getnodes(mesh), Val(dim))
    cellsets = create_cellsets(getelementsdicts(mesh), getelementsets(mesh))
    nodesets = create_nodesets(getnodesets(mesh))
    return Grid(cells, nodes; cellsets=cellsets, nodesets=nodesets)
end

function create_nodes(rawnodes::RawNodes, ::Val{dim}) where{dim}
    num = getnumnodes(rawnodes)
    nodes=Array{Node{dim, Float64}}(undef, num)
    for (index, node_number) in enumerate(getnumbers(rawnodes))
        x=Vec{dim}(getcoordinate(rawnodes, index))
        nodes[node_number] = Node(x)
    end
    return nodes
end

function create_cells(rawelementsdict::Dict{String,RawElements}, user_elements::Dict, format)
    builtin_elements = get_element_type_dict(format)
    num_elements = sum(getnumelements.(values(rawelementsdict)))
    cells_generic = Array{Ferrite.AbstractCell}(undef, num_elements)
    for (key, rawelements) in rawelementsdict
        if haskey(user_elements, key)   # user_elements are prioritized over builtin
            addcells!(cells_generic, user_elements[key], rawelements, format)
        elseif haskey(builtin_elements, key)
            addcells!(cells_generic, builtin_elements[key], rawelements, format)
        else
            throw(UnsupportedElementType(key))
        end
    end
    # Return a Union of cell types as this should be faster to use than a generic cell
    cell_type = Union{(typeof.(unique(typeof,cells_generic))...)}
    cells = convert(Array{cell_type}, cells_generic)
    return cells
end

function addcells!(cells, elementtype, rawelements::RawElements, format)
    for (i, element_number) in enumerate(getnumbers(rawelements))
        node_numbers = gettopology(rawelements)[:,i]
        cells[element_number] = create_cell(elementtype, node_numbers, format)
    end
end

# Creating sets
function create_cellsets(rawelementsdict, rawelementsets)
    cellsets = Dict(key => Set(getnumbers(rawelements)) for (key, rawelements) in rawelementsdict)
    merge!(cellsets, Dict(key => Set(nums) for (key, nums) in rawelementsets))
    return cellsets
end

function create_nodesets(rawnodesets)
    return Dict(key => Set(nums) for (key, nums) in rawnodesets)
end


"""
    function generate_facesets!(grid::Ferrite.Grid)

Based on all nodesets in `grid`, generate facesets for those sets.
"""
function generate_facesets!(grid::Ferrite.Grid)
    for (key, set) in Ferrite.getnodesets(grid)
        cellset = get(Ferrite.getcellsets(grid), key, 1:getncells(grid))
        addfaceset!(grid, key, create_faceset(grid, set, cellset))
    end
end