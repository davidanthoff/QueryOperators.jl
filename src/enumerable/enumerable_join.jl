immutable EnumerableJoin{T,TKey,TI,SO,SI,OKS<:Function,IKS<:Function,RS<:Function} <: Enumerable{T}
    outer::SO
    inner::SI
    outerKeySelector::OKS
    innerKeySelector::IKS
    resultSelector::RS
end

function join(outer::Enumerable, inner::Enumerable, f_outerKeySelector::Function, outerKeySelector::Expr, f_innerKeySelector::Function, innerKeySelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TO = eltype(outer)
    TI = eltype(inner)
    TKeyOuter = Base._return_type(f_outerKeySelector, Tuple{TO,})
    TKeyInner = Base._return_type(f_innerKeySelector, Tuple{TI,})

    if TKeyOuter!=TKeyInner
        error("The keys in the join clause have different types, $TKeyOuter and $TKeyInner.")
    end

    SO = typeof(outer)
    SI = typeof(inner)

    T = Base._return_type(f_resultSelector, Tuple{TO,TI})

    OKS = typeof(f_outerKeySelector)
    IKS = typeof(f_innerKeySelector)
    RS = typeof(f_resultSelector)

    return EnumerableJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}(outer,inner,f_outerKeySelector,f_innerKeySelector,f_resultSelector)
end

# TODO This should be changed to a lazy implementation
function Base.start{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}(iter::EnumerableJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS})
    results = Array{T}(0)

    inner_dict = OrderedDict{TKeyOuter,Array{TI,1}}()
    for i in iter.inner
        key = iter.innerKeySelector(i)
        if !haskey(inner_dict, key)
            inner_dict[key] = Array{TI}(0)
        end
        push!(inner_dict[key], i)
    end

    for i in iter.outer
        outerKey = iter.outerKeySelector(i)
        if haskey(inner_dict,outerKey)
            for j in inner_dict[outerKey]
                push!(results, iter.resultSelector(i,j))
            end
        end
    end

    return results,1
end

function Base.next{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}(iter::EnumerableJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS},state)
    results = state[1]
    curr_index = state[2]
    return results[curr_index], (results, curr_index+1)
end

function Base.done{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}(iter::EnumerableJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS},state)
    results = state[1]
    curr_index = state[2]
    return curr_index > length(results)
end

macro join_internal(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
	q_outerKeySelector = Expr(:quote, outerKeySelector)
	q_innerKeySelector = Expr(:quote, innerKeySelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(join($(esc(outer)), $(esc(inner)), $(esc(outerKeySelector)), $(esc(q_outerKeySelector)), $(esc(innerKeySelector)),$(esc(q_innerKeySelector)), $(esc(resultSelector)),$(esc(q_resultSelector))))
end
