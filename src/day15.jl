using Test
using SparseArrays

# Add a cache to remove allocations!

include("utils.jl")


function can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, obstacle_pos, move, part2)
    if is_wall[obstacle_pos...] return false end
    tuple_pos = Tuple(obstacle_pos)
    lsibling, rsibling = ifelse(part2, ([0, 1], [0, -1]), ([0, 0], [0, 0]))
    for (obs_to_move, is_obs, sibling) in ((lobstacles_to_move, is_lobstacle, lsibling), (robstacles_to_move, is_robstacle, rsibling))
        if !is_obs[obstacle_pos...] continue end
        if tuple_pos in obs_to_move return true end  # if it can't move, it has already been falsed
        push!(obs_to_move, tuple_pos)
        return all(can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, obstacle_pos .+ offset, move, part2) for offset in (move, sibling))
    end
    return true
end

"""return true if the robot can step, and push the obstacles that need to move to obstacles_to_move"""
function can_step!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos, move, part2)
    return can_move!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos + move, move, part2)
end

function room_to_string(is_wall, is_lobstacle, is_robstacle, pos, part2)
    str = fill('.', size(is_wall))
    str[is_wall] .= '#'
    if !part2
        str[is_lobstacle] .= 'O'
    else
        str[is_lobstacle] .= '['
        str[is_robstacle] .= ']'
    end
    str[pos...] = '@'
    return arr2str(str)
end

function sum_inds(lobstacles)
    Is, Js = axes(lobstacles)
    i_gps = 100(Is .- 1)
    j_gps = Js .- 1
    sum(lobstacles .* (i_gps .+ j_gps'))
end

function solve(lines, part2)
    isplit = findfirst(x -> x == "", lines)
    directions = Dict('^' => [-1, 0], '>' => [0, 1], 'v' => [1, 0], '<' => [0, -1])
    moves = join(lines[isplit+1:end])
    
    replacements = ifelse(part2, ('#' => "##", 'O' => "[]", '.' => "..", '@' => "@."), ())
    room = permutedims(reduce(hcat, collect.(replace.(lines[1:isplit-1], replacements...))))

    is_wall = room .== '#'
    if !part2
        is_lobstacle = room .== 'O'
        is_robstacle = is_lobstacle
    else
        is_lobstacle = room .== '['
        is_robstacle = room .== ']'
    end
    pos = collect(findfirst(room .== '@').I)
    @debug "Initial state:\n" * room_to_string(is_wall, is_lobstacle, is_robstacle, pos, part2)

    nb_lobstacles = sum(is_lobstacle)
    nb_robstacles = sum(is_robstacle)
    for (i, char_move) in enumerate(moves)
        lobstacles_to_move = Set{NTuple{2, Int64}}()
        robstacles_to_move = Set{NTuple{2, Int64}}()
        move = directions[char_move]
        can_move = can_step!(lobstacles_to_move, robstacles_to_move, is_wall, is_lobstacle, is_robstacle, pos, move, part2)
        if can_move
            pos .+= move
            for (obs_to_move, is_obs) in ((lobstacles_to_move, is_lobstacle), (robstacles_to_move, is_robstacle))
                for obstacle_pos in obs_to_move is_obs[obstacle_pos...] = false end
                for obstacle_pos in obs_to_move is_obs[(obstacle_pos .+ move)...] = true end
            end
        end
    
        if Logging.min_enabled_level(current_logger()) <= Logging.Debug
            @debug "$i, Move $char_move:\n" * "can_move=$can_move\nnew_pos=$pos\nLobstacles to move: " * join(lobstacles_to_move, ", ") * "\nRobstacles to move: " * join(robstacles_to_move, ", ") * "\n" * room_to_string(is_wall, is_lobstacle, is_robstacle, pos, part2)
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
    sol1 = solve(lines, false)
    sol2 = solve(lines, true)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test15a.txt")))[1] == 2028
@test solve(readlines(joinpath(@__DIR__, "../data/test15b.txt"))) == (10092, 9021)
@time solve(readlines(joinpath(@__DIR__, "../data/val15.txt")))
