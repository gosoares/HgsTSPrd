using HgsTSPrd, Printf

function tsprd_execute(outputfolder::String)
    mkpath(outputfolder)
    run(pipeline(`git rev-parse HEAD`; stdout = joinpath(outputfolder, "git.commit"))) # save git commit hash to file

    instanceids = getinstancesids()

    println(" Executed  |   Time   | Last Instance")
    currentelement = 0
    startime = time_ns()
    ninstances = length(instanceids)

    Threads.@threads for instanceid in instanceids
        runinstance(instanceid, outputfolder)

        instancename = "$(instanceid.instanceset)/$(instanceid.name)_$(instanceid.beta) $(instanceid.execid)"
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
    execid::Int

    function InstanceID(iset::String, name::String, beta::String, execid::Int)
        N = parse(Int, match(r"\d+", name).match)
        return new(iset, name, N, beta, execid)
    end
end

function runinstance(instanceid::InstanceID, outputfolder::String)
    instance_str = "$(instanceid.instanceset)/$(instanceid.name)_$(instanceid.beta)"
    inputfile = "../instances/$instance_str.dat"
    outputfile = joinpath(outputfolder, "$(instance_str)_$(instanceid.execid).txt")
    isfile(outputfile) && return nothing

    data = Data(String[inputfile, "-o", outputfile, "-t", string(TIME_LIMIT)])
    warmup(data)

    starttime = time_ns()
    ga = GeneticAlgorithm(data)
    run!(ga)

    savetofile!(data, ga, starttime; print = false)
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

    return [
        InstanceID(instanceset, name, beta, e) for (instanceset, name) in all_instances for beta in betas for e in 1:10
    ]
end

if length(ARGS) != 1
    @warn("Inform the output folder")
    exit(1)
elseif !isdirpath("$(ARGS[1])/")
    @warn("\"$(ARGS[1])\" is not a valid folder.")
    exit(1)
end
tsprd_execute(ARGS[1])

# HgsTSPrd.main(ARGS)
