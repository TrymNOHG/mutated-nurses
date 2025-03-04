module Validation
    # Does the nurse return within their time window?
    # Are all patients visited within their time windows?
    # Does the demand imposed on the nurses exceed their capacity?
    # 

    function correct_format(solution)
        actual_solution = []
        for i in 0:size(individual.indices, 1)
            if i == 0
                route = individual.values[1:individual.indices[1] - 1]
            elseif i == size(individual.indices, 1)
                route = individual.values[individual.indices[i]:end]
            else
                route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
            end
            actual_solution.append(route)
        end
        println(actual_solution)
    end
end