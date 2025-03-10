module Visualization

using Plots

include("Modules.jl")
using .Modules

include("utils/NurseReader.jl")
using .NurseReader

export plot_patient_routes, graph_solution

function plot_patient_routes(id_routes, patients, depot_coords::Tuple{Int,Int}=(0,0), filename::String="patient_routes.png")
    """
    The creation of this code was heavily aided by Claude LLM.
    """
    routes = []
    for route in id_routes
        current_route = []
        for patient_id in route
            push!(current_route, patients[patient_id])
        end
        push!(routes, current_route)
    end

    p = plot(
        title = "Patient Routes Visualization",
        xlabel = "X Coordinate",
        ylabel = "Y Coordinate",
        legend = :topright,
        size = (800, 600),
        aspect_ratio = :equal
    )
    
    scatter!([depot_coords[1]], [depot_coords[2]], 
             label = "Depot", 
             marker = :square,
             markersize = 8,
             color = :black)
    
    colors = distinguishable_colors(length(routes), [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
    
    route_idx = 1
    for route in routes
        if isempty(route)
            continue
        end
        
        xs = [p.x_coord for p in route]
        ys = [p.y_coord for p in route]
        ids = [p.id for p in route]
        
        route_xs = [depot_coords[1]; xs; depot_coords[1]]
        route_ys = [depot_coords[2]; ys; depot_coords[2]]
        
        plot!(route_xs, route_ys, 
              label = "Route $(route_idx)",
              linewidth = 2,
              color = colors[route_idx],
              alpha = 0.7)
        
        scatter!(xs, ys, 
                 label = "",
                 color = colors[route_idx],
                 markersize = 6)
        
        for i in 1:length(ids)
            annotate!(xs[i], ys[i] + 0.5, text("$(ids[i])", 8, :center, colors[route_idx]))
        end
        route_idx += 1
    end
    
    savefig(p, filename)
    println("Plot saved as $(filename)")
    
    return p
end

function load_routes_array_from_file(filename::String)::Vector{Vector{Int}}
    # Initialize routes container
    routes = Vector{Vector{Int}}()
    
    # Open and read the entire file content
    content = open(filename, "r") do file
        read(file, String)
    end
    
    # Remove whitespace and parse the content as a Julia expression
    # This handles the format [[1,2,3], [4,5]]
    try
        parsed_array = eval(Meta.parse(content))
        
        # Verify it's a Vector of Vectors
        if parsed_array isa Vector && all(route -> route isa Vector, parsed_array)
            routes = parsed_array
        else
            error("File does not contain a properly formatted 2D array")
        end
    catch e
        println("Error parsing file: $e")
    end
    
    return routes
end

function graph_solution(solution_filename::String, json_file="./data/bin/serialized_train_9.bin")
    depot, patients, tt_tuple, n_col = load_data(json_file)
    routes = load_routes_array_from_file(solution_filename)
    plot_patient_routes(routes, patients, (depot.x_coord, depot.y_coord))
end

end