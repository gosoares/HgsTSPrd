struct LocalSearch{V}
    data::Data{V}
    split::Split{V}
end

function educate(localsearch::LocalSearch{V}, offspring::Individual{V}) where {V} end
