using Test
using SparseArrays

CI = CartesianIndex

"""
visited must be all false before calling.
return (number of visited cells, looped)
"""
function simulate_room!(visited, obstacles, start_pos, start_dir_i, directions, dir_to_ind)
    visited .= false
    curr_pos = start_pos
    curr_dir_i = start_dir_i
    looped = false
    while true
        visited[curr_pos, curr_dir_i] = true
        next_pos = curr_pos + dir_to_ind[directions[curr_dir_i]]
        
        if !checkbounds(Bool, obstacles, next_pos)
            break
        elseif visited[next_pos, curr_dir_i]
            looped = true
            break
        end
        
        if obstacles[next_pos]
            curr_dir_i = mod1(curr_dir_i + 1, 4)
        else
            curr_pos = next_pos
        end
    end
    return (sum(any(visited, dims=3)), looped)
end

function solve(lines::Vector{String})
    room = permutedims(reduce(hcat, collect.(lines)))
    
    obstacles = sparse(room .== '#')
    directions = collect("^>v<")
    dir_to_ind = Dict(directions .=>  ((-1, 0), (0, 1), (1, 0), (0, -1)) .|> CartesianIndex)
    
    start_pos = only(ij for ij in CartesianIndices(room) if room[ij] in keys(dir_to_ind))
    start_dir_i = findfirst(directions .== room[start_pos])
    visited = falses(size(obstacles)..., length(directions))
    
    sol1 = simulate_room!(visited, obstacles, start_pos, start_dir_i, directions, dir_to_ind)[1]
    
    sol2 = 0
    potential_obstructions = any(visited, dims=3)
    potential_obstructions[start_pos] = false
    for obstruction in findall(potential_obstructions)
        obstructed_obstacles = copy(obstacles)
        obstructed_obstacles[obstruction] = true
    
        sol2 += simulate_room!(visited, obstructed_obstacles, start_pos, start_dir_i, directions, dir_to_ind)[2]
    end
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test06.txt"))) == (41, 6)
@time solve(readlines(joinpath(@__DIR__, "../data/val06.txt")))
