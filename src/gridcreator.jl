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
    for node_number in getnodenums(rawnodes)
        x=Vec{dim}(getcoordinate(rawnodes, node_number))
        nodes[node_number] = Node(x)
    end
    return nodes
end

function create_cells(rawelementsdict::Dict{String,RawElements}, user_elements::Dict, format)
    builtin_elements = get_element_type_dict(format)
    num_elements = sum(getnumelements.(values(rawelementsdict)))
    cells = Array{Ferrite.AbstractCell}(undef, num_elements)
    for (key, rawelements) in rawelementsdict
        if haskey(user_elements, key)   # user_elements are prioritized over builtin
            addcells!(cells, user_elements[key], rawelements, format)
        elseif haskey(builtin_elements, key)
            addcells!(cells, builtin_elements[key], rawelements, format)
        else
            throw(UnsupportedElementType(key))
        end
    end
    # Convert to array with same types if all types are the same
    # Could perhaps be done already by using a function get_cell_type when creating cells...
    if all(y->isa(y, typeof(first(cells))),cells)
        cells = Array{typeof(first(cells))}([cell for cell in cells])
    end
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
    cellset_or_nothing = Dict(key => (haskey(getcellsets(grid), key) ? getcellsets(grid)[key] : nothing) 
                                for (key, set) in getnodesets(grid))
    merge!(getfacesets(grid), Dict(key => create_faceset(grid, set, cellset_or_nothing[key])
                                for (key, set) in getnodesets(grid)))
end