lines = readlines(joinpath(@__DIR__, "../data/val24.txt"))
i_split = findfirst(x -> x == "", lines)

input_pattern = r"(.{3}): (\d)"
matches = match.(input_pattern, lines[1:i_split-1])
inputs = Dict(match[1] => parse(Bool, match[2]) for match in matches)
operators = Dict("AND" => &, "OR" => |, "XOR" => ⊻)

operations = sort(Dict{String, NTuple{3, String}}())
operation_pattern = r"(.{3}) (.{2,3}) (.{3}) -> (.{3})"
for line in lines[i_split+1:end]
    var1, op, var2, out = match(operation_pattern, line).captures
    operations[out] = (op, var1, var2)
end

function evaluate(results, operations, operators, var)
    return get!(results, var) do
        op, var1, var2 = operations[var]
        operators[op](evaluate(results, operations, operators, var1), evaluate(results, operations, operators, var2))
    end
end

function compute_xyzsbits(operations, operators, inputs)
    results = copy(inputs)
    Zs = sort([x for x in keys(operations) if x[1] == 'z'])
    zbits = evaluate.(Ref(results), Ref(operations), Ref(operators), Zs)
    
    Xs = sort([x for x in keys(inputs) if x[1] == 'x'])
    xbits = getindex.(Ref(inputs), Xs)
    x = sum(2 .^ (0:length(Xs)-1) .* xbits)

    Ys = sort([x for x in keys(inputs) if x[1] == 'y'])
    ybits = getindex.(Ref(inputs), Ys)
    y = sum(2 .^ (0:length(Ys)-1) .* ybits)
    
    sbits = reverse(parse.(Bool, collect(bitstring(x + y))))[1:length(Zs)]
    
    return xbits, ybits, zbits, sbits
end

xbits, ybits, zbits, sbits = compute_xyzsbits(operations, operators, inputs)

i = findfirst(sbits .⊻ zbits)

# z(i-1) is correct hence c(i-2) is correct
# c(i-1) might be wrong. Is it ?

begin
operations1 = copy(operations)
operations1["z09"], operations1["cwt"] = operations1["cwt"], operations1["z09"]  # i = 10, z09

inputs1 = Dict(k => true for k in keys(inputs))
inputsr = Dict(k => rand(Bool) for k in keys(inputs))
xbits1, ybits1, zbits1, sbits1 = compute_xyzsbits(operations1, operators, inputsr)

i1 = findfirst(sbits1 .⊻ zbits1)
# 6 21 38

operations2 = copy(operations1)
operations2["jmv"], operations2["css"] = operations2["css"], operations2["jmv"]

xbits2, ybits2, zbits2, sbits2 = compute_xyzsbits(operations2, operators, inputsr)

i2 = findfirst(sbits2 .⊻ zbits2)

operations3 = copy(operations2)
operations3["z37"], operations3["pqt"] = operations3["pqt"], operations3["z37"]

xbits3, ybits3, zbits3, sbits3 = compute_xyzsbits(operations3, operators, inputsr)

i3 = findfirst(sbits3 .⊻ zbits3)

operations4 = copy(operations3)
operations4["z05"], operations4["gdd"] = operations4["gdd"], operations4["z05"]

xbits4, ybits4, zbits4, sbits4 = compute_xyzsbits(operations4, operators, inputsr)

i4 = findfirst(sbits4 .⊻ zbits4)
end

# z09, cwt, jmv, css, z37, pqt, z05, gdd
# css,cwt,gdd,jmv,pqt,z05,z09,z37