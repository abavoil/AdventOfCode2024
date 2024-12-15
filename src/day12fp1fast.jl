using Test

mutable struct Region{T}
    plant::T
    area::Int64
    perimeter::Int64
end

function solve(lines::Vector{String})
    mat = permutedims(mapreduce(collect, hcat, lines))
    n, m = size(mat)
    
    regions = similar(mat, Region)  # plant, area, perimeter
    
    function explore(regions, region, mat, i, j)
        if !checkbounds(Bool, mat, i, j) || mat[i, j] != region.plant
            region.perimeter += 1
            return
        end
        if isassigned(regions, i, j) return end
        regions[i, j] = region
        region.area += 1
        for (k, l) in ((i-1, j), (i+1, j), (i, j-1), (i, j+1))
            explore(regions, region, mat, k, l)
        end
    end
    
    for i in axes(mat, 1), j in axes(mat, 2)
        explore(regions, Region(mat[i, j], 0, 0), mat, i, j)
    end
    
    sum(r.area * r.perimeter for r in unique(regions))    
end


solve(readlines(joinpath(@__DIR__, "../data/val12.txt")))

# TODO:
# - pad mat with not a letter
# - Recursive convolution