mutable struct LocalSearch{V}
    data::Data{V}
    split::Split{V}

    clients::Vector{Vertex}
    routesPool::Vector{Route}

    routes::Vector{Route}
    emptyroutes::Vector{Route}

    intramovesorder::Vector{Int}
    intermovesorder::Vector{Int}
    routesorder::Vector{Tuple{Int,Int}}
    nb_routesorder::Int
end

function LocalSearch(data::Data{V}, split::Split{V}) where {V}
    routesorder = Tuple{Int,Int}[]
    sizehint!(routesorder, V * V)

    return LocalSearch{V}(
        data,
        split,
        Vertex[Vertex(i) for i in 1:V],
        Route[Route(V) for _ in 1:V],
        Route[],
        Route[],
        [i for i in 1:N_INTRA],
        [i for i in 1:N_INTER],
        routesorder,
        0,
    )
end

function educate!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    loadindividual!(ls, indiv)

    improved = true
    movetype = 0  # 0: intra, 1: inter, 2: depot
    notimproved = 0

    while improved
        while notimproved < 2
            if movetype == 0
                improved = intrasearch!(ls)
            elseif movetype == 1
                improved = intersearch!(ls)
            elseif movetype == 2
                improved = divideandswap!(ls)
            end

            updateroutesdata!(ls)
            movetype = (movetype + 1) % 3
            if improved
                updateroutesdata!(ls)
                notimproved = 0
            else
                notimproved += 1
            end
        end

        improved = splitsearch(ls, indiv)
    end

    saveindividual!(ls, indiv)
    return nothing
end

function splitsearch(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    prevtime = indiv.eval
    savegianttour!(ls, indiv)
    split!(ls.split, indiv)
    loadindividual!(ls, indiv)
    return indiv.eval < prevtime
end

function divideandswap!(ls::LocalSearch)
    for r in 2:lastindex(ls.routes)
        route = ls.routes[r]

        (ls.routes[r - 1].endtime >= route.releasedate) && continue
        (releasedate(ls.data, route[lastclientidx(route)]) == route.releasedate) && continue

        # skip vertices with higher release date
        startpos::Int = findfirst(v -> v.successors_rd < releasedate(ls.data, v), route.clients)

        for pos in startpos:(lastclientidx(route) - 1)
            new_ra_end =
                max(route.endprevious, route[pos].successors_rd) + # start time
                arctime(ls.data, 1, route[pos + 1]) +
                route[pos + 1].durationafter # duration
            new_rb_end =
                max(new_ra_end, route[pos + 1].predecessors_rd) + # start time
                route[pos].durationbefore +
                arctime(ls.data, route[pos], 1) # duration

            if new_rb_end < route.endtime
                newroute = addroute!(ls, route.pos + 1)
                splice!(newroute.clients, 2:1, view(route.clients, 2:pos))
                deleteat!(route.clients, 2:pos)
                return true
            end
        end
    end

    return false
end

function addroute!(ls::LocalSearch, pos::Integer = lastindex(ls.routes) + 1)
    route = isempty(ls.emptyroutes) ? ls.routesPool[length(ls.routes) + 1] : pop!(ls.emptyroutes)
    insert!(ls.routes, pos, route)

    resize!(route.clients, 2)
    route[1] = route.source
    route[2] = route.sink

    return route
end

function updateroutesdata!(ls::LocalSearch)
    endprev = 0

    toremove = Int[]
    for (pos, route) in enumerate(ls.routes)
        route.pos = pos

        if nclients(route) == 0 # remove empty routes
            push!(toremove, pos)
            continue
        end

        for c in 2:lastindex(route.clients)
            route[c].predecessors_rd = max(route[c - 1].predecessors_rd, releasedate(ls.data, route[c - 1]))
            route[c].durationbefore = route[c - 1].durationbefore + arctime(ls.data, route[c - 1], route[c])
        end

        for c in (lastindex(route.clients) - 1):-1:1
            route[c].successors_rd = max(route[c + 1].successors_rd, releasedate(ls.data, route[c + 1]))
            route[c].durationafter = arctime(ls.data, route[c], route[c + 1]) + route[c + 1].durationafter
        end

        route.releasedate = route[1].successors_rd
        route.duration = route[1].durationafter
        route.starttime = max(route.releasedate, endprev)
        route.endtime = route.starttime + route.duration
        route.endprevious = endprev
        endprev = route.endtime
    end

    for r in toremove
        push!(ls.emptyroutes, ls.routes[r])
    end
    deleteat!(ls.routes, toremove)

    # calculate the clearance between all pair of routes
    for r in 1:(lastindex(ls.routes) - 1)
        ls.routes[r].clearance[r] = -INF
        ls.routes[r].clearance[r + 1] = ls.routes[r + 1].releasedate - ls.routes[r].endtime
    end
    ls.routes[end].clearance[lastindex(ls.routes)] = -INF

    clearance = 0
    for r1 in eachindex(ls.routes)
        clearance = ls.routes[r1].clearance[r1 + 1]

        for r2 in (r1 + 2):lastindex(ls.routes)
            prevclearance = ls.routes[r2 - 1].clearance[r2]
            if clearance > 0
                clearance += max(prevclearance, 0)
            else
                clearance = max(clearance, prevclearance)
            end
            ls.routes[r1].clearance[r2] = clearance
        end
    end
    return nothing
end

function loadindividual!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    empty!(ls.routes)
    empty!(ls.emptyroutes)

    route = addroute!(ls)
    pop!(route.clients)
    for c in indiv
        push!(route.clients, ls.clients[c])

        if indiv.successors[c] == 1
            push!(route.clients, route.sink)
            route = addroute!(ls)
            pop!(route.clients)
        end
    end
    pop!(ls.routes)

    updateroutesdata!(ls)
    return nothing
end

function saveindividual!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    indiv.eval = ls.routes[end].endtime

    indiv.predecessors[1] = ls.routes[end].clients[end - 1]
    indiv.successors[1] = ls.routes[begin].clients[2].id

    pos = 2
    for route in ls.routes
        for c in clientsrange(route)
            indiv.predecessors[route[c]] = route[c - 1]
            indiv.successors[route[c]] = route[c + 1]
            indiv.gianttour[pos] = route[c]
            pos += 1
        end
    end

    return nothing
end

function savegianttour!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    pos = 2
    for route in ls.routes
        for c in clientsrange(route)
            indiv.gianttour[pos] = route[c]
            pos += 1
        end
    end
    return nothing
end

function printroutes(ls::LocalSearch)
    return printroutes(ls.data, ls.routes)
end

function printroutes(data::Data, routes::Vector{Route})
    sort!(routes; by = r -> r.pos)

    println("    RD  |  DURAT |  START |   END  |  ROUTE")

    for route in routes
        @printf "  %4d  |  %4d  |  %4d  |  %4d  |  " route.releasedate route.duration route.starttime route.endtime
        # print clients
        print("[ 0]")
        for c in 2:lastindex(route.clients)
            time = arctime(data, route[c - 1], route[c])
            @printf " -(%2d)-> [%2d]" time route[c].id
        end

        print("  Clearances: ")
        for r2 in routes
            (route.pos >= r2.pos) && continue
            @printf "(%d)[%d]  " r2.pos route.clearance[r2.pos]
        end
        println()
    end
end
