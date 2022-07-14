using Pkg
Pkg.activate(".")

using HGS_TSPRD, ProfileView

data = HGS_TSPRD.Data(["../instances/Solomon/50/C101_1.dat"])
ga = HGS_TSPRD.GeneticAlgorithm(data)
HGS_TSPRD.run!(ga)
@profview HGS_TSPRD.run!(ga)
