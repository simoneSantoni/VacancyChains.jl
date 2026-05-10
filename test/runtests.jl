using VacancyChains
using Test
using DataFrames
using Dates

@testset "VacancyChains.jl" begin

    @testset "Move and MoveSequence" begin
        m1 = Move(actor=1, from="A", to="B", time=1.0)
        @test m1.actor == 1
        @test m1.from == "A"
        @test m1.to == "B"
        @test m1.time == 1.0
        @test m1.movetype == :move
        @test is_internal(m1)
        @test !is_entry(m1)
        @test !is_exit(m1)

        # Entry and exit moves
        entry = Move(actor=2, to="C", time=2.0)
        exit_m = Move(actor=3, from="D", time=3.0)
        @test is_entry(entry)
        @test is_exit(exit_m)

        # A move with neither end is rejected
        @test_throws ArgumentError Move(actor=4, time=4.0)

        # Sequence sorts by time and tracks actors/positions
        ms = MoveSequence([
            Move(actor=1, from="A", to="B", time=2.0),
            Move(actor=2, from="C", to="A", time=1.0),
            Move(actor=3, to="C",          time=3.0),
        ])
        @test length(ms) == 3
        @test [m.time for m in ms] == [1.0, 2.0, 3.0]
        @test ms.n_actors == 3
        @test ms.n_positions == 3
        @test "A" in ms.positions

        # push! preserves time order
        push!(ms, Move(actor=4, from="B", to="D", time=2.5))
        @test [m.time for m in ms] == [1.0, 2.0, 2.5, 3.0]
    end

    @testset "Data Loading" begin
        df = DataFrame(
            actor = [1, 2, 3],
            from  = ["A", "C", missing],
            to    = ["B", "A", "C"],
            time  = [2.0, 1.0, 3.0],
        )
        ms = load_moves(df)
        @test length(ms) == 3
        @test [m.time for m in ms] == [1.0, 2.0, 3.0]
        @test ms[3].from === nothing  # missing → nothing (entry)

        # Actor names → integer IDs
        df2 = DataFrame(
            actor = ["alice", "bob", "alice"],
            from  = ["A", "B", "C"],
            to    = ["B", "C", "D"],
            time  = [1.0, 2.0, 3.0],
        )
        ms2 = load_moves(df2; actor_names=true)
        @test length(ms2) == 3
        @test ms2[1].actor == ms2[3].actor   # alice mapped to same ID twice
        @test ms2[1].actor != ms2[2].actor
    end

    @testset "build_chains: simple two-link chain" begin
        # Seed: actor 1 retires from A. Then actor 2 moves B→A.
        # Then actor 3 enters and fills B (external hire).
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),  # exit (seed)
            Move(actor=2, from="B", to="A", time=2.0),  # fills A, vacates B
            Move(actor=3,            to="B", time=3.0), # external hire fills B
        ])
        cs = build_chains(ms)
        @test n_chains(cs) == 1
        c = cs[1]
        @test length(c) == 2
        @test origin(c) == "A"
        @test termination(c) == :external_hire
        @test [m.time for m in c.moves] == [2.0, 3.0]
    end

    @testset "build_chains: abolished termination" begin
        # Seed exits A. Actor 2 fills A from B. Vacancy at B is never filled.
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
        ])
        cs = build_chains(ms)
        @test n_chains(cs) == 1
        @test termination(cs[1]) == :abolished
    end

    @testset "build_chains: orphan vacancy is silent" begin
        # Seed exits A but no later move ever fills A.
        ms = MoveSequence([
            Move(actor=1, from="A", time=1.0),
        ])
        cs = build_chains(ms)
        @test n_chains(cs) == 0
    end

    @testset "build_chains: rejects unknown rule" begin
        ms = MoveSequence([Move(actor=1, from="A", time=1.0)])
        @test_throws ArgumentError build_chains(ms; rule=:nonsense)
    end

    @testset "EDA: lengths, multiplier, terminations" begin
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
            Move(actor=4, from="C",         time=4.0),
            Move(actor=5, from="D", to="C", time=5.0),
        ])
        cs = build_chains(ms)
        @test n_chains(cs) == 2
        @test sort(chain_lengths(cs)) == [1, 2]
        @test chain_multiplier(cs) ≈ 1.5

        ts = termination_summary(cs)
        @test sum(ts.count) == n_chains(cs)
        # Exactly one external_hire and one abolished
        @test ts[ts.termination .== :external_hire, :count][1] == 1
        @test ts[ts.termination .== :abolished,     :count][1] == 1
    end

    @testset "EDA: mobility_table covers all moves" begin
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
        ])
        cs = build_chains(ms)
        df = mobility_table(cs)
        # Total cell sum = number of moves in chains
        n = sum([sum(df[!, c]) for c in names(df) if c != "origin"])
        @test n == n_moves(cs)
    end

    @testset "EDA: stratum_flows respects PositionAttribute" begin
        attr = PositionAttribute(:level,
            Dict("A" => "senior", "B" => "junior"),
            "unknown",
        )
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
        ])
        cs = build_chains(ms)
        flows = stratum_flows(cs, attr)
        @test "junior" in flows.from_stratum
        @test "senior" in flows.to_stratum
        @test sum(flows.count) == n_moves(cs)
    end

    @testset "EDA: residence_times" begin
        # Actor 1 enters A, then moves A→B
        ms = MoveSequence([
            Move(actor=1,            to="A", time=1.0),
            Move(actor=1, from="A", to="B",  time=4.0),
        ])
        rt = residence_times(ms)
        @test nrow(rt) == 1
        @test rt[1, :position] == "A"
        @test rt[1, :duration] == 3.0
    end

    @testset "EDA: compute_chain_statistics" begin
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
        ])
        cs = build_chains(ms)
        df = compute_chain_statistics(cs)
        @test nrow(df) == 1
        @test df[1, :length] == 2
        @test df[1, :duration] == 1.0
        @test df[1, :termination] == :external_hire
    end

    @testset "Estimation: fit_markov" begin
        # Two parallel chains so the Markov estimate is non-degenerate
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
            Move(actor=4, from="A",         time=4.0),
            Move(actor=5, from="B", to="A", time=5.0),
            Move(actor=6,            to="B", time=6.0),
        ])
        cs = build_chains(ms)
        result = fit_markov(cs)

        @test result.converged
        @test result.n_chains == n_chains(cs)
        @test result.n_moves  == n_moves(cs)

        # Each non-zero row of the transition matrix sums to 1
        for i in 1:size(result.transition_matrix, 1)
            row = result.transition_matrix[i, :]
            s = sum(row)
            @test s ≈ 0.0 || s ≈ 1.0
        end

        # coeftable round-trip
        ct = coeftable(result)
        @test "from_stratum" in names(ct)
        @test "probability"  in names(ct)
        @test sum(ct.count) == n_moves(cs)
    end

    @testset "Estimation stubs raise" begin
        ms = MoveSequence([Move(actor=1, from="A", to="B", time=1.0)])
        cs = build_chains(ms)  # may be empty, that's fine for the stub check
        X = zeros(0, 0)
        @test_throws ErrorException fit_chain_length(cs, X)
        @test_throws ErrorException fit_opportunity(cs, X)
        @test_throws ErrorException fit_mobility(cs, X)
    end

    @testset "Visualization stubs raise" begin
        ms = MoveSequence([
            Move(actor=1, from="A",         time=1.0),
            Move(actor=2, from="B", to="A", time=2.0),
            Move(actor=3,            to="B", time=3.0),
        ])
        cs = build_chains(ms)
        attr = PositionAttribute(:level, Dict("A" => "senior"), "junior")

        @test_throws ErrorException plot_chain_tree(cs[1])
        @test_throws ErrorException plot_length_distribution(cs)
        @test_throws ErrorException plot_mobility(cs)
        @test_throws ErrorException plot_stratum_flows(cs, attr)
        @test_throws ErrorException plot_termination(cs)
        @test_throws ErrorException plot_coefficients(nothing)
        @test_throws ErrorException plot_fitted_lengths(nothing)
        @test_throws ErrorException plot_residuals(nothing)

        result = fit_markov(cs)
        @test_throws ErrorException plot_transition_matrix(result)
    end
end
