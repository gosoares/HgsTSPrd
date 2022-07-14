mutable struct Vertex
    id::Int

    durationbefore::Int  # sum of travel times of arcs after this client
    durationafter::Int   # sum of travel times of arcs before this client
    predecessors_rd::Int  # the bigger release date of clients before this
    successors_rd::Int    # the bigger release date of clients after this
end

Vertex(id::Int) = Vertex(id, 0, 0, 0, 0)

@inline releasedate(data::Data, v::Vertex) = releasedate(data, v.id)
@inline arctime(data::Data, v1::Vertex, v2::Vertex) = arctime(data, v1.id, v2.id)

@inline Base.getindex(vec::Vector{Int}, v::Vertex) = vec[v.id]
@inline Base.setindex!(vec::Vector{Int}, value::Int, index::Vertex) = (vec[index.id] = value)
@inline Base.setindex!(vec::Vector{Int}, value::Vertex, index::Int) = (vec[index] = value.id)
@inline Base.setindex!(vec::Vector{Int}, value::Vertex, index::Vertex) = (vec[index.id] = value.id)
