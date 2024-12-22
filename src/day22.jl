lines = readlines(joinpath(@__DIR__, "../data/val22.txt"))

T = UInt32

const MOD_MINUS_1 = T(2^24-1)

function next(n, mod_minus_1=MOD_MINUS_1)
    n1 = (n<<6⊻n)&mod_minus_1
    n2 = (n1>>5⊻n1)&mod_minus_1
    n3 = (n2<<11⊻n2)&mod_minus_1
    return n3
end

# make 1 modlist for nb_iter = 2^[0:24]

modlist = next.(T(0):MOD_MINUS_1)
allunique(modlist)

function lookup(modlist, n, iterations)
    if iterations == 0
        return n
    else
        return lookup(modlist, modlist[begin + n], iterations-1)
    end
end

s = 0
for line in lines
    s += lookup(modlist, parse(Int, line), 2000)
end
s