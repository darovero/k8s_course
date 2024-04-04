#!/bin/bash

# Definir el nombre del archivo CSV
csv_file="deployments_sc.csv"

# Verificar si el archivo CSV proporcionado existe
if [ ! -f "$csv_file" ]; then
    echo "El archivo CSV \"$csv_file\" no existe."
    exit 1
fi

# Iterar sobre cada línea del archivo CSV, omitiendo la primera línea
{
    read -r header   # Leer la primera línea y descartarla
    while IFS=',' read -r deployment namespace; do
        # Realizar el describe de la deployment
        describe_output=$(kubectl describe deployment "$deployment" -n "$namespace" 2>/dev/null)

        # Extraer el nombre del deployment, el nombre del contenedor y la imagen del describe
        deployment_name=$(echo "$describe_output" | awk '/^Name:/ {print $2}')
        container_name=$(echo "$describe_output" | awk '/^Container ID:/ {print $2}')
        container_image=$(echo "$describe_output" | awk '/^Image:/ {print $2}')

        # Mostrar la información obtenida
        echo "Información obtenida de la deployment \"$deployment\" en el namespace \"$namespace\":"
        echo "Deployment Name: $deployment_name"
        echo "Container Name: $container_name"
        echo "Container Image: $container_image"

        # Ejecutar kubectl patch con las variables obtenidas
        kubectl patch deployment "$deployment_name" -n "$namespace" --type merge --patch "{\"spec\": {\"template\": {\"spec\": {\"containers\": [{\"name\": \"$container_name\", \"image\": \"$container_image\", \"securityContext\": {\"allowPrivilegeEscalation\": false}}]}}}}"

        echo "Se ha actualizado la deployment \"$deployment_name\" en el namespace \"$namespace\" con la imagen \"$container_image\"."
        echo ""
    done
} < "$csv_file"