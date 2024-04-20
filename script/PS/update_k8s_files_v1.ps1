# This script reads configuration data from a CSV file and performs several tasks for each configuration item.
$configFile = "configuracion.csv"
$configData = Import-Csv $configFile

foreach ($configItem in $configData) {
    # Extracting configuration parameters for each item
    $appDirectory = $configItem.appDirectory
    $yamlFileName = $configItem.yamlFileName
    $branch = $configItem.branch
    $organization = $configItem.organization
    $project = $configItem.project
    $repository = $configItem.repository
    $my_pat = $configItem.my_pat

    # Encoding Personal Access Token (PAT) to Base64 for authentication
    $b64_pat = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$my_pat"))

    # Constructing URL for Git clone operation
    $url = "https://$organization`:$my_pat@dev.azure.com/$organization/$project/_git/$repository"

    # Cloning repository using Git with authentication
    git -c "http.extraHeader=Authorization: Basic $b64_pat" clone -b $branch $url

    # Navigating into the cloned repository
    cd $repository
    $repoDirectory = Get-Location

    # Constructing path to YAML file within the repository
    $yamlFilePath = Join-Path -Path (Join-Path -Path $repoDirectory -ChildPath $appDirectory) -ChildPath $yamlFileName

    # Defining variables for resource limits and requests
    $cpu_limit = $configItem.cpu_limit
    $memory_limit = $configItem.memory_limit
    $cpu_request = $configItem.cpu_request
    $memory_request = $configItem.memory_request


    # Leer el contenido del archivo YAML
    $contenidoYAML = Get-Content -Path $yamlFilePath

    # Lista para almacenar las líneas del archivo YAML actualizado
    $nuevoContenido = @()

    # Añadir límites a las solicitudes y conservar la indentación
    foreach ($linea in $contenidoYAML) {
        $nuevoContenido += $linea

        if ($linea -match '^\s+image:') {
            $indentacion = $linea.IndexOf('image:')
            $nuevoContenido += ("{0}resources:" -f (' ' * $indentacion))
            $nuevoContenido += ("{0}  requests:" -f (' ' * ($indentacion)))
            $nuevoContenido += ("{0}    cpu: $cpu_request" -f (' ' * ($indentacion)))
            $nuevoContenido += ("{0}    memory: $memory_request" -f (' ' * ($indentacion)))
            $nuevoContenido += ("{0}  limits:" -f (' ' * ($indentacion)))
            $nuevoContenido += ("{0}    cpu: $cpu_limit" -f (' ' * ($indentacion)))
            $nuevoContenido += ("{0}    memory: $memory_limit" -f (' ' * ($indentacion)))
        }
    }

    # Guardar el archivo YAML actualizado
    $nuevoContenido | Set-Content -Path $yamlFilePath

    # Notifying successful addition of the fragment to the YAML file
    Write-Host "The fragment has been successfully added to the file $yamlFilePath."


    
    # Staging changes, committing, and pushing them to the remote repository
    git add .
    git commit -m "Added YAML fragment for Kubernetes resources"
    git push origin $branch

    # Returning to the parent directory and removing the cloned repository
    cd ..
    Remove-Item -Path $repoDirectory -Recurse -Force
}
