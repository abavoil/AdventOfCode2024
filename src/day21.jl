#=
+---+---+---+           +---+---+           +---+---+
| 7 | 8 | 9 |           | ^ | A |           | ^ | A |
+---+---+---+       +---+---+---+       +---+---+---+
| 4 | 5 | 6 |       | < | v | > |       | < | v | > |
+---+---+---+       +---+---+---+       +---+---+---+
| 1 | 2 | 3 |
+---+---+---+
    | 0 | A |
    +---+---+

v<<A^>>AvA^Av<<A^>>AAv<A<A^>>AA<Av>AA^Av<A^>AA<A>Av<A<A^>>AAA<Av>A^A
<v<A>>^AvA^A<vA<AA>>^AAvA<^A>AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A
<A>Av<<AA>^AA>AvAA^A<vAAA>^A
^A<<^^A>>AvvvA
379A
^A^^<<A>>AvvvA
<A>A<AAv<<AA<<^AvAA^Av<AAA^A
v<<A^>>AvA^A

029A                <A^A>^^AvvvA
                    <A^A^>^AvvvA
                    <A^A^^>AvvvA

d(A, 0) + 1 + d(0, 2) + 1 + d(2, 9) + 1 + d(9, A) + 1
= 1+1 + 1+1 + 3+1 + 3+1
= 12

A
0   -> <A           -> v<<A>>^A     -> v<A<AA>>^AvAA^<A>A
2   -> ^A           -> <A>A         -> v<<A>>^AvA^A
9   -> >^^A         -> vA^<AA^A     -> v<A>^A<Av<A>>^AA<A>A
A   -> vvvA         -> v<AAA>^A     -> v<A<A>>^AAAvA^<A>A

1. parse the code into the 1st arrow code using vectors
2. parse the 1st arrow code using 5*5 text-based rules

(4, 2) - (4, 3)
(3, 2) - (4, 2)
(1, 3) - (3, 2)
(4, 3) - (1, 3)
>^, ^<, v<, >v
=#


using Test

lines = readlines(joinpath(@__DIR__, "../data/test21.txt"))

digicode = Dict(c => CartesianIndices((4, 3))[i].I for (i, c) in enumerate("741.8520963A"))
arrowcode = Dict(c => CartesianIndices((2, 3))[i].I for (i, c) in enumerate(".<^vA>"))
delete!(digicode, '.')
delete!(arrowcode, '.')


dirs = ("^v", "<>")
mem = Dict{Tuple{Char, Char, Int}, String}()
for keyboard in (digicode, arrowcode)
    for (from_c, from_pos) in keyboard, (to_c, to_pos) in keyboard
        Δ = to_pos .- from_pos
        s = join(getindex.(dirs, 1 .+ (Δ .> 0)) .^ abs.(Δ), "") * "A"
        mem[from_c, to_c, 1] = join(getindex.(dirs, 1 .+ (Δ .> 0)) .^ abs.(Δ), "") * "A"
    end
end
# mem has length 145 because A->A is added twice

s = 0
for code in lines
    code_ = code
    for depth in 1:3
        commands = Array{String}(undef, length(code))
        for i in eachindex(code)
            from = get(code, prevind(code, i), 'A')
            to = code[i]
            commands[i] = mem[from, to, 1]
        end
        code = join(commands)
    end
    s += parse(Int, code_[1:end-1]) * length(code)
    println("(", length(code), ") ", code_, ": ", code)
end


if depth == 1 digicode[to] - digicode[from]
mem[from, to, depth]

<v<A>>^A<vA<A>>^AAvAA<^A>A<v<A>>^AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A