using Test
using Logging
using SparseArrays

# costs -> Array(i, j, d) -> ((next_pos, next_dir_i), move_cost)

CI = CartesianIndex

const infty = typemax(Int) ÷ 2

# Add a lines to mat function
# With an optional map function map_f

include("utils.jl")

function empty_maze(n)
    mat = fill(' ', n, n)
    mat[axes(mat, 1), 1] .= '#'
    mat[axes(mat, 1), end] .= '#'
    mat[1, axes(mat, 2)] .= '#'
    mat[end, axes(mat, 2)] .= '#'
    mat[2, 2] = 'S'
    mat[end-1, end-1] = 'E'
    return join.(eachrow(mat), "")
end

function parse_maze(lines, directions)
    State = NTuple{3, Int}
    mat = permutedims(reduce(hcat, collect.(lines)))
    is_wall = mat .== '#'
    start = findfirst(mat .== 'S').I
    goal = findfirst(mat .== 'E').I
    costs = Dict{State, Array{Tuple{State, Int}}}()  # ((pos, dir_i), (next_pos, next_dir_i))
    for pos in getfield.(findall(.!is_wall), :I)
        for dir in 1:4
            options = Tuple{State, Int}[]
            new_pos = pos .+ directions[dir]
            if !is_wall[new_pos...] push!(options, ((new_pos..., dir), 1)) end
            for rot in (-1, 1)
                push!(options, ((pos..., mod1(dir + rot, 4)), 1000))
            end
            costs[(pos..., dir)] = options
        end
    end
    return mat, start, goal, costs
end

"""write the shortest distance from the origin to each position in the maze"""
function explore!(dists_from_origin, costs, goal, curr_dist, state)
    if curr_dist >= dists_from_origin[state...] return end
    if curr_dist >= dists_from_origin[goal..., 1] return end
    dists_from_origin[state...] = curr_dist
    for (next_state, Δdist) in costs[state...]
        explore!(dists_from_origin, costs, goal, curr_dist + Δdist, next_state)
    end
    return dists_from_origin
end

function reverse_optimal_paths!(is_optimal, min_dists_from_origin, start, pos)
    is_optimal[pos...] = true
    if pos == start return end
    neighbors = [pos .+ d for d in directions]
    optimum = minimum(min_dists_from_origin[n...] for n in neighbors)
    for n in neighbors
        if min_dists_from_origin[n...] == optimum
            reverse_optimal_paths!(is_optimal, min_dists_from_origin, start,n)
        end
    end
    return is_optimal
end

"""mark all positions that are optimal
a cell (i, j) is optimal if
    - it is the end of the maze
    - is minimizes the distance to get to get to a neighboring optimal cell"""
function reverse_optimal_paths!(is_optimal, dists_from_origin, start, state)
    if is_optimal[state...] return is_optimal end
    is_optimal[state...] = true
    prev_states = [
        SA[(state[1:2] .- directions[state[3]])..., state[3]],
        SA[state[1:2]..., mod1(state[3] + 1, 4)],
        SA[state[1:2]..., mod1(state[3] - 1, 4)]
    ]
    @info "[State $(collect(state))]\n" * join([psd for psd in [(ps, dists_from_origin[ps...]) for ps in prev_states] if psd[2] < infty], "\n")
    min_prev_dist = minimum(dists_from_origin[ps...] for ps in prev_states)
    for prev_state in prev_states
        if dists_from_origin[prev_state...] == min_prev_dist
            reverse_optimal_paths!(is_optimal, dists_from_origin, start, prev_state)
        end
    end
    return is_optimal
end

lines = readlines(joinpath(@__DIR__, "../data/test16b.txt"))
lines = empty_maze(40)
directions = [(1, 0), (0, 1), (-1, 0), (0, -1)]
mat, start, goal, costs = parse_maze(lines, directions)
start_direction = 2

@time dists_from_origin = explore!(infty * ones(Int, size(mat)..., size(directions, 1)), costs, goal, 0, (start..., start_direction))
sol1 = minimum(dists_from_origin[goal..., :])
# min_dists_from_origin = dropdims(minimum(dists_from_origin; dims=3); dims=3)
# @info "[Distance from origin (-1 = not reachable)]\n" * arr2prettystr(map(x -> ifelse(x == infty, -1, x), min_dists_from_origin))

is_optimal = falses(size(mat)..., size(directions, 1))
for dir_i in axes(directions, 1)
    reverse_optimal_paths!(is_optimal, dists_from_origin, start, SA[goal..., dir_i])
end
any(is_optimal; dims=3)
# > 429