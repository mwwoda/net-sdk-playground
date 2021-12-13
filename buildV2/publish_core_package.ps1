Param
(
    [Alias('dr')]
    [bool]$DryRun = $true,

    [Alias('gh')]
    [string]$GithubToken,

    [Alias('ng')]
    [string]$NugetKey,

    [Alias('nv')]
    [string]$NextVersion,

    [Alias('b')]
    [string]$Branch="main",

    [Alias('bt')]
    [bool]$BuildAndTest =  $true
)

. $PSScriptRoot\variables.ps1

$ErrorActionPreference = "Stop"

if($NextVersion -eq $null -Or $NextVersion -eq ''){
    $NextVersion = $env:NextVersion
    if($NextVersion -eq $null -Or $NextVersion -eq ''){
        $NextVersion = (Select-String -Pattern [0-9]+\.[0-9]+\.[0-9]+ -Path $CHANGELOG_PATH | Select-Object -First 1).Matches.Value
    }
}

$CORE_NUPKG_PATH="$CORE_PROJ_DIR" + "\bin\Release\" + "$CORE_ASSEMBLY_NAME" + "." + "$NextVersion" + ".nupkg"

###########################################################################
# Parameters validation
###########################################################################

if($GithubToken -eq $null -Or $GithubToken -eq ''){
    $GithubToken = $env:GithubToken
    if($GithubToken -eq $null -Or $GithubToken -eq ''){
        Write-Output "Github token not supplied. Aborting script."
        exit 1
    }
}

if($NugetKey -eq $null -Or $NugetKey -eq ''){
    $NugetKey = $env:NugetKey
    if($NugetKey -eq $null -Or $NugetKey -eq ''){
        Write-Output "Nuget key not supplied. Aborting script."
        exit 1
    }
}

###########################################################################
# Ensure git tree is clean
###########################################################################

Invoke-Expression "& `"$GIT_SCRIPT`" -b $Branch"
if ($LASTEXITCODE -ne 0) {
   exit 1
}

###########################################################################
# Build and Test
###########################################################################

if($BuildAndTest){
    dotnet build $CORE_PROJ_DIR
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Compilation failed. Aborting script."
        exit 1
    }
    dotnet test -f $NET_CORE_VER
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Some of the unit test failed. Aborting script."
        exit 1
    }
    dotnet clean $CORE_PROJ_DIR
    if (test-path ("$CORE_PROJ_DIR" + "\bin")) { Remove-Item ("$CORE_PROJ_DIR" + "\bin") -r }
    if (test-path ("$CORE_PROJ_DIR" + "\obj")) { Remove-Item ("$CORE_PROJ_DIR" + "\obj") -r }
}else{
    Write-Output "Skipping build and test step."
}

###########################################################################
# Pack Core
###########################################################################

dotnet pack $CORE_PROJ_DIR -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Output "Package creation failed. Aborting script."
    exit 1
}

###########################################################################
# Add package to GitHub release
###########################################################################

if ($DryRun) { 
    Write-Output "Dry run. Package will not be added to the release."
}else{
    $password = ConvertTo-SecureString "$GithubToken" -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ("Release_Bot", $password)
    Set-GitHubAuthentication -SessionOnly -Credential $Cred

    $release = Get-GitHubRelease -OwnerName $REPO_OWNER -RepositoryName $REPO_NAME -Tag $NextVersion

    $release | New-GitHubReleaseAsset -Path $CORE_NUPKG_PATH
    $release | New-GitHubReleaseAsset -Path $CORE_PDB_PATH

    Clear-GitHubAuthentication
}

###########################################################################
# Publish Core to the Nuget
###########################################################################

if ($DryRun) { 
    Write-Output "Dry run. Package will not be published."
}else{
    dotnet nuget push $CORE_NUPKG_PATH -k $NugetKey -s $NUGET_URL
}

exit 0