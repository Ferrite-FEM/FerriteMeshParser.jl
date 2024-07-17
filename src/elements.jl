function get_element_type_dict(::AbaqusMeshFormat)

    quad = (Ferrite.Quadrilateral, ("CPE4", "CPS4", "CPE4R", "CPS4R"))
    quad2 = (SerendipityQuadraticQuadrilateral, ("CPS8", "CPS8R", "CPE8", "CPE8R"))
    tria = (Ferrite.Triangle, ("CPE3", "CPS3"))
    tria2 = (Ferrite.QuadraticTriangle, ("CPE6", "CPS6", "CPE6M", "CPS6M"))
    tetra = (Ferrite.Tetrahedron, ("C3D4",))
    tetra2 = (Ferrite.QuadraticTetrahedron, ("C3D10",))
    hexa = (Ferrite.Hexahedron, ("C3D8", "C3D8R"))
    hexa2 = (SerendipityQuadraticHexahedron, ("C3D20", "C3D20R"))

    dict = Dict{String, DataType}()
    for types in (quad, tria, quad2, tria2, tetra, tetra2, hexa, hexa2)
        merge!(dict, Dict(code => types[1] for code in types[2]))
    end
    return dict
end

# Default creator for Ferrite cell types from Abaqus elements
create_cell(::Type{CellType}, node_numbers, ::AbaqusMeshFormat) where {CellType <: Ferrite.AbstractCell} = CellType(ntuple(j -> node_numbers[j], length(node_numbers)))
