# Chain Reconstruction

A vacancy chain is reconstructed by linking moves through the positions
they vacate and fill: if move `m_i` has `from = p`, the next link
`m_{i+1}` in the chain is the earliest later move with `to = p`.

```julia
using VacancyChains

seq = MoveSequence([
    Move(actor=1, from="A",                 time=1.0),  # retirement (seed)
    Move(actor=2, from="B", to="A",         time=2.0),  # fills A, vacates B
    Move(actor=3,            to="B",         time=3.0), # external hire fills B
])

chains = build_chains(seq)
length(chains)             # 1
length(chains[1])          # 2
chains[1].termination      # :external_hire
```

Chains terminate in one of the kinds listed in `TERMINATION_KINDS`:
`:external_hire`, `:abolished`, `:open`, `:internal_exit`. The current
`:strict` reconstruction rule emits `:external_hire` and `:abolished`.

API reference: [Chain Reconstruction in Types](../api/types.md).
