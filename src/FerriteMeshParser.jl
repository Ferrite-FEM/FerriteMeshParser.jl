module FerriteMeshParser
using Ferrite
# Convenience when debugging
const DEBUG_PARSE = false

# Mesh formats
struct AutomaticMeshFormat end
struct AbaqusMeshFormat end

# Exceptions
struct UndetectableMeshFormatError <: Exception
    filename::String
end
Base.showerror(io::IO, e::UndetectableMeshFormatError) = println(io, "Couldn't automatically detect mesh format in $(e.filename)")

struct UnsupportedElementType <: Exception
    elementtype::String
end
Base.showerror(io::IO, e::UnsupportedElementType) = println(io, "The element type \"$(e.elementtype)\" is not supported or given in user_elements")


include("rawmesh.jl")
include("elements.jl")
include("reading_utils.jl") 
include("abaqusreader.jl")
include("gridcreator.jl")

"""
    function get_ferrite_grid(filename; meshformat=AutomaticMeshFormat(), user_elements::Dict{String,DataType}=Dict{String,DataType}())

    Greate a `Ferrite.Grid` by reading in the file specified by `filename`.

    ## Optional arguments (default)
    * `meshformat` (`FerriteMeshParser.AutomaticMeshFormat`): Which format the mesh 
      is given in, normally automatically detected by file extension
    * `user_elements` (`Dict{String,DataType}()`): Used to add extra elements not supported,
      might require separate constructor.
    * `generate_facesets` (`true`): Should facesets be detected automatically from all nodesets?

"""
function get_ferrite_grid(filename; meshformat=AutomaticMeshFormat(), user_elements::Dict{String,DataType}=Dict{String,DataType}(), generate_facesets::Bool=true)
    detected_format = detect_mesh_format(filename, meshformat)
    mesh = read_mesh(filename, detected_format)
    grid = create_grid(mesh, detected_format, user_elements)
    generate_facesets && generate_facesets!(grid)
    return grid
end

"""
    create_faceset(grid::Ferrite.AbstractGrid, nodeset::Set{Int}, cellset::Union{Nothing,Set{Int}}=nothing)

Find the faces in the grid for which all nodes are in `nodeset`. Return them as a `Set{FaceIndex}`.
A `cellset` can be given to only look only for faces amongst those cells to speed up the computation. 
Otherwise the search is over all cells
"""
function create_faceset(grid::Ferrite.AbstractGrid, nodeset::Set{Int}, ::Nothing=nothing)
    faceset = Set{FaceIndex}()
    for (cellid, cell) in enumerate(getcells(grid))
        if any(map(n-> n ∈ nodeset, cell.nodes))
            # check actual faces
            for (faceid, face) in enumerate(Ferrite.faces(cell))
                if all(map(n -> n ∈ nodeset, face))
                    push!(faceset, FaceIndex(cellid, faceid))
                end
            end
        end
    end
    return faceset
end

function create_faceset(grid::Ferrite.AbstractGrid, nodeset::Set{Int}, cellset::Set{Int})
    faceset = Set{FaceIndex}()
    cellrange = collect(cellset)
    for (i, cell) in enumerate(getcells(grid)[cellrange])
        cellid = cellrange[i]
        for (faceid, face) in enumerate(Ferrite.faces(cell))
            if all(map(n -> n ∈ nodeset, face))
                push!(faceset, FaceIndex(cellid, faceid))
            end
        end
    end
    return faceset
end

detect_mesh_format(_, meshformat) = meshformat
function detect_mesh_format(filename, ::AutomaticMeshFormat)
    if endswith(filename, ".inp")
        return AbaqusMeshFormat()
    else
        throw(UndetectableMeshFormatError(filename))
    end
end

export get_ferrite_grid, create_faceset

end