using Test
using Logging

with_logger(SimpleLogger(Error)) do
    @testset verbose = true "my_functions" begin
        @testset "io.jl" begin
            include("io.jl")
            test_arr2str()
        end
        @testset "correlation.jl" begin
            include("correlation.jl")
            test_correlation()
        end
    end
end