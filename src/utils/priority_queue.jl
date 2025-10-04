struct PriorityQueue
    heap::Vector
    lt::Function
    rev::Bool
end

PriorityQueue() = PriorityQueue([], <, false)
PriorityQueue(lt::Function) = PriorityQueue([], lt, false)
PriorityQueue(rev::Bool) = PriorityQueue([], <, rev)
PriorityQueue(lt::Function, rev::Bool) = PriorityQueue([], lt, rev)

pop!(pq::PriorityQueue) = popfirst!(pq.heap)
push!(pq::PriorityQueue, x) = (push!(pq.heap, x); percolate!(pq, length(pq.heap)))

function percolate!(pq::PriorityQueue, i)
    while i > 1
        j = div(i, 2)
        if pq.lt(pq.heap[j], pq.heap[i])
            pq.heap[j], pq.heap[i] = pq.heap[i], pq.heap[j]
        else
            break
        end
        i = j
    end
end