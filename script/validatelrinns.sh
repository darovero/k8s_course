#!/bin/bash

# Check if an argument (the namespace name) is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

# Assign the first argument to the namespace variable
namespace="$1"

# Log file with namespace name included
log_file="deployment_log_$namespace.txt"

# Log the date and time when the command is executed along with the namespace name
echo "$(date): Command executed with namespace '$namespace'" >> "$log_file"

# Execute the kubectl command with the provided namespace and custom-columns, and log the output to the log file
kubectl get deployments --namespace "$namespace" -o=custom-columns=NAME:.metadata.name,CPU_Requests:.spec.template.spec.containers[*].resources.requests.cpu,CPU_Limits:.spec.template.spec.containers[*].resources.limits.cpu,MEM_Requests:.spec.template.spec.containers[*].resources.requests.memory,MEM_Limits:.spec.template.spec.containers[*].resources.limits.memory >> "$log_file"

# Log successful execution message
echo "$(date): Script execution completed successfully." >> "$log_file"