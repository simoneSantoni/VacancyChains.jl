# VacancyChains.jl

[![Mobility Analysis](https://img.shields.io/badge/Mobility-Analysis-orange.svg)](https://github.com/simoneSantoni/VacancyChains.jl)
[![Build Status](https://github.com/simoneSantoni/VacancyChains.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/simoneSantoni/VacancyChains.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://simoneSantoni.github.io/VacancyChains.jl/stable/)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://simoneSantoni.github.io/VacancyChains.jl/dev/)
[![Julia](https://img.shields.io/badge/Julia-1.9+-purple.svg)](https://julialang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <img src="docs/src/assets/logo.svg" alt="VacancyChains.jl icon" width="160">
</p>

A Julia package for **vacancy chain analysis**: modeling temporally ordered sequences of moves in which an entity vacating a position triggers another entity to fill it.

## Overview

A vacancy chain begins when a position becomes open (e.g., a worker retires, a hermit crab abandons a shell) and propagates as the resulting opening is filled by another entity, who in turn vacates their own position, and so on until the chain terminates (external hire, abolition of the position, or merger). VacancyChains.jl provides tools for:

- **Chain reconstruction**: assembling temporally ordered move records into chains
- **Descriptive analysis**: chain length, multipliers, stratum transitions, and termination patterns
- **Visualization**: chain trees, mobility tables, and flow diagrams
- **Estimation**: Markov mobility models, opportunity/demand models, and chain-level regression
- **Inference visualization**: coefficient plots, transition matrices, and fitted-vs-observed diagnostics

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/simoneSantoni/VacancyChains.jl")
```

## Features

### 1. Data Organization

Functions for ingesting mobility records and reconstructing chains.

```julia
load_moves(df)                       # Load moves from a DataFrame
load_moves("moves.csv")              # Load from CSV file
MoveSequence(moves)                  # Time-sorted collection of moves
build_chains(seq; rule=:strict)      # Reconstruct chains from a move sequence
ChainSet(chains)                     # Collection of chains with stratum tracking
PositionAttribute(name, dict, default) # Position-level covariate
```

### 2. Exploratory Data Analysis

Summary statistics over chains, moves, and positions.

```julia
chain_lengths(chains)                # Vector of chain lengths
chain_multiplier(chains)             # Mean moves per initiating vacancy
mobility_table(chains; by=:stratum)  # Origin × destination move counts
stratum_flows(chains)                # Long-form flow counts between strata
termination_summary(chains)          # Counts of chain termination types
residence_times(seq)                 # Time-in-position distribution
```

### 3. Descriptive Visualization

Plot recipes for chain structure and aggregate mobility patterns.

```julia
plot_chain_tree(chain)                       # Tree diagram of a single chain
plot_length_distribution(chains)             # Histogram of chain lengths
plot_mobility(chains; layout=:sankey)        # Sankey of stratum-to-stratum flows
plot_stratum_flows(chains)                   # Heatmap of stratum transition counts
plot_termination(chains)                     # Bar chart of termination reasons
```

### 4. Estimation

Statistical models for chain dynamics and stratified mobility.

```julia
fit_markov(chains)                           # Stratum-level Markov transition model
fit_opportunity(chains, X)                   # Opportunity / labor-demand model (Konda & Stewman)
fit_chain_length(chains, X; family=:nbinom)  # Regression on chain length
fit_mobility(chains, X; model=:multinomial)  # Stratum-conditional mobility model
```

### 5. Visualization of Estimation Outcomes

Plot recipes for fitted models.

```julia
plot_coefficients(result)            # Coefficient plot with confidence intervals
plot_transition_matrix(result)       # Heatmap of estimated transition probabilities
plot_fitted_lengths(result)          # Fitted vs. observed chain length distribution
plot_residuals(result)               # Diagnostic residual plot
```

## Usage

### Basic Example

```julia
using VacancyChains

# Define a sequence of moves
moves = [
    Move(actor=1, from="position_A", to="position_B", time=1.0),
    Move(actor=2, from="position_C", to="position_A", time=2.0),
    Move(actor=3, from=nothing,      to="position_C", time=3.0),
]
seq = MoveSequence(moves)

# Reconstruct vacancy chains
chains = build_chains(seq)

# Descriptive summaries
println(chain_lengths(chains))
println(chain_multiplier(chains))

# Fit a stratum-level Markov mobility model
result = fit_markov(chains)

# View results
println(result)
```

### Result Structure

`fit_markov` returns a `MarkovResult` with:

- `transition_matrix::Matrix{Float64}`: Estimated stratum-to-stratum transition probabilities
- `std_errors::Matrix{Float64}`: Standard errors of transition probabilities
- `stratum_names::Vector{String}`: Names of strata
- `n_chains::Int`: Number of chains in the model
- `n_moves::Int`: Number of moves in the model
- `log_likelihood::Float64`: Log-likelihood at convergence
- `converged::Bool`: Whether estimation converged

```julia
# Access results
coef(result)            # Coefficient estimates
stderror(result)        # Standard errors
coeftable(result)       # Full coefficient table as DataFrame
```

### Loading Data

```julia
using DataFrames

# From DataFrame
df = DataFrame(
    actor    = [1, 2, 3],
    from     = ["position_A", "position_C", missing],
    to       = ["position_B", "position_A", "position_C"],
    time     = [1.0, 2.0, 3.0],
)
seq = load_moves(df)

# From CSV file
seq = load_moves("moves.csv")

# With position-level attributes (e.g., stratum, salary grade)
strata = PositionAttribute(:stratum,
    Dict("position_A" => "senior",
         "position_B" => "senior",
         "position_C" => "junior"),
    "unknown",
)
```

### Position Attributes

Define and use position-level attributes for stratified analysis.

```julia
# Categorical and numeric attributes
stratum = PositionAttribute(:stratum, Dict("A" => "senior", "B" => "junior"), "unknown")
salary  = PositionAttribute(:salary,  Dict("A" => 95000.0, "B" => 60000.0),  0.0)

# Use in models
fit_markov(chains; by=stratum)
fit_mobility(chains, [stratum, salary])
```

### Computing Chain Statistics Without Fitting

```julia
# Compute descriptive statistics over a ChainSet
stats_df = compute_chain_statistics(chains)

# Iterate explicitly over chains
for chain in chains
    println("Length: ", length(chain))
    println("Origin stratum: ", origin_stratum(chain))
    println("Termination: ", termination(chain))
end
```

## Utility Functions

```julia
# Chain accessors
length(chain)                        # Number of moves in a chain
origin(chain)                        # Initiating vacancy
termination(chain)                   # Termination reason
moves(chain)                         # Moves in time order

# ChainSet accessors
n_chains(chains)                     # Total number of chains
n_moves(chains)                      # Total number of moves across chains
strata(chains)                       # Set of strata involved

# Move utilities
is_internal(move)                    # Whether `from` and `to` are both internal
is_entry(move)                       # Whether `from` is external (entry into the system)
is_exit(move)                        # Whether `to` is external (exit from the system)
```

## Running Tests

```julia
include("test/runtests.jl")
```

## Documentation

For more detailed documentation, see:

- [Stable Documentation](https://simoneSantoni.github.io/VacancyChains.jl/stable/)
- [Development Documentation](https://simoneSantoni.github.io/VacancyChains.jl/dev/)

## References

1. White, H.C. (1970). *Chains of Opportunity: System Models of Mobility in Organizations*. Harvard University Press.

2. Chase, I.D. (1991). Vacancy chains. *Annual Review of Sociology*, 17, 133–154.

3. Stewman, S. (1986). Demographic models of internal labor markets. *Administrative Science Quarterly*, 31(2), 212–247.

4. Sørensen, A.B. (1977). The structure of inequality and the process of attainment. *American Sociological Review*, 42(6), 965–978.

5. Rosenbaum, J.E. (1979). Tournament mobility: Career patterns in a corporation. *Administrative Science Quarterly*, 24(2), 220–241.

6. Konda, S.L., & Stewman, S. (1980). An opportunity labor demand model and Markovian labor supply models: Comparative tests in an organizational context. *American Sociological Review*, 45(2), 276–301.

7. Cheng, S., & Park, B. (2020). Flows and boundaries: A network approach to studying occupational mobility in the labor market. *American Journal of Sociology*, 126(3), 577–631.

8. Barnett, W.P., & Miner, A.S. (1992). Standing on the shoulders of others: Career interdependence in job mobility. *Administrative Science Quarterly*, 37(2), 262–281.

## License

MIT License — see [LICENSE](LICENSE) for details.
