using Pkg
Pkg.activate(@__DIR__)

using HGS_TSPRD, Profile, PProf

data = HGS_TSPRD.Data(["$(@__DIR__)/../instances/Solomon/100/C101_1.dat"])
ga = HGS_TSPRD.GeneticAlgorithm(data)
HGS_TSPRD.run!(ga)
@time HGS_TSPRD.run!(ga)
@profile HGS_TSPRD.run!(ga)
pprof()
readline()
