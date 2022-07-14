struct Split{V}
    data::Data{V}

    # stores for each position in the big tour which of the previous
    # positions has the first vertex with bigger release date
    rdpos::MVector{V,Int}

    # cumulative of arc times
    cumulative::MVector{V,Int}

    # durint split, stores the origin of the best arc arriving at i
    bestin::MVector{V,Int}

    # during the split, stores the value of the best arc arriving at i
    phi::MVector{V,Int}
end

function Split(data::Data{V}) where {V}
    return Split{V}(data, MVector{V,Int}(undef), MVector{V,Int}(undef), MVector{V,Int}(undef), MVector{V,Int}(undef))
end

function split!(split::Split{V}, indiv::Individual{V}) where {V}
    load!(split, indiv)

    fill!(split.phi, INF)

    for j in 2:V
        rdposj = split.rdpos[j]
        jtodepot = timet(split.data, indiv[j], 1)
        cumulj = split.cumulative[j]
        sigma = releasedate(split.data, indiv[rdposj])

        for i in 2:split.rdpos[j]
            deltaj = sigma + timet(split.data, 1, indiv[i]) + (cumulj - split.cumulative[i]) + jtodepot
            if deltaj < split.phi[j]
                split.phi[j] = deltaj
                split.bestin[j] = i
            end
            sigma = max(sigma, split.phi[i])
        end
    end

    return save!(split, indiv)
end

@inline function load!(split::Split{V}, indiv::Individual{V}) where {V}
    rdpos = 2
    split.rdpos[2] = rdpos
    split.cumulative[2] = 0

    for c in 3:V
        (releasedate(split.data, indiv[c]) > releasedate(split.data, indiv[rdpos])) && (rdpos = c)
        split.rdpos[c] = rdpos
        split.cumulative[c] = split.cumulative[c - 1] + timet(split.data, indiv[c - 1], indiv[c])
    end
    return nothing
end

@inline function save!(split::Split{V}, indiv::Individual{V}) where {V}
    indiv.predecessors[1] = indiv.gianttour[V]  # predecessor of depot is the last client
    indiv.successors[1] = indiv.gianttour[2]    # successor of depot is the first client
    indiv.predecessors[indiv.gianttour[2]] = 1  # predecessor of first client is the depot
    indiv.successors[indiv.gianttour[V]] = 1    # successor of the last client is the depot

    nextdepot = split.bestin[V] - 1 # position that has a depot after it
    for i in (V - 1):-1:2
        if i == nextdepot
            indiv.predecessors[indiv.gianttour[i + 1]] = 1
            indiv.successors[indiv.gianttour[i]] = 1
            nextdepot = split.bestin[nextdepot] - 1
        else
            indiv.predecessors[indiv.gianttour[i + 1]] = indiv.gianttour[i]
            indiv.successors[indiv.gianttour[i]] = indiv.gianttour[i + 1]
        end
    end

    return indiv.eval = split.phi[end]
end
