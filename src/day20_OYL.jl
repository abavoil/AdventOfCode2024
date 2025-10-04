using Test
using Logging
using ProgressBars

const IntType = Int32
const CI = CartesianIndex
const directions = CI.([(-1, 0), (1, 0), (0, -1), (0, 1)])

struct Maze{T}
    start::CI{2}
    end_::CI{2}
    ispath::BitMatrix
    dist_to_end::Matrix{T}
    dist_from_start::Matrix{T}
    non_cheated_time::T
    path_indices::Vector{CI{2}}
end


function initialize_maze(lines)
    mat = permutedims(reduce(hcat, collect.(lines)))
    start = findfirst(mat .== 'S')
    end_ = findfirst(mat .== 'E')
    ispath = mat .!= '#'
    neighbors(pos, ispath) = (pos + d for d in directions if ispath[pos + d])

    dist_to_end = fill(typemax(IntType), size(mat))
    to_explore = [(end_, 0)]

    while !isempty(to_explore)
        curr, dist = pop!(to_explore)
        dist_to_end[curr] = dist
        for next in neighbors(curr, ispath)
            dist_to_end[next] < typemax(IntType) && continue
            push!(to_explore, (next, dist + 1))
        end
    end

    dist_from_start = fill(typemax(IntType), size(mat))
    to_explore = [(start, 0)]

    while !isempty(to_explore)
        curr, dist = pop!(to_explore)
        dist_from_start[curr] = dist
        for next in neighbors(curr, ispath)
            dist_from_start[next] < typemax(IntType) && continue
            push!(to_explore, (next, dist + 1))
        end
    end

    path_indices = findall(ispath)
    non_cheated_time = dist_to_end[start]
    return Maze(start, end_, ispath, dist_to_end, dist_from_start, non_cheated_time, path_indices)
end

function manhattan_circle(center, radius)
    return (center + delta
            for i in 0:radius-1
            for delta in (CI(i, radius - i), CI(radius - i, -i), CI(-i, -radius + i), CI(-radius + i, i)))
end

function add_cheats!(cheat_count_by_time_save, cheat_end, cheat_dist, min_save, maze)
    for cheat_start in manhattan_circle(cheat_end, cheat_dist)
        checkbounds(Bool, maze.ispath, cheat_start) || continue
        maze.ispath[cheat_start] || continue
        cheated_time = maze.dist_from_start[cheat_start] + maze.dist_to_end[cheat_end] + cheat_dist
        time_save = maze.non_cheated_time - cheated_time
        time_save < min_save && continue
        cheat_count_by_time_save[time_save] = get(cheat_count_by_time_save, time_save, 0) + 1
    end
end

function count_cheats(max_cheat_dist, min_save, maze)
    cheat_count_by_time_save = Dict{IntType, IntType}()
    for cheat_dist in 2:max_cheat_dist, cheat_end in maze.path_indices
        add_cheats!(cheat_count_by_time_save, cheat_end, cheat_dist, min_save, maze)
    end
    return sum(values(cheat_count_by_time_save))
end

function solve(lines)
    maze = initialize_maze(lines)

    sol1 = count_cheats(2, 100, maze)
    sol2 = count_cheats(20, 100, maze)
    return sol1, sol2
end

solve(readlines(joinpath(@__DIR__, "../data/test20.txt")))
@time solve(readlines(joinpath(@__DIR__, "../data/val20.txt")))

# Start from the end of the cheat
# Check only for the border + for the start if start is in range
# Dynamic programming possible ?

lines = readlines(joinpath(@__DIR__, "../data/val20.txt"))
maze = initialize_maze(lines)
count_cheats(20, 100, maze)

cheat_count_by_time_save = Dict{IntType, IntType}()

for cheat_end in ProgressBar(path_indices), cheat_dist in 2:max_cheat_dist
    add_cheats!(cheat_count_by_time_save, cheat_end, cheat_dist)
end

for (k, v) in sort(cheat_count_by_time_save)
    println(v, " cheats save ", k, " picoseconds")
end
println(sum(values(cheat_count_by_time_save)))
