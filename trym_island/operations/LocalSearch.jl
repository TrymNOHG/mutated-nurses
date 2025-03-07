module LocalSearch

function LNS()
    # Removal of r # of patients based on relatedness score (should be in Fitness.jl)
    # Insertion based on heuristics (most constrained variable and least constraining value)
    # Maybe some modification of Farthest insertion heuristic
end

function remove!(r, individual, patients, travel_time_table)
    # removes list of patients 
    constrained_variables = []
    # Write actual logic
    return constrained_variables
end

function insert!()
    # Could test with different discrepancies in the search (i.e., different allowable re-insertions for a given variable)
end

end