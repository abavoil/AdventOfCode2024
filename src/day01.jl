using Test

function solve(lines::Vector{String})
    n = length(lines)
    l1 = Array{Int64}(undef, n)
    l2 = Array{Int64}(undef, n)

    for (i, line) in enumerate(lines)
        n1, n2 = parse.(Int64, split(line))
        l1[i] = n1
        l2[i] = n2
    end

    sol1 = sum(abs.(sort(l1) .- sort(l2)))

    sol2 = sum(n * count(l1 .== n) * count(l2 .== n) for n in intersect(unique(l1), unique(l2)))

    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test01.txt"))) == (11, 31)
@time solve(readlines(joinpath(@__DIR__, "../data/val01.txt")))
