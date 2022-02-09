```@meta
CurrentModule = FerriteMeshParser
```

# FerriteMeshParser
[FerriteMeshParser](https://github.com/KnutAM/FerriteMeshParser.jl) is used to parse a mesh file (currently, only Abaqus input files are supported) into a `Ferrite.Grid` . The main exported function is `get_ferrite_grid`:
```@docs
get_ferrite_grid
```

Additionally, it is possible to create facesets from a given nodeset using `create_faceset`. However, this is normally only required if calling `get_ferrite_grid` with `generate_facesets=false`. 
```@docs
create_faceset
```