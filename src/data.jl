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
@inline arctime(data::Data, v1::Int, v2::Int) = data.timesmatrix[v1][v2]
@inline timesfrom(data, v) = data.times_matrix[v]

function Data(args::Vector{String})
    inputfile, outputfile, params = parseargs(args)

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

function parseargs(args::Vector{String})
    (isempty(args) || length(args) % 2 == 0) && paramserror()

    inputfile = args[1]
    isfile(inputfile) || paramserror("File not found: $inputfile")

    # default parameters
    mu = 20
    lambda = 40
    nbelite = 8
    nclose = 6
    itni = 10000
    itdiv = 4000
    timelimit = 600
    seed = rand(UInt32)
    outputfile = ""

    try
        for i in 2:2:length(args)
            if args[i] == "-t"
                timelimit = parse(Int, args[i + 1])
            elseif args[i] == "-s"
                seed = parse(Int, args[i + 1])
            elseif args[i] == "-t"
                outputfile = args[i + 1]
            elseif args[i] == "--mu"
                mu = parse(Int, args[i + 1])
            elseif args[i] == "--lambda"
                lambda = parse(Int, args[i + 1])
            elseif args[i] == "--nbelite"
                nbelite = parse(Int, args[i + 1])
            elseif args[i] == "--nclose"
                nclose = parse(Int, args[i + 1])
            elseif args[i] == "--itni"
                itni = parse(Int, args[i + 1])
            elseif args[i] == "--itdiv"
                itdiv = parse(Int, args[i + 1])
            else
                paramserror("Unknown argument: $(args[i])")
            end
        end
    catch e
        paramserror(sprint(showerror, e))
    end

    return inputfile, outputfile, AlgParams(mu, lambda, nbelite, nclose, itni, itdiv, timelimit, seed)
end

function paramserror(detail::String = "")
    !isempty(detail) && println(detail)
    println("
    usage: TSPrd instance_file [args]

    Possible arguments:
        -t timeLimit          Maximum execution time, in seconds
        -o outputFile         File to print the execution results
        -s seed               Numeric value for seeding the RNG
        --mu                  Minimum size of the population
        --lambda              Maximum number of additional individuals in the population
        --nbelite             Number of elite individuals for the biased fitness
        --nclose              Number of closest indivials to consider when calculating the diversity
        --itni                Max iterations without improvement to stop the algorithm
        --itdiv               Iterations without improvement to diversify
    ")
    exit(1)
    return nothing
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
