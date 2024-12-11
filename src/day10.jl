using Test

function accessible_9s(heads, mem, mem_val0, mat, n, m, height, i, j)
    if !(1 <= i <= n && 1 <= j <= m) || mat[i, j] != height return mem_val0 end
    if height == 9 return Dict((i, j) => 1) end

    if height == 0 push!(heads, (i, j)) end
    return get!(mem, (i, j)) do
        # # Introduces **RUNTIME DISPATCH**
        # reduce((d1, d2) -> mergewith(+, d1, d2), (accessible_9s(heads, mem, mem_val0, mat, n, m, height+1, k, l) for (k, l) in ((i-1, j), (i+1, j), (i, j-1), (i, j+1))))
        mem_val = copy(mem_val0)
        for (k, l) in ((i-1, j), (i+1, j), (i, j-1), (i, j+1))
            for (nine_pos, count) in accessible_9s(heads, mem, mem_val0, mat, n, m, height+1, k, l)
                mem_val[nine_pos] = get!(mem_val, nine_pos, 0) + count
            end
        end
        mem[(i, j)] = mem_val
    end
end

function solve(lines::Vector{String})
    mat = permutedims(mapreduce(l -> parse.(Int64, l), hcat, collect.(lines)))
    heads = Tuple{Int64, Int64}[]
    mem = Dict{Tuple{Int64, Int64}, Dict{Tuple{Int64, Int64}, Int64}}()
    mem_val0 = valtype(mem)()
    n, m = size(mat)
    for i in 1:n, j in 1:m
        accessible_9s(heads, mem, mem_val0, mat, n, m, 0, i, j)
    end
    sol1 = sum(length(mem[h]) for h in heads)
    sol2 = sum(sum(values(mem[h])) for h in heads)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test10.txt"))) == (36, 81)
@time solve(readlines(joinpath(@__DIR__, "../data/val10.txt")))
