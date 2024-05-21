var documenterSearchIndex = {"docs":
[{"location":"examples/user_element/","page":"User element","title":"User element","text":"EditURL = \"../literate/user_element.jl\"","category":"page"},{"location":"examples/user_element/#User-element","page":"User element","title":"User element","text":"","category":"section"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"In this example, we will add support for an element that is currently not supported inside the package: The linear wedge element, C3D6, defined in wedge_element.inp","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"(Image: )","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"For this element, it can be defined as a specific Ferrite.Cell type","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"using Ferrite, FerriteMeshParser\nLinearWedge = Ferrite.Cell{3,6,5}","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"For this element to work with Ferrite, one must define a new reference shape e.g. Wedge and the appropriate interpolations for this shape. In doing so, one also chooses the node order. Following the standard Ferrite conventions, the node order should be the same as in Abaqus as shown above. To change this, it is possible to overload the function FerriteMeshParser.create_cell as follows","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"create_cell(::Type{LinearWedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = LinearWedge(ntuple(j->node_numbers[j], length(node_numbers)))","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"This setup allows changing the node order for your specific element. It is also possible to use another type which is not a variant of Ferrite.Cell, but rather a subtype of Ferrite.AbstractCell. After these modifications, one can import the mesh by specifying that the Abaqus code C3D6 should be interpreted as a LinearWedge:","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"grid = get_ferrite_grid(\"wedge_element.inp\"; user_elements=Dict(\"C3D6\"=>LinearWedge));\nnothing #hide","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"Giving the following grid","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"println(typeof(grid))\nprintln(unique(typeof.(getcells(grid))))    # The different cell types in the grid","category":"page"},{"location":"examples/user_element/#user-element-plain-program","page":"User element","title":"Plain Program","text":"","category":"section"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"Below follows a version of the program without any comments. The file is also available here: user_element.jl","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"using Ferrite, FerriteMeshParser\nLinearWedge = Ferrite.Cell{3,6,5}\n\ncreate_cell(::Type{LinearWedge}, node_numbers, ::FerriteMeshParser.AbaqusMeshFormat) = LinearWedge(ntuple(j->node_numbers[j], length(node_numbers)))\n\ngrid = get_ferrite_grid(\"wedge_element.inp\"; user_elements=Dict(\"C3D6\"=>LinearWedge));\n\nprintln(typeof(grid))\nprintln(unique(typeof.(getcells(grid))))    # The different cell types in the grid\n\n# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"","category":"page"},{"location":"examples/user_element/","page":"User element","title":"User element","text":"This page was generated using Literate.jl.","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"EditURL = \"../literate/compact_tension.jl\"","category":"page"},{"location":"examples/compact_tension/#2d-mixed-mesh-import","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"","category":"section"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"In this example, we will import a 2d mesh of a Compact Tension (CT) specimen from Abaqus. The mesh has both triangular and quadrilateral cells, and we define a few sets in Abaqus.","category":"page"},{"location":"examples/compact_tension/#Abaqus-setup","page":"2d mixed mesh import","title":"Abaqus setup","text":"","category":"section"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"(Image: ) Figure 1: Geometry and sets, mesh overview and detailed mesh from Abaqus.","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"We have created sets for the hole (blue line: \"Hole\"), the symmetry edge (red line: \"Symmetry\"), and the crack zone (green area: \"CrackZone\").","category":"page"},{"location":"examples/compact_tension/#Importing-mesh","page":"2d mixed mesh import","title":"Importing mesh","text":"","category":"section"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"The mesh above was created in Abaqus cae, and in this example we import the generated input file: compact_tension.inp","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"using Ferrite, FerriteMeshParser\n\ngrid = get_ferrite_grid(\"compact_tension.inp\")","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"We can now inspect this grid, showing that we have different cell types","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"println(typeof(grid))\nprintln(unique(typeof.(getcells(grid))))    # The different cell types in the grid","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"Furthermore, the node and cell sets are imported","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"println([(key, length(set)) for (key, set) in Ferrite.getnodesets(grid)])\nprintln([(key, length(set)) for (key, set) in Ferrite.getcellsets(grid)])","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"As we see, in addition to the sets created in Abaqus, the cellsets also include a set for each abaqus element type (useful if you for example defined reduced integration in only part of the domain and want to have this in Ferrite). Finally, facetsets are automatically created by default (can be turned off by generate_facetsets=false argument) based on the nodesets:","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"println([(key, length(set)) for (key, set) in Ferrite.getfacesets(grid)])","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"Clearly, the facetset \"CrackZone\" doesn't make much sense, but unless the mesh is very large it doesn't hurt. The facetsets can be created manually from each nodeset by using the create_facetset function:","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"facetset = create_facetset(grid, getnodeset(grid,\"Hole\"));\nnothing #hide","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"This can, if desired, be merged into the grid by","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"addfaceset!(grid, \"HoleManual\", facetset)","category":"page"},{"location":"examples/compact_tension/#compact-tension-plain-program","page":"2d mixed mesh import","title":"Plain Program","text":"","category":"section"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"Below follows a version of the program without any comments. The file is also available here: compact_tension.jl","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"using Ferrite, FerriteMeshParser\n\ngrid = get_ferrite_grid(\"compact_tension.inp\")\n\nprintln(typeof(grid))\nprintln(unique(typeof.(getcells(grid))))    # The different cell types in the grid\n\nprintln([(key, length(set)) for (key, set) in Ferrite.getnodesets(grid)])\nprintln([(key, length(set)) for (key, set) in Ferrite.getcellsets(grid)])\n\nprintln([(key, length(set)) for (key, set) in Ferrite.getfacesets(grid)])\n\nfacetset = create_facetset(grid, getnodeset(grid,\"Hole\"));\n\n# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"","category":"page"},{"location":"examples/compact_tension/","page":"2d mixed mesh import","title":"2d mixed mesh import","text":"This page was generated using Literate.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = FerriteMeshParser","category":"page"},{"location":"#FerriteMeshParser","page":"Home","title":"FerriteMeshParser","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Parse a mesh file (currently, only Abaqus input files are supported) into a Ferrite.Grid. The main exported function is get_ferrite_grid, which allows you to import an abaqus mesh as ","category":"page"},{"location":"","page":"Home","title":"Home","text":"grid = get_ferrite_grid(\"myabaqusinput.inp\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"Note that the .inp file extension is required to automatically detect that it is an Abaqus input file. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"There are currently a two main limitations","category":"page"},{"location":"","page":"Home","title":"Home","text":"Only one part/instance from Abaqus is supported\nThe node and element numbering must be consecutive (i.e. no missing numbers allowed)","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"get_ferrite_grid","category":"page"},{"location":"#FerriteMeshParser.get_ferrite_grid","page":"Home","title":"FerriteMeshParser.get_ferrite_grid","text":"function get_ferrite_grid(\n    filename; \n    meshformat=AutomaticMeshFormat(), \n    user_elements=Dict{String,DataType}(), \n    generate_facetsets=true\n    )\n\nCreate a Ferrite.Grid by reading in the file specified by filename.\n\nOptional arguments:\n\nmeshformat: Which format the mesh    is given in, normally automatically detected by the file extension\nuser_elements: Used to add extra elements not supported,   might require a separate cell constructor.\ngenerate_facetsets: Should facesets be automatically generated from all nodesets?\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"create_facetset","category":"page"},{"location":"#FerriteMeshParser.create_facetset","page":"Home","title":"FerriteMeshParser.create_facetset","text":"create_facetset(\n    grid::Ferrite.AbstractGrid, \n    nodeset::Set{Int}, \n    cellset::Union{UnitRange{Int},Set{Int}}=1:getncells(grid)\n    )\n\nFind the facets in the grid for which all nodes are in nodeset. Return them as a Set{FacetIndex}. A cellset can be given to only look only for faces amongst those cells to speed up the computation.  Otherwise the search is over all cells.\n\nThis function is normally only required when calling get_ferrite_grid with generate_facetsets=false.  The created facetset can be added to the grid as addfacetset!(grid, \"facetsetkey\", facetset)\n\n\n\n\n\n","category":"function"}]
}
