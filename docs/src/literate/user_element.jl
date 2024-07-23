# # User element
# In this example, we will add support for an element that is currently not 
# supported inside the package: The linear wedge element, `C3D6`, defined in
# [wedge_element.inp](wedge_element.inp)
# 
# ![](wedge_element.svg)
# 
# For this element, it can be defined as a specific `Ferrite.Cell` type
using Ferrite, FerriteMeshParser
LinearWedge = Ferrite.Cell{3, 6, 5}

# For this element to work with Ferrite, one must define a new reference shape
# e.g. Wedge and the appropriate interpolations for this shape. In doing so, 
# one also chooses the node order. Following the standard Ferrite conventions, 
# the node order should be the same as in Abaqus as shown above. To change this,
# it is possible to overload the function `FerriteMeshParser.create_cell` as follows

create_cell(::Type{LinearWedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = LinearWedge(ntuple(j -> node_numbers[j], length(node_numbers)))

# This setup allows changing the node order for your specific element. 
# It is also possible to use another type which is not a variant of `Ferrite.Cell`, but 
# rather a subtype of `Ferrite.AbstractCell`. After these modifications, one can import 
# the mesh by specifying that the Abaqus code `C3D6` should be interpreted as a `LinearWedge`:

grid = get_ferrite_grid("wedge_element.inp"; user_elements = Dict("C3D6" => LinearWedge));

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
