lines = readlines(joinpath(@__DIR__, "../data/val24.txt"))
i_split = findfirst(x -> x == "", lines)

input_pattern = r"(.{3}): (\d)"
matches = match.(input_pattern, lines[1:i_split-1])
results = Dict(match[1] => parse(Int, match[2]) for match in matches)
operators = Dict("AND" => &, "OR" => |, "XOR" => ⊻)

operations = sort(Dict{String, NTuple{3, String}}())
operation_pattern = r"(.{3}) (.{2,3}) (.{3}) -> (.{3})"
for line in lines[i_split+1:end]
    var1, op, var2, out = match(operation_pattern, line).captures
    operations[out] = (op, var1, var2)
end
operations
sort!(operations)

function evaluate(var)
    return get!(results, var) do
        op, var1, var2 = operations[var]
        operators[op](evaluate(var1), evaluate(var2))
    end
end

Zs = sort([x for x in keys(operations) if x[1] == 'z'])
evaluate.(Zs)
sol1 = sum(2 .^ (0:length(Zs)-1) .* evaluate.(Zs))
