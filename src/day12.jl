using Test
using LinearAlgebra: norm, ⋅
using Logging

includet("utils.jl")

function explore_region(mat, region, n, m, plant, i, j)
    if !(1 <= i <= n && 1 <= j <= m) return end
    if mat[i, j] != plant return end
    if region[i, j] return end
    region[i, j] = true
    for (k, l) in ((i-1, j), (i+1, j), (i, j-1), (i, j+1))
        explore_region(mat, region, n, m, plant, k, l)
    end
end

function solve(lines::Vector{String})
    mat = permutedims(mapreduce(collect, hcat, lines))
    n, m = size(mat)

    edge_kernels = rotations([1 0])
    vertex_kernels = (rotations([1 0; 0 0])..., rotations([1 1; 1 0])...)
    vertex_weights = (rotations([1 1; 1 0])..., rotations([1 1; 1 1])...)

    explored = falses(size(mat)...)
    regions = Tuple{Int64, Int64, Int64}[]  # area, perimeter, nb_edges
    region = falses(size(mat)...)
    for i in axes(mat, 1), j in axes(mat, 2)
        if explored[i, j] continue end
        # @debug "\n[Region i=$i, j=$j]\n" * compact_string(region, Int)
        region .= falses(size(mat)...)
        explore_region(mat, region, n, m, mat[i, j], i, j)
        surface = sum(region)
        perimeter = 0
        # for k in edge_kernels
        #     perimeter += sum(correlate_loops(region, Bool.(k); map_f = !⊻, reduce_f = &))
        # end
        # nb_edges = 0
        # for (k, w) in zip(vertex_kernels, vertex_weights)
        #     corr = correlate_eigsum(region, Bool.(k); weights = Bool.(w), map_f = !⊻, reduce_f = &, weight_f = (w, val) -> !w | val)
        #     @debug "\n[Kernel]\n" * compact_string(k, Int) * "\n[Weights]\n" * compact_string(w, Int) * "\n[Result]\n" * compact_string(corr, Int)
        #     nb_edges += sum(corr)
        # end
        perimeter = sum(sum(correlate_loops(region, Bool.(k); map_f = !⊻, reduce_f = &)) for k in edge_kernels)
        nb_edges = sum(sum(
            correlate_eigsum(region, Bool.(k); weights = Bool.(w), map_f = !⊻, reduce_f = &, weight_f = (w, val) -> !w | val))
            for (k, w) in zip(vertex_kernels, vertex_weights))
        push!(regions, (surface, perimeter, nb_edges))
        explored .|= region
    end
    regions

    sol1 = sum(s * p for (s, p, _) in regions)
    sol2 = sum(s * nb_e for (s, _, nb_e) in regions)
    return sol1, sol2
end

# 890206 too low

@test solve(readlines(joinpath(@__DIR__, "../data/test12a.txt"))) == (140, 80)
@test solve(readlines(joinpath(@__DIR__, "../data/test12b.txt"))) == (772, 436)
@test solve(readlines(joinpath(@__DIR__, "../data/test12c.txt"))) == (1930, 1206)
@test solve(readlines(joinpath(@__DIR__, "../data/test12d.txt")))[2] == 236
@test solve(readlines(joinpath(@__DIR__, "../data/test12e.txt")))[2] == 368
@time solve(readlines(joinpath(@__DIR__, "../data/val12.txt")))