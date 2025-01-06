#= TODO: A-star + dichotomy =#

CI = CartesianIndex

using Test

lines = readlines(joinpath(@__DIR__, "../data/val18.txt"))
bytes = map(l -> CI(Tuple(1 .+ parse.(Int, split(l, ",")))), lines)
nbytes = length(bytes)


size_ = 6 + 1
size_ = 70 + 1
labels = zeros(Int16, size_, size_, 1)

neighbour_offsets = [CI(i, j) for i in -1:1, j in -1:1 if (i, j) != (0, 0)]
for (ibyte, byte) in enumerate(bytes)
    label = ifelse(byte[1] == size_ || byte[2] == 1, nbytes, ibyte)
    neighbours = filter(x -> checkbounds(Bool, labels, x), byte .+ neighbour_offsets)
    neighbour_labels = filter(x -> x > 0, labels[neighbours])
    label = maximum(neighbour_labels; init=label)
    labels[byte] = label
    labels[any(labels[:,:,:] .== reshape(neighbour_labels, 1, 1, :); dims=3)] .= label
    if any(labels[1, :] .== nbytes) || any(labels[:, size_] .== nbytes)
        println(join(byte.I .- 1, ','))
        break
    end
end
