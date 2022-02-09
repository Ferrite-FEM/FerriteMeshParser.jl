using Ferrite, FerriteMeshParser

grid = get_ferrite_grid("compact_tension.inp")

println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

println([(key, length(set)) for (key, set) in getnodesets(grid)])
println([(key, length(set)) for (key, set) in getcellsets(grid)])

println([(key, length(set)) for (key, set) in getfacesets(grid)])

faceset = create_faceset(grid, getnodeset(grid,"Hole"));

merge!(getfacesets(grid), Dict("HoleManual" => faceset))
println([(key, length(set)) for (key, set) in getfacesets(grid)])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

