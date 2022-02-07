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

Create a `grid::Ferrite.Grid` from `filename` with a mesh format specificed by `meshformat`. 
`user_elements` can be used to 

1. Override the default behavior for a given element code
2. Define the behavior for other element codes

"""
function get_ferrite_grid(filename; meshformat=AutomaticMeshFormat(), user_elements::Dict{String,DataType}=Dict{String,DataType}())
    detected_format = detect_mesh_format(filename, meshformat)
    mesh = read_mesh(filename, detected_format)
    return create_grid(mesh, detected_format, user_elements)
end

detect_mesh_format(_, meshformat) = meshformat
function detect_mesh_format(filename, ::AutomaticMeshFormat)
    if endswith(filename, ".inp")
        return AbaqusMeshFormat()
    else
        throw(UndetectableMeshFormatError(filename))
    end
end

export get_ferrite_grid

end