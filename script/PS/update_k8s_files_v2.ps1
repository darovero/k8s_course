# This script reads configuration data from a CSV file and performs several tasks for each configuration item.
$configFile = "configuration.csv"
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


    # Read YAML file contents
    $contentYAML = Get-Content -Path $yamlFilePath

    # List for storing the lines of the updated YAML file
    $newContent = @()

    # Flag to indicate if information on resources, limits, requests, cpu, and memory has already been found
    $resourcesFound = $false
    $limitsFound = $false
    $requestsFound = $false
    $cpuFound = $false
    $memoryFound = $false

    # Iterate over each line of YAML content
    foreach ($line in $contentYAML) {
        # Check if information on resources, limits, requests, cpu, and memory has already been found
        if ($line -match '^\s+resources:') {
            $resourcesFound = $true
            continue
        }
        if ($line -match '^\s+limits:') {
            $limitsFound = $true
            continue
        }
        if ($line -match '^\s+  requests:') {
            $requestsFound = $true
            continue
        }
        if ($line -match '^\s+    cpu:') {
            $cpuFound = $true
            continue
        }
        if ($line -match '^\s+    memory:') {
            $memoryFound = $true
            continue
        }

        # If the `imagePullPolicy` key is found, add the resource and boundary lines
        if ($line -match '^\s+imagePullPolicy:') {
            $indentacion = $line.IndexOf('imagePullPolicy:')
            $newContent += $line
            if (-not $resourcesFound) {
                $newContent += ("{0}resources:" -f (' ' * $indentacion))
                $newContent += ("{0}  requests:" -f (' ' * ($indentacion)))
                $newContent += ("{0}    cpu: $cpu_request" -f (' ' * ($indentacion)))
                $newContent += ("{0}    memory: $memory_request" -f (' ' * ($indentacion)))
            }
            if (-not $limitsFound) {
                $newContent += ("{0}  limits:" -f (' ' * ($indentacion)))
                $newContent += ("{0}    cpu: $cpu_limit" -f (' ' * ($indentacion)))
                $newContent += ("{0}    memory: $memory_limit" -f (' ' * ($indentacion)))
            }
            continue
        }

    # Add line to new content if it is not information about resources, limits, requests, cpu, and memory
    $newContent += $line
}

    # Save the updated YAML file
    $newContent | Set-Content -Path $yamlFilePath
   
    # Staging changes, committing, and pushing them to the remote repository
    git add .
    git commit -m "Added Limits & Requests to the YAML file"
    git push origin $branch

    # Returning to the parent directory and removing the cloned repository
    cd ..
    Remove-Item -Path $repoDirectory -Recurse -Force
}
