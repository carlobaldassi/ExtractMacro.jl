module ExtractMacroTests

using ExtractMacro
using Test

mutable struct X
    i::Int
    v::Vector{Int}
end

function test1C()
    x = X(1, [2, 3, 4])

    @extract x : i v

    @test i == 1
    @test v == [2, 3, 4]

    v[3] = 5

    @test x.v == [2, 3, 5]

    x.i = 3

    @extract x : a=v[i]

    @test a == 2

    @extract x : j=i a=v[j]

    @test j == 3
    @test a == 5

    i = 2
    @extract x : a=(v[1]+esc(i))

    @test a == 4

    @extract x : s=sum(v)+2i-1

    @test s == 15
end

function test1X()
    x = X(1, [2, 3, 4])

    @extract x

    @extract x i v

    @test i == 1
    @test v == [2, 3, 4]

    v[3] = 5

    @test x.v == [2, 3, 5]

    x.i = 3

    @extract x a=v[i]

    @test a == 2

    @extract x j=i a=v[j]

    @test j == 3
    @test a == 5

    i = 2
    @extract x a=(v[1]+esc(i))

    @test a == 4

    @extract x s=sum(v)+2i-1

    @test s == 15
end

mutable struct Y
    i::Int
    v::Vector{Int}
    z::Vector{Int}
end

function test2C()
    y = Y(1, [2,3,4], [5,6,7])

    @extract y : t=[i for i in v]
    @test t == [i for i in y.v]

    @extract y : t=[2k .+ v' .- j .- i for (k,j) in zip(v,z)]
    @test t == [2k .+ y.v' .- j .- y.i for (k,j) in zip(y.v,y.z)]

    @extract y : t=[2z .+ v' .- j .- i for (z,j) in zip(v,z)]
    @test t == [2z .+ y.v' .- j .- y.i for (z,j) in zip(y.v,y.z)]
end

function test2X()
    y = Y(1, [2,3,4], [5,6,7])

    @extract y t=[i for i in v]
    @test t == [i for i in y.v]

    @extract y t=[2k .+ v' .- j .- i for (k,j) in zip(v,z)]
    @test t == [2k .+ y.v' .- j .- y.i for (k,j) in zip(y.v,y.z)]

    @extract y t=[2z .+ v' .- j .- i for (z,j) in zip(v,z)]
    @test t == [2z .+ y.v' .- j .- y.i for (z,j) in zip(y.v,y.z)]
end

mutable struct Z
    x::X
end

function test3C()
    z = Z(X(1, [2,3,4]))

    @extract z : t=x.i
    @test t == z.x.i

    @extract z.x : t=i
    @test t == z.x.i
end

function test3X()
    z = Z(X(1, [2,3,4]))

    @extract z t=x.i
    @test t == z.x.i

    @extract z.x t=i
    @test t == z.x.i
end

macro test_extract_failure(ex...)
    ex = Expr(:call, :macroexpand, @__MODULE__, Expr(:quote, Expr(:macrocall, Symbol("@extract"), [nothing, ex...]...)))
    quote
        @test_throws LoadError $ex
    end
end

function test4C()
    @test_extract_failure x : abs(v)
    @test_extract_failure x : v'
    @test_extract_failure x : v[1]
end

function test4X()
    @test_extract_failure x abs(v)
    @test_extract_failure x v'
    @test_extract_failure x v[1]
end

@testset "plain and indexing expressions" begin
    test1C()
    test1X()
end
@testset "comprehensions" begin
    test2C()
    test2X()
end
@testset "nested objects" begin
    test3C()
    test3X()
end
@testset "failure conditions" begin
    test4C()
    test4X()
end

end # module
