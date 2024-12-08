using Test

function solve(lines::Vector{String})
    mat = permutedims(reduce(hcat, collect.(lines)))

    positions = zip(mat, CartesianIndices(mat))
    F, IJ = typeof.(first(positions))
    frequencies = Dict{F, Set{IJ}}()
    for (f, ij) in positions
        if f == '.' continue end
        if haskey(frequencies, f)
            push!(frequencies[f], ij)
        else
            frequencies[f] = Set((ij,))
        end
    end

    nodes1 = falses(size(mat)...)
    nodes2 = falses(size(mat)...)
    for (f, positions) in frequencies
        for (ij, kl) in Iterators.product(positions, positions)
            if ij == kl continue end
            steps = 0
            diff = kl - ij
            while checkbounds(Bool, nodes2, kl + steps * diff)
                nodes2[kl + steps * diff] = true
                if steps == 1 nodes1[kl + steps * diff] = true end
                steps += 1
            end
        end
    end
    sol1 = sum(nodes1)
    sol2 = sum(nodes2)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test08.txt"))) == (14, 34)
@profview @benchmark solve($(readlines(joinpath(@__DIR__, "../data/val08.txt"))))

lines = readlines(joinpath(@__DIR__, "../data/test08.txt"))
mat = permutedims(reduce(hcat, collect.(lines)))

function groupby(zipped)
    F, IJ = typeof.(first(positions))
    frequencies = Dict{F, Set{IJ}}()
    foreach(positions) do (k, v)
        if haskey(frequencies, k)
            push!(frequencies[k], v)
        else
            frequencies[k] = Set((v,))
        end
    end
end

positions = zip(mat, CartesianIndices(mat))
F, IJ = typeof.(first(positions))
frequencies = Dict{F, Set{IJ}}()
for (f, ij) in positions
    if f == '.' continue end
    if haskey(frequencies, f)
        push!(frequencies[f], ij)
    else
        frequencies[f] = Set((ij,))
    end
end

nodes1 = falses(size(mat)...)
nodes2 = falses(size(mat)...)
for (f, positions) in frequencies
    for (ij, kl) in Iterators.product(positions, positions)
        if ij == kl continue end
        steps = 0
        diff = kl - ij
        while checkbounds(Bool, nodes2, ij + steps * diff)
            nodes2[ij + steps * diff] = true
            if steps == 1 nodes1[ij + steps * diff] = true end
            steps += 1
        end
    end
end
sol1 = sum(nodes1)
sol2 = sum(nodes2)


nodes1 = falses(size(mat)...)
nodes2 = falses(size(mat)...)
for (f, positions) in frequencies
    for (ij, kl) in Iterators.product(positions, positions)
        if ij == kl continue end
        steps = 0
        diff = kl - ij
        while checkbounds(Bool, nodes2, kl + steps * diff)
            nodes2[kl + steps * diff] = true
            if steps == 1 nodes1[kl + steps * diff] = true end
            steps += 1
        end
    end
end
sol1 = sum(nodes1)
sol2 = sum(nodes2)