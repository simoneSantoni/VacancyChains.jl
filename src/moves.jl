"""
Move loading and parsing utilities.

Move records are accepted from CSV files or in-memory `DataFrame`s. Actors
may be supplied as integer IDs or as string names (in which case names are
mapped to integer IDs in order of first appearance).
"""

"""
    load_moves(filepath::String; kwargs...) -> MoveSequence

Load moves from a CSV file. The CSV is read with `CSV.read(filepath, DataFrame)`
and then dispatched to the `DataFrame` method below; see that method for the
keyword arguments.
"""
function load_moves(filepath::String;
                    actor_col::Symbol=:actor,
                    from_col::Symbol=:from,
                    to_col::Symbol=:to,
                    time_col::Symbol=:time,
                    type_col::Union{Symbol, Nothing}=nothing,
                    time_type::Type{T}=Float64,
                    actor_names::Bool=false) where T
    df = CSV.read(filepath, DataFrame)
    load_moves(df; actor_col, from_col, to_col, time_col, type_col,
               time_type, actor_names)
end

"""
    load_moves(df::DataFrame; kwargs...) -> MoveSequence

Build a `MoveSequence` from a `DataFrame` of mobility records.

# Keyword Arguments
- `actor_col::Symbol=:actor`: Column with actor IDs (or names if
  `actor_names=true`)
- `from_col::Symbol=:from`: Column with origin position labels; `missing`
  values are treated as entries from outside the system
- `to_col::Symbol=:to`: Column with destination position labels; `missing`
  values are treated as exits from the system
- `time_col::Symbol=:time`: Column with timestamps
- `type_col::Union{Symbol, Nothing}=nothing`: Optional column with move
  types (parsed as `Symbol`)
- `time_type::Type=Float64`: Type used to parse timestamps
- `actor_names::Bool=false`: If `true`, treat actor entries as names and
  map them to consecutive integer IDs in order of first appearance
"""
function load_moves(df::DataFrame;
                    actor_col::Symbol=:actor,
                    from_col::Symbol=:from,
                    to_col::Symbol=:to,
                    time_col::Symbol=:time,
                    type_col::Union{Symbol, Nothing}=nothing,
                    time_type::Type{T}=Float64,
                    actor_names::Bool=false) where T
    name_to_id = Dict{Any, Int}()
    if actor_names
        for nm in df[!, actor_col]
            haskey(name_to_id, nm) || (name_to_id[nm] = length(name_to_id) + 1)
        end
    end

    moves_vec = Move{T}[]
    sizehint!(moves_vec, nrow(df))

    for row in eachrow(df)
        actor = actor_names ? name_to_id[row[actor_col]] : Int(row[actor_col])
        from  = _maybe_position(row[from_col])
        to    = _maybe_position(row[to_col])
        time_val = parse_time(row[time_col], T)
        movetype = isnothing(type_col) ? :move : Symbol(row[type_col])
        push!(moves_vec, Move{T}(actor, from, to, time_val, movetype))
    end

    return MoveSequence(moves_vec)
end

_maybe_position(x::AbstractString) = String(x)
_maybe_position(::Missing) = nothing
_maybe_position(::Nothing) = nothing
_maybe_position(x) = String(string(x))

"""
    parse_time(val, ::Type{T}) where T

Parse a time value to the specified type.
"""
parse_time(val::T, ::Type{T}) where T = val
parse_time(val::Number, ::Type{T}) where T<:Number = T(val)
parse_time(val::AbstractString, ::Type{Float64}) = parse(Float64, val)
parse_time(val::AbstractString, ::Type{Int}) = parse(Int, val)
parse_time(val::AbstractString, ::Type{DateTime}) = DateTime(val)
parse_time(val::AbstractString, ::Type{Date}) = Date(val)

# Unix-seconds → DateTime convenience
parse_time(val::Number, ::Type{DateTime}) = DateTime(Dates.unix2datetime(val))
