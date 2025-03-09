module LocalSearch

function LNS(rem_rat=0.1)

    # Removal of r # of patients based on relatedness score (should be in Fitness.jl)
    # Insertion based on heuristics (most constrained variable and least constraining value)
    # Maybe some modification of Farthest insertion heuristic
end

function remove!(r, individual, patients, travel_time_table)
    # removes list of patients 
    constrained_variables = []

    ### High Travel Time Removal ###
    # Considerations: 
    # Should the travel time of i be just the sum of the time from i-1 to i + i to i+1? 
    # Should the travel time be the "cost of insertion"?
    from = 1
    for (i, route) in enumerate(individual)
        
    end

    #################################
    
    # Write actual logic
    return constrained_variables
end

function insert!()
    # Could test with different discrepancies in the search (i.e., different allowable re-insertions for a given variable)
end

function relatedness()

end

end