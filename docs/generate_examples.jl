using Literate

## ! Config
example_files = joinpath(@__DIR__, "..", "examples") |> x -> readdir(x; join = true)
output_dir = joinpath(@__DIR__, "src", "examples")

# Run the production loop
filter!(endswith(".jl"), example_files)
for fn in example_files
    Literate.markdown(fn, output_dir; execute = true)
end

# TODO: change meta fields at the top of each file!
