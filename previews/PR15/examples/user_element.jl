using Ferrite, FerriteMeshParser
LinearWedge = Ferrite.Cell{3,6,5}

create_cell(::Type{LinearWedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = LinearWedge(ntuple(j->node_numbers[j], length(node_numbers)))

grid = get_ferrite_grid("wedge_element.inp"; user_elements=Dict("C3D6"=>LinearWedge));

println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

