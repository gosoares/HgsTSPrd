const N_INTER = 4

function intersearch!(ls::LocalSearch)
    (length(ls.routes) == 1) && (return false)

    shuffle!(ls.data.rng, ls.intermovesorder)
    improvedany = false
    improved = false

    whichmove = 1
    while whichmove <= N_INTER
        move = ls.intermovesorder[whichmove]
        improved = false

        updateroutesorder(ls)
        for routespair in ls.routesorder
            route1 = ls.routes[routespair[1]]
            route2 = ls.routes[routespair[2]]

            if move == 1
                improved = interrelocation!(ls.data, route1, route2, 1)
            elseif move == 2
                improved = interrelocation!(ls.data, route1, route2, 2)
            elseif move == 3
                (route1.pos > route2.pos) && continue
                improved = interswap!(ls.data, route1, route2, 1, 1)
            elseif move == 4
                improved = interswap!(ls.data, route1, route2, 1, 2)
            else
                error("unknown move")
            end

            if improved
                break
            end
        end

        if improved
            updateroutesdata!(ls)
            shuffle!(ls.data.rng, ls.intermovesorder)
            whichmove = 1
            improvedany = true
        else
            whichmove += 1
        end
    end

    return improvedany
end

function interrelocation!(data::Data, route1::Route, route2::Route, bsize::Int)
    for c in blocksrange(route1, bsize)
        route1.newreleasedate = max(route1[c].predecessors_rd, route1[c + bsize - 1].successors_rd)
        route1.newduration =
            route1[c - 1].durationbefore +
            arctime(data, route1[c - 1], route1[c + bsize]) +
            route1[c + bsize].durationafter
        route2.newreleasedate = max(
            route2.releasedate, releasedate(data, route1[c]), releasedate(data, route1[c + bsize - 1])
        ) # valid for bsize up to 2
        blockduration = route1[c].durationafter - route1[c + bsize - 1].durationafter

        for pos in 1:lastclientidx(route2)
            route2.newduration =
                route2[pos].durationbefore +
                arctime(data, route2[pos], route1[c]) +
                blockduration +
                arctime(data, route1[c + bsize - 1], route2[pos + 1]) +
                route2[pos + 1].durationafter

            if evaluateinterroutemove(route1, route2)
                # println("improved")
                block = splice!(route1.clients, c:(c + bsize - 1))
                splice!(route2.clients, (pos + 1):pos, block)
                return true
            end
        end
    end

    return false
end

function interswap!(data::Data, route1::Route, route2::Route, b1size::Int, b2size::Int)
    for c1 in blocksrange(route1, b1size)
        prer1_rd = max(route1[c1].predecessors_rd, route1[c1 + b1size - 1].successors_rd)
        prer1_duration = route1[c1 - 1].durationbefore + route1[c1 + b1size].durationafter
        block1duration = route1[c1].durationafter - route1[c1 + b1size - 1].durationafter

        for c2 in blocksrange(route2, b2size)
            route1.newreleasedate = max(
                prer1_rd, releasedate(data, route2[c2]), releasedate(data, route2[c2 + b2size - 1])
            ) # valid for b2size up to 2
            route1.newduration =
                prer1_duration +
                arctime(data, route1[c1 - 1], route2[c2]) + # arc before block
                (route2[c2].durationafter - route2[c2 + b2size - 1].durationafter) + # block duration
                arctime(data, route2[c2 + b2size - 1], route1[c1 + b1size]) # arc after block

            route2.newreleasedate = max(
                route2[c2].predecessors_rd,
                route2[c2 + b2size - 1].successors_rd,
                releasedate(data, route1[c1]),
                releasedate(data, route1[c1 + b1size - 1]),
            ) # valid for b2size up to 2

            route2.newduration =
                route2[c2 - 1].durationbefore +
                block1duration +
                route2[c2 + b2size].durationafter +
                arctime(data, route2[c2 - 1], route1[c1]) +
                arctime(data, route1[c1 + b1size - 1], route2[c2 + b2size])

            if evaluateinterroutemove(route1, route2)
                block1 = splice!(route1.clients, c1:(c1 + b1size - 1), view(route2.clients, c2:(c2 + b2size - 1)))
                splice!(route2.clients, c2:(c2 + b2size - 1), block1)
                return true
            end
        end
    end
    return false
end

function evaluateinterroutemove(route1::Route, route2::Route)
    if route1.pos > route2.pos
        route1, route2 = route2, route1
    end
    clearance = route1.clearance[route2.pos - 1]

    deltar1end = max(route1.endprevious, route1.newreleasedate) + route1.newduration - route1.endtime

    newr2endprevious = route2.endprevious + min(max(0, deltar1end - clearance), max(deltar1end, clearance))
    newr2end = max(newr2endprevious, route2.newreleasedate) + route2.newduration

    return newr2end < route2.endtime
end

function updateroutesorder(ls::LocalSearch)
    if ls.nb_routesorder != length(ls.routes)
        resize!(ls.routesorder, length(ls.routes) * (length(ls.routes) - 1))

        pos = 1
        for r1 in eachindex(ls.routes)
            for r2 in eachindex(ls.routes)
                (r1 == r2) && continue
                ls.routesorder[pos] = (r1, r2)
                pos += 1
            end
        end

        ls.nb_routesorder = length(ls.routesorder)
    end

    shuffle!(ls.data.rng, ls.routesorder)
    return nothing
end
