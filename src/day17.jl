import Base.string
using Logging

using StrFormat

include("utils.jl")

mutable struct Computer
    A::Int
    B::Int
    C::Int
    prog::Array{Int, 1}
    ptr::Int
    output::Array{Int, 1}
    Computer(A, B, C, prog) = new(A, B, C, prog, 0, [])

    function Computer(cpt, A)
        new(A, cpt.B, cpt.C, copy(cpt.prog), cpt.ptr, copy(cpt.output))
    end

    function Computer(str::String)
        pattern = r"Register A: (\d+)\nRegister B: (\d+)\nRegister C: (\d+)\n\nProgram: (.*)"
        matches = match(pattern, str).captures
        A, B, C = parse.(Int, matches[1:3])
        prog = parse.(Int, split(matches[4], ","))
        return Computer(A, B, C, prog)
    end
end

function string(cpt::Computer)
    return f"Register A: \(cpt.A)\nRegister B: \(cpt.B)\nRegister C: \(cpt.C)\n" * " "^(9+cpt.ptr) * "v\nProgram: " * join(cpt.prog, "") * "\nOutput:  " * join(cpt.output, "") * "\n"
end

function read_output(cpt::Computer)
    return join(cpt.output, ",")
end

function combo(cpt, operand)
    if 0 <= operand <= 3 return operand
    elseif operand == 4 return cpt.A
    elseif operand == 5 return cpt.B
    elseif operand == 6 return cpt.C
    end
    @warn "Reserved operand: $operand"
    return -1
end

function read_instr(cpt)
    if !checkbounds(Bool, cpt.prog, cpt.ptr + 1)
        return (-1, -1)
    end
    opcode = cpt.prog[cpt.ptr += 1]
    literal_operand = cpt.prog[cpt.ptr += 1]
    return opcode, literal_operand
end

function step(cpt)
    opcode, literal_operand = read_instr(cpt)
    execute_instr(cpt, Val(opcode), literal_operand)
    return opcode
end

function run(cpt)
    while step(cpt) >= 0 end
    return cpt
end

function is_self_replicating(cpt)
    while true
        opcode = step(cpt)
        if opcode == 5
            length(cpt.output) > length(cpt.prog) && return false
            last(cpt.output) != cpt.prog[length(cpt.output)] && return false
        end
        opcode == -1 && break
    end
    return cpt.output == cpt.prog
end

function find_self_replicating_A(cpt)
    # Ajouter une taille max d'output
    A = 1
    while true
        is_self_replicating(Computer(cpt, A)) && return A
        if A % 100000 == 0 @info f"Checked up to \%'d(A)" end
        A += 1
    end
end

# 2  1  7  1  4  5  0  3
# 4  1  5  5  0  5  3  0
begin
    function execute_instr(cpt, ::Val{-1}, literal_operand) nothing end
    function execute_instr(cpt, ::Val{0}, literal_operand) cpt.A = cpt.A >> combo(cpt, literal_operand) end
    function execute_instr(cpt, ::Val{1}, literal_operand) cpt.B = cpt.B ⊻ literal_operand end
    function execute_instr(cpt, ::Val{2}, literal_operand) cpt.B = combo(cpt, literal_operand) % 8 end
    function execute_instr(cpt, ::Val{3}, literal_operand) cpt.A > 0 && (cpt.ptr = literal_operand) end
    function execute_instr(cpt, ::Val{4}, literal_operand) cpt.B = cpt.B ⊻ cpt.C end
    function execute_instr(cpt, ::Val{5}, literal_operand) push!(cpt.output, combo(cpt, literal_operand) % 8) end
    function execute_instr(cpt, ::Val{6}, literal_operand) cpt.B = cpt.A >> combo(cpt, literal_operand) end
    function execute_instr(cpt, ::Val{7}, literal_operand) cpt.C = cpt.A >> combo(cpt, literal_operand) end
end
begin
    function test0()
        cpt = Computer(read(joinpath(@__DIR__, "../data/test17a.txt"), String))
        run(cpt)
        return read_output(cpt) == "4,6,3,5,6,3,5,2,1,0"
    end

    function test1()
        cpt = Computer(0, 0, 9, [2;6])
        step(cpt)
        return cpt.B == 1 
    end

    function test2()
        cpt = Computer(10, 0, 0, [5,0,5,1,5,4])
        run(cpt)
        return read_output(cpt) == "0,1,2"
    end

    function test3()
        cpt = Computer(2024, 0, 0, [0,1,5,4,3,0])
        run(cpt)
        return read_output(cpt) == "4,2,5,6,7,7,7,7,3,1,0" && cpt.A == 0
    end

    function test4()
        cpt = Computer(0, 29, 0, [1,7])
        step(cpt)
        return cpt.B == 26
    end

    function test5()
        cpt = Computer(0, 2024, 43690, [4,0])
        step(cpt)
        return cpt.B == 44354
    end

    function test6()
        cpt = Computer(read(joinpath(@__DIR__, "../data/test17b.txt"), String))
        return is_self_replicating(Computer(cpt, 117440))
    end

    function test7()
        return find_self_replicating_A(Computer(read(joinpath(@__DIR__, "../data/test17b.txt"), String))) == 117440
    end
end

@testset "day17" begin
    dblog = SimpleLogger(Logging.Debug)
    @test test0()
    @test test1()
    @test test2()
    @test test3()
    @test test4()
    @test test5()
    @test test6()
    @test test7()
end

@test read_output(run(Computer(read(joinpath(@__DIR__, "../data/test17a.txt"), String)))) == "4,6,3,5,6,3,5,2,1,0"
@time println(run(Computer(read(joinpath(@__DIR__, "../data/val17.txt"), String))))
@time find_self_replicating_A(Computer(read(joinpath(@__DIR__, "../data/test17b.txt"), String)))

# 2_300_000_000
# @time find_self_replicating_A(Computer(read(joinpath(@__DIR__, "../data/val17.txt"), String)))


cpt = Computer(read(joinpath(@__DIR__, "../data/val17.txt"), String))
is_self_replicating(Computer(cpt, 128evalpoly(8, reverse(cpt.prog))))


# 2 4 1 1 7 5 1 5 4 0 5 5 0 3 3 0
# 4   1   5   5   0   5   3   0


# function out(A)
#     B2 = (A % 8) ⊻ 1
#     out = ((B2 ⊻ 5) ⊻ (A >> B2)) % 8
# end

# B1 B2 C1 B3 B4
#  D  E  F  G  H
function next_output(A)
    D = A % 8
    E = D ⊻ 1
    F = A >> E
    G = E ⊻ 5
    H = G ⊻ F
    return H % 8
end


bitlength(x) = sizeof(x)<<3 - leading_zeros(x)

# On veut afficher 16 nombres, donc on a besoin de 16 itérations.

# Soit A(i) = Valeur de A après i itérations de la boucle : A(0) = A recherché
# Pour que le programme s'arrête, il faut que A(i=16) = 0
# Donc A(i=15) ∈ [1, 7] = [8^0, 8^1-1]
# Donc A(i=14) ∈ [8, 63] = [8^1, 8^2-1]
# Donc A(i) ∈ [8^(15-i), 8^(16-i)-1]
# Donc A(i=0) ∈ [8^15, 8^16-1] = [35184372088832, 281474976710655]


# (..a2a1a0 >> E = ...a(E+2)a(E+1)a(E)) ⊻ g(bitlength_G)...g2g1g0
# On calcule G ⊻ F. F est un décalage d'au plus bitlength_maxG bits vers la droite de A
# Donc les bits > maxE + bitlength_maxG de A n'intéragissent pas avec H
# Donc ils n'ont aucune influence sur le nombre en sortie
# Seul rem(A, 2^(maxE + bitlength_maxG)) = A & (1 + maxE + bitlength_maxG) importe
# donc on s'intéresse à out(A) pour A modulo 1<<(1 + maxE + bitlength_maxG)) = 2<<maxE<<bitlength_maxG

# D = A % 8, donc D ∈ 0:7
Ds = 0:7

Gs = @. (Ds ⊻ 1) ⊻ 5
maxG = maximum(Gs)
bitlength_maxG = bitlength(maxG)

Es = @. Ds ⊻ 1
maxE = maximum(Es)

N = 2<<maxE<<bitlength_maxG
A_modN = 0:N-1
outs = (local Es = @. (A_modN % 8) ⊻ 1; @. ((Es ⊻ 5) ⊻ (A_modN >> Es)) % 8)

# Soit n(i) = out(i) la sortie désirée dans la boucle i
# On cherche alors A(i-1) tel que f(A(i-1)) ≡ n(i) [N]
# Où f(A(i-1)) = out(A(i-1)) est la sortie si on a A(i-1) à l'itération précédente
# On sait de A(i-1) que A(i-1) ÷ 8 = A(i),
# Donc ∃k ∈ [0..A(i)-1] | A(i-1) = 8A(i) + k
# De plus, on est modulo N, donc k ∈ [0..N-1]
# Finalement, A(i-1) = 8A(i) + k avec k ∈ [0..min(N-1, 8A(i)-1)] à déterminer

nb_correct = 0
A = 0
wanted = cpt.prog
while true
    # if nb_correct > 5 break end
    cptA = Computer(cpt, A)
    run(cptA)
    if cptA.output == cpt.prog println("GOT IT"); break end
    curr_nb_correct = 0
    for (prog_val, out) in zip(reverse(cptA.prog), reverse(cptA.output))
        curr_nb_correct += prog_val == out
    end
    @info f"[A = \(A)]\n\{>20}(join(wanted, \"\"))\n\{>20}(join(cptA.output, \"\"))\n" * " "^(20 - nb_correct) * "^\nnb_correct = $nb_correct"
    if curr_nb_correct == length(wanted) break end
    for _ in nb_correct+1:curr_nb_correct
        A *= 8
    end
    nb_correct = curr_nb_correct
    A += 1
    if A > 8^16 println("A > 8^16"); break end
end
@test is_self_replicating(Computer(cpt, A))

# 164279033360034 too high


function try_recusrion()
    findall_out = Dict{Int, Array{Int, 1}}()
    for (k, out) in zip(A_modN, outs)
        Ks = get!(findall_out, out, [])
        push!(Ks, k)
    end
    @assert all(issorted.(values(findall_out)))

    function find_prevA(min_found, findall_out, A, i, prog)
        # Calculer tous les prevA qui donnent out == prog[i] et A == A
        if i >= 3 @show only(min_found), A, i end
        if A >= only(min_found) return typemax(Int) end
        if i == 0
            min_found[1] = min(min_found[1], A)
            return A
        end
        min_valid_prevA = typemax(Int)
        for (indk, k) in enumerate(findall_out[prog[i]])
            if indk > 1 &&k >= A break end
            min_valid_prevA = min(min_valid_prevA, find_prevA(min_found, findall_out, 8A + k, i-1, prog))
            # if k >= A break end  # break car les k sont ordonnées
        end
        return min_valid_prevA
    end

    min_found = [typemax(Int)]
    i = 16
    A = 0
    find_prevA(min_found, findall_out, 0, i, cpt.prog)
end


function try_forloop()
    first_out = Dict{Int, Int}()
    for (k, out) in zip(A_modN, outs)
        first_out[out] = min(k, get!(first_out, out, typemax(Int)))
    end

    wanted_out = [5]
    A = 0
    for out in reverse(wanted_out)
        k = first_out[out]
        A = 8A + k
    end

    cptA = Computer(cpt, A)
    run(cptA)
    println(string(cptA))
end
