# Exploratory Analysis

Once you have a `ChainSet` from [`build_chains`](@ref), the EDA helpers
turn it into summary statistics and `DataFrame`s ready for plotting.

```julia
using VacancyChains

# (build chains first as in the previous section)

chain_lengths(chains)              # Vector{Int}
chain_multiplier(chains)           # mean moves per chain (vacancy multiplier)
mobility_table(chains)             # origin × destination DataFrame
termination_summary(chains)        # counts/proportions by termination kind
compute_chain_statistics(chains)   # one row per chain
```

For stratified summaries, project positions through a `PositionAttribute`:

```julia
attr = PositionAttribute(:level,
    Dict("A" => "senior", "B" => "junior"),
    "unknown",
)

mobility_table(chains; by=attr)
stratum_flows(chains, attr)
```

`residence_times(seq)` returns time-in-position spells reconstructed from
consecutive moves of the same actor, given the underlying `MoveSequence`.

API reference: [Estimation API](../api/estimation.md) (for related result
types), [Types](../api/types.md) (for `ChainSet` and `PositionAttribute`).
