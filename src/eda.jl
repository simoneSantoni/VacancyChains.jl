"""
Exploratory data analysis for vacancy chains.

These helpers operate on a `ChainSet` (or, where noted, a `MoveSequence`)
and return either summary scalars, vectors, or `DataFrame`s suitable for
plotting.
"""

"""
    chain_lengths(cs::ChainSet) -> Vector{Int}

Number of moves in each chain, in chain order.
"""
chain_lengths(cs::ChainSet) = [length(c) for c in cs]

"""
    chain_multiplier(cs::ChainSet) -> Float64

Mean number of moves per chain — the "vacancy multiplier" in
White (1970)'s terminology: how many person-moves a single initiating
vacancy generates, on average.
"""
function chain_multiplier(cs::ChainSet)
    n = n_chains(cs)
    n == 0 && return 0.0
    return n_moves(cs) / n
end

"""
    mobility_table(cs::ChainSet; by::Union{PositionAttribute, Nothing}=nothing) -> DataFrame

Origin × destination mobility table aggregated over all moves in all
chains. Rows are origins, columns are destinations.

If `by` is supplied, positions are first projected through the attribute
(grouping moves by stratum); otherwise raw position labels are used.
Entry moves (`from === nothing`) and exit moves (`to === nothing`) are
included as a synthetic `"<external>"` category.
"""
function mobility_table(cs::ChainSet; by::Union{PositionAttribute, Nothing}=nothing)
    counts = Dict{Tuple{String, String}, Int}()
    for c in cs
        for m in c.moves
            o = _label(m.from, by)
            d = _label(m.to, by)
            counts[(o, d)] = get(counts, (o, d), 0) + 1
        end
    end

    origins      = sort!(unique([k[1] for k in keys(counts)]))
    destinations = sort!(unique([k[2] for k in keys(counts)]))

    df = DataFrame(origin = origins)
    for d in destinations
        df[!, Symbol(d)] = Int[get(counts, (o, d), 0) for o in origins]
    end
    return df
end

_label(p::AbstractString, ::Nothing) = String(p)
_label(::Nothing, ::Nothing) = "<external>"
_label(p::AbstractString, attr::PositionAttribute) = string(attr[String(p)])
_label(::Nothing, ::PositionAttribute) = "<external>"

"""
    stratum_flows(cs::ChainSet, attr::PositionAttribute) -> DataFrame

Long-form flow counts between strata. Returns a `DataFrame` with columns
`from_stratum`, `to_stratum`, `count`. Entries/exits are encoded as the
`"<external>"` stratum.
"""
function stratum_flows(cs::ChainSet, attr::PositionAttribute)
    counts = Dict{Tuple{String, String}, Int}()
    for c in cs
        for m in c.moves
            o = _label(m.from, attr)
            d = _label(m.to, attr)
            counts[(o, d)] = get(counts, (o, d), 0) + 1
        end
    end
    rows = [(from_stratum=k[1], to_stratum=k[2], count=v) for (k, v) in counts]
    return DataFrame(rows)
end

"""
    termination_summary(cs::ChainSet) -> DataFrame

Counts and proportions of chains by termination kind.
"""
function termination_summary(cs::ChainSet)
    counts = Dict{Symbol, Int}(k => 0 for k in TERMINATION_KINDS)
    for c in cs
        counts[c.termination] += 1
    end
    n = max(n_chains(cs), 1)
    rows = [(termination=k, count=counts[k], proportion=counts[k] / n)
            for k in TERMINATION_KINDS]
    return DataFrame(rows)
end

"""
    residence_times(seq::MoveSequence) -> DataFrame

Time-in-position durations, computed from consecutive moves of the same
actor. Returns a `DataFrame` with columns `actor`, `position`, `entered`,
`left`, `duration`.
"""
function residence_times(seq::MoveSequence{T}) where T
    by_actor = Dict{Int, Vector{Int}}()
    for (i, m) in enumerate(seq.moves)
        push!(get!(by_actor, m.actor, Int[]), i)
    end

    rows = NamedTuple[]
    for (actor, idxs) in by_actor
        sort!(idxs, by=i -> seq.moves[i].time)
        for k in 1:(length(idxs) - 1)
            mk = seq.moves[idxs[k]]
            mk_next = seq.moves[idxs[k + 1]]
            position = mk.to
            position === nothing && continue   # actor had exited
            mk_next.from == position || continue  # not a contiguous spell
            push!(rows, (
                actor    = actor,
                position = position,
                entered  = mk.time,
                left     = mk_next.time,
                duration = mk_next.time - mk.time,
            ))
        end
    end
    return DataFrame(rows)
end

"""
    compute_chain_statistics(cs::ChainSet) -> DataFrame

Per-chain descriptive statistics. Columns: `chain_id`, `length`, `origin`,
`termination`, `start_time`, `end_time`, `duration`.
"""
function compute_chain_statistics(cs::ChainSet)
    rows = NamedTuple[]
    for c in cs
        ts = [m.time for m in c.moves]
        push!(rows, (
            chain_id    = c.id,
            length      = length(c),
            origin      = c.origin === nothing ? "<external>" : c.origin,
            termination = c.termination,
            start_time  = isempty(ts) ? missing : minimum(ts),
            end_time    = isempty(ts) ? missing : maximum(ts),
            duration    = isempty(ts) ? missing : (maximum(ts) - minimum(ts)),
        ))
    end
    return DataFrame(rows)
end
