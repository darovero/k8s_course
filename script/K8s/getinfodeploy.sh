#!/bin/bash

NAMESPACE=$1
OUTPUT_FILE="deployment_containers.csv"

echo "Deployment Name,Container Name" > $OUTPUT_FILE

deployments=$(kubectl get deployments -n $NAMESPACE -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

for deployment in $deployments; do
    containers=$(kubectl get deployment $deployment -n $NAMESPACE -o=jsonpath='{.spec.template.spec.containers[*].name}')
    for container in $containers; do
        echo "$deployment,$container" >> $OUTPUT_FILE
    done
done

echo "La información ha sido exportada a $OUTPUT_FILE"

