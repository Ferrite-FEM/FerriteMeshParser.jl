using Ferrite, FerriteMeshParser

create_cell(::Type{Wedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = Wedge(ntuple(j->node_numbers[j], length(node_numbers)))

grid = get_ferrite_grid("wedge_element.inp"; user_elements=Dict("C3D6"=>Wedge));

println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
