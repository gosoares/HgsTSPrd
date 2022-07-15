"""
    Route

A struct that represents a route in the solution

# Attributes
    - pos: The position of the route in the solution
    - clients: The clients in the route plus a vertex representing the depot at the beggining and at the end
    - source: A vertex representing the depot at the beggining of the route
    - sink: A vertex representing the depot at the end of the route
    - releasedate: The release date of the route, that it the maximum release date between the clients in the route
    - starttime: The start time of the route
    - duration: The duration of the route
    - endtime: The end time of the route
    - endprevious: The end time of the previous route
    - newreleasedate: The evaluated release date of the route after a move
    - newduration: The evaluated duration of the route after a move
    - clearance: How much clearance this route have in relation to each route after it.
c = clearance[j] > 0 means that this route can increase its and time by at most c
    without affecting the start time of route r. After that, it will increase the starting
    time of route j by the difference between the time increase and c
c = clearance[j] < 0 means that this route is coupled with the route j (there's no waiting time
    between theses routes), decreasing the endtime of this route will decrease the starting time of
    route j by the max of the decrease and c
"""
mutable struct Route
    pos::Int

    clients::Vector{Vertex}
    source::Vertex
    sink::Vertex

    releasedate::Int
    starttime::Int
    duration::Int
    endtime::Int
    endprevious::Int

    newreleasedate::Int
    newduration::Int

    clearance::Vector{Int}
end

function Route(V::Int)
    clients = Vertex[]
    sizehint!(clients, V)
    return Route(-1, clients, Vertex(1), Vertex(1), 0, 0, 0, 0, 0, 0, 0, Vector{Int}(undef, V))
end

nclients(r::Route) = length(r.clients) - 2

@inline lastclientidx(r::Route) = lastindex(r.clients) - 1
@inline clientsrange(r::Route) = 2:(lastindex(r.clients) - 1)
@inline lastblockidx(r::Route, bsize::Int) = lastindex(r.clients) - bsize
@inline blocksrange(r::Route, bsize::Int) = 2:(lastindex(r.clients) - bsize)

@inline Base.getindex(r::Route, idx::Integer) = r.clients[idx]
@inline Base.setindex!(r::Route, v::Vertex, idx::Integer) = (r.clients[idx] = v)
