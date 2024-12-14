#=
correlate_eigsum is faster
correlate_loops supports striding
=#

using Test
using Logging
using Base.Iterators: product
using Core.Compiler: return_type

CI = CartesianIndex
CIs = CartesianIndices


function build_out(A, kernel;stride_ = ntuple(_ -> 1, ndims(A)), * = *)
    Ctype = return_type(*, Tuple{eltype(A), eltype(kernel)})
    Csize = size(A) .÷ stride_ .+ size(kernel) .- 1
    C =  Array{Ctype}(undef, Csize...)
    return C
end

function set_padding(P, A, kernel, padding)
    P .= padding
    P[CI(size(kernel) .- 1) .+ CIs(A)] .= A
end

function build_padded(A, kernel, padding=zero(eltype(A)))
    P = similar(A, size(A) .+ 2 .* (size(kernel) .- 1))
    P[CI(size(kernel) .- 1) .+ CIs(A)] .= A
    return P
end
    
function prepare_correlate(A, kernel; stride_ = ntuple(_ -> 1, ndims(A)), * = *)
    C = build_out(A, kernel; stride_, *)
    P = build_padded(A, kernel)
    return (C, P)
end

function check_correlate(C, A, kernel, padded, stride_, *)
    P = padded
    if any(size(A) .% stride_ .!= 0)
        @warn "size(A) = " * string(size(A)) * " is not element-wise divisible by stride_ = " * string(stride_)
    end

    @assert ndims(kernel) == ndims(A) "A and the kernel must have same number of dimensions"
    @assert all(stride_ .> 0) "stride_ must be positive"
    @assert size(C) == size(A) .÷ stride_ .+ size(kernel) .- 1  "Bad size for C, use `C = Array{typeof(*(first(A), first(kernel)))}(undef, size(A) .÷ stride_ .+ size(kernel) .- 1)`"
    @assert size(P) == size(A) .+ 2 .* (size(kernel) .- 1)  "Bad size for P, use `P = similar(A, size(A) .+ 2 .* (size(kernel) .- 1))`"
end

function correlate_loops!(out, A, kernel, padded; stride_ = ntuple(_ -> 1, ndims(A)), padding=zero(eltype(A)), * = *, + = +)
    C, P = out, padded
    if !all(stride_ .== 1) @info "Not tested for stride_ != 1" end
    check_correlate(C, A, kernel, padded, stride_, *)
    set_padding(P, A, kernel, padding)

    indsK = CIs(kernel)[2:end]
    firstind = first(CIs(kernel))
    for indC in CIs(C)
        ind0P = CI(stride_ .* (indC - firstind).I)
        val = kernel[firstind] * P[ind0P + firstind]
        for indK in indsK
            val += kernel[indK] * P[ind0P + indK]
        end
        C[indC] = val
    end
    return C
end
function correlate_loops(A, kernel; stride_ = ntuple(_ -> 1, ndims(A)), padding=zero(eltype(A)), * = *, + = +)
    C, P = prepare_correlate(A, kernel, ; stride_=stride_, * = *)
    @info "loop" * string(size(C))
    return correlate_loops!(C, A, kernel, P; stride_=stride_, padding=padding, * = *, + = +)
end

function prepare_eigmap(arr1, arr2; f=*)
    ind1 = Array{CI}(undef, one.(size(arr1))..., size(arr2)...)
    ind2 = Array{CI}(undef, size(arr1)..., one.(size(arr2))...)
    f_type = return_type(f, Tuple{eltype(arr1), eltype(arr2)})
    eigarr = Array{f_type}(undef, size(arr1)..., size(arr2)...)
    return (ind1, ind2, eigarr)
end

function check_eigmap(arr1, arr2, ind1, ind2, eigarr; f=*)
    @assert size(ind1) == (one.(size(arr1))..., size(arr2)...)
    @assert size(ind2) == (size(arr1)..., one.(size(arr2))...)
    @assert size(eigarr) == (size(arr1)..., size(arr2)...)
end

function correlate_eigsum!(out, A, kernel, padded, indK, indC, eigarr; stride_ = ntuple(_ -> 1, ndims(A)), padding=0, * = *, + = +)
    C, P = out, padded
    @assert all(stride_ .== 1) "Not implemented for stride_ != 1"
    check_correlate(C, A, kernel, P, stride_, *)
    check_eigmap(C, kernel, indK, indC, eigarr; f=*)
    
    n = ndims(A)
    n_ones = ntuple(i -> 1, n)
    set_padding(P, A, kernel, padding)
    indK .= reshape(CIs(kernel), n_ones..., size(kernel)...)
    indC .= reshape(CIs(C), size(C)..., n_ones...)
    # @show inds = size(CI.(reshape(collect(stride_), 2, 1) .* Tuple.(indC .- CI(n_ones))) .+ indK)
    # @inbounds eigarr .= kernel[indK] .* P[inds]
    @inbounds eigarr .= kernel[indK] .* P[indC .- CI(n_ones) .+ indK]
    out .= sum(eigarr; dims=n+1:2n)
end
function correlate_eigsum(A, kernel; stride_ = ntuple(_ -> 1, ndims(A)), padding=0, * = *, + = +)
    C, P = prepare_correlate(A, kernel, ; stride_=stride_, * = *)
    indK, indC, eigarr = prepare_eigmap(C, kernel; f=*)
    @info "eigsum" * string(size(C))
    return correlate_eigsum!(C, A, kernel, P, indK, indC, eigarr; stride_=stride_, padding=padding, * = *, + = +)
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

    # dumb way to compute autocorrelation
    @test correlate_eigsum(A, A)[(end + 1) ÷ 2, (end + 1) ÷ 2] == sum(A .* A)

end

function benchmark_correlation()
    n = 200
    A = rand(1:10, n, n)
    kernel = rand(1:10, 3, 3)
    @profview @btime correlate_loops(A, kernel)
    @profview @btime correlate_eigsum(A, kernel)

    out, padded = prepare_correlate(A, kernel)
    indK, indC, eigarr = prepare_eigmap(out, kernel)
    @profview @btime correlate_loops!(out, A, kernel, padded)
    @profview @btime correlate_eigsum!(out, A, kernel, padded, indK, indC, eigarr)
end
