using Ferrite, FerriteMeshParser, Tensors

function material_stiffness(E=210.e3, ν=0.3)
    G = E / 2(1 + ν)
    K = E / 3(1 - 2ν)
    I2 = one(SymmetricTensor{2,3})
    I4vol = I2⊗I2
    I4dev = otimesu(I2,I2) - I4vol / 3
    stiff_3d = 2G*I4dev + K*I4vol
    return SymmetricTensor{4,2}((i,j,k,l)->stiff_3d[i,j,k,l])
end

function doassemble!(cv, K, dh)
    first_cellid = Dict(key => first(getcellset(dh.grid, key)) for key in keys(cv))
    ndpc = Dict(key => ndofs_per_cell(dh, first_cellid[key]) for key in keys(cv))
    Ke = Dict(key => zeros(n,n) for (key,n) in ndpc)

    f = zeros(ndofs(dh))
    assembler = start_assemble(K, f)

    for key in keys(cv)
        for cell in CellIterator(dh, collect(getcellset(dh.grid, key)))
            assemble_cell!(assembler, cell, cv[key], Ke[key])
        end
    end
end

function assemble_cell!(assembler, cell, cv, Ke)
    reinit!(cv, cell)
    n_basefuncs = getnbasefunctions(cv)
    fill!(Ke, 0)
    for q_point in 1:getnquadpoints(cv)
        dσdϵ = material_stiffness()
        dΩ = getdetJdV(cv, q_point)
        for i in 1:n_basefuncs
            δ∇N = shape_symmetric_gradient(cv, q_point, i)
            for j in 1:n_basefuncs
                ∇N = shape_symmetric_gradient(cv, q_point, j)
                Ke[i, j] += δ∇N ⊡ dσdϵ ⊡ ∇N * dΩ
            end
        end
    end
    assemble!(assembler, celldofs(cell), Ke)
end

function solve()
    # Import grid from abaqus mesh
    grid = get_ferrite_grid(joinpath(@__DIR__, "compact_tension.inp"))

    # Setup the interpolation and integration for each field
    dim=Ferrite.getdim(grid)
    grid_keys = ["CPS4R", "CPS3"]
    qr = Dict("CPS4R"=>QuadratureRule{dim, RefCube}(2), "CPS3"=>QuadratureRule{dim, RefTetrahedron}(1))
    ip = Dict("CPS4R"=>Lagrange{dim, RefCube, 1}(), "CPS3"=>Lagrange{dim, RefTetrahedron, 1}())
    cv = Dict(key=>CellVectorValues(qr[key], ip[key]) for key in keys(ip))

    # Setup the MixedDofHandler
    fields = Dict(key=>Field(:u, ip[key], dim) for key in keys(ip))
    dh = MixedDofHandler(grid)
    for key in grid_keys # Use grid_keys to ensure correct order
        push!(dh, FieldHandler([fields[key]], getcellset(grid, key)))
    end
    close!(dh)

    # Add boundary conditions
    ch = ConstraintHandler(dh);
    bc_sym = Dirichlet(:u, getfaceset(grid, "Symmetry"), (x, t) -> 0, 1)
    bc_hole = Dirichlet(:u, getfaceset(grid, "Hole"), (x, t) -> Vec{2}((-t, 0.0)), [1,2])

    # Happens to be only quad elements on constrainted surfaces. How to do this more generally?
    add!(ch, dh.fieldhandlers[1], bc_sym)
    add!(ch, dh.fieldhandlers[1], bc_hole)
    close!(ch)

    # Assemble stiffness matrix
    K = create_sparsity_pattern(dh);
    doassemble!(cv, K, dh)

    # Solve linear equation system
    f = zeros(ndofs(dh))
    update!(ch, 1.0)
    apply!(K, f, ch)
    u = K\f

    # Save displacement field
    vtk_grid(joinpath(@__DIR__, "mixed_dof_handler"), dh) do vtk
        vtk_point_data(vtk, dh, u)
    end
end

solve()

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

