# # User element
# In this example, we will add support for an element that is currently not 
# supported inside the package: The linear wedge element, `C3D6`, defined in
# [wedge_element.inp](wedge_element.inp), which exists in Ferrite as `Wedge`.
# It is also possible to define how to read in other cells not defined in 
# Ferrite using the same technique, but that also requires defining further 
# information to be able to use such cells in Ferrite later.  
# 
# ![](wedge_element.svg)
# 
using Ferrite, FerriteMeshParser

# The `Wedge` cell has the same node order in Ferrite as in Abaqus (above). 
# Hence, in this case it is not required, but if desired it can be changed 
# by overloading the function `FerriteMeshParser.create_cell` as follows

create_cell(::Type{Wedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = Wedge(ntuple(j->node_numbers[j], length(node_numbers)))

# This setup allows changing the node order for your specific element.
# After these modifications, one can import 
# the mesh by specifying that the Abaqus code `C3D6` should be interpreted as a `LinearWedge`:

grid = get_ferrite_grid("wedge_element.inp"; user_elements=Dict("C3D6"=>Wedge));

# Giving the following grid
println(typeof(grid))
println(unique(typeof.(getcells(grid))))    # The different cell types in the grid

# 
#md # ## [Plain Program](@id user-element-plain-program)
#md #
#md # Below follows a version of the program without any comments.
#md # The file is also available here: [user_element.jl](user_element.jl)
#md #
#md # ```julia
#md # @__CODE__
#md # ```

