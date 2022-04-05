using FerriteMeshParser
using Ferrite
using Test


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
        filename = joinpath(@__DIR__, "test_files", base_name*".inp")
        grid = get_ferrite_grid(filename)
        dh = MixedDofHandler(grid)
        unique_celltypes = unique(typeof.(grid.cells))
        
        fields = [Field(:u, Ferrite.default_interpolation(type), 1) for type in unique_celltypes]
        cellsets = [findall(x->isa(x,type), grid.cells) for type in unique_celltypes]
        fieldhandlers = [FieldHandler([field], Set(set)) for (field,set) in zip(fields, cellsets)]
        push!.((dh,), fieldhandlers)
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

@testset "facesetgeneration" begin
    filename = joinpath(@__DIR__, "test_files", "compact_tension.inp")
    grid = get_ferrite_grid(filename)
    @test create_faceset(grid, getnodeset(grid, "Hole")) == create_faceset(grid, getnodeset(grid, "Hole"), getcellset(grid, "Hole"))    # Test that including cells doesn't change the created sets
end

@testset "exceptions" begin
    filename = joinpath(@__DIR__, "runtests.jl")
    @test_throws FerriteMeshParser.UndetectableMeshFormatError get_ferrite_grid(filename) 

    filename = joinpath(@__DIR__, "test_files", "twoinstances.inp")
    @test_throws FerriteMeshParser.InvalidFileContent get_ferrite_grid(filename) 

    filename = joinpath(@__DIR__, "test_files", "unsupported_element.inp")
    @test_throws FerriteMeshParser.UnsupportedElementType get_ferrite_grid(filename) 

end

@testset "ordering" begin
    filename0 = joinpath(@__DIR__, "test_files", "2D_UnitArea_Linear.inp")
    grid0 = get_ferrite_grid(filename0)

    filename1 = joinpath(@__DIR__, "test_files", "2D_UnitArea_Linear_flipelementorder.inp")
    grid1 = get_ferrite_grid(filename1)

    filename2 = joinpath(@__DIR__, "test_files", "2D_UnitArea_Linear_perturbnodeorder.inp")
    grid2 = get_ferrite_grid(filename2)

    # comparing grid0==grid<i> doesn't work, so check each field:
    for key in fieldnames(typeof(grid0))
        @test getfield(grid0, key) == getfield(grid1, key)
        @test getfield(grid0, key) == getfield(grid2, key)
    end
end

@testset "caseinsensitive" begin
    filename = joinpath(@__DIR__, "test_files", "uppercase_test.inp")
    grid = get_ferrite_grid(filename)
    @test getncells(grid) == 2
    @test getnnodes(grid) == 6
end
    
