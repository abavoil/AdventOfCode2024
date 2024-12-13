using Test
using Logging

function parse_machine(machine)
    pattern = r"Button A: X\+(\d+), Y\+(\d+)\nButton B: X\+(\d+), Y\+(\d+)\nPrize: X=(\d+), Y=(\d+)"
    return parse.(Int, match(pattern, machine).captures)
end

function solve_machine(a, b, c, d, x, y)
    det = a*d - b*c
    pushesA, remA = divrem(d * x - c * y, det)
    pushesB, remB = divrem(-b * x + a * y, det)
    tokens1 = ifelse(remA + remB == 0, 3*pushesA + pushesB, 0)
    
    x += 10000000000000
    y += 10000000000000
    pushesA, remA = divrem(d * x - c * y, det)
    pushesB, remB = divrem(-b * x + a * y, det)
    tokens2 = ifelse(remA + remB == 0, 3*pushesA + pushesB, 0)
    
    return tokens1, tokens2
end

function solve(io)
    nb_tokens = [0, 0]
    while !eof(io)
        machine = join((readline(io) for _ in 1:3), "\n")
        readline(io)
        nb_tokens .+= solve_machine(parse_machine(machine)...)
    end
    sol1, sol2 = nb_tokens
    return sol1, sol2
end

@test open(solve, joinpath(@__DIR__, "../data/test13.txt"), "r")[1] == 480
@time open(solve, joinpath(@__DIR__, "../data/val13.txt"), "r")

# Hypothèses sur les inputs :
# - A et B ne sont pas colinéaires
# - X = a*A + b*B avec a, b ∈ R_+
# Donc pas besoin de tester si det < 0
# ni si un des nombres 


function solve_readlines(io)
    lines = readlines(io)
    machines = reshape(lines[.!((1:end) .% 4 .== 0)], 3, :)
    
    nb_tokens = [0, 0]
    for col in eachcol(machines)
        machine = join(col, "\n")
        nb_tokens .+= solve_machine(parse_machine(machine)...)
    end
    sol1, sol2 = nb_tokens
    return sol1, sol2
end


function solve_readlines_array(io)
    lines = readlines(io)
    machines = join.(eachcol(reshape(lines[.!((1:end) .% 4 .== 0)], 3, :)), '\n')
    inputs = [parse_machine(m) for m in machines]
    
    nb_tokens = [0, 0]
    for (a, b, c, d, x, y) in inputs
        nb_tokens .+= solve_machine(a, b, c, d, x, y)
    end
    sol1, sol2 = nb_tokens
    return sol1, sol2
end

"""Execute -> all give the same time..."""
function benchmarks()
    for f in (solve, solve_readlines, solve_readlines_array)
        @test open(f, joinpath(@__DIR__, "../data/test13.txt"), "r")[1] == 480
        @time for i in 1:1000 open(f, joinpath(@__DIR__, "../data/val13.txt"), "r") end
    end
end

benchmarks()
