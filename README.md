# FerriteMeshParser

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Ferrite-FEM.github.io/FerriteMeshParser.jl/dev)
[![Build Status](https://github.com/Ferrite-FEM/FerriteMeshParser.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Ferrite-FEM/FerriteMeshParser.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Ferrite-FEM/FerriteMeshParser.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Ferrite-FEM/FerriteMeshParser.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Import mesh from Abaqus input (`.inp`) files into `Ferrite.jl`'s `Grid` type. User-defined cell types are supported. 

Pull requests that add Julia code to parse other mesh formats are very welcome! Note that for [`Gmsh`](https://gmsh.info/), the package [`FerriteGmsh.jl`](https://github.com/Ferrite-FEM/FerriteGmsh.jl) already provides a versatile interface.

## Getting started
A very brief intro is given here, please see the [docs](https://Ferrite-FEM.github.io/FerriteMeshParser.jl/dev) for further details and examples
### Installation
```julia
]add FerriteMeshParser
using FerriteMeshParser
```

### Basic usage
Let `filename` be the path to your Abaqus input file and do
```julia
grid = get_ferrite_grid(filename)
```

### Custom cells (elements)
```julia
grid = get_ferrite_grid(filename; user_elements::Dict{String,DataType}=Dict{String,DataType}())
```
Supply a dictionary with keys being element codes in the mesh file `filename` and the value being the corresponding concrete subtype of `Ferrite.AbstractCell`. 

Additionally, you may have to overload the function
```julia
FerriteMeshParser.create_cell(::Type{CellType}, node_numbers, format::FerriteMeshParser.AbaqusMeshFormat) where{CellType<:Ferrite.AbstractCell}
```
Overloading is required if the constructor of your `CellType` needs different constructor input arguments than a tuple of node indices in the order given in the input file. 
`create_cell` should return an instance of your subtype of `Ferrite.AbstractCell` with the given node_numbers. 


## Current limitations
* Only one part and one instance can exist in the input file
* Node and element numbers must start at 1 and not have any gaps (e.g if there are 10 nodes, no node number higher than 10 can be given)

## Contributors
The code was originally written by [KristofferC](https://github.com/KristofferC) and [kimauth](https://github.com/kimauth)
