
lines = readlines(joinpath(@__DIR__, "../data/test23.txt"))
undirected_links = [(l[1:2], l[4:5]) for l in lines]
links = sort(reduce(vcat, [[link, reverse(link)] for link in undirected_links]))

groups = Set{NTuple{3, String}}()
for l1 in links
    if l1[1][1] != 't' continue end
    for l2 in links
        if l2[1] != l1[2] continue end
        (; start, stop) = searchsorted(links, (l2[2], l1[1]))
        if start != stop continue end
        l3 = links[start]
        push!(groups, Tuple(sort(getindex.([l1, l2, l3], 1))))
    end
end
length(groups)

largest_network = Set{String}()
unused_links = deepcopy(links)
while !isempty(unused_links)
    curr_link = pop!(unused_links)
    nodes_to_visit = Set(curr_link)
    curr_network = Set{String}()
    while !isempty(nodes_to_visit) && !isempty(unused_links)
        @show nodes_to_visit
        node = pop!(nodes_to_visit)
        if node in curr_network continue end
        push!(curr_network, node)
        i_start = searchsortedfirst(unused_links, (node, "aa"))
        i_stop = searchsortedfirst(unused_links, (node, "zz"))
        for i in i_start:i_stop-1
            @show unused_links[i]
            push!(nodes_to_visit, unused_links[i][1])
        end
    end
    if length(curr_network) > length(largest_network)
        largest_network = curr_network
    end
end

largest_network = Set{String}()
unvisited = Set(getindex.(links, 1))
while !isempty(unvisited)
    root = pop!(unvisited)
    to_visit = Set((root,))
    curr_network = Set((root,))
    while !isempty(to_visit)
        curr = pop!(to_visit)
        push!(curr_network, curr)
        delete!(unvisited, curr)
        start = searchsortedfirst(links, (curr, "aa"))
        stop = searchsortedfirst(links, (curr, "zz"))
        # @show curr, links[start:stop-1]
        for i in start:stop-1
            @show links[i]
            if links[i][2] ∉ unvisited continue end
            push!(to_visit, links[i][2])
        end
    end
    @show curr_network
    if length(curr_network) > length(largest_network)
        largest_network = curr_network
    end
end

Set(["ka", "qp", "td", "cg", "yn", "wq", "tb", "tc", "ub", "wh", "co", "ta", "de", "vc", "kh", "aq"])

qp, kh, td, ub, wh