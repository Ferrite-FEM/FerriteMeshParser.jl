isabaquskeyword(l) = startswith(l, "*")

struct AbaqusInpBlock
    keyword::String
    parameters::LittleDict{String}
    data::Vector{Vector}
end

struct AbaqusInp
    blocks::Vector{AbaqusInpBlock}
end

inpblocks(inp::AbaqusInp) = inp.blocks
keyword(datablock::AbaqusInpBlock) = datablock.keyword
datalines(datablock::AbaqusInpBlock) = datablock.data
parameters(datablock::AbaqusInpBlock) = datablock.parameters

function parse_abaqus(s)
    parsed = tryparse(Int, s)
    !isnothing(parsed) && return parsed
    parsed = tryparse(Float64, s)
    !isnothing(parsed) && return parsed
    startswith(s, '"') && endswith(s, '"') && return s[2:end-1]
    return s
end

# skips comment lines and supports line continuation
# removes leading and trailing whitespace
function eatline_abaqus(f)
    line = readline(f)
    while startswith(line, "**")
        line = strip(readline(f))
        isodd(count('"', line)) && throw(InvalidFileContent("Quoted strings cannot span multiple lines!"))
    end
    while endswith(line, ",")
        eof(f) && throw(InvalidFileContent("Reached end of file on line continuation!"))
        next = strip(readline(f))
        isodd(count('"', line)) && throw(InvalidFileContent("Quoted strings cannot span multiple lines!"))
        startswith(next, "**") && continue
        startswith(next, '*') && throw(InvalidFileContent("Ran into new keyword during line continuation"))
        line *= next
    end
    DEBUG_PARSE && println("Ate: " * line)
    return line
end

# removes whitespace, splits at comma, and uppercases everything
# while reserving quoted strings
function clean_and_split(line)
    quoted_split = split(line, '"') # even indices -> quoted; odd inices not quoted
    sections = String[""]
    for (i, s) in pairs(quoted_split)
        if isodd(i)
            s = replace(s, " " => "")
            s = uppercase(s)
            s_split = split(s, ',', keepempty=true)
            sections[end] *= first(s_split)
            append!(sections, s_split[2:end])
        else
            sections[end] *= '"' * s * '"'
        end
    end
    return sections
end

function parsekeywordline(line)
    sections = clean_and_split(line)
    parameters = LittleDict{String, Any}()
    for parameter in sections[2:end]
        if contains(parameter, '=')
            (key, value) = split(parameter, '=')
            parameters[key] = parse_abaqus(value)
        else
            parameters[parameter] = nothing
        end
    end
    return AbaqusInpBlock(sections[1], parameters, Vector[])
end

function parsedataline(line)
    sections = clean_and_split(line)
    return parse_abaqus.(sections)
end

function parse_abaqus_inp(filename)
    keywords = AbaqusInpBlock[]
    open(filename) do f
        while !eof(f)
            line = eatline_abaqus(f)
            line == "" && continue
            if isabaquskeyword(line)
                push!(keywords, parsekeywordline(line))
            else
                isempty(keywords) && throw(InvalidFileContent("The first non-comment line must be a keyword line!"))
                push!(keywords[end].data, parsedataline(line))
            end
        end
    end
    return AbaqusInp(keywords)
end

function read_abaqus_nodes!(inpblock::AbaqusInpBlock, node_numbers, coord_vec)
    for dataline in datalines(inpblock)
        push!(node_numbers, dataline[1])
        append!(coord_vec, dataline[2:end])
    end
    return length(datalines(inpblock)[1]) - 1
end

function read_abaqus_elements!(inpblock::AbaqusInpBlock, topology_vectors, element_number_vectors, element_sets)
    topology_vec = get!(topology_vectors, parameters(inpblock)["TYPE"], Int[])
    element_numbers = get!(element_number_vectors, parameters(inpblock)["TYPE"], Int[])
    element_numers_new = Int[]
    for dataline in datalines(inpblock)
        push!(element_numers_new, dataline[1])
        append!(topology_vec, dataline[2:end])
    end
    append!(element_numbers, element_numers_new)
    elset = get(parameters(inpblock), "ELSET", nothing)
    if !isnothing(elset)
        element_sets[elset] = element_numers_new
    end
end

function read_abaqus_set!(inpblock::AbaqusInpBlock, sets)
    if haskey(parameters(inpblock), "GENERATE")
        start, stop, step = only(datalines(inpblock))
        indices = collect(start:step:stop)
    else
        indices = reduce(vcat, datalines(inpblock))
    end
    setname = parameters(inpblock)[keyword(inpblock)[2:end]]
    sets[setname] = indices
end

function read_mesh(filename, ::AbaqusMeshFormat)
    dim = 0
    node_numbers = Int[]
    coord_vec = Float64[]

    topology_vectors = Dict{String, Vector{Int}}()
    element_number_vectors = Dict{String, Vector{Int}}()

    nodesets = Dict{String, Vector{Int}}()
    elementsets = Dict{String, Vector{Int}}()
    part_counter = 0
    instance_counter = 0

    inp = parse_abaqus_inp(filename)

    for inpblock in inpblocks(inp)
        if keyword(inpblock) == "*NODE"
            DEBUG_PARSE && println("Reading nodes")
            read_dim = read_abaqus_nodes!(inpblock, node_numbers, coord_vec)
            dim == 0 && (dim = read_dim)  # Set dim if not yet set
            read_dim != dim && throw(DimensionMismatch("Not allowed to mix nodes in different dimensions"))
        elseif keyword(inpblock) == "*ELEMENT"
            DEBUG_PARSE && println("Reading elements")
            read_abaqus_elements!(inpblock, topology_vectors, element_number_vectors, elementsets)
        elseif keyword(inpblock) == "*ELSET"
            DEBUG_PARSE && println("Reading elementset")
            read_abaqus_set!(inpblock, elementsets)
        elseif keyword(inpblock) == "*NSET"
            DEBUG_PARSE && println("Reading nodeset")
            read_abaqus_set!(inpblock, nodesets)
        elseif keyword(inpblock) == "*PART"
            DEBUG_PARSE && println("Increment part counter")
            part_counter += 1
        elseif keyword(inpblock) == "*INSTANCE"
            DEBUG_PARSE && println("Increment instance counter")
            instance_counter += 1
        end
    end

    if part_counter > 1 || instance_counter > 1
        msg = "Multiple parts or instances are not supported\n"
        msg *= "Tip: If you want a single grid, merge parts and differentiated by Abaqus sets\n"
        msg *= "     If you want multiple grids, split into multiple input files"
        throw(InvalidFileContent(msg))
    end
    
    elements = Dict{String, RawElements}()
    for element_type in keys(topology_vectors)
        topology_vec = topology_vectors[element_type]
        element_numbers = element_number_vectors[element_type]
        n_elements = length(element_numbers)
        topology_matrix = reshape(topology_vec, :, n_elements)
        elements[element_type] = RawElements(numbers=element_numbers, topology=topology_matrix)
    end
    nodes = RawNodes(numbers=node_numbers, coordinates=reshape(coord_vec, dim, :))
    return RawMesh(elements=elements, nodes=nodes, nodesets=nodesets, elementsets=elementsets)
end