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

    savetofile!(data, ga, starttime; print = false)

    return nothing
end

function warmup(data::Data)
    ga = GeneticAlgorithm(data; itni = data.params.itni ÷ 10)
    run!(ga)
    return nothing
end

function savetofile!(data::Data, ga::GeneticAlgorithm, starttime::Integer; print::Bool = false)
    exectime = floor(Int, (time_ns() - starttime) / 1000000)
    bestsoltime = floor(Int, (ga.population.searchprogress[end][1] - starttime) / 1000000)

    mkpath(rsplit(data.outputfile, '/'; limit = 2)[1])
    open(data.outputfile, "w") do f
        write(f, "EXEC_TIME $exectime\n")
        write(f, "SOL_TIME $bestsoltime\n")
        write(f, "OBJ $(ga.population.bestsolution.eval)\n")
        write(f, "SEED $(data.params.seed)\n")
    end

    if print
        println("Execution Time : $exectime ms")
        println("Solution Time  : $bestsoltime ms")
        println("Obj            : $(ga.population.bestsolution.eval)")
        println("Seed           : $(data.params.seed)")
    end
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
