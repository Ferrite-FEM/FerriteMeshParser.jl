using Ferrite, FerriteMeshParser

grid = get_ferrite_grid("compact_tension.inp")

println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

println([(key, length(set)) for (key, set) in Ferrite.getnodesets(grid)])
println([(key, length(set)) for (key, set) in Ferrite.getcellsets(grid)])

println([(key, length(set)) for (key, set) in Ferrite.getfacesets(grid)])

facetset = create_facetset(grid, getnodeset(grid, "Hole"));

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
