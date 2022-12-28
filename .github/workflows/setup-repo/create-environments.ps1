#Requires -Version 3

$ErrorActionPreference = "Stop"

function CreateGitHubEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string] 
        $ownerName,
        [Parameter(Mandatory = $true)]
        [string] 
        $repoName,
        [Parameter(Mandatory = $true)]
        [string] 
        $environmentName,
        [Parameter(Mandatory = $false)]
        [bool] 
        $protectedBranches = $false
    )

    $tmp = New-TemporaryFile
    Set-Content -Path $tmp.FullName -Value @"
{
    "wait_timer": 0,
    "reviewers": [],
    "deployment_branch_policy":
    {
        "protected_branches": $( $protectedBranches ? 'true' : 'false' ),
        "custom_branch_policies": $( $protectedBranches ? 'false' : 'true' )
    }
}
"@

    # https://docs.github.com/en/rest/deployments/environments?apiVersion=2022-11-28#create-or-update-an-environment
    $request = "/repos/$ownerName/$repoName/environments/$environmentName"

    Write-Host "Creating environment '$environmentName'" -ForegroundColor Blue
    Write-Host "Request: $request" -ForegroundColor Gray
    Write-Host "Body: $( Get-Content $tmp.FullName )" -ForegroundColor Gray
    
    gh api --method PUT -H "Accept: application/vnd.github+json" $request -f name=$environmentName --input $tmp.FullName

    Remove-Item $tmp.FullName -Force
}

function CreateGitHubEnvironments {
    param (
        [Parameter(Mandatory = $true)]
        [string] 
        $ownerName,
        [Parameter(Mandatory = $true)]
        [string] 
        $repoName,
        [Parameter(Mandatory = $true)]
        [string[]] 
        $environmentNames    
    )

    foreach ($environmentName in $environmentNames) {
        CreateGitHubEnvironment -ownerName $ownerName -repoName $repoName -environmentName $environmentName -protectedBranches $( $environmentName -ne "DEV" )
    }
}

$ownerName = "dehchrist"
$repoName = "gh-workflow-demo"
$environmentNames = @("DEV", "TST", "UAT", "PRD")

gh auth login --web

CreateGitHubEnvironments -ownerName $ownerName -repoName $repoName -environmentNames $environmentNames
