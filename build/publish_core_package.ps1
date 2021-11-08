Param
(
    #[Parameter(Mandatory)]
    [Alias('dr')]
    [bool]$DryRun = $true,

    #[Parameter(Mandatory)]
    [Alias('gh')]
    [string]$GithubToken,

    #[Parameter(Mandatory)]
    [Alias('ng')]
    [string]$NugetKey,

    #[Parameter(Mandatory)]
    [Alias('nv')]
    [string]$NextVersion
)

$ErrorActionPreference = "Stop"
#.\build\release.ps1
$ROOT_DIR=$pwd
$CHANGELOG_PATH="$ROOT_DIR" + "\CHANGELOG.md"
$SLN_PATH="$ROOT_DIR" + "\Net.Sdk.Playground.sln"
$FRAMEWORK_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground"
$CORE_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground.Core"
$CORE_ASSEMBLY_NAME="Net.Sdk.Playground.Core"
$TEST_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground.Test"
$NET_CORE_VER="netcoreapp2.0"
$NET_FRAMEWORK_VER="net45"
$FRAMEWORK_DLL_PATH="$ROOT_DIR" + "\Net.Sdk.Playground\bin\Release\Net.Sdk.Playground.dll"
$NET_CORE_CSPROJ_PATH="$CORE_PROJ_DIR" + "\Net.Sdk.Playground.Core.csproj"
$ASSEMBLYINFO_PATH="$FRAMEWORK_PROJ_DIR" + "\Utility\AssemblyInfo.cs"
$NET_FRAMEWORK_NUSPEC_PATH="$FRAMEWORK_PROJ_DIR" + "\Net.Sdk.Playground.nuspec"
$REPO_OWNER="mwwoda"
$REPO_NAME="net-sdk-playground"
$NUGET_URL="https://api.nuget.org/v3/index.json"
$FRAMEWORK_NUPKG_PATH="$CORE_PROJ_DIR" + "\bin\Release\" + "$CORE_ASSEMBLY_NAME" + "." + "$NextVersion" + ".nupkg"

###########################################################################
# Ensure git tree is clean
###########################################################################

if (git status --porcelain) { exit 0 }

###########################################################################
# Pack Core
###########################################################################

dotnet pack $CORE_PROJ_DIR -c Release

###########################################################################
# Publish Core to nuget
###########################################################################

if ($DryRun) { 
    Write-Output "Running in Dry run. Package will not be published"
    exit 0
}else{
    dotnet nuget push $FRAMEWORK_NUPKG_PATH -k $NugetKey -s $NUGET_URL
}