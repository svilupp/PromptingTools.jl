using Literate

## ! Config
example_files = joinpath(@__DIR__, "..", "examples") |> x -> readdir(x; join = true)
output_dir = joinpath(@__DIR__, "src", "examples")

# Run the production loop
for fn in example_files
    Literate.markdown(fn, output_dir; execute = true)
end