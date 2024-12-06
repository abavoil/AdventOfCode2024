using Test

function solve(lines::Vector{String})
    i_split = findfirst(x -> x == "", lines)
    rules = map(x -> parse.(Int64, split(x, "|")), lines[1:i_split-1])
    lists = map(x -> parse.(Int64, split(x, ",")), lines[i_split+1:end])

    dict_rules = Set((rule[1], rule[2]) for rule in rules)
    
    lessthan(x, y) = (x, y) ∈ dict_rules
    
    sol1, sol2 = 0, 0
    for list in lists
        if issorted(list, lt=lessthan) 
            sol1 += list[(end+1) ÷ 2]
        else
            sol2 += sort(list, lt=lessthan)[(end+1) ÷ 2]
        end
    end
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test05.txt"))) == (143, 123)
@time solve(readlines(joinpath(@__DIR__, "../data/val05.txt")))

lines = readlines(joinpath(@__DIR__, "../data/test05.txt"))
