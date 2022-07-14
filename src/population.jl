mutable struct Population
    data::Data
    split::Split

    individuals::Vector{Individual}
    bestsolution::Individual

    searchprogress::Vector{Pair{Int,Int}}
end

function Population(data::Data, split::Split)
    individuals = Individual[]
    sizehint!(individuals, data.params.mu + data.params.lambda + 1)

    return Population(data, split, individuals, EmptyIndividual(data), Pair{Int,Int}[])
end

"""
    initialize!(pop)

Initialize the population with `2*mu` random individuals.
"""
function initialize!(pop::Population)
    for _ in 1:(2 * pop.data.params.mu)
        indiv = RandomIndividual(pop.data)
        split!(pop.split, indiv)
        addindividual!(pop, indiv)
    end
    return pop
end

"""
    addindividual(pop, indiv)

Add a individual to the population, and return whether this individual is the best so far.
"""
function addindividual!(pop::Population, indiv::Individual)
    for indiv2 in pop.individuals
        insertclosest!(indiv, indiv2)
    end

    # Find the position for the individual such that the population is ordered
    # in respect to the solution eval
    pos = searchsortedlast(pop.individuals, indiv; by = idv -> idv.eval, rev = true)
    insert!(pop.individuals, pos + 1, indiv)

    # Update the best solution
    if indiv.eval < pop.bestsolution.eval
        pop.bestsolution = indiv
        push!(pop.searchprogress, (elapsedtime(pop.data) => indiv.eval))
        return true
    end

    return false
end

"""
    survival(pop, n_survivors = pop.data.params.mu)

Eliminate the worst individuals in the population,
until the population size is `n_survivors`.
"""
function survival!(pop::Population, n_survivors::Int = pop.data.params.mu)
    while length(pop.individuals) > n_survivors
        removeworst!(pop)
    end

    pop.individuals = pop.individuals[1:(pop.data.params.mu)]
    return pop
end

"""
    removeworst!(pop)

Remove worst individual from the population with respect to the biased fitness,
and giving priority to clone individuals.
"""
function removeworst!(pop::Population)
    updatebiasedfitness!(pop)

    worstpos = -1
    worstisclone = false
    worstfit = -1.0

    for (i, indiv) in enumerate(pop.individuals)
        isclone = indiv.closest[begin][1] < 0.0001
        if (isclone && !worstisclone) || (isclone == worstisclone && indiv.biasedfitness > worstfit)
            worstisclone = isclone
            worstpos = i
            worstfit = indiv.biasedfitness
        end
    end

    worstindiv = popat!(pop.individuals, worstpos)

    for indiv in pop.individuals
        removefromclosest!(indiv, worstindiv)
    end

    return nothing
end

"""
    updatebiasedfitness!(pop)

Update biased fitness of all individuals in the population.
The biased fitness is calculated with the equation:

``BF(P) = fit(I) + \\left( 1 - \\frac{nbElite}{nbIndiv} \\right)dc(I)``

Where `fit(I)` and `dc(I)` are the rank of the individual w.r.t the fitness and the contribution 
of the individual to the diversity of the population.
`nbIndiv` is the current number of individuals in the population and `nbElite` is a parameter controlling
the minimum number of best individuals w.r.t. the fitness that should be kept in the population.

"""
function updatebiasedfitness!(pop::Population)
    # since the population is sorted by the eval, the position of a
    # individual in the population is the rank of the fitness for that individual
    # now we calculate the rank of the diversity using the nCloseMean
    rank = [-nclosemean(indiv, pop.data.params.nclose) => rankfit for (rankfit, indiv) in enumerate(pop.individuals)]
    sort!(rank)

    for (rankdc, (_, rankfit)) in enumerate(rank)
        pop.individuals[rankfit].biasedfitness =
            rankfit + (1.0 - pop.data.params.nbelite / length(pop.individuals)) * rankdc
    end

    return pop
end

function selectparents(pop::Population)
    updatebiasedfitness!(pop)

    first = binarytournament(pop)
    second = binarytournament(pop)
    while first == second
        second = binarytournament(pop)
    end

    return first, second
end

function binarytournament(pop::Population)
    first = rand(pop.data.rng, pop.individuals)
    second = rand(pop.data.rng, pop.individuals)
    return first.biasedfitness < second.biasedfitness ? first : second
end

"""
    diversify!(pop)

Remove all but the best `mu/3` individuals from the population and generate
`2*mu` new individuals randomly.
"""
function diversify!(pop::Population)
    survival(pop, pop.data.params.mu / 3)
    return initialize!(pop)
end
