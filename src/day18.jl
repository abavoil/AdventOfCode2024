using Test

function unvisited_neighbors(unvisited, node)
    neighboors = [node .+ offset for offset in ((-1, 0), (1, 0), (0, -1), (0, 1))]
    return [n for n in neighboors if checkbounds(Bool, unvisited, n...) && unvisited[n...]]
end

max_dist_from_edge = 6
nb_bytes = 12

max_dist_from_edge = 70
nb_bytes = 1024

lines = readlines(joinpath(@__DIR__, "../data/val18.txt"))
bytes = map(l -> Tuple(1 .+ parse.(Int, split(l, ","))), lines)[1:nb_bytes]

width = max_dist_from_edge + 1
start = (1, 1)
goal = (width, width)

unvisited = trues(width, width)
foreach(bytes) do byte unvisited[byte...] = false end
dist = fill(typemax(Int), width, width)
dist[start...] = 0

while unvisited[goal...]
    node = argmin(ij -> dist[ij], filter(ij -> unvisited[ij], CartesianIndices(unvisited))).I
    for neighbor in unvisited_neighbors(unvisited, node)
        dist[neighbor...] = min(dist[neighbor...], dist[node...] + 1)
    end
    unvisited[node...] = false
end
dist
