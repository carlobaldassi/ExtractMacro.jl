# ExtractMacro

[![Build Status](https://travis-ci.org/carlobaldassi/ExtractMacro.jl.svg?branch=master)](https://travis-ci.org/carlobaldassi/ExtractMacro.jl)

This package provides a single convenience macro, `@extract`, which helps extracting fields from composite types, e.g. this:

```julia
@extract x : a b c=a[i]+b[j]
```

is translated to:

```julia
a = x.a
b = x.b
c = x.a[i] + x.b[j]
```

The colon after the `x` is optional, its only purpose is to enhance readibility.

Note that since the assignments follow the usual Julia pass-by-reference rules, if you extract a scalar value (e.g. an `Int`) from a field,
and subsequently modify it, the value of the field in the parent object will not be affected. But if you extract a container (e.g. a `Vector`) and
modify its contents, the change will be reflected in the parent object. For example:

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

Destination variable names can be changed:

``` julia
@extract x : a q=v
```

is equivalent to:

```
a = x.a
q = x.v
```

Arbitrary functions (including indexing) can be applied:

```julia
@extract x : v1=abs(v[1]) vi=abs(v[i]) y=max(v[1],a)
```

is equivalent to:

```julia
v1 = abs(x.v[1])
vi = abs(x.v[i])
y = max(x.v[1], x.a)
```

Notice that the `i` within the indexing expression is left untouched: indexing is special in this regard.
In order to use another field to index, you can do:

```julia
@extract x : i=a vi=v[i]
```

In order to explicitly avoid symbol manipulation on the right hand side, use `esc`:

```julia
@extract x : y=abs(v[1] + esc(a))
```

is equivalent to:

```julia
y = abs(x.v[1] + a)
```
