Param
(
    [Alias('dr')]
    [bool]$DryRun = $true,

    [Alias('ng')]
    [string]$NugetKey,

    [Alias('nv')]
    [string]$NextVersion,

    [Alias('b')]
    [string]$Branch="main",

    [Alias('bt')]
    [bool]$BuildAndTest =  $true
)

$ErrorActionPreference = "Stop"

$ROOT_DIR=$pwd
$GIT_SCRIPT="$PSScriptRoot" + "\ensure_git_clean.ps1"
$CORE_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground.Core"
$CORE_ASSEMBLY_NAME="Net.Sdk.Playground.Core"
$NUGET_URL="https://api.nuget.org/v3/index.json"
$NET_CORE_VER="netcoreapp2.0"
$CHANGELOG_PATH="$ROOT_DIR" + "\CHANGELOG.md"

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
    dotnet test -f $NET_CORE_VER
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

###########################################################################
# Publish Core to the Nuget
###########################################################################

if ($DryRun) { 
    Write-Output "Dry run. Package will not be published."
}else{
    dotnet nuget push $CORE_NUPKG_PATH -k $NugetKey -s $NUGET_URL
}

exit 0