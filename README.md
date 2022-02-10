# FerriteMeshParser

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://KnutAM.github.io/FerriteMeshParser.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://KnutAM.github.io/FerriteMeshParser.jl/dev)
[![Build Status](https://github.com/KnutAM/FerriteMeshParser.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/KnutAM/FerriteMeshParser.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/KnutAM/FerriteMeshParser.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/KnutAM/FerriteMeshParser.jl)

**Note:** This package is currently only work in progress and there are likely many bugs. Frequent interface changes might also occur. 

**Goals**

* Contain the common elements for 2d and 3d from Abaqus
* Provide interface for a user to extend to non-supported Abaqus element types
* Provide interface for a user to override default behavior if desired

## Getting started
For more info and examples, please see the docs
### Basic usage
Let `filename` be the path to your Abaqus input file and do
```julia
grid = get_ferrite_grid(filename)
```

### Custom cells (elements)
```julia
grid = get_ferrite_grid(filename; user_elements::Dict{String,DataType}=Dict{String,DataType}())
```
Supply a dictionary with keys being element codes in the mesh file `filename` and the value being the corresponding concrete subtype of `Ferrite.AbstractCell`. Additionally, you should overload the function with your `CellType`
```julia
FerriteMeshParser.create_cell(::Type{CellType}, node_numbers, format::FerriteMeshParser.AbaqusMeshFormat) where{CellType<:Ferrite.AbstractCell}
```
to return an instance of your subtype of `Ferrite.AbstractCell` with the given node_numbers. 


## Current limitations
* Only one part or instance can exist in the input file
* All node and element numbers must start at 1 and not have any gaps (e.g if there are 10 nodes, no node number higher than 10 can be given)


# Credits
This module is built upon scripts kindly provided by (in alphabetical order)

* [@kimauth](github.com/kimauth)
* [@kristofferC](github.com/kristofferC)

but all bugs belong to [@KnutAM](github.com/KnutAM)
