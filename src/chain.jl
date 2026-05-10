"""
Chain reconstruction.

A vacancy chain is reconstructed by linking moves through the positions
they vacate and fill: if move `m_i` has `from = p`, the next link `m_{i+1}`
in the chain is the earliest later move with `to = p`. The chain terminates
when no such filling move exists (`:abolished` if the data window has ended,
`:open` if the chain is still propagating at the end of the observed data),
or when the filling move is an entry from outside the system (`:external_hire`).

A chain is *seeded* by an event that opens a position from outside the
mobility process — typically a retirement, a death, or the creation of a
new position. In the move representation that comes through as either:

- an *exit* move (`to === nothing`) — actor leaves the system and vacates
  `from`, which becomes the seed vacancy; or
- an *internal* move whose `from` was never previously occupied in the data
  window — i.e. the position is "fresh" (e.g. a newly created post that an
  actor takes up by moving from elsewhere). In this case the move itself is
  also the first link of the chain.

The current `build_chains` implementation treats *exit* moves as seeds
explicitly. Internal moves whose `from` is never observed as a `to` of an
earlier move are left ungrouped (no chain is constructed for them).
"""

"""
    build_chains(seq::MoveSequence; rule::Symbol=:strict) -> ChainSet

Reconstruct vacancy chains from a `MoveSequence`.

# Arguments
- `seq`: time-sorted moves

# Keyword Arguments
- `rule::Symbol=:strict`: linking rule. Currently only `:strict` is
  implemented — link `m_i` to the *earliest later* move whose `to` equals
  `m_i.from`. Each move can be the successor of at most one prior move.
"""
function build_chains(seq::MoveSequence{T}; rule::Symbol=:strict) where T
    rule === :strict ||
        throw(ArgumentError("only rule=:strict is implemented, got :$rule"))

    n = length(seq)
    # successor[i] = j means move j fills the vacancy at seq[i].from.
    successor = fill(0, n)
    used      = falses(n)  # whether move j has already been claimed as a successor

    # Index moves by `to` for quick lookup
    fillers_by_position = Dict{String, Vector{Int}}()
    for j in 1:n
        seq[j].to === nothing && continue
        push!(get!(fillers_by_position, seq[j].to::String, Int[]), j)
    end

    for i in 1:n
        seq[i].from === nothing && continue  # entry moves create no upstream vacancy
        candidates = get(fillers_by_position, seq[i].from::String, Int[])
        # earliest later, unclaimed candidate
        for j in candidates
            j > i || continue
            used[j] && continue
            successor[i] = j
            used[j] = true
            break
        end
    end

    # Identify chain heads. A head is a move that begins a chain:
    #   - exit moves (to === nothing): seed by leaving the system; the chain
    #     itself starts with the move that fills `from`
    #   - any move not claimed as someone's successor: a fresh entry into
    #     the chain graph
    chains = Chain{T}[]
    chain_id = 0

    # First: chains seeded by exit moves
    for i in 1:n
        seq[i].to === nothing || continue
        # The chain proper starts at the move that fills seq[i].from
        start = successor[i]
        start == 0 && continue  # vacancy never filled — no chain to record
        # Walk forward from `start`
        chain_id += 1
        push!(chains, _walk_chain(seq, start, successor, chain_id, seq[i].from))
    end

    # Second: unseeded chains — moves not claimed by any predecessor and
    # not exit moves. These are chains whose seed wasn't observed as an
    # exit move (e.g. a newly created position).
    for j in 1:n
        used[j] && continue
        seq[j].to === nothing && continue  # exits handled above (as seeds)
        chain_id += 1
        push!(chains, _walk_chain(seq, j, successor, chain_id, seq[j].to))
    end

    return ChainSet(chains)
end

function _walk_chain(seq::MoveSequence{T}, start::Int, successor::Vector{Int},
                     id::Int, origin_pos::Union{String, Nothing}) where T
    moves_vec = Move{T}[]
    j = start
    while j != 0
        push!(moves_vec, seq[j])
        j = successor[j]
    end
    last_move = moves_vec[end]
    term = if is_entry(last_move)
        :external_hire          # chain ended because someone entered from outside
    elseif last_move.from !== nothing
        :abolished              # vacancy at last_move.from was never filled
    else
        :open                   # last_move was an exit (no chain continuation expected)
    end
    return Chain(id, moves_vec, origin_pos, term)
end
