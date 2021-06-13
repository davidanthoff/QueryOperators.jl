struct EnumerableIterable{T,S} <: Enumerable
    source::S
end

function query(source)
    if !IteratorInterfaceExtensions.isiterable(source)
        error("$(typeof(source)) does not meet the IteratorInterfaceExtensions.jl API")
    end
    typed_source = IteratorInterfaceExtensions.getiterator(source)
	T = eltype(typed_source)
    S = typeof(typed_source)

    source_enumerable = EnumerableIterable{T,S}(typed_source)

    return source_enumerable
end

Base.IteratorSize(::Type{EnumerableIterable{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableIterable{T,S}}) where {T,S} = T

Base.length(iter::EnumerableIterable{T,S}) where {T,S} = length(iter.source)

function Base.iterate(iter::EnumerableIterable{T,S}, state...) where {T,S}
    return iterate(iter.source, state...)
end

