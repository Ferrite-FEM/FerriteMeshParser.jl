# generate examples
import Literate

EXAMPLEDIR = joinpath(@__DIR__, "src", "literate")
GENERATEDDIR = joinpath(@__DIR__, "src", "examples")
mkpath(GENERATEDDIR)

# Copy supplementary files first
supplementary_fileextensions = [".inp", ".svg", ".png", ".jpg", ".gif"]
for example in readdir(EXAMPLEDIR)
    if any(endswith.(example, supplementary_fileextensions))
        cp(joinpath(EXAMPLEDIR, example), joinpath(GENERATEDDIR, example); force=true)
    end
end

for example in readdir(EXAMPLEDIR)
    if endswith(example, ".jl")
        input = abspath(joinpath(EXAMPLEDIR, example))
        script = Literate.script(input, GENERATEDDIR)
        code = strip(read(script, String))

        # remove "hidden" lines which are not shown in the markdown
        line_ending_symbol = occursin(code, "\r\n") ? "\r\n" : "\n"
        code_clean = join(filter(x->!endswith(x,"#hide"),split(code, r"\n|\r\n")), line_ending_symbol)

        mdpost(str) = replace(str, "@__CODE__" => code_clean)
        Literate.markdown(input, GENERATEDDIR, postprocess = mdpost)
        Literate.notebook(input, GENERATEDDIR, execute = is_ci) # Don't execute locally
    else
        if !any(endswith.(example, supplementary_fileextensions))
            @warn "ignoring $example"
        end
    end
end

# remove any .vtu files in the generated dir (should not be deployed)
cd(GENERATEDDIR) do
    foreach(file -> endswith(file, ".vtu") && rm(file), readdir())
    foreach(file -> endswith(file, ".pvd") && rm(file), readdir())
end
