using DiskCaches
using Test
using Base.Threads
using Pidfile

@testset "DiskCaches.jl" begin
    path = mktempdir()
    c1 = DiskCache(joinpath(path, "path1"))
    @test length(c1) == 0
    @test isempty(c1) == true
    @test_throws ErrorException empty!(c1)
    @test (c1[1] = 1) == 1
    @test_throws ErrorException c1[1] = 2
    @test_throws ErrorException pop!(c1)
    @test_throws ErrorException delete!(c1, 1)
    @test_throws KeyError c1[2]
    @test get(c1, 2, "hello") == "hello"
    @test get(c1, 2, "goodbye") == "goodbye"
    @test get!(c1, 2, "hello") == "hello"
    @test get!(c1, 3) do
        [1, 2, [3, "goodbye"]]
    end == [1, 2, [3, "goodbye"]]
    @test c1[2] == "hello"
    @test c1[3] == [1, 2, [3, "goodbye"]]
    @test length(c1) == 3
    @test !isempty(c1)

    c1_copy = DiskCache(joinpath(path, "path1"))
    @test c1_copy[1] == 1
    @test c1_copy[2] == "hello"
    @test c1_copy[3] == [1, 2, [3, "goodbye"]]
    @test_throws ErrorException c1_copy[3] = 4
    c1_copy[4] = 4
    @test c1_copy[4] == 4
    @test c1[4] == 4
    c1_copy[5] = 5
    @test length(c1) == 5

    c2 = DiskCache(joinpath(path, "path2"))
    c2_copy = DiskCache(joinpath(path, "path2"))
    c2[1] = 4
    c2[2] = 5
    c2[3] = 6
    @test Set([k for k in keys(c2_copy)]) == Set([1, 2, 3])
    @test Set([v for v in values(c2_copy)]) == Set([4, 5, 6])
    @test Set([(k, v) for (k, v) in c2_copy]) == Set([(1, 4), (2, 5), (3, 6)])
    @test Set([(k, v) for (k, v) in pairs(c2_copy)]) == Set([(1, 4), (2, 5), (3, 6)])

    C3 = [DiskCache(joinpath(path, "path3")) for _ in 1:16]
    ncalls = Atomic{Int}(0)
    @threads for i = 1:16
        get!(C3[i], "$(i)_get!", "get!")
        get!(C3[i], "$(rand(1:16))_get_call!") do
            "get_call!"
            atomic_add!(ncalls, 1)
        end
        get!(C3[i], "$(i)_get_call!") do
            "get_call!"
            atomic_add!(ncalls, 1)
        end

        C3[i]["$(i)_set!"] = "set!"
    end
    @test all(length.(C3) .== 3 * 16) 
    @test ncalls[] == 16
end
