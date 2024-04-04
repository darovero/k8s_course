#!/bin/bash

# Bash script to update Kubernetes deployments based on information provided in a CSV file.

# Check if sufficient arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 namespace"
    exit 1
fi

# Define the path to the CSV file
csv_file="update_ape.csv"

# Assign the namespace argument to a variable
namespace="$1"

# Define the path to the log file
log_file="update_log_$(date +"%Y%m%d_%H%M%S").log"

# Redirect all output to the log file
exec > >(tee -a "$log_file") 2>&1

# Print a header in the log file
echo "========== Deployment Update Log - $(date) =========="

# Read the CSV file and perform the updates
{
    # Skip the first line of the CSV file containing field names
    read  
    while IFS=',' read -r deploymentname containername limitiscpu limitsmemory requestscpu requestsmemory; do
        echo "Updating deployment '$deploymentname' in namespace '$namespace' - Container: '$containername'"

        # Execute the kubectl patch command to update the deployment
        kubectl patch deployment "$deploymentname" -n "$namespace" -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$containername\",\"resources\":{\"limits\":{\"cpu\":\"$limitiscpu\",\"memory\":\"$limitsmemory\"},\"requests\":{\"cpu\":\"$requestscpu\",\"memory\":\"$requestsmemory\"}}}]}}}}"

        # Check if the command was executed successfully
        if [ $? -eq 0 ]; then
            echo "Deployment '$deploymentname' updated successfully."
        else
            echo "Error updating deployment '$deploymentname'."
        fi

    done
} < "$csv_file"

# Print completion message to the log file
echo "========== Deployment Update Completed - $(date) =========="

