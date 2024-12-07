using Test

function check(goal, numbers, operators, val, i)
    if val > goal
        return false
    elseif i == length(numbers)
        return goal == val
    end
    return any(check(goal, numbers, operators, op(val, numbers[i+1]), i+1) for op in operators)
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
