using Test
    
function nb_ways(mem, d, patterns)
    if length(d) == 0 return 1 end
    if haskey(mem, d) return mem[d] end
    retval = 0
    for p in patterns
        if startswith(d, p)
            retval += sum(nb_ways(mem, d[length(p)+1:end], patterns))
        end
    end
    mem[d] = retval
    return retval
end
nb_ways(d, patterns) = nb_ways(Dict{String, Int}(), d, patterns)

function solve(lines)
    patterns = split(lines[1], ", ")
    designs = lines[3:end]
    
    re = Regex("^(" * join(patterns, "|") * raw")*$")
    sol1 = sum(occursin(re, d) for d in designs)
    sol2 = sum(nb_ways(d, patterns) for d in designs)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test19.txt"))) == (6, 16)
@time solve(readlines(joinpath(@__DIR__, "../data/val19.txt")))