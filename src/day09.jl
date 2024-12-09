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


    isfree = copy(isfree_)
    blocks = copy(blocks_)
    istart = iend = 1
    jstart = jend = n
    while jstart > 1
        # istart < iend else istart += 1
        # jstart < jend else jend -= 1 
        # istart..iend is free
        # jstart..jend is same file
        # iend - istart >= jend - jstart else jend = jstart - 1, jstart = jend, istart = 1, istart = 1
        # then swap

        if iend >= jstart
            # can't find room for this file
            jend = jstart - 1
            istart = iend = 1

        # Identify next file
        elseif jstart > jend jstart -= 1  # jstart < jend
        elseif isfree[jend] jend -= 1  # jend is not free
        elseif blocks[jstart - 1] == blocks[jend] jstart -= 1  # jstart..jend is same file

        # Identify next free block
        elseif istart > iend iend += 1  # istart < iend
        elseif !isfree[istart] istart += 1  # istart is free
        elseif isfree[iend + 1] iend += 1  # istart..iend is free

        # If possible, swap
        elseif iend - istart >= jend - jstart
            from = jstart:jend
            to = istart:istart + jend - jstart
            blocks[to] .= blocks[jstart]
            isfree[to] .= false
            isfree[from] .= true
            blocks[from] .= -1

            istart = iend = 1
            jstart = jend = jstart - 1
        
        # Start looking for a new block
        else
            istart = iend + 1
        end
        # disp(blocks, isfree, istart, iend, jstart, jend)
    end
    sol2 = sum((0:n-1) .* blocks .* .!isfree)
    return sol1, sol2
end

@time solve(readlines(joinpath(@__DIR__, "../data/test09.txt"))) == (1928, 2858)
@time solve(readlines(joinpath(@__DIR__, "../data/val09.txt")))

lines = readlines(joinpath(@__DIR__, "../data/val09.txt"))

disk_map = parse.(Int64, collect(only(lines)))[1:end-(end+1)%2]
n = sum(disk_map)