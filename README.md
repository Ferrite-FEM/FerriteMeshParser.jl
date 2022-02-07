# FerriteMeshParser

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://KnutAM.github.io/FerriteMeshParser.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://KnutAM.github.io/FerriteMeshParser.jl/dev)
[![Build Status](https://github.com/KnutAM/FerriteMeshParser.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/KnutAM/FerriteMeshParser.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/KnutAM/FerriteMeshParser.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/KnutAM/FerriteMeshParser.jl)


**Goals**

* Contain the common elements for 2d and 3d from Abaqus
* Provide interface for a user to extend to non-supported Abaqus element types
* Provide interface for a user to override default behavior if desired

## Getting started
### Basic usage
Let `filename` be the path to your Abaqus input file and do
```julia
grid = get_ferrite_grid(filename)
```

### Custom cells
```julia
grid = get_ferrite_grid(filename; user_elements::Dict{String,DataType}=Dict{String,DataType}())
```
Supply a dictionary with keys being the element code filename and the value being the corresponding concrete subtype of `AbstractCell` in Ferrite. Additionally, you should overload the function 
```julia
FerriteMeshParser.create_cell(::Type{CellType}, node_numbers, format::FerriteMeshParser.AbaqusMeshFormat) where{CellType<:Ferrite.AbstractCell}
```
to return an instance of your subtype of `Ferrite.AbstractCell` with the given node_numbers. 


### Full interface function
The full interface allows specifying the type of input if it is not possible to detect automatically (currently automatically identified as `FerriteMeshParser.AbaqusMeshFormat` by `.inp` file ending)
```julia
grid = get_ferrite_grid(filename; input_format=FerriteMeshParser.AutomaticMeshFormat(), user_elements::Dict{String,DataType}=Dict{String,DataType}())
```

## Current limitations
* Only one part or instance can exist in the input file
* All node and element numbers must start at 1 and not have any gaps (e.g if there are 10 nodes, no node number higher than 10 can be given)


## Todos
* Give error if more than one part or instance is given (not currently supported)
* Improve creation of cells - should not hard-code the Ferrite.AbstractCell type of the array

## Open challenges
* Need to handle the case when node numbers are not consecutive, might be cases where some numbers are skipped.
* Support facesets (could be created from surface in abaqus .inp files, but seems a bit involved...)
* Element and node numbers are local to each instance/part. Would it be possible to support multiple parts/instances?


# Credits
This module is built upon scripts kindly provided by (in alphabetical order)

* [@kimauth](github.com/kimauth)
* [@kristofferC](github.com/kristofferC)

but all bugs belong to [@KnutAM](github.com/KnutAM)