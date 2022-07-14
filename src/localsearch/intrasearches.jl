function intrarelocation!(ls::LocalSearch, route::Route, bsize::Int)
    bestimprovement = 0
    bestblockpos = -1
    bestinspos = -1

    for c in 2:(lastindex(route.clients) - bsize)
        preimprovement =
            arctime(ls.data, route[c - 1], route[c]) + arctime(ls.data, route[c + bsize - 1], route[c + bsize]) -
            arctime(ls.data, route[c - 1], route[c + bsize])

        for pos in chain(1:(c - 2), (c + bsize):(lastindex(route.clients) - bsize))
            improvement =
                preimprovement + arctime(ls.data, route[pos], route[pos + 1]) - arctime(ls.data, route[pos], route[c]) -
                arctime(ls.data, route[c + bsize - 1], route[pos + 1])
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
