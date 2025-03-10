import json
import argparse

def convert_instance(json_path, output_path):
    # Load JSON data
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    # Extract fields from JSON
    instance_name = data.get("instance_name", "instance")
    nbr_nurses = data.get("nbr_nurses", 0)
    capacity_nurse = data.get("capacity_nurse", 0)
    depot = data["depot"]
    patients = data["patients"]
    travel_times = data["travel_times"]

    # Dimension: 1 (depot) + number of patients
    num_patients = len(patients)
    dimension = 1 + num_patients

    # Sort patients by key (as integers) for consistent ordering
    sorted_patient_keys = sorted(patients, key=lambda k: int(k))

    with open(output_path, 'w') as f:
        # Write header information
        f.write(f"NAME : {instance_name}\n")
        f.write("COMMENT : Converted instance\n")
        f.write("TYPE : VRPTW\n")
        f.write(f"DIMENSION : {dimension}\n")
        f.write("EDGE_WEIGHT_TYPE : EXPLICIT\n")
        f.write(f"VEHICLES : {nbr_nurses}\n")
        f.write("EDGE_WEIGHT_FORMAT : FULL_MATRIX\n")
        f.write(f"CAPACITY : {capacity_nurse}\n")
        
        # Write EDGE_WEIGHT_SECTION (the travel time matrix)
        f.write("EDGE_WEIGHT_SECTION\n")
        for row in travel_times:
            # row_str = "\t".join(str((x)) for x in row)
            row_str = "\t".join(str(round(x*1)) for x in row)
            f.write(row_str + "\n")
        
        # Write NODE_COORD_SECTION
        f.write("NODE_COORD_SECTION\n")
        # Customer 1 is the depot
        f.write(f"1\t{depot['x_coord']*1}\t{depot['y_coord']*1}\n")
        # Subsequent customers: each patient (customer indices 2, 3, …)
        for idx, key in enumerate(sorted_patient_keys, start=2):
            patient = patients[key]
            f.write(f"{idx}\t{patient['x_coord']}\t{patient['y_coord']}\n")
        
        # Write DEMAND_SECTION
        f.write("DEMAND_SECTION\n")
        # Depot demand is 0
        f.write("1\t0\n")
        for idx, key in enumerate(sorted_patient_keys, start=2):
            patient = patients[key]
            f.write(f"{idx}\t{patient['demand']}\n")
        
        # Write DEPOT_SECTION
        f.write("DEPOT_SECTION\n")
        f.write("1\n-1\n")
        
        # Write SERVICE_TIME_SECTION
        f.write("SERVICE_TIME_SECTION\n")
        # Depot service time is 0
        f.write("1\t0\n")
        for idx, key in enumerate(sorted_patient_keys, start=2):
            patient = patients[key]
            f.write(f"{idx}\t{patient['care_time']*1}\n")
        
        # Write TIME_WINDOW_SECTION
        f.write("TIME_WINDOW_SECTION\n")
        # For depot: ready time is 0, due date is depot.return_time
        f.write(f"1\t0\t{depot['return_time']*1}\n")
        for idx, key in enumerate(sorted_patient_keys, start=2):
            patient = patients[key]
            f.write(f"{idx}\t{patient['start_time']*1}\t{patient['end_time']*1 - patient['care_time']*1}\n")
        
        f.write("EOF\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert VRPTW JSON to Solomon format")
    parser.add_argument("--input", required=True, help="Path to the input JSON file")
    parser.add_argument("--output", required=True, help="Path to the output TXT file")
    args = parser.parse_args()
    convert_instance(args.input, args.output)
