lines = readlines(joinpath(@__DIR__, "../data/val22.txt"))

T = UInt32
T = Int64

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

# Cache: n -> (iterations, n^iterations)
# update: cache[n] = (c_iter, next_n), if interations > c_iter, cache[n] = interations, next_n^(iterations - c_iter)
function lookup(modlist, n, iterations)
    if iterations == 0
        return n
    else
        return lookup(modlist, modlist[1 + n], iterations-1)
    end
end

s = 0
for line in lines
    s += lookup(modlist, parse(T, line), 2000)
end
s

invmodlist = similar(modlist)
setindex!.(Ref(invmodlist), T(0):T(MOD_MINUS_1), 1 .+ modlist);
Int(invmodlist[1 + modlist[1 + n]])

# Dict{pattern -> List{Gain}}
N = 2000
pattern_length = 4

nb_bananas = Dict{NTuple{4, T}, Vector{T}}()

for buyer in eachindex(lines)
    initial_secret = parse(T, lines[buyer])
    secrets = Vector{T}(undef, N)
    secrets[1] = initial_secret
    for i in 2:N
        secrets[i] = modlist[1 + secrets[i-1]]
    end

    prices = secrets .% 10
    changes = diff(prices)

    for buy_time in pattern_length+1:N
        pattern = @view changes[buy_time - pattern_length:buy_time-1]
        pattern_bananas = get!(nb_bananas, Tuple(pattern), zeros(T, axes(lines)))
        if pattern_bananas[buyer] == 0
            pattern_bananas[buyer] = prices[buy_time]
        end
    end
end
nb_bananas

total_bananas = [(pattern, sum(pattern_bananas)) for (pattern, pattern_bananas) in nb_bananas]
argmax(((pattern, bananas),) -> bananas, total_bananas)[2]
