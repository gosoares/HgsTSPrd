struct AlgParams
    mu::Int         # minimum size of the population
    lambda::Int     # maximum number of additional individuals in the population
    nbelite::Int   # number of elite individuals for the biased fitness
    nclose::Int    # number of closest indivials to consider when calculating the diversity
    itni::Int      # max iterations without improvement to stop the algorithm
    itdiv::Int     # iterations without improvement to diversify
    timelimit::Int # in seconds
    seed::UInt32    # seed for RNG
end

struct Data{V} # V: how many vertices
    timesmatrix::NTuple{V,NTuple{V,Int}}   # times matrix
    releasedates::NTuple{V,Int}            # release date of each vertex
    params::AlgParams                       # algorithm params
    rng::Xoshiro                            # random number generator
    outputfile::String                     # Path of the file to save results
end

const INF = typemax(Int) ÷ 2

@inline releasedate(data::Data, v::Int) = data.releasedates[v]
@inline timet(data::Data, v1::Int, v2::Int) = data.timesmatrix[v1][v2]
@inline timesfrom(data, v) = data.times_matrix[v]

function Data(args::Vector{String})
    s = ArgParseSettings(; prog = "HGS_TSPRD")
    @add_arg_table s begin
        ("instance_file"; help = "File for the instance to run"; arg_type = String; required = true)
        ("-o"; help = "Output file to save results"; arg_type = String; default = "")
        ("-s"; help = "Seed for the RNG"; arg_type = UInt32; default = rand(UInt32))
        ("-t"; help = "Time limit"; arg_type = Int; default = 600)
        ("--mu"; arg_type = Int; default = 20)
        ("--lambda"; arg_type = Int; default = 40)
        ("--nbElite"; arg_type = Int; default = 8)
        ("--nClose"; arg_type = Int; default = 6)
        ("--itNi"; arg_type = Int; default = 10000)
        ("--itDiv"; arg_type = Int; default = 4000)
    end
    parsed_args = parse_args(args, s)

    params = AlgParams(
        parsed_args["mu"]::Int,
        parsed_args["lambda"]::Int,
        parsed_args["nbElite"]::Int,
        parsed_args["nClose"]::Int,
        parsed_args["itNi"]::Int,
        parsed_args["itDiv"]::Int,
        parsed_args["t"]::Int,
        parsed_args["s"]::UInt32,
    )

    inputfile = parsed_args["instance_file"]::String
    outputfile = parsed_args["o"]::String

    if !isfile(inputfile)
        throw(ArgumentError("File not found: $inputfile"))
    end

    V, timesmatrix, releasedates = open(inputfile, "r") do file
        first_char = peek(file, Char)

        if first_char == '<'
            return read_coords(file)
        elseif first_char == 'N'
            return read_distance_matrix(file)
        else
            throw(ArgumentError("Unknown instance file format"))
        end
    end

    floydwarshall(timesmatrix)

    return Data{V}(
        ntuple(i -> ntuple(j -> timesmatrix[i, j], V), V),
        ntuple(i -> releasedates[i], V),
        params,
        Xoshiro(params.seed),
        outputfile,
    )
end

function read_coords(file::IO)
    readuntil(file, "<DIMENSION> ")
    V = parse(Int, readline(file))

    readuntil(file, "</VERTICES>")
    readline(file)

    X, Y, releasedates = Int[], Int[], Int[]
    for _ in 1:V
        values = split(readline(file))
        push!(X, parse(Int, values[1]))
        push!(Y, parse(Int, values[2]))
        push!(releasedates, parse(Int, values[7]))
    end

    timesmatrix = Matrix{Int}(undef, V, V)

    for i in 1:V
        timesmatrix[i, i] = 0

        for j in i:V
            a = X[i] - X[j]
            b = Y[i] - Y[j]
            timesmatrix[i, j] = timesmatrix[j, i] = floor(sqrt(a * a + b * b) + 0.5)
        end
    end

    return V, timesmatrix, releasedates
end

function read_distance_matrix(file::IO)
    readuntil(file, "DIMENSION: ")
    V = parse(Int, readline(file))
    readuntil(file, "EDGE_WEIGHT_SECTION")

    times_matrix = reshape(parse.(Int, split(readuntil(file, "RELEASE_DATES"))), V, V)
    readline(file)
    release_dates = [parse(Int, readline(file)) for _ in 1:V]

    return V, times_matrix, release_dates
end

function floydwarshall(matrix::Matrix{Int})
    for k in 1:size(matrix)[1]
        for i in 1:size(matrix)[1]
            for j in 1:size(matrix)[1]
                matrix[i, j] = min(matrix[i, j], matrix[i, k] + matrix[k, j])
            end
        end
    end
end
