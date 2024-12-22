using StrFormat

include("utils.jl")

const infty = typemax(Int) ÷ 2


lines = readlines(joinpath(@__DIR__, "../data/test20.txt"))

mat = permutedims(reduce(hcat, collect.(lines)))
iswall = mat .== '#'
start = findfirst(mat .== 'S').I
goal = findfirst(mat .== 'E').I
directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
neighbors(pos, iswall, directions) = filter(x -> !iswall[x...], [pos .+ offset for offset in directions])

unvisited = Set([node.I for node in findall(.!iswall)])
dist = Dict(node => infty for node in unvisited)
dist[start] = 0

n = 0
while !isempty(unvisited)
    curr = argmin(x -> dist[x], unvisited)
    delete!(unvisited, curr)
    for next in neighbors(curr, iswall, directions)
        n += 1
        if dist[next] > dist[curr] + 1
            dist[next] = dist[curr] + 1
        end
    end
end

dist_mat = [get(dist, (x, y), infty) for x in 1:size(mat, 1), y in 1:size(mat, 2)]
println(arr2str((x -> ifelse(x == infty, " ##", f"\%3d(x)")).(dist_mat)))

time_saves = Dict{Int, Int}()
max_cheat = 2
for start_pos in getfield.(findall(iswall), :I)
    dist_to_start = infty
    for dir in directions
        entry = start_pos .- dir
        if !checkbounds(Bool, iswall, entry...) || iswall[entry...] continue end
        dist_to_start = min(dist_to_start, dist[entry...] + 1)
    end
    unvisited = Set([start_pos .+ (i, j) for i=-max_cheat:max_cheat, j=-max_cheat:max_cheat if checkbounds(Bool, iswall, start_pos .+ (i, j))])
    @show (start_pos), dist_to_start
    start_dist = 1 + get(dist, start_pos, infty) 
end

time_saves = Dict{Int, Int}
start_pos = first(getfield.(findall(iswall), :I))
# dist_to_start = 1 + minimum(dist[start_pos .+ dir] for dir in directions)
# if dist_to_start >= infty continue end  # not accessible
# dijkstra distances, revenir en arrière
# ajouter temps gagné sur tout le rectangle