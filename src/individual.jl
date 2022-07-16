mutable struct Individual{V}
    eval::Int # completion time of last route
    gianttour::Vector{Int} # element at position 1 is a sentinel
    successors::Vector{Int}
    predecessors::Vector{Int}
    closest::Vector{Pair{Float64,Individual{V}}}
    biasedfitness::Float64
end

function RandomIndividual(data::Data{V}) where {V}
    gianttour = Int[i for i in 1:V]
    shuffle!(data.rng, view(gianttour, 2:V))
    closest = Pair{Float64,Individual{V}}[]
    sizehint!(closest, data.params.mu + data.params.lambda + 2)
    return Individual{V}(INF, gianttour, Vector{Int}(undef, V), Vector{Int}(undef, V), closest, Inf)
end

function EmptyIndividual(data::Data{V}) where {V}
    closest = Pair{Float64,Individual{V}}[]
    sizehint!(closest, data.params.mu + data.params.lambda + 2)
    return Individual{V}(INF, Vector{Int}(undef, V), Vector{Int}(undef, V), Vector{Int}(undef, V), closest, Inf)
end

mutable struct NCloseMean # just a auxiliar struct to calculate the dc rank of the individuals
    rankfit::Int
    nclosemean::Float64
end

# order by increasing nclosemean
Base.isless(a::NCloseMean, b::NCloseMean) = a.nclosemean > b.nclosemean

"""
    insertclosest!(indiv1, indiv2)

Insert `indiv1` in the closest list of `indiv2` and vice versa.
"""
function insertclosest!(indiv1::Individual{V}, indiv2::Individual{V}) where {V}
    dist = distance(indiv1, indiv2)
    insertclosest!(indiv1, indiv2, dist)
    insertclosest!(indiv2, indiv1, dist)
    return nothing
end

"""
    insertclosest!(individual, cl, dist)

Insert the individual `cl` into the closest list of `indiv` with a distance of `dist`.
"""
function insertclosest!(indiv::Individual{V}, cl::Individual{V}, dist::Float64) where {V}
    el = dist => cl
    pos::Int = searchsortedlast(indiv.closest, el; by = e -> e[1])
    insert!(indiv.closest, pos + 1, el)
    return nothing
end

function removefromclosest!(indiv::Individual{V}, cl::Individual{V}) where {V}
    pos::Int = findfirst(e -> e[2] == cl, indiv.closest)
    popat!(indiv.closest, pos)
    return nothing
end

"""
    nclosemean(indiv, nclose)

Calculate the average distance of the `nclose` closest individuals to `indiv`.
"""
function nclosemean(indiv::Individual{V}, nclose::Int)::Float64 where {V}
    return sum(indiv.closest[i][1] for i in 1:nclose) / nclose
end

"""
    distance(indiv1, indiv2)

Calculate the distance between `indiv1` and `indiv2`, with the formula:

``\\delta(I_1, I_2) = 1 - \\frac{|A(I_1) \\cap A(I_2)|}{|A(I_1) \\cup A(I_2)|}``

where `A(I)` is the set of arcs of the solution given by `I`.
"""
function distance(indiv1::Individual{V}, indiv2::Individual{V}) where {V}
    I = 0  # number of arcs that exists in both solutions
    U = 0  # number of arcs in Arcs(s1) U Arcs(s2)

    # check successor of all vertices includind the depot
    for i in 1:V
        if indiv1.successors[i] == indiv2.successors[i]
            I += 1
            U += 1
        else
            U += 2
        end
    end

    # check for other arcs involving depot
    for i in 2:V
        depotpred1 = indiv1.predecessors[i] == 1
        depotpred2 = indiv2.predecessors[i] == 1
        if depotpred1 && depotpred2
            I += 1
            U += 1
        elseif depotpred1 || depotpred2
            U += 1
        end
    end

    return 1.0 - I / U
end

@inline Base.getindex(indiv::Individual, idx::Integer) = indiv.gianttour[idx]
@inline Base.setindex!(indiv::Individual, value::Int, pos::Integer) = (indiv.gianttour[pos] = value)

@inline Base.iterate(indiv::Individual) = (indiv[2], 3)
@inline Base.iterate(indiv::Individual, state) = iterate(indiv.gianttour, state)
