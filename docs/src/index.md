# ExtractMacro.jl documentation

This package provides just one macro, `@extract`, which you can use by entering:

```
using ExtractMacro
```

The macro creates local variables from expressions involving composite types fields.
It is especially useful to avoid writing expressions of the form `obj.field` repeatedly.
For example, instead of having code like this:


```julia
potential(network::Network, i::Int) =
    dot(unsafe(network.J[i]), unsafe(network.current_state.s)) - network.H0 -
        network.lambda * (network.current_state.S - network.f * network.N)
```

you could use the macro and get a more readable version:

```julia
function potential(network::Network, i::Int)
    @extract network : N f H0 lambda state=current_state Ji=unsafe(J[i])
    @extract state   : S s=unsafe(s)

    return dot(Ji, s) - H0 - lambda * (S - f * N)
end
```

This makes the function look a little bit like a method in some standard OO languages (e.g., C++) where
class methods bring the class fields in scope. Note however that the `@extract` macro does not work like that:
it always works by creating local variables. The consequences of this are discussed further after the macro
documentation.

```@autodocs
Modules = [ExtractMacro]
```

As mentioned above, since the assignments follow the usual Julia pass-by-reference rules, if you extract
a scalar value (e.g. an `Int`) from a field, and subsequently modify it, the value of the field in the
parent object will not be affected. But if you extract a container (e.g. a `Vector`) and modify its
contents, the change will be reflected in the parent object. For example:

```julia
type X
    a::Int
    v::Vector{Int}
end
x = X(1, [2,3,4])
@extract x : a v
a = 5     # will not change x.a
v[1] = 5  # will change x.v[1]
```
