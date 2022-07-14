module HGS_TSPRD

using ArgParse
using Random
using StaticArrays

include("data.jl")
include("individual.jl")
include("split.jl")
include("population.jl")
include("localsearch.jl")
include("genetic.jl")

function main(args::Vector{String})
    data = Data(args)
    genetic = GeneticAlgorithm(data)
    run!(genetic)

    exectime = (time_ns() - data.starttime) / 1000000
    println("Execution Time: $exectime ms")
    return nothing
end

end # module
