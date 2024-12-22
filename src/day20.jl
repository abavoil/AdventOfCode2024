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
for start_pos in getfield.(findall(iswall), :I)
    for dir in directions
        entry = start_pos .- dir
        if !checkbounds(Bool, iswall, entry...) || iswall[entry...] continue end
        end_pos = start_pos .+ dir
        time_save = dist[entry...] - 2 - minimum(get(dist, start_pos .+ dir, infty) for dir in directions)
        @show time_save
        if time_save > 0
            time_saves[time_save] = 1 + get!(time_saves, time_save, 0)
            # improvements[improvement] = (start_pos..., end_pos...) get!(improvements, improvement, [])
        end
    end
end
println.(collect(sort(time_saves)));
sum(v for (k, v) in time_saves if k >= 100; init=0)