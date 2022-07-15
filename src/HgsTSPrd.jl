module HgsTSPrd

using Printf, Random

include("data.jl")
include("individual.jl")
include("split.jl")
include("population.jl")
include("localsearch/vertex.jl")
include("localsearch/route.jl")
include("localsearch/localsearch.jl")
include("localsearch/intrasearches.jl")
include("localsearch/intersearches.jl")
include("genetic.jl")

function main(args::Vector{String})
    data = Data(args)
    warmup(data)
    starttime = time_ns()

    ga = GeneticAlgorithm(data)
    run!(ga)

    exectime = floor(Int, (time_ns() - starttime) / 1000000)
    bestsoltime = floor(Int, (ga.population.searchprogress[end][1] - starttime) / 1000000)
    println()
    println("Execution Time : $exectime ms")
    println("Solution Time  : $bestsoltime ms")
    println("Obj            : $(ga.population.bestsolution.eval)")
    println("Seed           : $(data.params.seed)")

    # println()
    # individual = RandomIndividual(data)
    # split = Split(data)
    # split!(split, individual)

    # @show individual.gianttour
    # @show individual.successors
    # @show individual.predecessors

    # ls = LocalSearch(data, split)
    # loadindividual!(ls, individual)
    # saveindividual!(ls, individual)
    # println()

    # @show individual.gianttour
    # @show individual.successors
    # @show individual.predecessors

    return nothing
end

function warmup(data::Data)
    ga = GeneticAlgorithm(data; itni = data.params.itni ÷ 10)
    run!(ga)
    return nothing
end

export main, warmup
export Data
export GeneticAlgorithm, run!, ordercrossover
export Split, split!
export Population,
    Individual,
    EmptyIndividual,
    RandomIndividual,
    initialize!,
    addindividual!,
    survival!,
    removeworst!,
    updatebiasedfitness!,
    selectparents,
    binarytournament,
    diversify!
export LocalSearch,
    Route,
    Vertex,
    educate!,
    splitsearch!,
    addroute!,
    updateroutesdata!,
    loadindividual!,
    saveindividual!,
    savegianttour!,
    printroutes,
    intrasearch!,
    intersearch!

end # module
