# VacancyChains.jl

**Vacancy chain analysis for Julia.**

A vacancy chain is a sequence of moves triggered by a single opening:
when one person leaves a position, the position they vacate is filled
by someone else, who in turn vacates *their* position, and so on. The
chain ends when the last vacancy is filled by someone from outside the
system (an "external hire") or when the position is abolished entirely.

VacancyChains.jl provides the data types and estimators needed to
reconstruct, summarise, model, and visualise these chains.

## What is a vacancy chain?

The intuition is simplest in the negative: **persons cannot move unless
there is somewhere to go**. Empty slots — *vacancies* — are what make
mobility possible.

When a vacancy appears, it propagates *backwards* through the system
relative to the flow of persons. A person moving from position
``B \to A`` is, equivalently, a vacancy moving from position
``A \to B``. Persons and vacancies are mirror images of one another in
the same dataset.

A small example. Position ``A`` opens up because its incumbent retires.
Person 2, currently in ``B``, is promoted to ``A``. That move opens
``B``, which person 3 (in ``C``) takes. ``C`` is then filled by an
external hire. The chain has three links:

```
[ Vacancy created at A by person 1's retirement ]   ← seed
                       │
                       ▼
              person 2: B  ──►  A                    ← link 1
                       │
                       ▼
              person 3: C  ──►  B                    ← link 2
                       │
                       ▼
              person 4: ∅  ──►  C                    ← link 3
                                                       (external hire,
                                                        chain terminates)
```

Three internal staff moved up the ladder; one external hire entered at
the bottom; the position structure is unchanged. None of this would
have happened without the original retirement.

In VacancyChains.jl this is the canonical example:

```julia
using VacancyChains

moves = MoveSequence([
    Move(actor=1, from="A",          time=1.0),  # retirement (seed)
    Move(actor=2, from="B", to="A",  time=2.0),  # link 1
    Move(actor=3, from="C", to="B",  time=3.0),  # link 2
    Move(actor=4,           to="C",  time=4.0),  # link 3 (external hire)
])
chains = build_chains(moves)
length(chains)            # 1
length(chains[1])         # 3
chains[1].termination     # :external_hire
```

## White's insight: persons and vacancies are duals

Harrison White's *Chains of Opportunity* (1970) made one foundational
observation: in studying mobility data, you can switch perspectives.

- **Person view.** "Person 2 moved from ``B`` to ``A``; person 3 moved
  from ``C`` to ``B``; person 4 was hired into ``C``." Three separate
  events with no obvious connection.
- **Vacancy view.** "A single vacancy was born at ``A`` by retirement;
  it moved to ``B``, then to ``C``, and was killed by an external
  hire." One coherent story with a clear birth and death.

The two views describe the same data but, mathematically, they are
*duals*: a person flow ``i \to j`` is equivalent to a vacancy flow
``j \to i``. Formally, if ``F`` is the matrix of person flows
(``F_{ij}`` = number of moves from ``i`` to ``j``), then ``F^\top`` is
the matrix of vacancy flows.

White showed that the vacancy view is often the cleaner one because
vacancies have well-defined *birth* events (something opens up — a
retirement, a death, a new position) and well-defined *death* events
(an external hire, an abolition). Persons, by contrast, can move
multiple times across many chains, making their trajectories harder to
attribute to specific causes. This gave White:

1. a unit of analysis — *the chain* — that aggregates causally
   connected moves; and
2. a tractable stochastic model: vacancies move through positions
   Markov-fashion until killed.

```
       PERSON FLOW                VACANCY FLOW (= dual)
       ───────────────►           ◄───────────────────
       2:  B  ──►  A              vacancy:  A  ──►  B
       3:  C  ──►  B              vacancy:  B  ──►  C
       4:  ∅  ──►  C              vacancy:  C  ──►  ∅  (killed)
```

## The vacancy multiplier

The simplest, most empirically useful summary of a chain set is the
**multiplier**, defined as the average number of moves per chain:

```math
M = \frac{1}{N_{\text{chains}}} \sum_{c=1}^{N_{\text{chains}}} \ell_c,
```

where ``\ell_c`` is the length (number of moves) of chain ``c``. The
multiplier is a measure of *opportunity yield*: a single retirement
that triggers ``M = 3`` moves means three internal staff get promoted
before the chain terminates.

In White's data on early-twentieth-century US Methodist, Episcopalian,
and Presbyterian clergy, multipliers ranged from roughly 1.5 to 2.5
depending on denomination and decade — a non-trivial amount of
mobility per opening, and a quantity that captures something the raw
mobility table cannot.

[`chain_multiplier`](@ref) computes ``M`` directly from a `ChainSet`:

```julia
chain_multiplier(chains)   # 3.0 in the example above
```

## Markov dynamics on vacancies

If positions can be grouped into a finite set of strata
``S = \{s_1, s_2, \ldots, s_k\}`` (e.g. job grades, geographic
regions, denominations), the vacancy process can be modelled as a
Markov chain on ``S`` with transition matrix

```math
Q_{st} = \Pr(\text{vacancy moves from } s \text{ to } t)
       = \Pr(\text{a vacancy at } s \text{ is filled by someone from } t),
```

with absorbing "external" states for chain termination. The expected
number of further moves given a vacancy currently at ``s`` is then

```math
\mathbb{E}[\ell \mid s] \;=\; \sum_{k=0}^{\infty} \sum_{t \in S} (Q^k)_{st}
\;=\; \bigl[(I - Q)^{-1} \mathbf{1}\bigr]_s,
```

where ``(I - Q)^{-1}`` is the *fundamental matrix* of the absorbing
Markov chain. This gives a closed-form prediction for chain lengths in
terms of the estimated transition matrix.

The estimator [`fit_markov`](@ref) returns the row-normalised
maximum-likelihood estimate of ``Q`` together with multinomial-row
standard errors:

```math
\widehat{Q}_{st} \;=\; \frac{N_{st}}{\sum_{u \in S} N_{su}},
\qquad
\widehat{\mathrm{SE}}(\widehat{Q}_{st}) \;=\;
\sqrt{\frac{\widehat{Q}_{st}(1 - \widehat{Q}_{st})}{N_{s\bullet}}}.
```

See the [Estimation API](api/estimation.md) page for the full
derivation and theoretical background.

## Where vacancy chains have been applied

Empirical applications span four broad domains:

| Domain | Representative work | What is the "vacancy"? |
|--------|--------------------|------------------------|
| Internal labour markets | White (1970), Stewman (1986), Smith (1983), Smith & Abbott (1983) | An open job in a firm, parish, or department |
| Public-sector careers | Konda & Stewman (1980), Rosenbaum (1979) | An open rank in the military or civil service |
| Housing markets | Various (housing-economics tradition) | An empty dwelling at a given price tier |
| Animal behaviour | Chase (1991) | An empty hermit-crab shell, nesting site, or territory |

The most striking parallel is the non-human one. Hermit crabs
occupy abandoned snail shells; when one crab finds a larger empty
shell and moves in, its old shell is taken by another crab in size
order, whose old shell is taken by a still-smaller crab, and so on
until a shell is too small for any waiting crab and is left to
deteriorate. The math is identical to White's clergy data:

```
hermit-crab system                clergy / firm system
──────────────────                ────────────────────
new large shell appears   ←→      retirement opens senior post
crab vacates old shell    ←→      promotion vacates junior post
chain ends: shell unused  ←→      chain ends: position abolished
chain ends: small new crab ←→     chain ends: external hire
```

Chase (1991) reviews the biological literature in detail and shows
that the same multiplier dynamics apply across taxa.

## Notation used in this manual

| Symbol | Meaning |
|--------|---------|
| ``S`` | Set of strata or position labels |
| ``s, t \in S`` | Generic strata |
| ``N_{st}`` | Count of moves from ``s`` to ``t`` |
| ``Q, \widehat{Q}`` | Vacancy transition matrix (true / estimated) |
| ``\ell_c`` | Length (number of moves) of chain ``c`` |
| ``M`` | Vacancy multiplier (mean chain length) |
| ``F`` | Person flow matrix; ``F^\top`` is the vacancy flow matrix |
| `<external>` | Synthetic stratum for entries (`from === nothing`) and exits (`to === nothing`) |

## Where to next

- [Getting Started](getting_started.md) — install the package and
  reproduce the multiplier example above.
- [Moves and Data](guide/moves.md) — how mobility records are
  represented as `Move` and `MoveSequence`.
- [Chain Reconstruction](guide/chains.md) — the linking rule
  [`build_chains`](@ref) uses to assemble moves into chains.
- [Estimation](api/estimation.md) — full statistical specification of
  [`fit_markov`](@ref), with the McFarland (1970) Markov-mobility
  background and the Konda & Stewman (1980) opportunity model.
- [References](references.md) — annotated bibliography of the works
  cited above.
