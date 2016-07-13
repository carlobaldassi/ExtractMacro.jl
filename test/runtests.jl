module ExtractMacroTests

using ExtractMacro
using Base.Test

type X
    i::Int
    v::Vector{Int}
end

function test1()
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

    @extract x : s=sum(v)

    @test s == 10
end

function test2()
    x = X(1, [2, 3, 4])

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

    @extract x s=sum(v)

    @test s == 10
end

test1()
test2()

end # module
