#!/bin/bash

# Verificar si se proporcionaron suficientes argumentos
if [ $# -ne 2 ]; then
    echo "Uso: $0 archivo.csv namespace"
    exit 1
fi

# Asignar argumentos a variables
csv_file="$1"
namespace="$2"

# Verificar si kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "kubectl no está instalado. Por favor, instale kubectl antes de ejecutar este script."
    exit 1
fi

# Leer el archivo CSV y realizar los cambios
while IFS=',' read -r deploymentname containername limitiscpu limitsmemory requestscpu requestsmemory; do
    echo "Actualizando deployment '$deploymentname' en el namespace '$namespace' - Container: '$containername'"

    # Ejecutar el comando kubectl patch
    kubectl patch deployment "$deploymentname" -n "$namespace" -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$containername\",\"resources\":{\"limits\":{\"cpu\":\"$limitiscpu\",\"memory\":\"$limitsmemory\"},\"requests\":{\"cpu\":\"$requestscpu\",\"memory\":\"$requestsmemory\"}}}]}}}}"
    
    # Verificar si el comando fue ejecutado exitosamente
    if [ $? -eq 0 ]; then
        echo "Deployment '$deploymentname' actualizado correctamente."
    else
        echo "Error al actualizar deployment '$deploymentname'."
    fi

done < "$csv_file"

