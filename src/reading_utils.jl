# Returns the next line without advancing in the buffer
#function peek_line(f)
#    mark(f)
#    line = strip(readline(f))
#    DEBUG_PARSE && println("Peeked: ", line)
#    reset(f)
#    return line
#end

# Returns the next line and advance in the buffer
function eat_line(f)
    line = strip(readline(f))
    DEBUG_PARSE && println("Ate: ", line)
    return line
end

# Returns a Vector{SubString{String}} with lines read until 
# stopsign encountered. Buffer at beginning of stopsign
function readlinesuntil(f; stopsign)
    # Split lines for both Windows and Linux line endings
    data = strip.(split(readuntil(f, stopsign; keep = false), r"\r\n|\n"))
    # Set buffer to the beginning of the stopsign
    seek(f, position(f) - length(stopsign))
    return data
end

# Read lines until a (stripped) line starts with stopsign. 
# Sets the buffer to the start of the identified line
function discardlinesuntil(io; stopsign)
    l = ""
    mark(io)
    while !startswith(strip(l), stopsign) && !eof(io)
        mark(io)
        l = readline(io)
    end
    reset(io)
end
