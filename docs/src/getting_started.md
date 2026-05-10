# Getting Started

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/simoneSantoni/VacancyChains.jl")
```

## A worked example

```julia
using VacancyChains

# Three moves: a retirement (seed), the move that fills the vacancy,
# and an external hire that closes the chain.
moves = [
    Move(actor=1, from="position_A",          time=1.0),
    Move(actor=2, from="position_B", to="position_A", time=2.0),
    Move(actor=3,            to="position_B", time=3.0),
]
seq = MoveSequence(moves)

# Reconstruct vacancy chains
chains = build_chains(seq)

# Descriptive summaries
println(chain_lengths(chains))      # [2]
println(chain_multiplier(chains))   # 2.0
println(termination_summary(chains))

# Fit a stratum-level Markov mobility model
result = fit_markov(chains)
println(result)
```
