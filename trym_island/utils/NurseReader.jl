# module NurseReader
#     using JSON3
#     using DataFrames
#     using Serialization

#     include("../models/Patient.jl")
#     include("../models/Depot.jl")

#     export extract_nurse_data, load_data

module NurseReader
    using JSON3, DataFrames, Serialization
    using ..Models  # Import types from Models module

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

        depot = Depot(json_obj.nbr_nurses, json_obj.capacity_nurse, json_obj.benchmark, json_obj.depot.return_time, json_obj.depot.x_coord, json_obj.depot.y_coord)
        travel_time_table = json_obj.travel_times
        n = length(travel_time_table)
        m = length(travel_time_table[1])
        flattened = Vector{Float32}(undef, n*m)
        for (i, row) in enumerate(travel_time_table)
            row_vals = Float32.(row)
            flattened[(i-1)*m + 1 : i*m] = row_vals
        end
        travel_time_array = Tuple(flattened)
        n_col = m
        tt_tuple = travel_time_array
        # return(depot, patients, tt_tuple, n_col)
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