import Base: ==
using FerriteMeshParser
using Ferrite
using Test
using Aqua

Aqua.test_all(FerriteMeshParser; ambiguities = false)
Aqua.test_ambiguities(FerriteMeshParser)    # This excludes Core and Base, which gets many ambiguities with ForwardDiff

# Function to retrieve test fields
gettestfile(args...) = joinpath(@__DIR__, "test_files", args...)

# Define equality check between grids
==(a::Grid,b::Grid) = all([isequal(getfield.((a,b), (name,))...) for name in fieldnames(typeof(a))])

# Overload default_interpolation where not given in Ferrite
if !isdefined(Main, :SerendipityQuadrilateral)
    const SerendipityQuadrilateral = Cell{2,8,4}
end
Ferrite.default_interpolation(::Type{SerendipityQuadrilateral}) = Serendipity{2, RefCube, 2}()
Ferrite.vertices(c::SerendipityQuadrilateral) = (c.nodes[1], c.nodes[2], c.nodes[3], c.nodes[4])
Ferrite.faces(c::SerendipityQuadrilateral) = ((c.nodes[1],c.nodes[2]), (c.nodes[2],c.nodes[3]), (c.nodes[3],c.nodes[4]), (c.nodes[4],c.nodes[1]))

@testset "CheckVolumes" begin
    unit_volume_files = ("2D_UnitArea_Linear", "2D_UnitArea_Quadratic", 
                         "3D_UnitVolume_LinearHexahedron", "3D_UnitVolume_LinearTetrahedron",
                         "3D_UnitVolume_QuadraticHexahedron", "3D_UnitVolume_QuadraticTetrahedron")
    for base_name in unit_volume_files
        filename = gettestfile(base_name*".inp")
        grid = get_ferrite_grid(filename)
        dh = MixedDofHandler(grid)
        unique_celltypes = unique(typeof.(grid.cells))
        
        fields = [Field(:u, Ferrite.default_interpolation(type), 1) for type in unique_celltypes]
        cellsets = [findall(x->isa(x,type), grid.cells) for type in unique_celltypes]
        fieldhandlers = [FieldHandler([field], Set(set)) for (field,set) in zip(fields, cellsets)]
        add!.((dh,), fieldhandlers)
        close!(dh)

        cv_vec = Any[]
        for type in unique_celltypes
            ip = Ferrite.default_interpolation(type)
            dim = Ferrite.getdim(ip)
            ref = Ferrite.getrefshape(ip)
            qr = QuadratureRule{dim, ref}(1)
            push!(cv_vec, CellScalarValues(qr, ip))
        end
        
        for (cellset, cv, type) in zip(cellsets, cv_vec, unique_celltypes)
            for cell in CellIterator(dh, cellset)
                reinit!(cv, cell)
                V = getdetJdV(cv, 1)
                volcheck = V ≈ 1.0
                !volcheck && println("Volume check failure for \"$base_name.inp\" with a cell of type \"$type\"")
                @test volcheck
            end
        end
    end
end

@testset "celltype" begin
    _getgridtype(::Grid{dim,C}) where {dim,C} = C
    grid_concrete = get_ferrite_grid(gettestfile("2D_CPE3.inp"))
    grid_mixed = get_ferrite_grid(gettestfile("2D_CPE3_CPE4R.inp"))
    @test isconcretetype(_getgridtype(grid_concrete))
    @test _getgridtype(grid_mixed) == Union{Triangle,Quadrilateral}
end

@testset "facesetgeneration" begin
    filename = gettestfile("compact_tension.inp")
    grid = get_ferrite_grid(filename)
    @test create_faceset(grid, getnodeset(grid, "Hole")) == create_faceset(grid, getnodeset(grid, "Hole"), getcellset(grid, "Hole"))    # Test that including cells doesn't change the created sets
end

@testset "exceptions" begin
    filename = joinpath(@__DIR__, "runtests.jl")
    @test_throws FerriteMeshParser.UndetectableMeshFormatError get_ferrite_grid(filename) 

    filename = gettestfile("twoinstances.inp")
    @test_throws FerriteMeshParser.InvalidFileContent get_ferrite_grid(filename) 

    filename = gettestfile("unsupported_element.inp")
    @test_throws FerriteMeshParser.UnsupportedElementType get_ferrite_grid(filename) 

end

@testset "ordering" begin
    filename0 = gettestfile("2D_UnitArea_Linear.inp")
    grid0 = get_ferrite_grid(filename0)

    filename1 = gettestfile("2D_UnitArea_Linear_flipelementorder.inp")
    grid1 = get_ferrite_grid(filename1)

    filename2 = gettestfile("2D_UnitArea_Linear_perturbnodeorder.inp")
    grid2 = get_ferrite_grid(filename2)

    # comparing grid0==grid<i> doesn't work, so check each field:
    for key in fieldnames(typeof(grid0))
        @test getfield(grid0, key) == getfield(grid1, key)
        @test getfield(grid0, key) == getfield(grid2, key)
    end
end

@testset "caseinsensitive" begin
    filename = gettestfile("uppercase_test.inp")
    grid = get_ferrite_grid(filename)
    @test getncells(grid) == 2
    @test getnnodes(grid) == 6
end
    
@testset "sets" begin
    filename = gettestfile("generated_set.inp")
    grid = get_ferrite_grid(filename)
    @test getcellset(grid, "lower") == Set(1:8)
    @test getnodeset(grid, "lower") == Set((1,  2,  3,  4,  7,  8,  9, 10, 11, 12, 13, 14, 20, 21, 22))

    filename = gettestfile("2D_UnitArea_Quadratic.inp")
    grid = get_ferrite_grid(filename)
    @test getcellset(grid, "mysetname") == Set((1,))
end

@testset "custom_cells" begin
    filename = gettestfile("unsupported_element.inp")
    grid = get_ferrite_grid(filename; user_elements=Dict("CPS5R"=>Cell{2,4,4}))
    @test getcellset(grid, "CPS5R") == Set((1,))
    @test isa(getcells(grid)[1], Cell{2,4,4})
end

@testset "specify_file_type" begin
    filename = gettestfile("2D_UnitArea_Quadratic.inp")
    filename_cp = joinpath(@__DIR__, "tmp.txt")
    cp(filename, filename_cp; force=true)
    grid_cp = get_ferrite_grid(filename_cp; meshformat=FerriteMeshParser.AbaqusMeshFormat())
    grid = get_ferrite_grid(filename)
    @test grid_cp == grid
    rm(filename_cp)
end