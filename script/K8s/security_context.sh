#!/bin/bash

# Check if the CSV file exists
if [ -f "deployments_sc.csv" ]; then
    # Read the CSV file line by line, skipping the first line
    for line in $(sed '1d' deployments_sc.csv); do
        # Read deployment and namespace from each line
        deployment=$(echo "$line" | cut -d ',' -f 1)
        namespace=$(echo "$line" | cut -d ',' -f 2)

        # Get the deployment name
        deployment_name=$(kubectl get deploy "$deployment" -n "$namespace" -o jsonpath='{.metadata.name}')

        # Get the container name
        container_name=$(kubectl get deploy "$deployment" -n "$namespace" -o=jsonpath='{.spec.template.spec.containers[*].name}')

        # Get the container image
        container_image=$(kubectl get deploy "$deployment" -n "$namespace" -o=jsonpath='{.spec.template.spec.containers[*].image}')

        # Store the information in temporary variables
        temp_deployment="$deployment_name"
        temp_container="$container_name"
        temp_image="$container_image"

        # Execute the kubectl patch command with the temporary variables
        kubectl patch deployment "$temp_deployment" -n "$namespace" --type merge --patch "{\"spec\": {\"template\": {\"spec\": {\"containers\": [{\"name\": \"$temp_container\", \"image\": \"$temp_image\", \"securityContext\": {\"allowPrivilegeEscalation\": false}}]}}}}"

        # Add a message for each deployment and namespace
        echo "Deployment $temp_deployment in namespace $namespace has been patched."
    done
else
    echo "The deployments_sc.csv file does not exist."
fi