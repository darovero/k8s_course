# Parámetros de conexión a Azure DevOps
$organization = "devopsdarovero"
$project = "Personal_Labs"
$repoName = "scripts"
$pat = "pat_powershell"  # PAT (Personal Access Token) con permisos de lectura en el repositorio

# URL para obtener los repositorios del proyecto
$reposUrl = "https://dev.azure.com/$organization/$project/_apis/git/repositories?api-version=6.0"

# Realizar la solicitud para obtener los repositorios
$reposResponse = Invoke-RestMethod -Uri $reposUrl -Headers @{Authorization = "Basic " + [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$pat"))} -Method Get

# Buscar el repositoryId del repositorio por su nombre
$repository = $reposResponse.value | Where-Object { $_.name -eq $repoName }

if ($repository -ne $null) {
    $repositoryId = $repository.id
    Write-Host "El repositoryId del repositorio '$repoName' es: $repositoryId"
} else {
    Write-Host "No se encontró el repositorio '$repoName' en el proyecto '$project'."
}
