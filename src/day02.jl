using Test

function solve(lines::Vector{String})
    function check_report(report)
        d = diff(report)
        d *= sign(d[1])
        return all(1 .<= d .<= 3)
    end

    reports = map(x -> parse.(Int64, split(x)), lines)
    sol1 = sum(check_report(report) for report in reports)

    # diffs = diff.(reports)
    # diffs = [sign(d[1]) .* d for d in diffs]
    # sol2 = sum(all(d[2:end-1] .<= 3) && (count(d .< 1) + (d[1] > 3) + (d[end] > 3) <= 1) for d in diffs)

    # sol2 = 0
    # for report in reports
    #     d = diff(report)
    #     d *= sign(d[1])
    #     ko_indexes = findall(.!(1 .<= d .<= 3))
    #     if length(ko_indexes) == 0
    #         sol2 += 1
    #     elseif length(ko_indexes) == 1
    #         i_ko = only(ko_indexes)
    #         report1 = report[1:end .!= i_ko]
    #         report2 = report[1:end .!= i_ko+1]
    #         d1 = diff(report1)
    #         d2 = diff(report2)
    #         d1 *= sign(d1[1])
    #         d2 *= sign(d2[1])
    #         @show i_ko, report1, report2, d1, d2
    #         sol2 += all(1 .<= d1 .<= 3) || all(1 .<= d2 .<= 3)
    #     end
    # end

    sol2 = 0
    for report in reports
        # if the report is safe, removing the first element (or the last) keeps it safe
        sol2 += any(check_report(report[1:end .!= i]) for i in 1:length(report))
    end
    return sol1, sol2
end

@test solve(readlines(joinpath(@__DIR__, "../data/test02.txt"))) == (2, 4)
solve(readlines(joinpath(@__DIR__, "../data/val02.txt")))
