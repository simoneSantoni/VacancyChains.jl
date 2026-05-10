# References

The package draws on a 50-year tradition of vacancy-chain and mobility
modelling. Citations on the API pages refer to entries in this list.

## Foundational works on vacancy chains

- **White, H. C.** (1970). *Chains of Opportunity: System Models of
  Mobility in Organizations*. Cambridge, MA: Harvard University Press.
  The originating monograph. Frames mobility as a system of person–job
  matches in which a single opening (a "vacancy") propagates through the
  organization until it is killed by an external hire, a death, or the
  abolition of a position. Introduces the *vacancy multiplier* and shows
  that vacancies follow Markov-like dynamics that are the dual of person
  movements.

- **White, H. C.** (1970b). Matching, vacancies, and mobility.
  *Journal of Political Economy*, 78(1), 97–105. The companion theoretical
  paper. Develops the duality between vacancy chains and person chains
  formally and gives the multiplier interpretation in steady state.

- **MacCrimmon, K. R.** (1971). Review of *Chains of Opportunity*.
  *Administrative Science Quarterly*, 16(4), 525–528. An early critique
  raising data and identification concerns that subsequent estimators
  attempted to address.

- **McFarland, D. D.** (1974). Review of *Chains of Opportunity*.
  *Contemporary Sociology*, 3(2), 109–110. Together with MacCrimmon, set
  the agenda for refining the original Markov assumptions.

- **Ginnis, M. R.** (1972). Moving vacancies: A new mobility model.
  Develops the "vacancy moves" perspective that complements White's
  person-mobility framing.

- **Chase, I. D.** (1991). Vacancy chains.
  *Annual Review of Sociology*, 17, 133–154. The canonical review.
  Synthesises empirical work across human (job-ladder) and non-human
  (hermit-crab shells, nesting sites) systems, and consolidates the
  terminology used here.

## Markov and demographic models of mobility

- **McFarland, D. D.** (1970). Intragenerational social mobility as a
  Markov process: Including a time-stationary Markovian model that
  explains observed declines in mobility rates over time.
  *American Sociological Review*, 35(3), 463–476. The standard reference
  for treating stratum-to-stratum transitions as Markov chains, on which
  [`fit_markov`](@ref VacancyChains.fit_markov) is built.

- **Stewman, S.** (1986). Demographic models of internal labor markets.
  *Administrative Science Quarterly*, 31(2), 212–247. Comprehensive
  treatment of how demographic accounting (cohort, grade-of-entry,
  time-in-rank) interacts with vacancy-chain dynamics inside firms.
  Source for the "stratified" estimators planned in
  [`fit_mobility`](@ref VacancyChains.fit_mobility).

- **Konda, S. L., & Stewman, S.** (1980). An opportunity labor demand
  model and Markovian labor supply models: Comparative tests in an
  organizational context. *American Sociological Review*, 45(2),
  276–301. Source for the planned
  [`fit_opportunity`](@ref VacancyChains.fit_opportunity)
  estimator: vacancy chains, in this view, are driven by an exogenous
  demand process that opens positions and a Markov supply process that
  fills them.

- **Sørensen, A. B.** (1977). The structure of inequality and the
  process of attainment. *American Sociological Review*, 42(6),
  965–978. Embeds vacancy-driven mobility in a broader theory of how
  positional structure produces inequality of outcomes. Motivates
  treating chain length and origin/destination strata as outcomes, not
  just process descriptors.

- **Tuma, N. B.** (1976). Rewards, resources, and the rate of mobility:
  A nonstationary multivariate stochastic model.
  *American Sociological Review*, 41(2), 338–360. Continuous-time
  alternative to the discrete-time Markov view; relevant background for
  the planned
  [`fit_chain_length`](@ref VacancyChains.fit_chain_length)
  hazard-style estimators.

## Tournament mobility and career structure

- **Rosenbaum, J. E.** (1979). Tournament mobility: Career patterns in a
  corporation. *Administrative Science Quarterly*, 24(2), 220–241.
  Argues that early-career moves disproportionately shape later
  trajectories. Justifies stratifying chain-length analyses by the
  tournament round in which a vacancy originates.

- **Smith, M. R.** (1983). Mobility in professional occupational-internal
  labor markets: Stratification, segmentation and vacancies.
  *American Sociological Review*, 48(2), 289–305. Empirical application
  of vacancy-chain ideas inside a professional ILM; discusses stratum
  definitions that map directly onto
  [`PositionAttribute`](@ref VacancyChains.PositionAttribute).

- **Smith, M. R., & Abbott, A.** (1983). A labor market perspective on
  the mobility of college football coaches.
  *Social Forces*, 61(4), 1147–1167. A canonical small-scale,
  full-population vacancy-chain dataset that the test fixtures in
  [test/runtests.jl](https://github.com/simoneSantoni/VacancyChains.jl/blob/main/test/runtests.jl)
  echo (single-position retirements seeding short chains).

- **Rosenfeld, R. A.** (1992). Job mobility and career processes.
  *Annual Review of Sociology*, 18, 39–61. Survey article situating
  vacancy chains among other approaches to studying careers.

- **Barnett, W. P., & Miner, A. S.** (1992). Standing on the shoulders
  of others: Career interdependence in job mobility.
  *Administrative Science Quarterly*, 37(2), 262–281. Empirical
  treatment of how one person's move alters the opportunity set of
  others — the social-interdependence motivation for treating chains as
  the primary unit of analysis.

## Networks and contemporary extensions

- **Cheng, S., & Park, B.** (2020). Flows and boundaries: A network
  approach to studying occupational mobility in the labor market.
  *American Journal of Sociology*, 126(3), 577–631. Reframes mobility
  data as a directed weighted network of positions; informs the design
  of [`mobility_table`](@ref VacancyChains.mobility_table) and the
  planned Sankey layout in
  [`plot_mobility`](@ref VacancyChains.plot_mobility).

## Sibling software

- **REM.jl** (Santoni, ongoing). Relational Event Models in Julia. Used
  here as a structural template for package layout, naming conventions,
  and documentation. See
  [statistical-network-analysis-with-Julia/REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl).

- **eventnet** (Lerner et al.). Java reference implementation of REM
  that REM.jl ports. Listed for completeness because the relational-event
  framing is sometimes useful for representing vacancy moves at sub-chain
  resolution.
