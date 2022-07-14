using HgsTSPrd
using Test

@testset "HgsTSPrd" begin
    if isempty(ARGS)
        main(["../instances/Solomon/10/C101_1.dat"])
        main(["../instances/Solomon/10/C101_1.dat"])
        main(["../instances/Solomon/10/C101_1.dat"])
    else
        main(ARGS)
        main(ARGS)
    end
end
