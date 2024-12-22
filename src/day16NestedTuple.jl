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
    State = Tuple{NTuple{2, Int}, Int}
    mat = permutedims(reduce(hcat, collect.(lines)))
    iswall = mat .== '#'
    start = findfirst(mat .== 'S').I
    goal = findfirst(mat .== 'E').I
    costs = Dict{State, Array{Tuple{State, Int}}}()  # ((pos, dir_i), (next_pos, next_dir_i))
    for pos in getfield.(findall(.!iswall), :I)
        for dir in 1:4
            options = Tuple{State, Int}[]
            new_pos = pos .+ directions[dir]
            if !iswall[new_pos...] push!(options, ((new_pos, dir), 1)) end
            for rot in (-1, 1)
                push!(options, ((pos, mod1(dir + rot, 4)), 1000))
            end
            costs[(pos, dir)] = options
        end
    end
    return mat, start, goal, costs
end

"""write the shortest distance from the origin to each position in the maze"""
function explore!(dists_to_origin, costs, goal, curr_dist, pos, dir_i)
    if curr_dist >= dists_to_origin[pos..., dir_i] return end
    if curr_dist >= dists_to_origin[goal..., 1] return end
    dists_to_origin[pos..., dir_i] = curr_dist
    for ((next_pos, next_dir_i), Δdist) in costs[pos, dir_i]
        explore!(dists_to_origin, costs, goal, curr_dist + Δdist, next_pos, next_dir_i)
    end
end

"""mark all positions that are optimal
a cell (i, j) is optimal if
    - it is the end of the maze
    - is minimizes the distance to get to get to a neighboring optimal cell"""
function reverse_explore!(is_optimal, dists_to_origin, goal, pos)
    is_optimal[pos...] = true
    neighbors = (start .+ d for d in directions)
    optimal_neighbors = findall(==(minimum(dists_to_origin[neighbors, :])), neighbors)
    reverse_explore!(is_optimal, dists_to_origin, goal, optimal_neighbors)
end

lines = readlines(joinpath(@__DIR__, "../data/val16.txt"))
# lines = empty_maze(40)
directions = [(1, 0), (0, 1), (-1, 0), (0, -1)]
@btime parse_maze($lines, $directions) # 4.816 ms (81200 allocations: 16.30 MiB)
mat, start, goal, costs = parse_maze(lines, directions)
@info "[Maze]\n" *arr2str(mat)

dists_from_origin = infty * ones(Int, size(mat)..., size(directions, 1))
@time explore!(dists_from_origin, costs, goal, 0, start, 2) # 6.010686 seconds (109.85 M allocations: 4.911 GiB, 2.98% gc time, 0.44% compilation time)
sol1 = minimum(dists_from_origin[goal..., :])
min_dists_from_origin = dropdims(minimum(dists_from_origin; dims=3); dims=3)
@info "[Distance from origin (-1 = not reachable)]\n" * arr2prettystr(map(x -> ifelse(x == infty, -1, x), minimum(dists_from_origin; dims=3)))

@time neighbors = [goal .+ d for d in directions]
@time goal .+ d 


@profview @time for i=1:100
    dists_from_origin = infty * ones(size(mat)..., size(directions, 1))
    explore!(dists_from_origin, costs, 0, start, 2)
end
minimum(dists_from_origin[goal..., :])
















# function show_mem(mat, mem)
#     min_cost_to_end = [minimum(get(mem, ((i, j), dir_i), (infty-1, true))[1] for dir_i in axes(directions, 1)) for i in axes(mat, 1), j in axes(mat, 2)]
#     min_cost_to_end[min_cost_to_end .== infty-1] .= -10
#     min_cost_to_end[min_cost_to_end .== infty] .= -1
#     @info "\n" * arr2prettystr(min_cost_to_end)
# end

# evaluate_neighboor((move_cost, (remaining_cost, is_valid))) = ifelse(is_valid, remaining_cost + move_cost, infty)

# function compute_remaining_cost(snake_tail, mem, costs, goal, state)
#     debug_string = "state = " * string(state) * "  "
#     snake_tail = push!(copy(snake_tail), state)
#     print("Open ")
#     return get!(mem, state) do
#         println("Close")
#         if state[1] == goal
#             @info debug_string * "Return goal"
#             return (0, true)
#         end
#         best_is_valid = false
#         best_rem_cost = infty
#         for (next_state, move_cost) in costs[state]
#             if next_state ∈ snake_tail continue end
#             # if state == ((8, 4), 1) @show next_state end
#             neighboor_rem_cost, neighboor_is_valid = compute_remaining_cost(snake_tail, mem, costs, goal, next_state)
#             if neighboor_is_valid & (move_cost + neighboor_rem_cost < best_rem_cost)
#                 best_rem_cost = move_cost + neighboor_rem_cost
#                 best_is_valid = true
#             end
#         end
#         pop!(snake_tail, state)
#         @info debug_string * "Return " * string((best_rem_cost, best_is_valid)) * "  " * string(costs[state])
#         return best_rem_cost, best_is_valid
#     end
# end

# mem = Dict{State, Tuple{Int, Bool}}()
# compute_remaining_cost(Set{State}(), mem, costs, goal, (start, 2))
# show_mem(mat, mem)