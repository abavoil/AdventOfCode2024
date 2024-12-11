using Test

function search_trails!(trails, mat, n, m, i0, j0, height, i, j)
    if !(1 <= i <= n && 1 <= j <= m) || mat[i, j] != height return end
    if mat[i, j] == 9
        trail = (i0, j0, i, j)
        trails[trail] = 1 + get!(trails, trail, 0)
    else
        for (k, l) in ((i-1, j), (i+1, j), (i, j-1), (i, j+1))
            search_trails!(trails, mat, n, m, i0, j0, height + 1, k, l)
        end
    end
end

function search_trails(mat)
    trails = Dict{Tuple{Int64, Int64, Int64, Int64}, Int64}()
    n, m = size(mat)
    for i in 1:n, j in 1:m
        search_trails!(trails, mat, n, m, i, j, 0, i, j)
    end
    return trails
end

function solve(lines::Vector{String})
    mat = permutedims(mapreduce(l -> parse.(Int64, l), hcat, collect.(lines)))
    trails = search_trails(mat)
    sol1 = length(trails)
    sol2 = sum(values(trails))
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test10.txt"))) == (36, 81)
@time solve(readlines(joinpath(@__DIR__, "../data/val10.txt")))
