using Test

"""
arr: Array{T}
f: function T -> String
"""
function arr2str(arr, f = x -> x)
    join((join(r, "") for r in eachrow(map(string ∘ f, arr))), "\n")
end
arr2str(arr::AbstractArray{T}) where T <: Number = arr2str(arr, x -> ifelse(x >= typemax(T) ÷ 3, "#", string(x)))
arr2str(arr::AbstractArray{Bool}) = arr2str(arr, x -> ifelse(x, "#", "."))

function test_arr2str()
    arr = [1 2; 3 4]
    @test arr2str(arr) == "12\n34"
    
    f = x -> ifelse(x == 1, "A", "B")
    @test arr2str(arr, f) == "AB\nBB"
end

function arr2prettystr(arr, f = x -> x)
    io = IOBuffer()
    show(io, "text/plain", f.(arr))
    return split(String(take!(io)), "\n"; limit=2)[2]
end

