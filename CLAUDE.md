# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What the package is

VacancyChains.jl models **vacancy chains** — temporally ordered sequences of moves where one entity vacating a position triggers another to fill it (job-ladder mobility, hermit-crab shells). The package is scaffolded but partial: chain reconstruction, EDA, and a closed-form Markov estimator are implemented; the other `fit_*` functions and all `plot_*` functions are exported stubs that raise `ErrorException("... is not implemented yet")` so the public API in [README.md](README.md) is stable from v0.1.0 onward.

## Development commands

```bash
# Run the full test suite from the shell
julia --project -e 'using Pkg; Pkg.test()'

# Or, faster while iterating, run runtests.jl directly
julia --project -e 'include("test/runtests.jl")'

# Build the docs (separate environment under docs/)
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); include("docs/make.jl")'
```

The test suite is a single [test/runtests.jl](test/runtests.jl) with named `@testset` blocks. To run a single testset, copy its body into the REPL with the package loaded — there is no per-file test entry point and no command-line testset filter wired up.

## Architecture

The module entry point [src/VacancyChains.jl](src/VacancyChains.jl) re-exports a small surface and `include`s files in order: `types.jl`, `moves.jl`, `chain.jl`, `eda.jl`, `estimation.jl`, `visualization.jl`. This ordering matters — later files use types and helpers from earlier ones.

### Core types ([src/types.jl](src/types.jl))

- **`Move{T}`** — one mobility event with `actor`, `from`, `to`, `time::T`, `movetype`. **Either `from` or `to` may be `nothing`, but not both.** This three-valued shape is the foundation of the whole model:
  - `from === nothing` → **entry** (actor enters from outside; closes a chain because no upstream vacancy is created).
  - `to === nothing` → **exit** (actor leaves the system; *seeds* a chain by creating the initial vacancy at `from`).
  - both non-`nothing` → **internal** move; forms the body of a chain.

  Predicates `is_entry`, `is_exit`, `is_internal` encode this. The `Move{T}` inner constructor enforces "at least one side non-nothing" — don't relax this.

- **`MoveSequence{T}`** — time-sorted collection of moves with cached `actors`/`positions` sets. Iterates in time order; `push!` does sorted insertion to keep the time invariant.

- **`Chain{T}`** — ordered moves linked by vacancy propagation, carrying an `id`, `origin` position, and `termination::Symbol`. Termination must be one of `TERMINATION_KINDS = (:internal_exit, :external_hire, :abolished, :open)` — the constructor validates this.

- **`ChainSet{T}`** — collection of chains; `n_moves(cs)` may be smaller than `length(seq)` because seed (exit) moves and orphan vacancies are not part of any chain.

- **`PositionAttribute{T}`** — position-to-value mapping with a default (e.g., a stratum or salary grade). Indexed by `String` and by `Nothing` (returns the default for `nothing` positions).

### Chain reconstruction ([src/chain.jl](src/chain.jl))

`build_chains(seq; rule=:strict)` is the only linking algorithm. The `:strict` rule:

1. For every move `m_i` with `from = p`, the successor is the **earliest later move whose `to == p`** that has not already been claimed by another predecessor. Each fill is consumed at most once.
2. Chain heads are emitted in two passes:
   - **Seeded**: every exit move's `from` position is a seed; the chain proper starts at whatever fills that vacancy. **The seed exit move itself is not part of the chain** — the chain is the propagation it triggers.
   - **Unseeded**: any non-exit move never claimed as a successor (e.g. fresh-position moves whose `from` was never a `to` earlier).
3. Termination is read from the chain's last move: entry → `:external_hire`; non-`nothing` `from` (vacancy never filled) → `:abolished`; the `:open` and `:internal_exit` cases exist in `TERMINATION_KINDS` but the current walker only emits `:external_hire` and `:abolished`.
4. **Orphan vacancies** (an exit whose `from` is never filled) emit *no* chain — `n_chains` decreases silently. Tests pin this behavior.

Only `rule=:strict` is implemented. Other rule symbols `throw(ArgumentError(...))`. If you add a new rule, dispatch through this same keyword.

### EDA ([src/eda.jl](src/eda.jl))

`mobility_table`, `stratum_flows`, `chain_lengths`, `chain_multiplier`, `termination_summary`, `residence_times`, `compute_chain_statistics`. The `chain_multiplier` is White (1970)'s vacancy multiplier (mean moves per chain). All aggregations that touch positions go through a private `_label` helper that maps `nothing` to the synthetic stratum string `"<external>"` — this is how entries and exits show up in mobility tables and Markov estimates without a separate "external" type. **Don't introduce a parallel convention** for representing externals; reuse `_label`.

`residence_times` reconstructs in-position spells from consecutive moves of the same actor and only emits a row when the spells are contiguous (next move's `from` equals current move's `to`).

### Estimation ([src/estimation.jl](src/estimation.jl))

- **`fit_markov(cs; by=nothing)`** — closed-form, row-normalised MLE of a first-order Markov transition matrix over strata. With `by=nothing`, transitions are between raw position labels; with a `PositionAttribute`, positions are projected through it. Standard errors use the multinomial-row formula `√(p̂(1-p̂)/n_s)`. Each chain is treated as an independent realisation. `converged` is always `true` and is kept only for parity with future iterative estimators.
- **`MarkovResult`** — exposes `coef`, `stderror`, `coeftable` (long-form `DataFrame` with columns `from_stratum`, `to_stratum`, `probability`, `std_error`, `count`).
- **`fit_chain_length`, `fit_opportunity`, `fit_mobility`** — exported but raise `ErrorException` until implemented. Reserve their existing signatures.

### Visualization ([src/visualization.jl](src/visualization.jl))

All `plot_*` functions are exported stubs that raise. The module-level docstring explains the intent: implement them as Plots.jl recipes (or CairoMakie equivalents) consuming the `DataFrame` shapes that EDA functions already produce. The names and arities are the public API — don't rename them when implementing.

### Documentation site ([docs/](docs/))

Docs are built with `Documenter.jl` from [docs/make.jl](docs/make.jl). The docs environment has its own `Project.toml` and pulls the package in via `Pkg.develop(path=".")`. The page tree is committed in `make.jl`; if you add a new page, both add the file under `docs/src/` and register it in the `pages = [...]` block.

## Two reference resources at the repo root

These are not part of the package — they exist to inform implementation.

### `exampleOfProjects/` — structural template (REM.jl)

A complete sibling package (Relational Event Models) by the same maintainer. The VacancyChains.jl layout (verb-named entry points like `load_*`/`fit_*`/`plot_*`, per-feature files, single `runtests.jl`, separate `docs/Project.toml`) is modeled on REM.jl. **Mirror its conventions when extending VacancyChains.jl** unless there's a concrete reason to diverge — vacancy chains are chain-level (not dyadic event-level), so the *type model* will differ from REM's `Event`/`NetworkState`/statistics-as-structs design.

### `pubs/` — domain literature (untracked, mode 700)

Numbered subdirectories each holding one PDF of a foundational paper (White 1970 *Chains of Opportunity*, Chase 1991, Stewman 1986, Sørensen 1977, Rosenbaum 1979 tournament mobility, Konda & Stewman 1980 opportunity-demand, Cheng & Park 2020, etc.) plus `pubs/notes.pdf`. Read these when modeling decisions need theoretical grounding (e.g., what counts as a "seed", how to define termination kinds, which estimation targets matter for `fit_opportunity`).

## Working conventions

- **Externals are always `"<external>"`** in stratum-aggregated outputs (`mobility_table`, `stratum_flows`, `fit_markov`). Do not invent another representation.
- **Entry/exit semantics are load-bearing.** Code that reads or writes `Move` should branch on `is_entry`/`is_exit`/`is_internal` rather than re-checking `from === nothing` ad hoc — it's clearer and consistent with the docstrings.
- **Termination kinds are a closed set** (`TERMINATION_KINDS`). Adding one means updating `Chain`'s constructor check and `termination_summary`.
- **`exampleOfProjects/` and `pubs/` are deliberately untracked** by the maintainer; do not `git add` them. The git status also shows several deleted `bck/brainstorming/*`, `bck/synthesis/*`, and `claude4.6.md` paths — those are intentional removals, not work to restore.
- **Stub `fit_*` and `plot_*` are intentional.** Implement by replacing the body; do not change the exported name or arity.
