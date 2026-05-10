# Types

The data model has three layers:

1. **Atomic events** — a [`Move`](@ref) is a single mobility record:
   one actor leaves one position and (optionally) enters another at a
   point in time.
2. **Time-ordered collections** — a [`MoveSequence`](@ref) is the
   sorted set of all observed moves, with derived sets of actors and
   positions.
3. **Reconstructed structures** — a [`Chain`](@ref) is an ordered
   sequence of moves linked by the propagation of a single vacancy; a
   [`ChainSet`](@ref) is the collection of chains produced by
   [`build_chains`](@ref).

A fourth helper, [`PositionAttribute`](@ref), attaches stratum or other
position-level covariates to the position labels used inside moves.

The split into "moves" (raw observations) and "chains" (reconstructed
structures) follows the conceptual distinction that
[White (1970)](../references.md) drew between *person mobility* (what
the data records) and *vacancy mobility* (what is theoretically
interesting). [Chase (1991)](../references.md) reviews the same
distinction across human and non-human systems and is the source of the
termination kinds enumerated by [`TERMINATION_KINDS`](@ref).

## Why `from` and `to` are nullable

Either side of a `Move` may be `nothing`:

- `from === nothing` encodes an *entry* — the actor was not in the
  observed system before this move (e.g. an external hire). Entry
  moves close vacancy chains because they create no upstream vacancy.
- `to === nothing` encodes an *exit* — the actor leaves the observed
  system (retirement, death, transfer outside the firm). Exit moves
  *seed* chains: they create the initial vacancy that subsequent moves
  fill.

This nullability is what lets one data type carry the full information
needed for chain reconstruction without auxiliary "vacancy" records.
The convention follows the data-organisation choice in
[Stewman (1986)](../references.md), who treats entries and exits as
boundary events of the same mobility process.

## Data types

```@docs
Move
MoveSequence
Chain
ChainSet
PositionAttribute
TERMINATION_KINDS
```

## Construction and reconstruction

```@docs
load_moves
build_chains
```

## Exploratory analysis

These return summary scalars or `DataFrame`s suitable for direct
plotting. The motivating descriptive targets are taken from
[White (1970)](../references.md) (chain length, multiplier),
[McFarland (1970)](../references.md) (mobility tables), and
[Stewman (1986)](../references.md) (residence times and stratum flows).

```@docs
chain_lengths
chain_multiplier
mobility_table
stratum_flows
termination_summary
residence_times
compute_chain_statistics
```

## Predicates and accessors

```@docs
is_entry
is_exit
is_internal
n_chains
n_moves
```

## Internal helpers

```@docs
VacancyChains.parse_time
```

## References

The conceptual choices encoded in these types — chain as primary unit,
entry/exit as boundary moves, stratum as position covariate — come from
the works listed on the [References](../references.md) page. The
canonical entry points are White (1970), Chase (1991), and
Stewman (1986).
