using Test

"""
arr: Array{T}
f: function T -> String
"""
function compact_string(arr, f = identity)
    join((join(r, "") for r in eachrow(map(string ∘ f, arr))), "\n")
end

function test_compact_string()
    arr = [1 2; 3 4]
    @test compact_string(arr) == "12\n34"
    
    f = x -> ifelse(x == 1, "A", "B")
    @test compact_string(arr, f) == "AB\nBB"
end
