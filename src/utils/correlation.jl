#=
correlate_eigsum is faster
correlate_loops supports striding
=#

#=
WEIGHTS
tester le type de eltype(weights) * (eltype(kernel) * eltype(A))
test : détection de coin sur test12e.txt
=#

using Test
using Logging
using Core.Compiler: return_type
using BenchmarkTools

CI = CartesianIndex
CIs = CartesianIndices

function build_out(A, kernel; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), map_f = *, weight_f = *)
    Ctype = return_type(weight_f, Tuple{eltype(weights), return_type(map_f, Tuple{eltype(A), eltype(kernel)})})  # weights * map_f(A, kernel)
    Csize = size(A) .÷ stride_ .+ size(kernel) .- 1
    C =  Array{Ctype}(undef, Csize...)
    return C
end

function set_padding(P, A, padding)
    P .= padding
    P[CI((size(P) .- size(A)) .÷ 2) .+ CIs(A)] .= A
end

function build_padded(A, kernel, padding=zero(eltype(A)))
    P = similar(A, size(A) .+ 2 .* (size(kernel) .- 1))
    set_padding(P, A, padding)
    return P
end
    
function prepare_correlate(A, kernel; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), map_f = *, weight_f = *)
    C = build_out(A, kernel; weights, stride_, map_f, weight_f)
    P = build_padded(A, kernel)
    return (C, P)
end

function check_correlate(C, A, kernel, padded, weights, stride_, map_f, weight_f)
    P = padded
    if any(size(A) .% stride_ .!= 0)
        @warn "size(A) = " * string(size(A)) * " is not element-wise divisible by stride_ = " * string(stride_)
    end

    @assert size(weights) == size(kernel) "size(weights) = " * string(size(weights)) * " != size(kernel) = " * string(size(kernel))
    @assert eltype(C) == return_type(weight_f, Tuple{eltype(weights), return_type(map_f, Tuple{eltype(A), eltype(kernel)})})
    @assert ndims(kernel) == ndims(A) "A and the kernel must have same number of dimensions"
    @assert all(stride_ .> 0) "stride_ must be positive"
    @assert size(C) == size(A) .÷ stride_ .+ size(kernel) .- 1  "Bad size for C, use `C = Array{typeof(map_f(first(A), first(kernel)))}(undef, size(A) .÷ stride_ .+ size(kernel) .- 1)`"
    @assert size(P) == size(A) .+ 2 .* (size(kernel) .- 1)  "Bad size for P, use `P = similar(A, size(A) .+ 2 .* (size(kernel) .- 1))`"
end

function correlate_loops!(out, A, kernel, padded; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), padding=zero(eltype(A)), map_f = *, reduce_f = +, weight_f = *)
    @debug "loops!", size(weights), size(kernel)
    C, P = out, padded
    check_correlate(C, A, kernel, padded, weights, stride_, map_f, weight_f)
    set_padding(P, A, padding)

    indsK = CIs(kernel)[2:end]
    firstind = first(CIs(kernel))
    for indC in CIs(C)
        ind0P = CI(stride_ .* (indC - firstind).I)
        val = map_f(kernel[firstind], P[ind0P + firstind])
        for indK in indsK
            val = weight_f(weights[indK], reduce_f(val, map_f(kernel[indK], P[ind0P + indK])))
        end
        C[indC] = val
    end
    return C
end
function correlate_loops(A, kernel; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), padding=zero(eltype(A)), map_f = *, reduce_f = +, weight_f = *)
    @debug "loops", size(weights), size(kernel)
    C, P = prepare_correlate(A, kernel, ; stride_ = stride_, map_f = map_f, weight_f = weight_f)
    return correlate_loops!(C, A, kernel, P; weights, stride_=stride_, padding=padding, map_f = map_f, reduce_f = reduce_f)
end

function prepare_eigmap(arr1, arr2; map_f = *)
    ind1 = Array{CI}(undef, one.(size(arr1))..., size(arr2)...)
    ind2 = Array{CI}(undef, size(arr1)..., one.(size(arr2))...)
    f_type = return_type(map_f, Tuple{eltype(arr1), eltype(arr2)})
    eigarr = Array{f_type}(undef, size(arr1)..., size(arr2)...)
    return (ind1, ind2, eigarr)
end

function check_eigmap(arr1, arr2, ind1, ind2, eigarr; map_f = *)
    @assert size(ind1) == (one.(size(arr1))..., size(arr2)...)
    @assert size(ind2) == (size(arr1)..., one.(size(arr2))...)
    @assert size(eigarr) == (size(arr1)..., size(arr2)...)
    @assert eltype(eigarr) == return_type(map_f, Tuple{eltype(arr1), eltype(arr2)})
end

function correlate_eigsum!(out, A, kernel, padded, indK, indC, eigarr; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), padding=0, map_f = *, reduce_f = +, weight_f = *)
    # get rid of CI https://discourse.julialang.org/t/selecting-multiple-elements-of-an-array-by-a-list-of-indices/47483
    # Inds... or to_ind(Inds, stride)
    # https://docs.julialang.org/en/v1/base/arrays/#Base.to_indices
    @debug "eigsum!", size(weights), size(kernel)
    C, P = out, padded
    @assert all(stride_ .== 1) "Not implemented for stride_ != 1"
    check_correlate(C, A, kernel, P, weights, stride_, map_f, weight_f)
    check_eigmap(C, kernel, indK, indC, eigarr; map_f=map_f)
    
    n = ndims(A)
    n_ones = ntuple(i -> 1, n)
    set_padding(P, A, padding)
    indK .= reshape(CIs(kernel), n_ones..., size(kernel)...)
    indC .= reshape(CIs(C), size(C)..., n_ones...)
    # TODO:
    #  - Mettre les indices dans un Array{Int} plutot qu'un Array{CI}
    #  - partir de Base.Iterators.product(axes(A)) au lieu de CIs(A)
    @inbounds eigarr .= weight_f.(weights[indK], map_f.(kernel[indK], @view P[indC .- CI(n_ones) .+ indK]))
    out .= reduce(reduce_f, eigarr; dims=n+1:2n)
end
function correlate_eigsum(A, kernel; weights = one.(kernel), stride_ = ntuple(_ -> 1, ndims(A)), padding=0, map_f = *, reduce_f = +, weight_f = *)
    @debug "eigsum", size(weights), size(kernel)
    C, P = prepare_correlate(A, kernel, ; stride_ = stride_, map_f = map_f, weight_f = weight_f)
    indK, indC, eigarr = prepare_eigmap(C, kernel; map_f=map_f)
    return correlate_eigsum!(C, A, kernel, P, indK, indC, eigarr; weights, stride_=stride_, padding=padding, map_f = map_f, reduce_f = reduce_f, weight_f = weight_f)
end

function test_correlation()
    A = [1 2 1; 2 3 1; 1 2 1]
    kernel = [1 0; 2 3]
    expectation = [3 8 7 2; 6 14 11 3; 3 10 10 3; 0 1 2 1]

    @test expectation == correlate_loops(A, kernel)
    @test expectation == correlate_eigsum(A, kernel)

    let
        out, padded = prepare_correlate(A, kernel)
        correlate_loops!(out, A, kernel, padded)
        @test expectation == out
    end

    let
        out, padded = prepare_correlate(A, kernel)
        indK, indC, eigarr = prepare_eigmap(out, kernel)
        correlate_eigsum!(out, A, kernel, padded, indK, indC, eigarr)
        @test expectation == out
    end

    stride_ = (2, 3)
    strided_expectation = expectation[1:stride_[1]:end, 1:stride_[2]:end]
    let
        @test strided_expectation == correlate_loops(A, kernel; stride_=stride_)
    end

    # # TODO
    # let
    #     correlate_eigsum(A, kernel; stride_=stride_)
    #     @test strided_expectation == out skip=true
    # end
    # test détection de coins sur test12e.txt

    # dumb way to compute autocorrelation
    @test correlate_eigsum(A, A)[(end + 1) ÷ 2, (end + 1) ÷ 2] == sum(A .* A)

    # TODO: test on binary with map_f = !⊻ and reduce_f = &
end

function benchmark_correlation()
    n = 200
    A = rand(1:10, n, n)
    kernel = rand(1:10, 3, 3)
    @profview @btime correlate_loops($A, $kernel)
    @profview @btime correlate_eigsum($A, $kernel)

    out, padded = prepare_correlate(A, kernel)
    indK, indC, eigarr = prepare_eigmap(out, kernel)
    @profview @btime correlate_loops!($out, $A, $kernel, $padded)
    @profview @btime correlate_eigsum!($out, $A, $kernel, $padded, $indK, $indC, $eigarr)
end

function rotations(kernel)
    return (kernel, reverse(permutedims(kernel); dims=1), reverse(kernel), permutedims(reverse(kernel; dims=1)))
end

function test_rotations()
    kernel = reshape(1:2, 1, 2)  # [1 2]
    @test rotations(kernel) == ([1 2], [2; 1;;], [2 1], [1; 2;;])
    kernel = reshape(1:4, 2, 2)  # [1 3; 2 4]
    @test rotations(kernel) == ([1 3; 2 4], [3 4; 1 2], [4 2; 3 1], [2 1; 4 3])
    kernel = reshape('a' .+ (0:5), 2, 3)  # ['a' 'c' 'e'; 'b' 'd' 'f']
    @test rotations(kernel) == (['a' 'c' 'e'; 'b' 'd' 'f'], ['e' 'f'; 'c' 'd'; 'a' 'b'], ['f' 'd' 'b'; 'e' 'c' 'a'], ['b' 'a'; 'd' 'c'; 'f' 'e'])
end