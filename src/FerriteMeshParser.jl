module FerriteMeshParser
using Ferrite: 
    Ferrite, Grid, Node, Vec,
    getcells, getnodes, getcoordinates, getncells

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

struct InvalidFileContent <: Exception
    msg::String
end
Base.showerror(io::IO, e::InvalidFileContent) = println(io, e.msg)

@static if !isdefined(Ferrite, :SerendipityQuadraticHexahedron)
    const SerendipityQuadraticHexahedron = Ferrite.Cell{3,20,6}
    const SerendipityQuadraticQuadrilateral = Ferrite.Cell{2,8,4}
else
    const SerendipityQuadraticHexahedron = Ferrite.SerendipityQuadraticHexahedron
    const SerendipityQuadraticQuadrilateral = Ferrite.SerendipityQuadraticQuadrilateral
end

const FacetsDefined = isdefined(Ferrite, :FacetIndex) # Ferrite after v1.0 (Ferrite#914)

const FacetIndex   = FacetsDefined ? Ferrite.FacetIndex   : Ferrite.FaceIndex
const facets       = FacetsDefined ? Ferrite.facets       : Ferrite.faces
const addfacetset! = FacetsDefined ? Ferrite.addfacetset! : Ferrite.addfaceset!

include("rawmesh.jl")
include("elements.jl")
include("reading_utils.jl") 
include("abaqusreader.jl")
include("gridcreator.jl")

"""
    function get_ferrite_grid(
        filename; 
        meshformat=AutomaticMeshFormat(), 
        user_elements=Dict{String,DataType}(), 
        generate_facetsets=true
        )

Create a `Ferrite.Grid` by reading in the file specified by `filename`.

Optional arguments:
* `meshformat`: Which format the mesh 
    is given in, normally automatically detected by the file extension
* `user_elements`: Used to add extra elements not supported,
    might require a separate cell constructor.
* `generate_facetsets`: Should facesets be automatically generated from all nodesets?

"""
function get_ferrite_grid(filename; meshformat=AutomaticMeshFormat(), user_elements::Dict{String, DataType}=Dict{String, DataType}(), generate_facetsets::Bool=true, generate_facesets=nothing)
    generate_facesets !== nothing && error("The keyword generate_facesets is deprecated, use generate_facetsets instead")
    detected_format = detect_mesh_format(filename, meshformat)
    mesh = read_mesh(filename, detected_format)
    checkmesh(mesh)
    grid = create_grid(mesh, detected_format, user_elements)
    generate_facetsets && generate_facetsets!(grid)
    return grid
end

"""
    create_facetset(
        grid::Ferrite.AbstractGrid, 
        nodeset::Set{Int}, 
        cellset::Union{UnitRange{Int},Set{Int}}=1:getncells(grid)
        )

Find the facets in the grid for which all nodes are in `nodeset`. Return them as a `Set{FacetIndex}`.
A `cellset` can be given to only look only for faces amongst those cells to speed up the computation. 
Otherwise the search is over all cells.

This function is normally only required when calling `get_ferrite_grid` with `generate_facetsets=false`. 
The created `facetset` can be added to the grid as `addfacetset!(grid, "facetsetkey", facetset)`
"""
function create_facetset(grid::Ferrite.AbstractGrid, nodeset::AbstractSet{Int}, cellset=1:getncells(grid))
    facetset = sizehint!(Set{FacetIndex}(), length(nodeset))
    for (cellid, cell) in enumerate(getcells(grid))
        cellid ∈ cellset || continue
        if any(n-> n ∈ nodeset, cell.nodes)
            for (facetid, facet) in enumerate(facets(cell))
                if all(n -> n ∈ nodeset, facet)
                    push!(facetset, FacetIndex(cellid, facetid))
                end
            end
        end
    end
    return facetset
end

detect_mesh_format(_, meshformat) = meshformat
function detect_mesh_format(filename, ::AutomaticMeshFormat)
    if endswith(filename, ".inp")
        return AbaqusMeshFormat()
    else
        throw(UndetectableMeshFormatError(filename))
    end
end

export get_ferrite_grid, create_facetset

# Deprecated 
function create_faceset(args...)
    error("create_faceset is no longer supported, use create_facetset instead")
end
export create_faceset

end
