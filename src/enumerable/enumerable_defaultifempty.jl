struct EnumerableDefaultIfEmpty{T,S} <: Enumerable
    source::S
    default_value::T
end

Base.eltype(iter::EnumerableDefaultIfEmpty{T,S}) where {T,S} = T

Base.eltype(iter::Type{EnumerableDefaultIfEmpty{T,S}}) where {T,S} = T

function default_if_empty(source::S) where {S}
    T = eltype(source)

    if T<:NamedTuple
        default_value = T(i() for i in T.parameters)
    else
        default_value = T()
    end

    return EnumerableDefaultIfEmpty{T,S}(source, default_value)
end


function default_if_empty(source::S, default_value::TD) where {S,TD}
    T = eltype(source)
    if T!=TD
        error("The default value must have the same type as the elements from the source.")
    end
    return EnumerableDefaultIfEmpty{T,S}(source, default_value)
end

function Base.start(iter::EnumerableDefaultIfEmpty{T,S}) where {T,S}
    s = start(iter.source)
    return s, done(iter.source, s) ? Nullable(true) : Nullable{Bool}()
end

function Base.next(iter::EnumerableDefaultIfEmpty{T,S}, state) where {T,S}
    (s,status) = state

    if isnull(status)
        x = next(iter.source, s)
        v = x[1]
        s_new = x[2]
        return v, (s_new, Nullable{Bool}())
    elseif get(status)
        return iter.default_value, (s, Nullable(false))
    else !get(status)
        error()
    end
end

function Base.done(iter::EnumerableDefaultIfEmpty{T,S}, state) where {T,S}
    (s,status) = state
    if isnull(status)
        return done(iter.source, s)
    else
        return !get(status)
    end
end
