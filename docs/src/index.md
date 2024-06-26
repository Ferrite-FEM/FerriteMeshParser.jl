```@meta
CurrentModule = FerriteMeshParser
```

# FerriteMeshParser
Parse a mesh file (currently, only Abaqus input files are supported) into a `Ferrite.Grid`. The main exported function is `get_ferrite_grid`, which allows you to import an abaqus mesh as 
```julia
grid = get_ferrite_grid("myabaqusinput.inp")
```
Note that the `.inp` file extension is required to automatically detect that it is an Abaqus input file. 

There are currently a two main limitations

* Only one part/instance from Abaqus is supported
* The node and element numbering must be consecutive (i.e. no missing numbers allowed)

## API

```@docs
get_ferrite_grid
```

```@docs
create_facetset
```