function benchmark()
    global state
    state[:isimmutable] && return println("Skipping: Cannot benchmark after configs are immutable")
    @show "initconfig"
    @btime initconfig()
end