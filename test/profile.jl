using Pkg
Pkg.activate(@__DIR__)

using HgsTSPrd, Profile, PProf

data = Data(["$(@__DIR__)/../instances/Solomon/100/C101_1.dat"])
ga = GeneticAlgorithm(data)
run!(ga)
@time run!(ga)
@profile run!(ga)
pprof()
readline()
