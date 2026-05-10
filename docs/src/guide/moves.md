# Moves and Data

A `Move` records an actor transitioning from one position to another at a
point in time. Either side may be `nothing`, encoding entry into the
system (no `from`) or exit from the system (no `to`).

```julia
using VacancyChains

m_internal = Move(actor=1, from="A", to="B", time=1.0)
m_entry    = Move(actor=2,            to="C", time=2.0)  # external hire
m_exit     = Move(actor=3, from="D",          time=3.0)  # retirement
```

Collect them into a `MoveSequence`, which sorts by time and tracks the
sets of actors and positions appearing in the data.

```julia
seq = MoveSequence([m_internal, m_entry, m_exit])
length(seq)      # 3
seq.n_actors     # 3
seq.n_positions  # 4
```

Mobility records can also be loaded from a `DataFrame` or CSV file with
[`load_moves`](@ref). Use `actor_names=true` to map string actor names to
integer IDs in order of first appearance.

API reference: [Types](../api/types.md).
