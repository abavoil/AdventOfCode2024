using Test

function count_stones(cache, stone, blinks)
    if blinks == 0 return 1 end
    if haskey(cache, (stone, blinks)) return cache[(stone, blinks)] end
    
    if stone == 0 nb_stones = count_stones(cache, 1, blinks - 1)
    elseif (nd = ndigits(stone)) % 2 == 0
        stone1, stone2 = divrem(stone, 10^(nd÷2))
        nb_stones = count_stones(cache, stone1, blinks - 1) + count_stones(cache, stone2, blinks - 1)
    else nb_stones = count_stones(cache, stone * 2024, blinks - 1)
    end
    return cache[(stone, blinks)] = nb_stones
end
count_stones(arrangement, blinks) = sum(count_stones(Dict{Tuple{Int64, Int64}, Int64}(), stone, blinks) for stone in arrangement)

function solve(lines::Vector{String})
    initial_arrangement = parse.(Int64, split(only(lines), " "))
    cache = Dict{Tuple{Int64, Int64}, Int64}()
    sol1 = sum(count_stones(cache, stone, 25) for stone in initial_arrangement)
    sol2 = sum(count_stones(cache, stone, 75) for stone in initial_arrangement)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test11.txt")))[1] == 55312
@time solve(readlines(joinpath(@__DIR__, "../data/test11.txt")))
