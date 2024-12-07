using Test
import Base.Iterators: Stateful, popfirst!, peek

function solve(lines::Vector{String})
    str = join(lines, "")
    mul_re = r"mul\((\d{1,3}),(\d{1,3})\)"
    sol1 = sum(prod(parse.(Int64, m.captures)) for m in eachmatch(mul_re, str))


    do_inds = Stateful(m.offset for m in eachmatch(r"do\(\)", str))
    dont_inds = Stateful((m.offset for m in eachmatch(r"don't\(\)", str)))

    sol2 = 0
    enabled = true
    for m in eachmatch(mul_re, str)
        mul_ind = m.offset

        # -1 means nothing found since all indices are > 0
        last_do = -1
        while !isempty(do_inds) && peek(do_inds) < mul_ind
            last_do = popfirst!(do_inds)
        end
        
        last_dont = -1
        while !isempty(dont_inds) && peek(dont_inds) < mul_ind
            last_dont = popfirst!(dont_inds)
        end

        if !enabled && last_do > 0
            enabled = true
        elseif enabled && last_dont > 0
            enabled = false
        end

        if enabled
            sol2 += prod(parse.(Int64, m.captures))
        end
    end
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test03a.txt"))) == (161, 161)
@test solve(readlines(joinpath(@__DIR__, "../data/test03b.txt"))) == (161, 48)
@time solve(readlines(joinpath(@__DIR__, "../data/val03.txt")))
