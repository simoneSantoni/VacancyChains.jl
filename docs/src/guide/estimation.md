# Estimation

The first-cut estimator is [`fit_markov`](@ref), a closed-form Markov
mobility model on stratum (or position) transitions. More elaborate
models (`fit_chain_length`, `fit_opportunity`, `fit_mobility`) are
reserved in the public API but currently raise `not implemented`.

```julia
using VacancyChains

# (build chains as before)

result = fit_markov(chains)

result.transition_matrix    # row-stochastic Matrix{Float64}
result.std_errors           # multinomial-row SEs
result.log_likelihood
result.converged

coef(result)                # = result.transition_matrix
stderror(result)            # = result.std_errors
coeftable(result)           # long-form DataFrame, one row per (from, to)
```

For stratum-level estimation, pass a `PositionAttribute`:

```julia
result_strat = fit_markov(chains; by=attr)
```

API reference: [Estimation API](../api/estimation.md).
