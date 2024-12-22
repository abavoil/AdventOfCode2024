lines = readlines(joinpath(@__DIR__, "../data/test19.txt"))

patterns = split(lines[1], ", ")
designs = lines[3:end]

re = Regex("^(" * join(patterns, "|") * raw")*$")
println(re)
println.(designs);
sum(occursin(re, d) for d in designs)


function nb_ways(d, mem)
    println(d)
    return get!(mem, d) do
        ss1, ss2 = d[1:i], d[i+1:end]
        @info ss1, ss2
        sum(nb_ways(d[1:i], mem) * nb_ways(d[i+1:end], mem) for i in 1:length(d) - 1; init=0)
    end
end


# 143244302
# 3093746573775
mem = Dict(p => 1 for p in patterns)
sum(nb_ways(d, mem) for d in designs)
mem

mem = Dict(p => 1 for p in patterns)
nb_ways("brwrr", mem)
mem

lt(s1, s2) = length(s1) < length(s2) || (length(s1) == length(s2) && s1 < s2)

function nb_ways(d, mem)
    (;start, stop) = searchsorted(getindex.(mem, 1), d; lt=lt, rev=true)
    if start == stop return mem[start][2] end
    for (pat, n_pat) in mem
        if startswith(d, pat)
            n_d =  n_pat * nb_ways(d[length(pat)+1:end], mem)
            (; start) = searchsorted(getindex.(mem, 1), d; lt=lt, rev=true)
            insert!(mem, start, (d, n_d))
            return n_d
        end
    end
    return 1
end

mem = [(p, 1) for p in patterns]
d = designs[1]
nb_ways(d, mem)