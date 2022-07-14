using HGS_TSPRD
using Test

@testset "HgsTSPrd" begin
    if !isempty(ARGS)
        HGS_TSPRD.main(ARGS)
        HGS_TSPRD.main(ARGS)
    else
        HGS_TSPRD.main(["../instances/Solomon/100/RC101_3.dat"])
        HGS_TSPRD.main(["../instances/Solomon/100/RC101_3.dat"])
        HGS_TSPRD.main(["../instances/Solomon/100/RC101_3.dat"])
    end
end
