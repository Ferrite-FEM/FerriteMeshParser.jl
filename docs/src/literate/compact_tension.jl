# # 2d mixed mesh import
# In this example, we will import a 2d mesh of a Compact Tension (CT) specimen 
# from Abaqus. The mesh has both triangular and quadrilateral cells, and we define 
# a few sets in Abaqus.
# 
#-
# ## Abaqus setup
# 
# ![](compact_tension_specimen.svg)
# Figure 1: Geometry and sets, mesh overview and detailed mesh from Abaqus.
# 
# We have created sets for the hole (blue line: "Hole"), the symmetry edge 
# (red line: "Symmetry"), and the crack zone (green area: "CrackZone").
# 
# ## Importing mesh
# The mesh above was created in Abaqus cae, and in this example we 
# import the generated input file: [compact_tension.inp](compact_tension.inp)
# Print working directory

println(pwd())

#
using Ferrite, FerriteMeshParser

grid = get_ferrite_grid(joinpath(@__DIR__, "compact_tension.inp"))

# We can now inspect this grid, showing that we have different cell types
println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

# Furthermore, the node and cell sets are imported
println([(key, length(set)) for (key, set) in getnodesets(grid)])
println([(key, length(set)) for (key, set) in getcellsets(grid)])

# As we see, in addition to the sets created in Abaqus, the cellsets also include a set 
# for each abaqus element type (useful if you for example defined reduced integration
# in only part of the domain and want to have this in Ferrite). Finally, facesets are 
# automatically created by default (can be turned off by `generate_facesets=false` 
# argument) based on the nodesets:
println([(key, length(set)) for (key, set) in getfacesets(grid)])
# Clearly, the faceset `"CrackZone"` doesn't make much sense, but unless the mesh is 
# very large it doesn't hurt. The facesets can be created manually from each nodeset
# by using the `create_faceset` function: 
faceset = create_faceset(grid, getnodeset(grid,"Hole"));
# This can if desired be merged into the grid by
merge!(getfacesets(grid), Dict("HoleManual" => faceset))
println([(key, length(set)) for (key, set) in getfacesets(grid)])

# 
#md # ## [Plain Program](@id compact-tension-plain-program)
#md #
#md # Below follows a version of the program without any comments.
#md # The file is also available here: [compact_tension.jl](compact_tension.jl)
#md #
#md # ```julia
#md # @__CODE__
#md # ```

