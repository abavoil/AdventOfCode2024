using Test

function check(goal, numbers, operators, val, i)
    if val > goal
        return false
    elseif i == length(numbers)
        return goal == val
    end
    next_i = i + 1
    next_vals = (op(val, numbers[next_i]) for op in operators)
    return any(check(goal, numbers, operators, next_val, next_i) for next_val in next_vals)
end
function check(equation, operators) check(equation[1], equation[2], operators, equation[2][1], 1) end

function concat(a, b)
    return a * 10^(1 + floor(Int64, log10(b))) + b
end

function solve(lines::Vector{String})
    equations = [(parse(Int64, goal), parse.(Int64, split(numbers, " "))) for (goal, numbers) in split.(lines, ": ")]
    
    sol1 = sum(e[1] for e in equations if check(e, [*, +]))
    sol2 = sum(e[1] for e in equations if check(e, [*, +, concat]))
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test07.txt"))) == (3749, 11387)
@time solve(readlines(joinpath(@__DIR__, "../data/val07.txt")))
@code_warntype solve(readlines(joinpath(@__DIR__, "../data/val07.txt")))