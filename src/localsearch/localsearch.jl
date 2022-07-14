using Printf

const N_INTRA = 1 # number of implemented intra searchs

mutable struct LocalSearch{V}
    data::Data{V}
    split::Split{V}

    clients::Vector{Vertex}
    routesPool::Vector{Route}

    routes::Vector{Route}
    emptyroutes::Vector{Route}

    intramovesorder::Vector{Int}
end

function LocalSearch(data::Data{V}, split::Split{V}) where {V}
    return LocalSearch{V}(
        data,
        split,
        Vertex[Vertex(i) for i in 1:V],
        Route[Route(V) for _ in 1:V],
        Route[],
        Route[],
        [i for i in 1:N_INTRA],
    )
end

function educate!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    loadindividual!(ls, indiv)

    improved = intrasearch!(ls)
    updateroutesdata!(ls)

    saveindividual!(ls, indiv)

    return nothing
end

function intrasearch!(ls::LocalSearch{V}) where {V}
    shuffle!(ls.data.rng, ls.intramovesorder)
    improvedAny = false
    improved = false

    for route in ls.routes
        whichmove = 1
        while whichmove <= N_INTRA
            move = ls.intramovesorder[whichmove]

            if move == 1
                improved = intrarelocation!(ls, route, 1)
            end

            if improved
                shuffle!(ls.data.rng, ls.intramovesorder)
                whichmove = 1
                improvedAny = true
            else
                whichmove += 1
            end
        end
    end

    return improvedAny
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

    toremove = []
    for (pos, route) in enumerate(ls.routes)
        route.pos = pos
        route.N = nclients(route)

        if route.N == 0 # remove empty routes
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
        ls.routes[r].clearance[r + 1] = -INF
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

    return nothing
end

function saveindividual!(ls::LocalSearch{V}, indiv::Individual{V}) where {V}
    indiv.eval = ls.routes[end].endtime

    indiv.predecessors[1] = ls.routes[end].clients[end - 1]
    indiv.successors[1] = ls.routes[begin].clients[2].id

    pos = 2
    for route in ls.routes
        for c in 2:(lastindex(route.clients) - 1)
            indiv.predecessors[route[c]] = route[c - 1]
            indiv.successors[route[c]] = route[c + 1]
            indiv.gianttour[pos] = route[c]
            pos += 1
        end
    end

    return nothing
end

function printroutes(ls::LocalSearch)
    println("    RD  |  DURAT |  START |   END  |  ROUTE")

    for route in ls.routes
        @printf "  %4d  |  %4d  |  %4d  |  %4d  |  " route.releasedate route.duration route.starttime route.endtime
        # print clients
        print("[ 0]")
        for c in 2:lastindex(route.clients)
            time = arctime(ls.data, route[c - 1], route[c])
            @printf " -(%2d)-> [%2d]" time route[c].id
        end

        print("  Clearances: ")
        for r in (route.pos + 1):lastindex(ls.routes)
            @printf "(%d)[%d]  " r route.clearance[r]
        end
        println()
    end
end