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
    ga = GeneticAlgorithm(data)
    return execute!(ga, data.outputfile)
end

function execute!(ga::GeneticAlgorithm, outputfile::String = "")
    split = Split(ga.data)
    population = Population(ga.data, split)
    localsearch = LocalSearch(ga.data, split)

    starttime = time_ns()
    run!(ga, localsearch, population)
    exectime = time_ns() - starttime

    savetofile!(outputfile, ga.data, population, starttime, exectime)
    return nothing
end

function savetofile!(
    outputfile::String, data::Data{V}, pop::Population{V}, starttime::Integer, exectime::Integer
) where {V}
    exectime = floor(Int, exectime / 1000000)
    bestsoltime = floor(Int, (pop.searchprogress[end][1] - starttime) / 1000000)
    bestsoleval = besttime(pop)

    if !isempty(outputfile)
        mkpath(rsplit(outputfile, '/'; limit = 2)[1])
        open(outputfile, "w") do f
            write(f, "EXEC_TIME $exectime\n")
            write(f, "SOL_TIME $bestsoltime\n")
            write(f, "OBJ $bestsoleval\n")
            write(f, "SEED $(data.params.seed)\n")
        end
    end

    @info "Execution Time : $exectime ms"
    @info "Solution Time  : $bestsoltime ms"
    @info "Obj            : $bestsoleval"
    @info "Seed           : $(data.params.seed)"

    return nothing
end

export main, execute!, savetofile!
export Data
export GeneticAlgorithm, run!, ordercrossover
export Split, split!
export Population,
    Individual,
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
