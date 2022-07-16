using Pkg
Pkg.activate(@__DIR__)

using HgsTSPrd, Profile, PProf

data = Data(["$(@__DIR__)/../instances/TSPLIB/ch130_3.dat"])
# data = Data(["$(@__DIR__)/../instances/Solomon/100/C101_3.dat"])
# data = Data(["$(@__DIR__)/../instances/Solomon/10/C101_1.dat"])
# data = Data(["$(@__DIR__)/../instances/TSPLIB/eil51_3.dat"])
# data = Data(["$(@__DIR__)/../instances/TSPLIB/tsp225_3.dat", "--itni", "1000"])
ga = GeneticAlgorithm(data)
run!(ga)

Profile.clear_malloc_data()
run!(ga)

# @time run!(ga)
# @profile run!(ga)
# pprof()
# readline()
