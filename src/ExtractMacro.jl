module ExtractMacro

export @extract

"""
    @extract obj : exprs...

Extracts fields from composite types. E.g.

```julia
@extract x : a b

# is translated to:

a = x.a
b = x.b
```

The colon is optional: `@extract x a b` is the same as above.
Destination variable names can be changed, and arbitrary functions (including indexing) applied, e.g.:

```julia
@extract x : q=b a1=abs(a[1]) ai=abs(a[i]) y=max(a[1],b)

# is translated to:

q = x.b
a1 = abs(x.a[1])
ai = abs(x.a[i])
y = max(x.a[1], x.b)
```

Notice that the `i` within the indexing expression is left untouched: indexing is special in this regard.

In order to explicitly avoid symbol manipulation on the right hand side, use `esc()`, e.g.:

```julia
@extract x : y=abs(a[1] + esc(b))

# is translated to:

y = abs(x.a[1] + b) # b is left untouched
```
"""
macro extract(obj, vars...)
    ex = quote end
    # next block is to allow this syntax
    #   @extract X : a b c
    # (basically, we need to override the parsing precedence rules)
    if Meta.isexpr(obj, [:(=), :(=>), :(:=)]) && Meta.isexpr(obj.args[1], :(:))
        vars = Any[Expr(obj.head, obj.args[1].args[2:end]..., obj.args[2:end]...), vars...]
        obj = obj.args[1].args[1]
    elseif Meta.isexpr(obj, :(:))
        vars = Any[obj.args[2], vars...]
        obj = obj.args[1]
    end
    for v in vars
        if isa(v, Symbol)
            ex = quote
                $ex
                $(esc(v)) = $(prepend_obj(v, obj))
            end
        elseif isa(v, Expr)
            if v.head ∉ [:(=), :(=>), :(:=)]
                error("invalid @extract argument: expression `$(v)` out of an assigment")
            end
            va = v.args
            @assert length(va) == 2
            ex = quote
                $ex
                $(esc(va[1])) = $(prepend_obj(va[2], obj))
            end
        end
    end
    ex
end

update_skiplist!(x, skip) = nothing
update_skiplist!(x::Symbol, skip) = push!(skip, x)
function update_skiplist!(x::Expr, skip)
    Meta.isexpr(x, :tuple) || return
    for a in x.args
        update_skiplist!(a, skip)
    end
end

prepend_obj(x, obj, skip=[]) = x
prepend_obj(s::Symbol, obj, skip=[]) = s ∈ skip ? esc(s) : :($(esc(obj)).$s)
function prepend_obj(body::Expr, obj, skip=[])
    if Meta.isexpr(body, :call)
        if body.args[1] != :esc
            return Expr(body.head, Expr(:escape, body.args[1]), map(x->prepend_obj(x, obj, skip), body.args[2:end])...)
        else
            @assert length(body.args) == 2
            return Expr(:escape, body.args[2])
        end
    elseif Meta.isexpr(body, [:ref, :.])
        return Expr(body.head, prepend_obj(body.args[1], obj, skip), map(esc, body.args[2:end])...)
    elseif Meta.isexpr(body, [:comprehension, :generator])
        inner_generator = Meta.isexpr(body.args[1], :generator)
        args = inner_generator ? body.args[1].args : body.args
        length(args) == 2 || error("unsupported expression")
        Meta.isexpr(args[2], :(=)) || error("unsupported expression")

        iter = prepend_obj(args[2].args[2], obj, skip)

        var = args[2].args[1]
        update_skiplist!(var, skip)

        ex = prepend_obj(args[1], obj, skip)
        genargs = Expr(:(=), esc(var), iter)

        return inner_generator ?
                Expr(body.head, Expr(:generator, ex, genargs)) :
                Expr(body.head, ex, genargs)

    else
        return Expr(body.head, map(x->prepend_obj(x, obj, skip), body.args)...)
    end
end

end # module
