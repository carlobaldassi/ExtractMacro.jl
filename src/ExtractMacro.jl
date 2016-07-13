module ExtractMacro

export @extract

"""
    @extract obj : exprs...

Extracts fields from composite types. E.g.

    @extract x : a b

is translated to:

    a = x.a
    b = x.b

The colon is optional: `@extract x a b` is the same as above.
Destination variable names can be changed, and arbitrary functions (including indexing) applied, e.g.:

    @extract x : q=b a1=abs(a[1]) ai=abs(a[i]) y=max(a[1],b)

is translated to:

    q = x.b
    a1 = abs(x.a[1])
    ai = abs(x.a[i])
    y = max(x.a[1], x.b)

Notice that the `i` within the indexing expression is left untouched: indexing is special in this regard.

In order to explicitly avoid symbol manipulation on the right hand side, use `esc()`: this

    @extract x : y=abs(a[1] + esc(b))

is translated to:

    y = abs(x.a[1] + b)
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
            @assert v.head in [:(=), :(=>), :(:=)]
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

prepend_obj(x, obj) = x
prepend_obj(s::Symbol, obj) = :($(esc(obj)).$s)
function prepend_obj(body::Expr, obj)
    if Meta.isexpr(body, :call)
        if body.args[1] != :esc
            return Expr(body.head, Expr(:escape, body.args[1]), map(x->prepend_obj(x, obj), body.args[2:end])...)
        else
            @assert length(body.args) == 2
            return Expr(:escape, body.args[2])
        end
    elseif Meta.isexpr(body, :ref)
        return Expr(body.head, prepend_obj(body.args[1], obj), map(esc, body.args[2:end])...)
    else
        return Expr(body.head, map(x->prepend_obj(x, obj), body.args)...)
    end
end


end # module
