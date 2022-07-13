mutable struct Individual{V}
    eval::Int # completion time of last route
    giantTour::MVector{V,Int}
    successors::MVector{V,Int}
    predecessors::MVector{V,Int}
    closest::Vector{Pair{Float64,Individual}}
    biasedFitness::Float64
end
~
function RandomIndividual(data::Data{V}) where {V}
    giantTour = StaticArrays.sacollect(MVector{V,Int}, i for i in 1:V)
    shuffle!(data.rng, giantTour)

    return Individual{V}(INF, giantTour, MVector{V,Int}(undef), MVector{V,Int}(undef), Pair{Float64,Individual}[], Inf)
end

function EmptyIndividual(::Data{V}) where {V}
    return Individual(
        INF, MVector{V,Int}(undef), MVector{V,Int}(undef), MVector{V,Int}(undef), Pair{Float64,Individual}(), Inf
    )
end

@inline Base.getindex(indiv::Individual, idx::Integer) = indiv.giantTour[idx]
