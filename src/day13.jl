# Hypothèses sur les inputs :
# - A et B ne sont pas colinéaires
# - X = a*A + b*B avec a, b ∈ R_+
# Donc pas besoin de tester si det < 0
# ni si un des nombres 

using Test
using Logging

function parse_next(io)
    s = join((readline(io) for _ in 1:3), "\n")
    readline(io)
    pattern = r"Button A: X\+(\d+), Y\+(\d+)\nButton B: X\+(\d+), Y\+(\d+)\nPrize: X=(\d+), Y=(\d+)"
    return parse.(Int, match(pattern, s).captures)
end

function solve(io)
    nb_tokens = [0, 0]
    while !eof(io)
        (a, b, c, d, x, y) = parse_next(io)
        det = a*d - b*c
        # if det == 0, x == n*a != m*b ou x == n*a == m*b, but A and B not colinear
        pushesA, remA = divrem(d * x - c * y, det)
        pushesB, remB = divrem(-b * x + a * y, det)
        if remA + remB == 0  # and min(pushesA, pushesB) > 0
            nb_tokens[1] += 3*pushesA + pushesB
        end
        x += 10000000000000
        y += 10000000000000
        pushesA, remA = divrem(d * x - c * y, det)
        pushesB, remB = divrem(-b * x + a * y, det)
        if remA + remB == 0  # and min(pushesA, pushesB) > 0, but no negative tokens
            nb_tokens[2] += 3*pushesA + pushesB
        end
    end
    sol1, sol2 = nb_tokens
    return sol1, sol2
end

# A solution never involves a negative number of tokens
@test open(solve, joinpath(@__DIR__, "../data/test13.txt"), "r")[1] == 480
@time open(solve, joinpath(@__DIR__, "../data/val13.txt"), "r")
