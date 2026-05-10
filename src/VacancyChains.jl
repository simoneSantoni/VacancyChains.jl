"""
    VacancyChains.jl - Vacancy chain analysis for Julia

A Julia package for modeling vacancy chains: temporally ordered sequences
of moves in which one entity vacating a position triggers another entity
to fill it.

The public surface follows the pattern set by `REM.jl`: domain types
(`Move`, `MoveSequence`, `Chain`, `ChainSet`, `PositionAttribute`),
verb-named entry points (`load_moves`, `build_chains`, `fit_*`,
`plot_*`), and a per-feature file layout (`moves.jl`, `chain.jl`,
`eda.jl`, `estimation.jl`, `visualization.jl`).
"""
module VacancyChains

using CSV
using DataFrames
using Dates
using Distributions
using LinearAlgebra
using Printf
using Random
using SparseArrays
using Statistics
using StatsBase

# Core types
export Move, MoveSequence, Chain, ChainSet, PositionAttribute
export TERMINATION_KINDS
export is_entry, is_exit, is_internal
export origin, termination, moves
export n_chains, n_moves

# Data loading
export load_moves
export build_chains

# Exploratory data analysis
export chain_lengths, chain_multiplier
export mobility_table, stratum_flows, termination_summary
export residence_times, compute_chain_statistics

# Estimation
export MarkovResult
export fit_markov, fit_chain_length, fit_opportunity, fit_mobility
export coef, stderror, coeftable

# Visualization
export plot_chain_tree, plot_length_distribution, plot_mobility
export plot_stratum_flows, plot_termination
export plot_coefficients, plot_transition_matrix
export plot_fitted_lengths, plot_residuals

include("types.jl")
include("moves.jl")
include("chain.jl")
include("eda.jl")
include("estimation.jl")
include("visualization.jl")

end # module
