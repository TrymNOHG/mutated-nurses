module NurseReader
    using JSON3
    using DataFrames
    using Serialization

    include("../models/Patient.jl")
    include("../models/Depot.jl")

    export extract_nurse_data, load_data

    function extract_nurse_data(file_path::String, save_path::String)
        """ This function extracts data from JSON file and then save it into a binary file for easier loading in future """
        json_obj = JSON3.read(file_path)

        patients = Vector{Patient}(undef, length(json_obj.patients))        # Changed patients from being Vector(any) to vector(patients)
        for (i, patient_info) in enumerate(json_obj.patients)
            id = patient_info[1]
            patient_info = patient_info[2]
            patients[i] = Patient(i, patient_info.x_coord, patient_info.y_coord, patient_info.demand, patient_info.start_time, patient_info.end_time, patient_info.care_time)
        end

        depot = Depot(json_obj.nbr_nurses, json_obj.capacity_nurse, json_obj.benchmark, json_obj.depot.return_time)
        travel_time_table = json_obj.travel_times
        n = length(travel_time_table)
        m = length(travel_time_table[1])
        flattened = Vector{Float64}(undef, n*m)
        for (i, row) in enumerate(travel_time_table)
            row_vals = Float64.(row)
            flattened[(i-1)*m + 1 : i*m] = row_vals
        end
        travel_time_array = Tuple(flattened)
        n_col = m
        tt_tuple = travel_time_array
        data = (depot, patients, tt_tuple, n_col)
        serialize(save_path, data)
    end

    function load_data(bin_path::String)
        return deserialize(bin_path)
    end

    # @inline function get_time(tuple::NTuple{N, Float64}, i::Int, j::Int, cols::Int) where N
    #     @inbounds return tuple[(i-1)*cols + j]
    # end

end


# module NurseReader
#     using JSON
#     using DataFrames
#     using Base.Threads
#     export extract_nurse_data
#     struct Patient
#         id::Int
#         x_coord::Int
#         y_coord::Int
#         demand::Int
#         start_time::Int
#         end_time::Int
#         care_time::Int
#     end

#     struct Depot
#         num_nurses::Int
#         nurse_cap::Int
#         benchmark::Float64
#         return_time::Int
#     end

#     function extract_nurse_data(file_path::String)
#         # Parse JSON file
#         json_data = JSON.parsefile(file_path)

#         # Convert patients from Dict{String} to Vector{Patient} with sorted IDs
#         patients = Patient[
#             Patient(parse(Int, id), p["x_coord"], p["y_coord"], p["demand"], p["start_time"], p["end_time"], p["care_time"])
#             for (id, p) in sort(json_data["patients"], by=x->parse(Int, x[1]))
#         ]

#         # Extract depot info
#         depot = Depot(
#             json_data["nbr_nurses"],
#             json_data["capacity_nurse"],
#             json_data["benchmark"],
#             json_data["depot"]["return_time"]
#         )

#         # Convert travel_times to a matrix
#         travel_time_matrix = reduce(hcat, json_data["travel_times"])
#         n_col = size(travel_time_matrix, 2)

#         return depot, patients, travel_time_matrix, n_col
#     end
# end