using Test
using SparseArrays

# Idea to merge the two solutions : in part 1, make lobstacles = robstacles and sibling = [0, 0]

include("utils.jl")

function solve1(lines)
    isplit = findfirst(x -> x == "", lines)
    room = permutedims(reduce(hcat, collect.(lines[1:isplit-1])))
    direction = Dict('^' => (-1, 0), '>' => (0, 1), 'v' => (1, 0), '<' => (0, -1))
    char_moves = join(lines[isplit+1:end])
    # moves = reduce(hcat, collect.(getindex.(Ref(direction), collect(moves_char))))
    
    walls = room .== '#'
    
    # TODO: make it non-allocating, via a cache struct ?
    function find_available_spot(walls, obstacles, pos, move)
        checked_pos = copy(pos) # looping var
        while !walls[(checked_pos .+= move)...]
            if !obstacles[checked_pos...] return checked_pos end
        end
        return pos
    end
    
    function step!(walls, obstacles, pos, move)
        available_spot = find_available_spot(walls, obstacles, pos, move)
        if available_spot != pos
            pos .+= move
            obstacles[available_spot...] = true
            obstacles[pos...] = false
        end
        return obstacles, pos
    end
    
    function room_to_string(walls, obstacles, pos)
        str = fill('.', size(walls)...)
        str[walls] .= '#'
        str[obstacles] .= 'O'
        str[pos...] = '@'
        return arr2str(str)
    end
    
    function sum_inds(obstacles)
        sum(obstacles .* ((100axes(obstacles, 1) .- 100) .+ axes(obstacles, 2)' .- 1))
    end
    
    obstacles = room .== 'O'
    nb_obstacles = sum(obstacles)
    pos = collect(findfirst(room .== '@').I)
    for (i, c) in enumerate(char_moves)
        step!(walls, obstacles, pos, direction[c])

        if Logging.min_enabled_level(current_logger()) <= Logging.Debug
            @debug "$i, Move $c:\n" * room_to_string(walls, obstacles, pos)
            if walls[pos...] @warn "walking in walls at step $i" end
            if obstacles[pos...] @warn "walking in obstacles at step $i" end
            if any(obstacles .& walls) @warn "obstacles on wall at step $i" end
            if sum(obstacles) != nb_obstacles @warn "Number of obstacles changed at step $i" end
        end
    end
    
    return sum_inds(obstacles)
end

function solve2(lines)
    function can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, obstacle_pos, move)
        if is_wall[obstacle_pos...] return false end
        tuple_pos = Tuple(obstacle_pos)
        for (obs_to_move, is_obs, sibling) in ((lobstacles_to_move, is_lobstacle, [0, 1]), (robstacles_to_move, is_robstacle, [0, -1]))
            if !is_obs[obstacle_pos...] continue end
            if tuple_pos in obs_to_move return true end  # if it can't move, it has already been falsed
            push!(obs_to_move, tuple_pos)
            return all(can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, obstacle_pos .+ offset, move) for offset in (move, sibling))
        end
        return true
    end
    
    """return true if the robot can step, and push the obstacles that need to move to obstacles_to_move"""
    function can_step!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos, move)
        return can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos + move, move)
    end
    
    function room_to_string(is_wall, is_lobstacle, is_robstacle, pos)
        str = fill('.', size(is_wall))
        str[is_wall] .= '#'
        str[is_lobstacle] .= '['
        str[is_robstacle] .= ']'
        str[pos...] = '@'
        return arr2str(str)
    end
    
    function sum_inds(lobstacles)
        Is, Js = axes(lobstacles)
        i_gps = 100(Is .- 1)
        j_gps = Js .- 1
        sum(lobstacles .* (i_gps .+ j_gps'))
    end
    
    isplit = findfirst(x -> x == "", lines)
    direction = Dict('^' => [-1, 0], '>' => [0, 1], 'v' => [1, 0], '<' => [0, -1])
    moves = join(lines[isplit+1:end])
    
    double = Dict('#' => "##", 'O' => "[]", '.' => "..", '@' => "@.")
    room = permutedims(reduce(hcat, collect.(join.(eachrow(permutedims(mapreduce(l -> getindex.(Ref(double), collect(l)), hcat, lines[1:isplit-1])))))))
    @debug "Initial state:\n" * arr2str(room)
    is_wall = room .== '#'
    
    is_lobstacle = room .== '['
    is_robstacle = room .== ']'
    nb_lobstacles = sum(is_lobstacle)
    nb_robstacles = sum(is_robstacle)
    pos = collect(findfirst(room .== '@').I)
    for (i, char_move) in enumerate(moves)
        lobstacles_to_move = Set{NTuple{2, Int64}}()
        robstacles_to_move = Set{NTuple{2, Int64}}()
        move = direction[char_move]
        can_move = can_step!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos, move)
        if can_move
            pos .+= move
            for (obs_to_move, is_obs) in ((lobstacles_to_move, is_lobstacle), (robstacles_to_move, is_robstacle))
                for obstacle_pos in obs_to_move is_obs[obstacle_pos...] = false end
                for obstacle_pos in obs_to_move is_obs[(obstacle_pos .+ move)...] = true end
            end
        end
    
        if Logging.min_enabled_level(current_logger()) <= Logging.Debug
            @debug "$i, Move $char_move:\n" * "can_move=$can_move\nnew_pos=$pos\nLobstacles to move: " * join(lobstacles_to_move, ", ") * "\nRobstacles to move: " * join(robstacles_to_move, ", ") * "\n" * room_to_string(is_wall, is_lobstacle, is_robstacle, pos)
            if is_wall[pos...] @debug "walking in walls at step $i"; break end
            if is_lobstacle[pos...] @debug "walking in left obstacles at step $i"; break end
            if is_robstacle[pos...] @debug "walking in right obstacles at step $i"; break end
            if any(is_lobstacle .& is_wall) @debug "lobstacles on wall at step $i"; break end
            if any(is_robstacle .& is_wall) @debug "robstacles on wall at step $i"; break end
            if sum(is_lobstacle) != nb_lobstacles @debug "Number of left obstacles changed at step $i"; break end
            if sum(is_robstacle) != nb_robstacles @debug "Number of right obstacles changed at step $i"; break end
        end
    end
    
    return sum_inds(is_lobstacle)
end

function solve(lines::Vector{String})
    sol1 = solve1(lines)
    sol2 = solve2(lines)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test15a.txt")))[1] == 2028
@test solve(readlines(joinpath(@__DIR__, "../data/test15b.txt"))) == (10092, 9021)
@time solve(readlines(joinpath(@__DIR__, "../data/val15.txt")))