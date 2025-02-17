module NurseReader
    using JSON3
    using DataFrames

    include("../models/Patient.jl")
    include("../models/Depot.jl")

    export extract_nurse_data

    function extract_nurse_data(file_path::String)
        json_obj = JSON3.read(file_path)

        patients = []
        for (i, patient_info) in enumerate(json_obj.patients)
            id = patient_info[1]
            patient_info = patient_info[2]
            push!(patients, Patient(i, patient_info.x_coord, patient_info.y_coord, patient_info.demand, patient_info.start_time, patient_info.end_time, patient_info.care_time))
        end

        depot = Depot(json_obj.nbr_nurses, json_obj.capacity_nurse, json_obj.benchmark, json_obj.depot.return_time)
        travel_time_table = json_obj.travel_times
        return depot, patients, travel_time_table
    end
   
end