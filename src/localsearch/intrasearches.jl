function intrasearch!(ls::LocalSearch{V}) where {V}
    shuffle!(ls.data.rng, ls.intramovesorder)
    improvedAny = false
    improved = false

    for route in ls.routes
        whichmove = 1
        while whichmove <= N_INTRA
            move = ls.intramovesorder[whichmove]

            if move == 1
                improved = intrarelocation!(ls.data, route, 1)
            elseif move == 2
                improved = intraswap!(ls.data, route, 1, 1)
            else
                error("unknown move")
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

function intrarelocation!(data::Data, route::Route, bsize::Int)
    bestimprovement = 0
    bestblockpos = -1
    bestinspos = -1

    for c in 2:(lastindex(route.clients) - bsize)
        preimprovement =
            arctime(data, route[c - 1], route[c]) + arctime(data, route[c + bsize - 1], route[c + bsize]) -
            arctime(data, route[c - 1], route[c + bsize])

        for pos in chain(1:(c - 2), (c + bsize):(lastindex(route.clients) - bsize))
            improvement =
                preimprovement + arctime(data, route[pos], route[pos + 1]) - arctime(data, route[pos], route[c]) -
                arctime(data, route[c + bsize - 1], route[pos + 1])
            if improvement > bestimprovement
                bestimprovement = improvement
                bestblockpos = c
                bestinspos = pos
            end
        end
    end

    if bestimprovement > 0
        block = splice!(route.clients, bestblockpos:(bestblockpos + bsize - 1))
        (bestblockpos < bestinspos) && (bestinspos -= bsize)
        splice!(route.clients, (bestinspos + 1):bestinspos, block)
        return true
    end
    return false
end

function intraswap!(data::Data, route::Route, b1size::Int, b2size::Int)
    bestimprovement, pos1, pos2 = onewayintraswap(data, route, b1size, b2size)
    if b1size != b2size
        improvement, posa, posb = onewayintraswap(data, route, b2size, b1size)
        if improvement > bestimprovement
            bestimprovement = improvement
            pos1, pos2 = posa, posb
        end
    end

    if bestimprovement > 0
        block2 = splice!(route.clients, pos2:(pos2 + b2size - 1), view(route.clients, pos1:(pos1 + b1size - 1)))
        splice!(route.clients, pos1:(pos1 + b1size - 1), block2)
        return true
    end
    return false
end

function onewayintraswap(data::Data, route::Route, b1size::Int, b2size::Int)
    bestimprovement = 0
    bestpos1 = -1
    bestpos2 = -1

    for c1 in 2:(lastindex(route.clients) - b1size)
        preimprov = arctime(data, route[c1 - 1], route[c1]) + arctime(data, route[c1 + b1size - 1], route[c1 + b1size])

        for c2 in (c1 + 1):(lastindex(route.clients) - b2size)
            improv =
                preimprov + arctime(data, route[c2 + b2size - 1], route[c2 + b2size]) -
                arctime(data, route[c1 - 1], route[c2]) - arctime(data, route[c1 + b1size - 1], route[c2 + b2size])
            if c1 + 1 == c2 # adjacent blocks
                improv = improv - arctime(data, route[c2 + b1size - 1], route[c1])
            else
                improv =
                    improv + arctime(data, route[c2 - 1], route[c2]) -
                    arctime(data, route[c2 + b2size - 1], route[c1 + b1size]) - arctime(data, route[c2 - 1], route[c1])
            end

            if improv > bestimprovement
                bestimprovement = improv
                bestpos1 = c1
                bestpos2 = c2
            end
        end
    end

    return bestimprovement, bestpos1, bestpos2
end
