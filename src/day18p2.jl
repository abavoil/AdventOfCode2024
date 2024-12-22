using Test

function unvisited_neighbors(unvisited, node)
    neighboors = [node .+ offset for offset in ((-1, 0), (1, 0), (0, -1), (0, 1))]
    return [n for n in neighboors if checkbounds(Bool, unvisited, n...) && unvisited[n...]]
end

max_dist_from_edge = 6
nb_fallen_bytes = 12

max_dist_from_edge = 70
nb_fallen_bytes = 1024

lines = readlines(joinpath(@__DIR__, "../data/test18.txt"))
bytes = map(l -> Tuple(1 .+ parse.(Int, split(l, ","))), lines)

width = max_dist_from_edge + 1
start = (1, 1)
goal = (width, width)

unvisited = trues(width, width)
dist = fill(typemax(Int), width, width)
dist[start...] = 0


local sol1, sol2
for (i, new_byte) in enumerate(bytes)
    unvisited[dist .>= dist[new_byte...]] .= true
    unvisited[new_byte...] = false
    dist[dist .> dist[new_byte...]] .= typemax(Int)

    while unvisited[goal...]
        node = argmin(ij -> dist[ij], filter(ij -> unvisited[ij], CartesianIndices(unvisited))).I
        if isnothing(node) break end  # no node available
        for neighbor in unvisited_neighbors(unvisited, node)
            dist[neighbor...] = min(dist[neighbor...], dist[node...] + 1)
        end
        unvisited[node...] = false
    end

    @show i, dist[goal...]
    if i == nb_fallen_bytes
        sol1 = dist[goal...]
    end
    if unvisited[goal...] 
        sol2 = i
    end
end