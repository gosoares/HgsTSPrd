module HGS_TSPRD

using ArgParse
using Random
using StaticArrays

include("data.jl")
include("individual.jl")
include("split.jl")

function main()
    data = Data(ARGS)
    split = Split(data)

    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end # module
