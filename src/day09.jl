using Test

function disp(blocks, isfree, istart, iend, jstart, jend)
    block_str = blocks .|> x -> x == -1 ? " " : string(x)
    pointer_str = ['.' for _ in blocks]
    pointer_str[istart] = 'a'
    pointer_str[iend] = 'b'
    pointer_str[jstart] = 'c'
    pointer_str[jend] = 'd'
    isfree_str = isfree .|> x -> x ? ' ' : 'X'
    println(join(block_str, ""), " ", join(pointer_str, ""), " ", join(isfree_str, ""))
end

function solve(lines::Vector{String})
    disk_map = parse.(Int64, collect(only(lines)))[1:end-(end+1)%2]
    
    n = sum(disk_map)
    isfree_ = trues(n)
    blocks_ = -ones(Int64, n)
    
    curr_ind = 1
    for (i, len) in enumerate(disk_map)
        inds = curr_ind:(curr_ind + len - 1)
        if i % 2 == 1
            isfree_[inds] .= false
            blocks_[inds] .= i ÷ 2
        end
        curr_ind += len
    end
    
    isfree = copy(isfree_)
    blocks = copy(blocks_)
    i = 1
    j = length(blocks)
    while i < j
        if !isfree[i] i += 1
        elseif isfree[j] j -= 1
        else
            isfree[i], isfree[j] = isfree[j], isfree[i]
            blocks[i], blocks[j] = blocks[j], blocks[i]
        end
    end
    sol1 = sum((0:n-1) .* blocks .* .!isfree)


    max_length = 9
    pos = 0
    mem = Tuple{Int64, Int64, Int64}[]  # [(pos, len, val)] sorted by pos
    holes = [Int64[] for hole_length in 1:max_length]  # [sorted [pos]], There is no hole bigger than 9 that can be used because no file is empty
    for (i, len) in enumerate(disk_map)
        isfile = i % 2 == 1
        val = ifelse(isfile, (i - 1) ÷ 2, -1)
        push!(mem, (pos, len, val))
        !isfile && len > 0 && push!(holes[len], pos)
        pos += len
    end
    push!.(holes, 10*length(disk_map))

    for file in reverse(copy(mem))
        pos_f, len_f, val = file
        if val < 0 continue end
    
        # find hole
        len_h = argmin(l -> first(holes[l]), len_f:max_length)
        pos_h = first(holes[len_h])
        if pos_h > pos_f continue end
        ind_h = searchsortedfirst(mem, pos_h; lt=(x, y) -> x[1] < y[1])
        ind_f = searchsortedlast(mem, pos_f; lt=(x, y) -> x[1] < y[1])  # only empty mem can have len 0, so last will always give a file
    
        # swap the file and hole
        mem[ind_h] = (pos_h, len_f, val)
        mem[ind_f] = (pos_f, len_f, -1)
        popfirst!(holes[len_h])
    
        # add the new hole if not length 0
        len_new_h = len_h - len_f
        if len_new_h > 0
            pos_new_h = pos_h + len_f
            insert!(mem, ind_h + 1, (pos_new_h, len_new_h, -1))
            insert!(holes[len_new_h], searchsortedfirst(holes[len_new_h], pos_new_h), pos_new_h)
        end
    end
    
    sol2 = sum(val * len * (2pos + len - 1) for (pos, len, val) in mem if val >= 0) ÷ 2
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test09.txt"))) == (1928, 2858)
@profview for i = 1:1000 solve(readlines(joinpath(@__DIR__, "../data/val09.txt"))) end

lines = readlines(joinpath(@__DIR__, "../data/test09.txt"))

disk_map = parse.(Int64, collect(only(lines)))[1:end-(end+1)%2]

nothing
# 00...111...2...333.44.5555.6666.777.888899
# 00992111777.44.333....5555.6666.....8888..

# list des files en ordre décroissant
# Dict(taille => array des indices des trous de cette taille par ordre croissant)
# Disgression des trous :
#   - si list, pas de recherche en log(n) mais en n
#   - si array, pas d'insertion en log(n) mais en n (mémoire)
#   - il faut un BinaryTree mais fleemme

# Pour chaque file dans files
# file de taille len_f
# trouver argmin des trous de taille >= len_f -> len_h
# bouger file
# si len_f < len_h  (il reste un plus petit trou)
# binarysearch_insert(Dict[len_h - len_f], file_i + len_f + 1
