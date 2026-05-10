# Visualization API

All plotting functions are reserved by name in v0.1.0 and currently
raise `not implemented`. This page documents what each plot is *meant*
to render so that the public API is stable from the package's first
release. Implementations will land as
[Plots.jl](https://docs.juliaplots.org) recipes (or CairoMakie
equivalents) in a follow-up revision.

The data inputs each plot consumes are already produced by the
exploratory and estimation functions:

| Plot | Consumes | Produced by |
|------|----------|-------------|
| `plot_chain_tree` | a single `Chain` | `build_chains` |
| `plot_length_distribution` | `chain_lengths(::ChainSet)` | `chain_lengths` |
| `plot_mobility` | `mobility_table(::ChainSet)` | `mobility_table` |
| `plot_stratum_flows` | `stratum_flows(::ChainSet, ::PositionAttribute)` | `stratum_flows` |
| `plot_termination` | `termination_summary(::ChainSet)` | `termination_summary` |
| `plot_coefficients` | a result with `coeftable` support | `fit_markov` (more later) |
| `plot_transition_matrix` | `MarkovResult` | `fit_markov` |
| `plot_fitted_lengths` | a fitted-vs-observed length result | `fit_chain_length` (planned) |
| `plot_residuals` | residuals from a fitted model | any `fit_*` |

Splitting "compute" from "draw" follows the convention used in
[REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl)
and keeps the plotting surface independent of any particular plotting
backend.

## Descriptive plots

### `plot_chain_tree`

Tree diagram of a single chain, rendered as a left-to-right cascade in
which each node is a position and each edge is a move. The intended
look follows [White (1970)](../references.md), Chapter 5: the seed
vacancy at the root, terminal external hires or abolitions at the
leaves. Useful for case-study presentation of individual chains and
for teaching the basic vacancy-propagation mechanism.

```@docs
plot_chain_tree
```

### `plot_length_distribution`

Histogram of chain lengths across a `ChainSet`. The empirical
distribution is the central descriptive statistic in
[Chase (1991)](../references.md), figure 1, and is what the planned
[`fit_chain_length`](@ref VacancyChains.fit_chain_length) estimator
will be calibrated against.

```@docs
plot_length_distribution
```

### `plot_mobility`

Flow diagram of position-to-position (or stratum-to-stratum) mobility,
defaulting to a Sankey/alluvial layout. This view of mobility data is
the one popularised by
[Cheng & Park (2020)](../references.md): treat the mobility table as a
weighted directed network of positions and visualise it as flows
between them. Other layouts (`:chord`, `:matrix`) may be added.

```@docs
plot_mobility
```

### `plot_stratum_flows`

Heatmap of stratum-to-stratum transition counts, projected through a
[`PositionAttribute`](@ref VacancyChains.PositionAttribute).
Complements `plot_mobility` when the number of strata is small enough
that a heatmap reads more clearly than a Sankey. Stratum definitions
typically follow the rank/grade conventions of
[Stewman (1986)](../references.md) or
[Smith (1983)](../references.md).

```@docs
plot_stratum_flows
```

### `plot_termination`

Bar chart of the proportion of chains terminating in each kind from
[`TERMINATION_KINDS`](@ref VacancyChains.TERMINATION_KINDS).
The split between *external hire* and *abolition* is the descriptive
statistic that lets one diagnose whether mobility is being driven by
external recruitment or by structural shrinkage of the position set —
the question motivating
[Konda & Stewman (1980)](../references.md)'s opportunity model.

```@docs
plot_termination
```

## Estimation-output plots

### `plot_coefficients`

Coefficient plot with 95% confidence intervals. Generic over any
fitted result that supports `coef` and `stderror`; the rendering
convention matches
[ggcoef](https://www.danieldsjoberg.com/ggcoef-style/) /
`coefplot` in the R/Stata ecosystems.

```@docs
plot_coefficients
```

### `plot_transition_matrix`

Heatmap of estimated transition probabilities from a
[`MarkovResult`](@ref VacancyChains.MarkovResult). The
diagonal carries the "stay" probabilities (immobility within a
stratum); off-diagonal cells carry mobility. Following
[McFarland (1970)](../references.md), the recommended diagnostic is
to overlay the *expected* diagonal under perfect mobility and examine
the gap.

```@docs
plot_transition_matrix
```

### `plot_fitted_lengths`

Fitted vs. observed chain length distribution. Compares the
empirical histogram from `chain_lengths` against the predictive
distribution implied by a fitted
[`fit_chain_length`](@ref VacancyChains.fit_chain_length) (or
[`fit_opportunity`](@ref VacancyChains.fit_opportunity)) model. The
gap between the two — particularly in the tails — is the central
diagnostic used by [Chase (1991)](../references.md) when comparing
vacancy-chain models across systems.

```@docs
plot_fitted_lengths
```

### `plot_residuals`

Diagnostic residual plot. Shape and content depend on the model: for
a Markov fit, deviation residuals on the cell counts; for a
chain-length regression, Pearson or quantile residuals on the count
distribution.

```@docs
plot_residuals
```

## References

The visualization conventions follow the canonical descriptions in
White (1970), Chase (1991), McFarland (1970), Stewman (1986), and
Cheng & Park (2020). Full citations are on the
[References](../references.md) page.
