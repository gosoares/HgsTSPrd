module HgsTSPrd

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
    warmup(data)
    starttime = time_ns()

    ga = GeneticAlgorithm(data)
    run!(ga)

    exectime = (time_ns() - starttime) / 1000000
    bestsoltime = (ga.population.searchprogress[end][1] - starttime) / 1000000
    println()
    println("Execution Time : $exectime ms")
    println("Solution Time  : $bestsoltime ms")
    println("Obj            : $(ga.population.bestsolution.eval)")
    println("Seed           : $(data.params.seed)")

    return nothing
end

function warmup(data::Data)
    ga = GeneticAlgorithm(data; itni = data.params.itni ÷ 10)
    run!(ga)
    return nothing
end

export Data, GeneticAlgorithm
export main, run!

end # module
