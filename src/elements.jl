@static if !isdefined(Ferrite, :SerendipityQuadraticHexahedron)
    const SerendipityQuadraticHexahedron = Cell{3,20,6}
    const SerendipityQuadraticQuadrilateral = Cell{2,8,4}
end

function get_element_type_dict(::AbaqusMeshFormat)
    
    quad = (Quadrilateral, ("CPE4", "CPS4", "CPE4R", "CPS4R"))
    quad2 = (SerendipityQuadraticQuadrilateral, ("CPS8", "CPS8R", "CPE8", "CPE8R"))
    tria = (Triangle, ("CPE3", "CPS3"))
    tria2 = (QuadraticTriangle, ("CPE6", "CPS6", "CPE6M", "CPS6M"))
    tetra = (Tetrahedron, ("C3D4",))
    tetra2 = (QuadraticTetrahedron, ("C3D10",))
    hexa = (Hexahedron, ("C3D8","C3D8R"))
    hexa2 = (SerendipityQuadraticHexahedron, ("C3D20","C3D20R"))

    dict = Dict{String,DataType}()
    for types in (quad, tria, quad2, tria2, tetra, tetra2, hexa, hexa2)
        merge!(dict, Dict(code=>types[1] for code in types[2]))
    end
    return dict
end

# Default creator for Ferrite cell types from Abaqus elements
create_cell(::Type{CellType}, node_numbers, ::AbaqusMeshFormat) where{CellType<:Ferrite.AbstractCell} = CellType(ntuple(j->node_numbers[j], length(node_numbers)))
