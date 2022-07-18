using HgsTSPrd, Printf, Logging

"""
    tsprd_execute(outputfolder, threads, threadid)

Execute all TSPrd instances, saving the results in `outputfolder`
The variables `threads` and `threadid` is used to split the instances between threads.
"""
function tsprd_execute(outputfolder::String, threads::Int, threadid::Int)
    mkpath(outputfolder)
    run(pipeline(`git rev-parse HEAD`; stdout = joinpath(outputfolder, "git.commit"))) # save git commit hash to file

    instanceids = getinstancesids()
    sort!(instanceids; by = iid -> iid.N)
    instanceids = [instanceids[i] for i in threadid:threads:lastindex(instanceids)] # instances for this thread

    println(" Executed  |   Time   | Last Instance")
    currentelement = 0
    startime = time_ns()
    ninstances = length(instanceids)

    for instanceid in instanceids
        runinstance(instanceid, outputfolder)

        instancename = "$(instanceid.instanceset)/$(instanceid.name)_$(instanceid.beta)"
        currenttime = (time_ns() - startime) / 1000000000
        currentelement += 1
        @printf(
            "\r %4d/%4d | %02d:%02d:%02d | %s                  ",
            currentelement,
            ninstances,
            (currenttime ÷ 3600),
            (currenttime ÷ 60 % 60),
            (currenttime % 60),
            instancename
        )
    end

    return nothing
end

const TIME_LIMIT = floor(Int, 10 * 60 * (1976.0 / 1201.0))

struct InstanceID
    instanceset::String
    name::String
    N::Int
    beta::String

    function InstanceID(iset::String, name::String, beta::String)
        N = parse(Int, match(r"\d+", name).match)
        return new(iset, name, N, beta)
    end
end

function runinstance(instanceid::InstanceID, outputfolder::String)
    instance_str = "$(instanceid.instanceset)/$(instanceid.name)_$(instanceid.beta)"
    inputfile = "../instances/$instance_str.dat"
    data = Data(String[inputfile, "-t", string(TIME_LIMIT)])
    ga = GeneticAlgorithm(data)

    execute!(ga) # warmup for compilation

    for execid in 1:10
        outputfile = joinpath(outputfolder, "$(instance_str)_$(execid).txt")
        isfile(outputfile) && continue # already executed
        execute!(ga, outputfile)
    end

    return nothing
end

function getinstancesids()
    #! format: off
    solomon_instances = [("Solomon", "$n/$name") for n in (10, 15, 20, 25, 30, 35, 40, 45, 50, 100) for name in ("C101", "C201", "R101", "RC101")]
    tsplib_names = ["eil51", "berlin52", "st70", "eil76", "pr76", "rat99", "kroA100", "kroB100", "kroC100", "kroD100", "kroE100", "rd100", "eil101",
                    "lin105", "pr107", "pr124", "bier127", "ch130", "pr136", "pr144", "ch150", "kroA150", "kroB150", "pr152", "u159", "rat195",
                    "d198", "kroA200", "kroB200", "ts225", "tsp225", "pr226", "gil262", "pr264", "a280", "pr299", "lin318", "rd400", "fl417", "pr439",
                    "pcb442", "d493"]
    tsplib_instances = [["TSPLIB", name] for name in tsplib_names]
    atsplib_instances = [["aTSPLIB", name] for name in ["ftv33", "ft53", "ftv70", "kro124p", "rbg403"]]
    #! format: on
    all_instances = Iterators.flatten([solomon_instances, atsplib_instances, tsplib_instances])
    betas = ["0.5", "1", "1.5", "2", "2.5", "3"]

    return [InstanceID(instanceset, name, beta) for (instanceset, name) in all_instances for beta in betas]
end

if length(ARGS) != 3
    @warn("Usage: executor.jl output_folder nthreads threadid")
    exit(1)
elseif !isdirpath("$(ARGS[1])/")
    @warn("\"$(ARGS[1])\" is not a valid folder.")
    exit(1)
end

threads = parse(Int, ARGS[2])
threadid = parse(Int, ARGS[3])

if (threadid > threads)
    @warn "Invalid thread id $threadid for $threads threads."
    exit(1)
end

disable_logging(Logging.Info)
tsprd_execute(ARGS[1], threads, threadid)
