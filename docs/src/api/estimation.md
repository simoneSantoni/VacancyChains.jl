# Estimation API

VacancyChains.jl provides one implemented estimator and three reserved
names. The implemented estimator,
[`fit_markov`](@ref VacancyChains.fit_markov), is a closed-form
maximum-likelihood fit of a first-order Markov mobility model on
position (or stratum) transitions. The reserved names —
[`fit_chain_length`](@ref VacancyChains.fit_chain_length),
[`fit_opportunity`](@ref VacancyChains.fit_opportunity),
[`fit_mobility`](@ref VacancyChains.fit_mobility) — currently raise
`not implemented`; they are documented here so callers can plan against
a stable public API.

## `fit_markov`: first-order Markov mobility

### Statistical model

Let ``S`` be the (finite) set of strata or position labels and let
``N_{st}`` be the number of moves in the data whose origin label is
``s \in S`` and destination is ``t \in S``. The first-order Markov
model assumes that, conditional on origin ``s``, the destination is
drawn from a multinomial distribution

```math
P(\text{destination} = t \mid \text{origin} = s) = p_{st},
\qquad \sum_{t \in S} p_{st} = 1.
```

Treating each chain as an independent realisation of the Markov
process, the row-conditional log-likelihood is

```math
\ell(P) = \sum_{s \in S} \sum_{t \in S} N_{st} \log p_{st}.
```

The maximum-likelihood estimator is the row-normalised count matrix,

```math
\widehat{p}_{st} = \frac{N_{st}}{\sum_{u \in S} N_{su}},
```

which is what [`fit_markov`](@ref VacancyChains.fit_markov) returns in
`MarkovResult.transition_matrix`. Asymptotic standard errors come from
the standard multinomial-row formula,

```math
\widehat{\mathrm{SE}}(\widehat{p}_{st})
= \sqrt{\frac{\widehat{p}_{st}(1 - \widehat{p}_{st})}{N_{s\bullet}}},
\qquad N_{s\bullet} = \sum_{u \in S} N_{su},
```

returned in `MarkovResult.std_errors`. Rows whose origin never appears
have all-zero rows (`p̂` is undefined there); the field
`MarkovResult.transition_counts` exposes the underlying ``N_{st}`` for
inspection.

### Theoretical context

The Markov view of mobility predates vacancy-chain modelling. The
canonical statement is [McFarland (1970)](../references.md), who showed
that intragenerational mobility tables are well-approximated by
time-stationary Markov chains under fairly broad conditions. White's
[*Chains of Opportunity*](../references.md) builds on this by
*reversing* the direction of analysis — he models the trajectory of
*vacancies* rather than persons, and shows that under regularity
conditions the vacancy process is itself Markovian and is the dual of
the person mobility process.

`fit_markov` therefore admits two interpretations of the same
estimate:

- *Person mobility view*: ``\widehat{p}_{st}`` is the probability that
  a person in stratum ``s`` who moves next moves to ``t``.
- *Vacancy mobility view*: ``\widehat{p}_{st}`` is the probability
  that a vacancy in ``t`` (yes, ``t``) is filled from ``s`` — the rows
  of the transposed matrix carry vacancy-flow probabilities.

Both interpretations are first-order: history beyond the immediate
predecessor is ignored. [Stewman (1986)](../references.md) is the
standard reference for higher-order and demographically-stratified
extensions; those motivate the planned estimators below.

### Treating entries and exits

Entry moves (`from === nothing`) and exit moves (`to === nothing`) are
collapsed into a synthetic stratum `"<external>"` so that the matrix
is square and includes external entry/exit columns. This convention
follows [Stewman (1986)](../references.md) and matches the
data-organisation choice made by
[Smith & Abbott (1983)](../references.md) for the college-football
coaching market, where retirements and external hires are treated as
boundary moves of the same process.

```@docs
fit_markov
```

## `MarkovResult` and accessors

`MarkovResult` follows the conventions of
[`StatsAPI`](https://github.com/JuliaStats/StatsAPI.jl): the
`coef` / `stderror` / `coeftable` triple gives consistent access to
the estimate regardless of which estimator produced it. `coeftable`
returns a long-form `DataFrame` (one row per origin–destination cell)
suitable for joining against position-level covariates or for direct
plotting.

```@docs
MarkovResult
coef
stderror
coeftable
```

## Reserved estimators (not yet implemented)

These names are exported so that downstream code can bind against them
today; they currently raise `ErrorException` with a message stating
"not implemented". The intended specifications are below.

### `fit_chain_length`

A regression of chain length on chain-level covariates. The default
family will be Negative Binomial because empirical chain-length
distributions are typically over-dispersed
([Chase 1991](../references.md), figure 1). Continuous-time
alternatives in the spirit of
[Tuma (1976)](../references.md) — modelling time-to-termination
hazards rather than counts — are a natural follow-up.

```@docs
fit_chain_length
```

### `fit_opportunity`

A joint estimator for the opportunity / labor-demand model of
[Konda & Stewman (1980)](../references.md). The model decomposes the
observed transition rates into

- a *demand* component — the rate at which positions of each type
  open, treated as an exogenous input; and
- a *supply* component — a Markov fill process operating on the
  resulting vacancies.

The estimator returns separate parameters for the two components,
which is what lets it diagnose mobility shifts driven by changes in
opportunity structure (e.g. organisational growth or contraction)
versus changes in mobility behaviour conditional on opportunity.

```@docs
fit_opportunity
```

### `fit_mobility`

A stratum-conditional mobility model in which destination probabilities
depend on covariates `X`, defaulting to a multinomial logit
specification. This generalises [`fit_markov`](@ref) by letting the
transition probabilities depend on attributes of the moving actor or
the originating vacancy (cohort, tenure, grade-of-entry — the standard
covariates in [Stewman 1986](../references.md), §III–IV). It also
provides the natural fitting target for stratum definitions encoded as
a [`PositionAttribute`](@ref VacancyChains.PositionAttribute).

```@docs
fit_mobility
```

## References

The estimator design and naming follow the canonical mobility-modelling
literature: McFarland (1970) and Stewman (1986) for the Markov and
demographic-Markov views, White (1970) and Chase (1991) for the
vacancy-process duality, Konda & Stewman (1980) for the
opportunity / labor-demand decomposition, Tuma (1976) for continuous-time
extensions, and Cheng & Park (2020) for network reframings of mobility
tables. Full citations are on the [References](../references.md) page.
