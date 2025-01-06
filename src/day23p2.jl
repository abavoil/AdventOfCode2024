# map each node to a number by reading it in base 26, with a=1,...,z=26
# Try DFS again, why is mine so slow ???

# cf for both points: https://github.com/goggle/AdventOfCode2024.jl/blob/main/src/day23.jl


lines = readlines(joinpath(@__DIR__, "../data/val23.txt"))
links = Dict{String, Set{String}}()
for l in lines
    n1, n2 = l[1:2], l[4:5]
    push!(get!(links, n1, Set{String}()), n2)
    push!(get!(links, n2, Set{String}()), n1)
end

function BronKerbosch(links, max_clique_, R, P, X)
    if length(P) == 0 && length(X) == 0
        if length(R) > length(only(max_clique_))
            max_clique_[1] = R
        end
    end
    for v in P
        BronKerbosch(links, max_clique_, R ∪ Set((v,)), P ∩ links[v], X ∩ links[v])
        setdiff!(P, (v,))
        union!(X, (v,))
    end
end

function find_max_clique(links, unselected, selected)
    max_clique = selected
    for node in unselected
        if issubset(selected, links[node])
            clique = find_max_clique(links, setdiff(unselected, (node,)), selected ∪ Set((node,)))
            if length(clique) > length(max_clique)
                max_clique = clique
            end
        end
    end
    return max_clique
end

function find_max_clique2(links, candidates, selected)
    max_clique = selected
    while !isempty(candidates)
        candidate = pop!(candidates)
        if issubset(selected, links[candidate])
            push!(selected, candidate)
            clique = find_max_clique(links, candidates, selected)
            if length(clique) > length(max_clique)
                max_clique = clique
            end
            delete!(selected, candidate)
        end
    end
    return max_clique
end


max_clique_ = [Set{String}()]
V = Set(keys(links));
@time BronKerbosch(links, max_clique_, empty(V), V, empty(V));
println(join(sort(collect(only(max_clique_))), ","))



V = Set(keys(links));
@time find_max_clique(links, V, empty(V));
V = Set(keys(links));
@time find_max_clique2(links, V, empty(V));


using Test

to_int(computer) = 26 * (computer[1] - 'a') + computer[2] - 'a' + 1
to_str(n) = (((n - 1) ÷ 26) % 26 + 'a') * ((n -1) % 26 + 'a')
@test to_str(to_int("rx")) == "rx"

N = 26^2
str_arr = [to_str(i) for i in 1:N]

lines = readlines(joinpath(@__DIR__, "../data/val23.txt"))

for l in lines
    n1, n2 = l[1:2], l[4:5]
    push!(get!(links, n1, Set{String}()), n2)
    push!(get!(links, n2, Set{String}()), n1)
end

function find_max_clique3(visited, current_clique, links)
    for candidate in keys(links)
        if visited[candidate] && (.!current_clique .| links[candidate]) continue end
        unvisited[candidate] = true
    end
end

for starting_node in keys(links)
    visited = falses(N)

end
