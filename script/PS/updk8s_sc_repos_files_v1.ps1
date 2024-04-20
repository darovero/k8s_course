# Loads configuration data from CSV file
$configFile = "add_sc_repos.csv"
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
    $allowPrivilegeEscalation = $configItem.allowpe

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

    # Read YAML file contents
    $contentYAML = Get-Content -Path $yamlFilePath

    # List for storing the lines of the updated YAML file
    $newContent = @()

    # Flag to indicate if information on securityContext, and allowPrivilegeEscalation has already been found
    #$securityContextFound = $false
    $allowPrivilegeEscalationFound = $false

    # Iterate over each line of YAML content
    foreach ($line in $contentYAML) {
        # # Check if information on securityContext, and allowPrivilegeEscalation has already been found
        # if ($line -match '^\s+securityContext:') {
        #     $securityContextFound = $true
        #     continue
        # }
        if ($line -match '^\s+allowPrivilegeEscalation:') {
            $allowPrivilegeEscalationFound = $true
            continue
        }

        # If the `imagePullPolicy` key is found, add the resource and boundary lines
        if ($line -match '^\s+imagePullPolicy:') {
            $indentation = $line.IndexOf('imagePullPolicy:')
            $newContent += $line
            if (-not $securityContextFound) {
                $newContent += ("{0}securityContext:" -f (' ' * $indentation))
                $newContent += ("{0}  allowPrivilegeEscalation: $allowPrivilegeEscalation" -f (' ' * ($indentation)))
            }
            continue
        }

        # Add line to new content if it is not information about securityContext, and allowPrivilegeEscalation
        $newContent += $line
    }

    # Save the updated YAML file
    $newContent | Set-Content -Path $yamlFilePath

    # Staging changes, committing, and pushing them to the remote repository
    git add .
    git commit -m "Updated YAML $yamlFileName file with securityContext and allowPrivilegeEscalation"
    try {
        git push origin $branch
        Write-Output "Changes pushed successfully."
    } catch {
        Write-Error "Failed to push changes: $_"
    }

    # Returning to the parent directory and removing the cloned repository
    cd ..
    Remove-Item -Path $repoDirectory -Recurse -Force
}
