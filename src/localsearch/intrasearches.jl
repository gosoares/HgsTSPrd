const N_INTRA = 6 # number of implemented intra searchs

function intrasearch!(ls::LocalSearch{V}) where {V}
    shuffle!(ls.data.rng, ls.intramovesorder)
    improvedany = false
    improved = false

    for route in ls.routes
        whichmove = 1

        while whichmove <= N_INTRA
            move = ls.intramovesorder[whichmove]

            improved = if move == 1 # relocation 1
                intrarelocation!(ls.data, route, 1)
            elseif move == 2 # swap 1 1
                intraswap!(ls.data, route, 1, 1)
            elseif move == 3 # 2opt
                intratwoopt!(ls.data, route)
            elseif move == 4 # relocation 2
                intrarelocation!(ls.data, route, 2)
            elseif move == 5 # swap 1 2
                intraswap!(ls.data, route, 1, 2)
            elseif move == 6 # swap 2 2
                intraswap!(ls.data, route, 2, 2)
            else
                error("unknown move")
            end

            if improved
                shuffle!(ls.data.rng, ls.intramovesorder)
                whichmove = 1
                improvedany = true
            else
                whichmove += 1
            end
        end
    end

    return improvedany
end

function intrarelocation!(data::Data, route::Route, bsize::Int)
    bestimprovement = 0
    bestblockpos = -1
    bestinspos = -1

    for c in blocksrange(route, bsize)
        preimprovement =
            arctime(data, route[c - 1], route[c]) + arctime(data, route[c + bsize - 1], route[c + bsize]) -
            arctime(data, route[c - 1], route[c + bsize])

        for pos in Iterators.flatten((1:(c - 2), (c + bsize):lastblockidx(route, bsize)))
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
            b1size, b2size = b2size, b1size
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

    for c1 in blocksrange(route, b1size)
        preimprov = arctime(data, route[c1 - 1], route[c1]) + arctime(data, route[c1 + b1size - 1], route[c1 + b1size])

        for c2 in (c1 + b1size):lastblockidx(route, b2size)
            improv =
                preimprov + arctime(data, route[c2 + b2size - 1], route[c2 + b2size]) -
                arctime(data, route[c1 - 1], route[c2]) - arctime(data, route[c1 + b1size - 1], route[c2 + b2size])
            if c1 + b1size == c2 # adjacent blocks
                improv = improv - arctime(data, route[c2 + b2size - 1], route[c1])
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

function intratwoopt!(data::Data, route::Route)
    bestimprovement = 0
    bestpos1 = -1
    bestpos2 = -1

    for c1 in clientsrange(route)
        preimprov = arctime(data, route[c1 - 1], route[c1]) + arctime(data, route[c1], route[c1 + 1])

        for c2 in (c1 + 1):lastclientidx(route)
            preimprov = preimprov + arctime(data, route[c2], route[c2 + 1]) - arctime(data, route[c2], route[c2 - 1])

            improv = preimprov - arctime(data, route[c1 - 1], route[c2]) - arctime(data, route[c1], route[c2 + 1])

            if improv > bestimprovement
                bestimprovement = improv
                bestpos1 = c1
                bestpos2 = c2
            end
        end
    end

    if bestimprovement > 0
        reverse!(route.clients, bestpos1, bestpos2)
        return true
    end

    return false
end
