using HGS_TSPRD
using Test

@testset "HgsTSPrd" begin
    if isempty(ARGS)
        HGS_TSPRD.main(["../instances/Solomon/10/C101_1.dat"])
        HGS_TSPRD.main(["../instances/Solomon/10/C101_1.dat"])
        HGS_TSPRD.main(["../instances/Solomon/10/C101_1.dat"])
    else
        HGS_TSPRD.main(ARGS)
        HGS_TSPRD.main(ARGS)
    end
end
