struct AlgParams
    mu::Int         # minimum size of the population
    lambda::Int     # maximum number of additional individuals in the population
    nb_elite::Int   # number of elite individuals for the biased fitness
    n_close::Int    # number of closest indivials to consider when calculating the diversity
    it_ni::Int      # max iterations without improvement to stop the algorithm
    it_div::Int     # iterations without improvement to diversify
    time_limit::Int # in seconds
    seed::UInt32    # seed for RNG
end

struct Data{V}
    # V: how many vertices
    N::Int                                  # how many vertices and how many clients (V-1 )
    times_matrix::NTuple{V,NTuple{V,Int}}   # times matrix
    release_dates::NTuple{V,Int}            # release date of each vertex
    params::AlgParams                       # algorithm params
    start_time::Int                         # starting time of algorithm
    rng::Xoshiro                            # random number generator
    output_file::String                     # Path of the file to save results
end

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

    input_file = parsed_args["instance_file"]::String
    output_file = parsed_args["o"]::String

    if !isfile(input_file)
        throw(ArgumentError("File not found: $input_file"))
    end

    V, times_matrix, release_dates = open(input_file, "r") do file
        first_char = peek(file, Char)

        if first_char == '<'
            return read_coordinates_list_instance(file)
        elseif first_char == 'N'
            return read_distance_matrix_instance(file)
        else
            throw(ArgumentError("Unknown instance file format"))
        end
    end

    floyd_warshall(times_matrix)

    return Data{V}(
        V - 1,
        ntuple(i -> ntuple(j -> times_matrix[i, j], V), V),
        ntuple(i -> release_dates[i], V),
        params,
        time_ns(),
        Xoshiro(params.seed),
        output_file,
    )
end

function read_coordinates_list_instance(file::IO)
    readuntil(file, "<DIMENSION> ")
    V = parse(Int, readline(file))

    readuntil(file, "</VERTICES>")
    readline(file)

    X, Y, release_dates = Int[], Int[], Int[]
    for _ in 1:V
        values = split(readline(file))
        push!(X, parse(Int, values[1]))
        push!(Y, parse(Int, values[2]))
        push!(release_dates, parse(Int, values[7]))
    end

    times_matrix = Matrix{Int}(undef, V, V)

    for i in 1:V
        times_matrix[i, i] = 0

        for j in i:V
            a = X[i] - X[j]
            b = Y[i] - Y[j]
            times_matrix[i, j] = times_matrix[j, i] = floor(sqrt(a * a + b * b) + 0.5)
        end
    end

    return V, times_matrix, release_dates
end

function read_distance_matrix_instance(file::IO)
    readuntil(file, "DIMENSION: ")
    V = parse(Int, readline(file))
    readuntil(file, "EDGE_WEIGHT_SECTION")

    times_matrix = reshape(parse.(Int, split(readuntil(file, "RELEASE_DATES"))), V, V)
    readline(file)
    release_dates = [parse(Int, readline(file)) for _ in 1:V]

    return V, times_matrix, release_dates
end

function floyd_warshall(matrix::Matrix{Int})
    for k in 1:size(matrix)[1]
        for i in 1:size(matrix)[1]
            for j in 1:size(matrix)[1]
                matrix[i, j] = min(matrix[i, j], matrix[i, k] + matrix[k, j])
            end
        end
    end
end
