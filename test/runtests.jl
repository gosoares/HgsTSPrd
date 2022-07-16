using HgsTSPrd
using Test

@testset "HgsTSPrd" begin
    if isempty(ARGS)
        main(["../instances/TSPLIB/ch130_3.dat"])
        main(["../instances/TSPLIB/ch130_3.dat"])
        main(["../instances/TSPLIB/ch130_3.dat"])
        # main(["../instances/Solomon/100/C101_1.dat"])
        # main(["../instances/Solomon/100/C101_3.dat"])
        # main(["../instances/TSPLIB/tsp225_3.dat"])
        # main(["../instances/Solomon/100/C101_3.dat"])
        # main(["../instances/TSPLIB/ch130_3.dat"])
    else
        main(ARGS)
        main(ARGS)
    end
end
