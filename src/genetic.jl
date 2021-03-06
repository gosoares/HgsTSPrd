struct GeneticAlgorithm{V}
    data::Data{V}
    copied::Vector{Bool} # mark if each client was copied from parent1 to offspring
end

function GeneticAlgorithm(data::Data{V}) where {V}
    return GeneticAlgorithm{V}(data, Vector{Bool}(undef, V))
end

function run!(ga::GeneticAlgorithm{V}, localsearch::LocalSearch{V}, population::Population{V}) where {V}
    maxtime = time_ns() + ga.data.params.timelimit * 1000000000

    initialize!(population)

    notimproved = 0
    while notimproved < ga.data.params.itni && time_ns() < maxtime
        offspring = ordercrossover(ga, population)
        split!(localsearch.split, offspring, ga.data)

        educate!(localsearch, offspring)
        improved = addindividual!(population, offspring)

        if improved
            notimproved = 0
        else
            notimproved += 1
            (notimproved % ga.data.params.itdiv == 0) && diversify!(population)
        end
    end
    return nothing
end

function ordercrossover(ga::GeneticAlgorithm{V}, population::Population{V})::Individual{V} where {V}
    parent1, parent2 = selectparents(population)
    offspring = getemptyindividual(population)
    fill!(ga.copied, false)

    startpos = rand(ga.data.rng, 2:V)
    endpos = rand(ga.data.rng, 2:V)
    while startpos == endpos
        endpos = rand(ga.data.rng, 2:V)
    end

    pos = startpos
    while pos != endpos
        offspring[pos] = parent1[pos]
        ga.copied[offspring[pos]] = true
        pos += 1
        (pos > V) && (pos = 2)
    end

    j = 2
    if endpos < startpos
        for pos in endpos:(startpos - 1)
            while ga.copied[parent2[j]]
                j += 1
            end
            offspring[pos] = parent2[j]
            j += 1
        end
    else
        for pos in 2:(startpos - 1) # copy to elements before startpos
            while ga.copied[parent2[j]]
                j += 1
            end
            offspring[pos] = parent2[j]
            j += 1
        end

        for pos in endpos:V # copy to elements after endpos
            while ga.copied[parent2[j]]
                j += 1
            end
            offspring[pos] = parent2[j]
            j += 1
        end
    end

    return offspring
end
