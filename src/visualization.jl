"""
Visualization stubs.

Plot functions are exported under their final names but currently raise
`not implemented` errors. They are intended to be implemented as
[Plots.jl](https://docs.juliaplots.org) recipes (or CairoMakie equivalents)
in a follow-up revision; keeping the names reserved here means the public
API in [README.md](README.md) is stable from v0.1.0 onward.

Each function returns a value suitable for display; the data shapes that
will feed them are already produced by [`mobility_table`](@ref),
[`stratum_flows`](@ref), [`termination_summary`](@ref),
[`chain_lengths`](@ref), and [`coeftable`](@ref).
"""

# Descriptive plots ----------------------------------------------------------

"""
    plot_chain_tree(chain::Chain)

Tree diagram of a single chain. Not yet implemented.
"""
plot_chain_tree(::Chain) =
    throw(ErrorException("plot_chain_tree is not implemented yet"))

"""
    plot_length_distribution(cs::ChainSet)

Histogram of chain lengths. Not yet implemented.
"""
plot_length_distribution(::ChainSet) =
    throw(ErrorException("plot_length_distribution is not implemented yet"))

"""
    plot_mobility(cs::ChainSet; layout::Symbol=:sankey, by=nothing)

Flow diagram of stratum-to-stratum mobility. `layout=:sankey` requests a
Sankey/alluvial layout; other layouts (`:chord`, `:matrix`) may be added.
Not yet implemented.
"""
plot_mobility(::ChainSet; layout::Symbol=:sankey, by=nothing) =
    throw(ErrorException("plot_mobility is not implemented yet"))

"""
    plot_stratum_flows(cs::ChainSet, attr::PositionAttribute)

Heatmap of stratum transition counts. Not yet implemented.
"""
plot_stratum_flows(::ChainSet, ::PositionAttribute) =
    throw(ErrorException("plot_stratum_flows is not implemented yet"))

"""
    plot_termination(cs::ChainSet)

Bar chart of chain termination kinds. Not yet implemented.
"""
plot_termination(::ChainSet) =
    throw(ErrorException("plot_termination is not implemented yet"))

# Estimation-output plots ----------------------------------------------------

"""
    plot_coefficients(result)

Coefficient plot with 95% confidence intervals. Not yet implemented.
"""
plot_coefficients(::Any) =
    throw(ErrorException("plot_coefficients is not implemented yet"))

"""
    plot_transition_matrix(result::MarkovResult)

Heatmap of estimated transition probabilities. Not yet implemented.
"""
plot_transition_matrix(::MarkovResult) =
    throw(ErrorException("plot_transition_matrix is not implemented yet"))

"""
    plot_fitted_lengths(result)

Fitted vs. observed chain length distribution. Not yet implemented.
"""
plot_fitted_lengths(::Any) =
    throw(ErrorException("plot_fitted_lengths is not implemented yet"))

"""
    plot_residuals(result)

Diagnostic residual plot. Not yet implemented.
"""
plot_residuals(::Any) =
    throw(ErrorException("plot_residuals is not implemented yet"))
