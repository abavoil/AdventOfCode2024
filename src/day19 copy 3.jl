lines = readlines(joinpath(@__DIR__, "../data/test19.txt"))

patterns = split(lines[1], ", ")
designs = lines[3:end]

mem = Dict{String, Int}()

function nb_combinations(design, mem)
    if haskey(mem, design) return mem[design] end
    s = 0
    for i in 2:length(design) - 1
        if (s1 = design[1:i]) in patterns
            s2 = design[i+1:end]
            n = nb_combinations(s1, mem) * nb_combinations(s2, mem)
            @show s1, s2
            s += n
        end
    end
    return mem[design] = s
end

mem = Dict((patterns .=> 1)...)
nb_combinations(designs[6], mem)

function nb_combinations(design, patterns)
    if design == "" return 1 end
    for i = 2:length(design) - 1
        if (s1 = design[1:i]) in patterns
            s2 = design[i+1:end]
            return nb_combinations(s1, patterns) * nb_combinations(s2, patterns)
        end
    end
end

nb_combinations(designs[6], patterns)