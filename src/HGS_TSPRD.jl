module HGS_TSPRD

using ArgParse
using Random

include("data.jl")

function main()
    data = Data(ARGS)

    return nothing
end

main()

end # module
