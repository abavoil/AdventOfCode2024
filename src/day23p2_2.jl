# map each node to a number by reading it in base 26, with a=1,...,z=26
# Try DFS again, why is mine so slow ???

# cf for both points: https://github.com/goggle/AdventOfCode2024.jl/blob/main/src/day23.jl

using Test

to_int(computer) = 26 * (computer[1] - 'a') + computer[2] - 'a' + 1
to_str(n) = (((n - 1) ÷ 26) % 26 + 'a') * ((n -1) % 26 + 'a')
@test to_str(to_int("rx")) == "rx"

#=
Given a clique and a list of candidates
    - if current_clique is bigger than max_clique, update max_clique
    - for each candidate
        - if any member of the clique is not linked to the candidate, continue
        - add the candidate to the visited list
        - recursive call for clique | candidate, links[candidate] & ~visited
=#
function find_max_clique3(max_clique, curr_clique, candidates, links)
    # @show findall(curr_clique)
    if sum(curr_clique) > sum(max_clique)
        max_clique .= curr_clique
    end
    if !any(candidates) return end  # no more candidates
    for candidate in axes(candidates, 1)
        if !candidates[candidate] || any(curr_clique .& .!links[candidate]) continue end
        curr_clique[candidate] = true
        candidates[candidate] = false
        find_max_clique3(max_clique, curr_clique, candidates, links)
        # every case with this candidate has been treated, so do not make it a candidate again !
        candidates[candidate] = true
    end
end

function sol2()
    N = 26^2

    lines = readlines(joinpath(@__DIR__, "../data/val23.txt"))
    links = [falses(N) for _ in 1:N]
    for l in lines
        n1, n2 = to_int(l[1:2]), to_int(l[4:5])
        links[n1][n2] = true
        links[n2][n1] = true
    end

    curr_clique = falses(N)
    max_clique = falses(N)
    for seed in axes(links, 1)
        if !any(links[seed]) continue end
        curr_clique .= false
        curr_clique[seed] = true
        find_max_clique3(max_clique, curr_clique, links[seed], links)
    end
    join(sort(to_str.(findall(max_clique))), ',')
end

@time sol2()