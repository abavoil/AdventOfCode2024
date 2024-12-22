using Test

include("utils.jl")

const infty = typemax(Int)
State = NTuple{3, Int}

function parse_maze(lines, directions)
    mat = permutedims(reduce(hcat, collect.(lines)))
    iswall = mat .== '#'
    start = findfirst(mat .== 'S').I
    goal = findfirst(mat .== 'E').I
    costs = Dict{State, Array{Tuple{State, Int}}}()  # ((pos, dir_i), (next_pos, next_dir_i))
    for pos in getfield.(findall(.!iswall), :I)
        for (dir_i, dir) in enumerate(directions)
            options = Tuple{State, Int}[]
            new_pos = pos .+ dir
            if !iswall[new_pos...] push!(options, ((new_pos..., dir_i), 1)) end
            for rot in (-1, 1)
                new_dir_i = mod1(dir_i + rot, 4)
                if !iswall[pos .+ directions[new_dir_i]...] push!(options, ((pos..., new_dir_i), 1000)) end
                # push!(options, ((pos..., mod1(dir_i + rot, 4)), 1000))
            end
            costs[(pos..., dir_i)] = options
        end
    end
    return mat, start, goal, costs
end

lines = readlines(joinpath(@__DIR__, "../data/val16.txt"))

directions = [(1, 0), (0, 1), (-1, 0), (0, -1)]
start_dir_i = 2

mat, start, goal, costs = parse_maze(lines, directions)
unvisited = Set(keys(costs))
dist = Dict(s => infty for s in keys(costs))
dist[(start..., start_dir_i)] = 0
shortest_paths = Dict(s => Array{State}[] for s in keys(costs))
shortest_paths[(start..., start_dir_i)] = [[(start..., start_dir_i)]]

n = 0
while !isempty(unvisited)
    curr = argmin(x -> dist[x], unvisited)
    delete!(unvisited, curr)
    if dist[curr] == infty continue end
    for (next, Δdist) in costs[curr]
        n += 1
        if dist[next] > dist[curr] + Δdist
            dist[next] = dist[curr] + Δdist
            shortest_paths[next] = copy.(shortest_paths[curr])
            push!.(shortest_paths[next], Ref(next))
        elseif dist[next] == dist[curr] + Δdist
            added_paths = copy.(shortest_paths[curr])
            push!.(added_paths, Ref(next))
            push!.(Ref(shortest_paths[next]), added_paths)
        end
    end
end

min_dist = minimum(dist[(goal..., dir_i)] for dir_i in axes(directions, 1))
goal_dirs = [dir_i for dir_i in axes(directions, 1) if dist[(goal..., dir_i)] == min_dist]
is_optimal = falses(size(mat))
for dir_i in goal_dirs
    for path in shortest_paths[(goal..., dir_i)]
        for state in path
            is_optimal[state[1], state[2]] = true
        end
    end
end
sum(is_optimal)