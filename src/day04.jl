using Test

function count_kernels(mat, kernels)
    count = 0
    for kernel in kernels
        bitkernel = kernel .> 0
        for i in 1:(size(mat, 1) - size(kernel, 1) + 1)
            for j in 1:(size(mat, 2) - size(kernel, 2) + 1)
                loc_mat = mat[i:i+size(kernel, 1)-1, j:j+size(kernel, 2)-1]
                if all(.!bitkernel .|| (loc_mat .== kernel))
                    count += 1
                end
            end
        end
    end
    return count
end

function solve(lines::Vector{String})
    lines2mat(lines) = Int64.(permutedims(reduce(hcat, collect.(lines)))) .- Int64('A') .+ 1

    mat = lines2mat(lines)
    kernel10 = lines2mat(["XMAS"])       # >
    kernel11 = permutedims(kernel10)     # v
    kernel12 = reverse(kernel10)         # <
    kernel13 = reverse(kernel11)         # ^
    kernel14 = diagm(kernel10[1, :])     # SE
    kernel15 = reverse(kernel14, dims=2) # SW
    kernel16 = reverse(kernel14)         # NW
    kernel17 = reverse(kernel16, dims=2) # NE
    kernels1 = [kernel10, kernel11, kernel12, kernel13, kernel14, kernel15, kernel16, kernel17]

    sol1 = count_kernels(mat, kernels1)

    kernel20 = lines2mat(["M.S", ".A.", "M.S"]) .|> x -> ifelse(x < 0, 0, x) # >
    kernel21 = permutedims(kernel20)                                         # v
    kernel22 = reverse(kernel20)                                             # <
    kernel23 = reverse(kernel21)                                             # ^
    kernels2 = [kernel20, kernel21, kernel22, kernel23]

    sol2 = count_kernels(mat, kernels2)
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test04.txt"))) == (18, 9)
solve(readlines(joinpath(@__DIR__, "../data/val04.txt")))

kernel10 = lines2mat(["M.S", ".A.", "M.S"]) .|> x -> ifelse(x < 0, 0, x) # >
kernel11 = permutedims(kernel10) # v
kernel12 = reverse(kernel10)     # <
kernel13 = reverse(kernel11)     # ^

