using Test
using Logging

include("utils.jl")

function compute_metric(room)
    return sum(room[1:end-1] .* room[2:end])
end

function compute_pos(room_size, robot, n)
    @. mod((robot[1:2] + n * robot[3:4]), room_size)
end

# Part 1
function compute_room!(room, room_size, robots, n)
    room .= 0
    for robot in robots
        room[1 .+ compute_pos(room_size, robot, n)...] += 1
    end
    return room
end

# Part 2
function compute_room!(room::AbstractArray{Bool}, room_size, robots, n)
    room .= false
    for robot in robots
        room[1 .+ compute_pos(room_size, robot, n)...] = true
    end
    return room
end

function room_to_string(room)
    compact_string(room, x -> ifelse(x == 0, ".", "#"))
end

function solve(lines::Vector{String}, room_size)
    size_x, size_y = room_size
    pattern = r"p=(\d+),(\d+) v=(\-?\d+),(\-?\d+)"
    robots = lines .|> l -> NTuple{4, Int}(parse.(Int, match(pattern, l).captures))

    # room of Ints to count
    room100 = compute_room!(zeros(Int, room_size), room_size, robots, 100)
    mid_x, mid_y = (room_size.+1) .÷ 2
    Xs = (1:mid_x - 1, mid_x + 1:size_x)
    Ys = (1:mid_y - 1, mid_y + 1:size_y)
    sol1 = prod(sum(room100[xs, ys]) for xs in Xs, ys in Ys)

    room = falses(room_size)
    _, sol2 = findmax(n -> compute_metric(compute_room!(room, room_size, robots, n)), 1:size_x*size_y)
    @info "[Most auto-correlated room with a 1 offset]\n" * room_to_string(compute_room!(room, room_size, robots, sol2))

    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test14.txt")), (11, 7))[1] == 12
solve(readlines(joinpath(@__DIR__, "../data/val14.txt")), (101, 103))
