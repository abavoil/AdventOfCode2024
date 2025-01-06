data = read(joinpath(@__DIR__, "../data/val25.txt"), String)
inputs = map(key_lock -> permutedims(reduce(hcat, map(l -> collect(l) .== '#', split(key_lock, "\n")))), split(data, "\n\n"))
i_split = findfirst(keylock -> keylock[1] == false, inputs)

locks = filter(keylock -> !keylock[1], inputs)
keys_ = filter(keylock -> keylock[1], inputs)

sum(!any(key .& lock) for key in keys_, lock in locks)
