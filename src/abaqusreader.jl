isabaquskeyword(l) = startswith(l, "*")

struct AbaqusKeyword
    keyword::String
    parameters::Vector
    data::Vector{Vector}
end

function parse_abaqus(s)
    parsed = tryparse(Int, s)
    !isnothing(parsed) && return parsed
    parsed = tryparse(Float64, s)
    !isnothing(parsed) && return parsed
    startswith(s, '"') && endswith(s, '"') && return s[2:end-1]
    return s
end

function skipcomments(f)
    while true
        mark(f)
        startswith(readline(f), "**") || break
    end
    reset(f)
end

# skips comment lines and supports continuation
# removes whitespace splits at comma and capitalizes everything not in quotes
# parses sections to Ints or Floats where possible
function readline_abaqus(f)
    line = readline(f)
    while startswith(line, "**")
        line = strip(readline(f))
    end
    while endswith(line, ",")
        eof(f) && throw(InvalidFileContent("Reached end of file on line continuation"))
        next = strip(readline(f))
        startswith(next, "**") && continue
        line *= next
    end
    quoted_split = split(line, '"') # even indices -> quoted; odd inices not quoted
    sections = String[""]
    for (i, s) in pairs(quoted_split)
        if isodd(i)
            s = replace(s, " " => "")
            s = uppercase(s)
            s_split = split(s, ',')
            sections[end] *= first(s_split)
            append!(sections, s_split[2:end])
        else
            sections[end] *= s
        end
    end
    sections_parsed = Vector(undef, length(sections))
    for (i, s) in pairs(sections)
        parsed = parse_abaqus(s)
        if parsed != s || !contains(s, '=')
            sections_parsed[i] = parsed
        else contains(s, '=')
            s_split = split(s, '=', limit=2)
            sections_parsed[i] = first(s_split) => parse_abaqus(last(s_split))
        end
    end
    # skip over comments after reading the line
    # to make eof work as expected
    skipcomments(f)
    return sections_parsed
end

function read_keywords(filename)
    keywords = AbaqusKeyword[]

    open(filename) do f
        skipcomments(f)
        while !eof(f)
            if peek(f, Char) == '*' 
                line = readline_abaqus(f)
                keyword = AbaqusKeyword(line[1], line[2:end], Vector[])
                push!(keywords, keyword)
            else
                line = readline_abaqus(f)
                push!(keywords[end].data, line)
            end
        end
    end

    return keywords
end

function join_multiline_elementdata(element_data::Vector{<:AbstractString})
    fixed_element_data = copy(element_data)
    i = 0
    i_fixed = 0
    nrows = length(element_data)
    while i < nrows
        i += 1
        length(element_data[i])==0 && continue
        i_fixed += 1
        fixed_element_data[i_fixed] = element_data[i]
        while endswith(fixed_element_data[i_fixed], ',') && i < nrows
            i += 1
            fixed_element_data[i_fixed] = fixed_element_data[i_fixed]*element_data[i]
        end
    end
    return fixed_element_data[1:i_fixed]
end

function read_abaqus_nodes!(f, node_numbers::Vector{Int}, coord_vec::Vector{Float64})
    local coords
    node_data = readlinesuntil(f; stopsign='*')
    for nodeline in node_data
        node = split(nodeline, ',', keepempty = false)
        length(node) == 0 && continue
        push!(node_numbers, parse(Int, node[1]))
        coords = parse.(Float64, node[2:end])
        append!(coord_vec, coords)
    end
    return length(coords)
end

function read_abaqus_elements!(f, topology_vectors, element_number_vectors, element_type::AbstractString, element_set="", element_sets=nothing)
    if !haskey(topology_vectors, element_type)
        topology_vectors[element_type] = Int[]
        element_number_vectors[element_type] = Int[]
    end
    topology_vec = topology_vectors[element_type]
    element_numbers = element_number_vectors[element_type]
    element_numbers_new = Int[]
    element_data_raw = readlinesuntil(f; stopsign='*')
    element_data = join_multiline_elementdata(element_data_raw)
    for elementline in element_data
        element = split(elementline, ',', keepempty = false)
        length(element) == 0 && continue
        n = parse(Int, element[1])
        push!(element_numbers_new, n)
        vertices = [parse(Int, element[i]) for i in 2:length(element)]
        append!(topology_vec, vertices)
    end
    append!(element_numbers, element_numbers_new)
    if element_set != ""
        element_sets[element_set] = copy(element_numbers_new)
    end
end

function read_abaqus_set!(f, sets, setname::AbstractString)
    if endswith(setname, "generate")
        split_line = split(strip(eat_line(f)), ",", keepempty = false)
        start, stop, step = [parse(Int, x) for x in split_line]
        indices = collect(start:step:stop)
        setname = split(setname, [','])[1]
    else
        data = readlinesuntil(f; stopsign='*')
        indices = Int[]
        for line in data
            indices_str = split(line, ',', keepempty = false)
            for v in indices_str
                push!(indices, parse(Int, v))
            end
        end
    end
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

    open(filename) do f
        while !eof(f)
            header = eat_line(f)
            if header == ""
                continue
            end
            DEBUG_PARSE && println("H: $header")
            if startswith(lowercase(header), "*node")
                DEBUG_PARSE && println("Reading nodes")
                read_dim = read_abaqus_nodes!(f, node_numbers, coord_vec)
                dim == 0 && (dim = read_dim)  # Set dim if not yet set
                read_dim != dim && throw(DimensionMismatch("Not allowed to mix nodes in different dimensions"))
            elseif startswith(lowercase(header), "*element")
                if ((m = match(r"\*Element, type=(.*), ELSET=(.*)"i, header)) !== nothing)
                    DEBUG_PARSE && println("Reading elements with elset")
                    read_abaqus_elements!(f, topology_vectors, element_number_vectors,  m.captures[1], m.captures[2], elementsets)
                elseif ((m = match(r"\*Element, type=(.*)"i, header)) !== nothing)
                    DEBUG_PARSE && println("Reading elements without elset")
                    read_abaqus_elements!(f, topology_vectors, element_number_vectors,  m.captures[1])
                end
            elseif ((m = match(r"\*Elset, elset=(.*)"i, header)) !== nothing)
                DEBUG_PARSE && println("Reading elementset")
                read_abaqus_set!(f, elementsets, m.captures[1])
            elseif ((m = match(r"\*Nset, nset=(.*)"i, header)) !== nothing)
                DEBUG_PARSE && println("Reading nodeset")
                read_abaqus_set!(f, nodesets, m.captures[1])
            elseif startswith(lowercase(header), "*part")
                DEBUG_PARSE && println("Increment part counter")
                part_counter += 1
            elseif startswith(lowercase(header), "*instance")
                DEBUG_PARSE && println("Increment instance counter")
                instance_counter += 1
                discardlinesuntil(f, stopsign='*')  # Instances contain translations, or start with *Node if independent mesh
            elseif isabaquskeyword(header)          # Ignore unused keywords
                DEBUG_PARSE && println("Discarding keyword content")
                discardlinesuntil(f, stopsign='*')
            else
                eof(f) && break # discardlinesuntil will stop at eof, and last line read again and incorrectly considered a "header"
                throw(InvalidFileContent("Unknown header, \"$header\", in file \"$filename\". Could also indicate an incomplete file"))
            end
        end

        if part_counter > 1 || instance_counter > 1
            msg = "Multiple parts or instances are not supported\n"
            msg *= "Tip: If you want a single grid, merge parts and differentiated by Abaqus sets\n"
            msg *= "     If you want multiple grids, split into multiple input files"
            throw(InvalidFileContent(msg))
        end
    end
    
    elements = Dict{String, RawElements}()
    for element_type in keys(topology_vectors)
        topology_vec = topology_vectors[element_type]
        element_numbers = element_number_vectors[element_type]
        n_elements = length(element_numbers)
        topology_matrix = reshape(topology_vec, length(topology_vec) ÷ n_elements, n_elements)
        elements[element_type] = RawElements(numbers=element_numbers, topology=topology_matrix)
    end
    nodes = RawNodes(numbers=node_numbers, coordinates=reshape(coord_vec, dim, length(coord_vec) ÷ dim))
    return RawMesh(elements=elements, nodes=nodes, nodesets=nodesets, elementsets=elementsets)
end