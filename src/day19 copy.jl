lines = readlines(joinpath(@__DIR__, "../data/test19.txt"))

patterns = split(lines[1], ", ")
designs = lines[3:end]

re = Regex("^(" * join(patterns, "|") * raw")*$")
println(re)
println.(designs);
sum(occursin(re, d) for d in designs)


function nb_ways(d, patterns)
    retval = 1
    for (p, n) in mem
        if startswith(d, p)
            split_n = n * nb_ways(d[length(p)+1:end], patterns)
            retval += split_n
            push!(mem, searchsortedfirst(mem, (p, d), by = x -> length(x[1])), d)
        end
    end
    return retval
end


# function nb_ways(d, patterns)
#     retval = 0
#     for known_p1 in mem
#         for known_p2 in mem
#             p1p2 = known_p1 .* known_p2
#             if startswith(d, p1p2[1])
#                 push!(mem, searchsortedfirst(mem, p1p2[1], by = x -> length(x[1])), p1p2[2])
#                 retval += n * nb_ways(d[length(known_p1[1]) + length(known_p2[1]) + 1:end], patterns)
#             end
#         end
#     end
#     return retval
# end

# 143244302
# 3093746573775
mem = [p => 1 for p in patterns]
s = 0
for d in designs
    s += nb_ways(d, patterns)
    @show nb_ways(d, patterns)
end
s

@time sum(nb_ways(d, patterns) for d in designs)

mem
d = first(designs)
nb_ways(d, patterns)