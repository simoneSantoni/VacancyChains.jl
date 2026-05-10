"""
Core types for vacancy chain analysis.

A *move* records an entity transitioning from one position to another at a
point in time. Either side may be `nothing`, encoding entry into the system
(no `from`) or exit from the system (no `to`). A *chain* is an ordered
sequence of moves linked by vacancy propagation: the move that vacates a
position triggers the next move that fills it.
"""

"""
    Move{T}

A single mobility event: an actor transitions from `from` to `to` at `time`.

`from === nothing` means the actor enters the system from outside (an entry
move that creates no upstream vacancy). `to === nothing` means the actor
exits the system (a terminating move that does not propagate further).

# Fields
- `actor::Int`: ID of the moving actor
- `from::Union{String, Nothing}`: Origin position (`nothing` if entry)
- `to::Union{String, Nothing}`: Destination position (`nothing` if exit)
- `time::T`: Timestamp of the move
- `movetype::Symbol`: Move type/category (default: `:move`)
"""
struct Move{T}
    actor::Int
    from::Union{String, Nothing}
    to::Union{String, Nothing}
    time::T
    movetype::Symbol

    function Move{T}(actor::Int,
                     from::Union{String, Nothing},
                     to::Union{String, Nothing},
                     time::T,
                     movetype::Symbol) where T
        from === nothing && to === nothing &&
            throw(ArgumentError("a Move must have at least one of `from` or `to`"))
        new{T}(actor, from, to, time, movetype)
    end
end

function Move(; actor::Int,
              from::Union{String, Nothing}=nothing,
              to::Union{String, Nothing}=nothing,
              time::T,
              movetype::Symbol=:move) where T
    Move{T}(actor, from, to, time, movetype)
end

"""
    is_entry(m::Move) -> Bool

`true` if `m` is an *entry* move — the actor enters the system from outside
(`m.from === nothing`). Entry moves close vacancy chains because they
create no upstream vacancy.
"""
is_entry(m::Move) = m.from === nothing

"""
    is_exit(m::Move) -> Bool

`true` if `m` is an *exit* move — the actor leaves the system
(`m.to === nothing`). Exit moves *seed* vacancy chains: they create the
initial vacancy that subsequent moves fill.
"""
is_exit(m::Move)  = m.to === nothing

"""
    is_internal(m::Move) -> Bool

`true` if `m` is fully internal — both `from` and `to` are non-`nothing`.
Internal moves form the body of vacancy chains.
"""
is_internal(m::Move) = m.from !== nothing && m.to !== nothing

function Base.show(io::IO, m::Move)
    f = m.from === nothing ? "∅" : m.from
    t = m.to   === nothing ? "∅" : m.to
    print(io, "Move(actor=$(m.actor), $f → $t @ $(m.time))")
end

"""
    MoveSequence{T}

Time-sorted collection of `Move{T}` records together with derived sets of
actors and positions.

# Fields
- `moves::Vector{Move{T}}`: Moves sorted by time
- `actors::Set{Int}`: Set of all actor IDs appearing in any move
- `positions::Set{String}`: Set of all (non-`nothing`) position labels
- `n_actors::Int`: Number of unique actors
- `n_positions::Int`: Number of unique positions
"""
mutable struct MoveSequence{T}
    moves::Vector{Move{T}}
    actors::Set{Int}
    positions::Set{String}
    n_actors::Int
    n_positions::Int

    function MoveSequence{T}() where T
        new{T}(Move{T}[], Set{Int}(), Set{String}(), 0, 0)
    end

    function MoveSequence(moves::Vector{Move{T}}) where T
        sorted_moves = sort(moves, by=m -> m.time)
        actors = Set{Int}()
        positions = Set{String}()
        for m in sorted_moves
            push!(actors, m.actor)
            m.from !== nothing && push!(positions, m.from)
            m.to   !== nothing && push!(positions, m.to)
        end
        new{T}(sorted_moves, actors, positions, length(actors), length(positions))
    end
end

Base.length(seq::MoveSequence) = length(seq.moves)
Base.iterate(seq::MoveSequence, state=1) = state > length(seq.moves) ? nothing : (seq.moves[state], state + 1)
Base.getindex(seq::MoveSequence, i) = seq.moves[i]
Base.lastindex(seq::MoveSequence) = length(seq.moves)

function Base.push!(seq::MoveSequence{T}, m::Move{T}) where T
    idx = searchsortedfirst(seq.moves, m, by=mv -> mv.time)
    insert!(seq.moves, idx, m)
    push!(seq.actors, m.actor)
    m.from !== nothing && push!(seq.positions, m.from)
    m.to   !== nothing && push!(seq.positions, m.to)
    seq.n_actors    = length(seq.actors)
    seq.n_positions = length(seq.positions)
    seq
end

"""
    Termination

How a vacancy chain ends.

- `:internal_exit` — chain ends because the last vacated position is filled
  by an actor leaving the system (no further vacancy created).
- `:external_hire` — chain ends because the last vacancy is filled from
  outside the system (entry move).
- `:abolished` — chain ends because the last vacancy is not filled within
  the observation window (no successor move on the position).
- `:open` — chain has not yet terminated within the observed data.
"""
const TERMINATION_KINDS = (:internal_exit, :external_hire, :abolished, :open)

"""
    Chain{T}

A vacancy chain: an ordered sequence of moves linked by vacancy propagation.

The chain begins with an *initiating vacancy* (the first opening, e.g.,
created by a retirement, a death, the creation of a new position, or an
external hire that needed to be replaced) and proceeds through successive
moves until it terminates.

# Fields
- `id::Int`: Identifier of the chain
- `moves::Vector{Move{T}}`: Moves in time order along the chain
- `origin::Union{String, Nothing}`: Position whose initial vacancy started the chain
- `termination::Symbol`: One of [`TERMINATION_KINDS`](@ref)
"""
struct Chain{T}
    id::Int
    moves::Vector{Move{T}}
    origin::Union{String, Nothing}
    termination::Symbol

    function Chain(id::Int, moves::Vector{Move{T}},
                   origin::Union{String, Nothing},
                   termination::Symbol) where T
        termination in TERMINATION_KINDS ||
            throw(ArgumentError("termination must be one of $TERMINATION_KINDS, got :$termination"))
        new{T}(id, moves, origin, termination)
    end
end

Base.length(c::Chain) = length(c.moves)
Base.iterate(c::Chain, state=1) = state > length(c.moves) ? nothing : (c.moves[state], state + 1)
Base.getindex(c::Chain, i) = c.moves[i]
Base.lastindex(c::Chain) = length(c.moves)

origin(c::Chain) = c.origin
termination(c::Chain) = c.termination
moves(c::Chain) = c.moves

function Base.show(io::IO, c::Chain)
    print(io, "Chain(id=$(c.id), length=$(length(c.moves)), origin=$(c.origin), termination=:$(c.termination))")
end

"""
    ChainSet{T}

Collection of `Chain{T}` produced by [`build_chains`](@ref).

# Fields
- `chains::Vector{Chain{T}}`: All reconstructed chains
- `positions::Set{String}`: Set of positions appearing in any chain
- `actors::Set{Int}`: Set of actors appearing in any chain
"""
struct ChainSet{T}
    chains::Vector{Chain{T}}
    positions::Set{String}
    actors::Set{Int}

    function ChainSet(chains::Vector{Chain{T}}) where T
        positions = Set{String}()
        actors = Set{Int}()
        for c in chains
            for m in c.moves
                push!(actors, m.actor)
                m.from !== nothing && push!(positions, m.from)
                m.to   !== nothing && push!(positions, m.to)
            end
        end
        new{T}(chains, positions, actors)
    end
end

Base.length(cs::ChainSet) = length(cs.chains)
Base.iterate(cs::ChainSet, state=1) = state > length(cs.chains) ? nothing : (cs.chains[state], state + 1)
Base.getindex(cs::ChainSet, i) = cs.chains[i]
Base.lastindex(cs::ChainSet) = length(cs.chains)

"""
    n_chains(cs::ChainSet) -> Int

Number of chains in the set.
"""
n_chains(cs::ChainSet) = length(cs.chains)

"""
    n_moves(cs::ChainSet) -> Int

Total number of moves across all chains in the set. May be smaller than
`length(seq)` for the underlying `MoveSequence` because seed (exit) moves
and orphan moves are not part of any chain.
"""
n_moves(cs::ChainSet) = sum(length(c) for c in cs.chains; init=0)

"""
    PositionAttribute{T}

Stores an attribute value for each position (e.g., stratum, salary grade).

# Fields
- `name::Symbol`: Name of the attribute
- `values::Dict{String, T}`: Mapping from position label to value
- `default::T`: Value returned for positions not in the dict
"""
struct PositionAttribute{T}
    name::Symbol
    values::Dict{String, T}
    default::T

    function PositionAttribute(name::Symbol, values::Dict{String, T}, default::T) where T
        new{T}(name, values, default)
    end

    function PositionAttribute(name::Symbol, default::T) where T
        new{T}(name, Dict{String, T}(), default)
    end
end

Base.getindex(attr::PositionAttribute{T}, p::AbstractString) where T = get(attr.values, String(p), attr.default)
Base.getindex(attr::PositionAttribute{T}, ::Nothing) where T = attr.default
Base.setindex!(attr::PositionAttribute{T}, val::T, p::AbstractString) where T = attr.values[String(p)] = val
