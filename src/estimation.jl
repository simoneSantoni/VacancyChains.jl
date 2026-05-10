"""
Estimation routines for vacancy chains.

This file contains the first-cut, closed-form Markov mobility estimator.
More elaborate models (opportunity / labor-demand, chain-length
regressions, multinomial mobility) are exposed by name in
[`VacancyChains`](@ref) but raise `not implemented` until added in a later
revision.
"""

"""
    MarkovResult

Result of [`fit_markov`](@ref).

# Fields
- `transition_matrix::Matrix{Float64}`: Row-stochastic estimated transition
  probabilities between strata. Rows correspond to origin strata, columns
  to destination strata, in the order given by `stratum_names`.
- `std_errors::Matrix{Float64}`: Asymptotic SEs of the transition
  probabilities (multinomial-row variance).
- `transition_counts::Matrix{Int}`: Raw counts used to form the estimate.
- `stratum_names::Vector{String}`: Stratum labels in row/column order.
- `n_chains::Int`: Number of chains entering the estimate.
- `n_moves::Int`: Number of moves entering the estimate.
- `log_likelihood::Float64`: Log-likelihood of the data under the
  estimated transition matrix.
- `converged::Bool`: Always `true` for the closed-form estimator; kept for
  parity with iterative estimators.
"""
struct MarkovResult
    transition_matrix::Matrix{Float64}
    std_errors::Matrix{Float64}
    transition_counts::Matrix{Int}
    stratum_names::Vector{String}
    n_chains::Int
    n_moves::Int
    log_likelihood::Float64
    converged::Bool
end

function Base.show(io::IO, r::MarkovResult)
    println(io, "MarkovResult")
    println(io, "  strata     : ", join(r.stratum_names, ", "))
    println(io, "  n_chains   : ", r.n_chains)
    println(io, "  n_moves    : ", r.n_moves)
    println(io, "  loglik     : ", @sprintf("%.4f", r.log_likelihood))
    println(io, "  converged  : ", r.converged)
    println(io, "  transition probabilities:")
    show(IOContext(io, :compact => true), MIME"text/plain"(), r.transition_matrix)
end

"""
    coef(r::MarkovResult) -> Matrix{Float64}

Return the estimated transition probability matrix.
"""
coef(r::MarkovResult) = r.transition_matrix

"""
    stderror(r::MarkovResult) -> Matrix{Float64}

Return asymptotic standard errors of the transition probabilities.
"""
stderror(r::MarkovResult) = r.std_errors

"""
    coeftable(r::MarkovResult) -> DataFrame

Return a long-form table with one row per (origin, destination) cell:
columns `from_stratum`, `to_stratum`, `probability`, `std_error`, `count`.
"""
function coeftable(r::MarkovResult)
    rows = NamedTuple[]
    for (i, fs) in enumerate(r.stratum_names)
        for (j, ts) in enumerate(r.stratum_names)
            push!(rows, (
                from_stratum = fs,
                to_stratum   = ts,
                probability  = r.transition_matrix[i, j],
                std_error    = r.std_errors[i, j],
                count        = r.transition_counts[i, j],
            ))
        end
    end
    return DataFrame(rows)
end

"""
    fit_markov(cs::ChainSet; by::Union{PositionAttribute, Nothing}=nothing) -> MarkovResult

Fit a first-order Markov mobility model on stratum transitions.

If `by` is supplied, positions are projected through the attribute and
transitions are counted at the stratum level. Otherwise transitions are
counted between raw position labels.

Each chain is treated as an independent realisation of the Markov process.
For each move with origin and destination strata `s` and `t`, the
transition `s → t` is incremented. The estimator is the row-normalised
maximum-likelihood estimate. Standard errors come from the standard
multinomial-row formula `√(p̂(1−p̂)/n_s)` where `n_s` is the number of
moves originating in `s`.

Entry moves (`from === nothing`) and exit moves (`to === nothing`) are
counted under the synthetic stratum `"<external>"`, so the matrix is
square and includes external entry/exit columns.
"""
function fit_markov(cs::ChainSet; by::Union{PositionAttribute, Nothing}=nothing)
    counts = Dict{Tuple{String, String}, Int}()
    n_moves_total = 0
    for c in cs
        for m in c.moves
            o = _label(m.from, by)
            d = _label(m.to, by)
            counts[(o, d)] = get(counts, (o, d), 0) + 1
            n_moves_total += 1
        end
    end

    strata = sort!(unique(vcat([k[1] for k in keys(counts)],
                               [k[2] for k in keys(counts)])))
    k = length(strata)
    idx = Dict(s => i for (i, s) in enumerate(strata))

    C = zeros(Int, k, k)
    for ((o, d), v) in counts
        C[idx[o], idx[d]] = v
    end

    P  = zeros(Float64, k, k)
    SE = zeros(Float64, k, k)
    loglik = 0.0
    for i in 1:k
        rowsum = sum(@view C[i, :])
        rowsum == 0 && continue
        for j in 1:k
            p = C[i, j] / rowsum
            P[i, j]  = p
            SE[i, j] = sqrt(max(p * (1 - p) / rowsum, 0.0))
            C[i, j] > 0 && (loglik += C[i, j] * log(p))
        end
    end

    return MarkovResult(P, SE, C, strata, n_chains(cs), n_moves_total, loglik, true)
end

"""
    fit_chain_length(cs::ChainSet, X::AbstractMatrix; family::Symbol=:nbinom)

Fit a regression model of chain length on chain-level covariates `X`.
Not yet implemented.
"""
function fit_chain_length(::ChainSet, ::AbstractMatrix; family::Symbol=:nbinom)
    throw(ErrorException("fit_chain_length is not implemented yet"))
end

"""
    fit_opportunity(cs::ChainSet, X::AbstractMatrix)

Fit an opportunity / labor-demand model in the spirit of
Konda & Stewman (1980). Not yet implemented.
"""
function fit_opportunity(::ChainSet, ::AbstractMatrix)
    throw(ErrorException("fit_opportunity is not implemented yet"))
end

"""
    fit_mobility(cs::ChainSet, X::AbstractMatrix; model::Symbol=:multinomial)

Fit a stratum-conditional mobility model with covariates `X`. Not yet
implemented.
"""
function fit_mobility(::ChainSet, ::AbstractMatrix; model::Symbol=:multinomial)
    throw(ErrorException("fit_mobility is not implemented yet"))
end
