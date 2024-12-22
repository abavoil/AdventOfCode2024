lines = readlines(joinpath(@__DIR__, "../data/test19.txt"))

patterns = split(lines[1], ", ")
designs = lines[3:end]

re = Regex("^(" * join(patterns, "|") * raw")*$")
println(re)
println.(designs);
sum(occursin(re, d) for d in designs)


function nb_ways(d, patterns)
    if length(d) == 0 return 1 end
    for known_p in mem
        if startswith(d, known_p[1])
            return known_p[2]
        end
    end
    
    retval = 0
    for p in patterns
        if startswith(d, p)
            retval += sum(nb_ways(d[length(p)+1:end], patterns))
        end
    end
    @show d, retval
    insert!(mem, searchsortedfirst(mem, d; by = x -> length(x[1])), (d, retval))
    return retval
end

# 143244302
# 3093746573775
mem = Tuple{String, Int64}[]
s = 0
for d in designs
    s += nb_ways(d, patterns)
end
s

@time sum(nb_ways(d, patterns) for d in designs)

mem
d = first(designs)
nb_ways(d, patterns)