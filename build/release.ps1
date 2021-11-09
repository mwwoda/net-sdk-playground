Param
(
    [Alias('dr')]
    [bool]$DryRun = $true,

    [Parameter(Mandatory)]
    [Alias('gh')]
    [string]$GithubToken,

    [Parameter(Mandatory)]
    [Alias('nv')]
    [string]$NextVersion,

    [Alias('rs')]
    [string]$ReleaseNotes="Release notes"
)

$ErrorActionPreference = "Stop"

$ROOT_DIR=$pwd
$FRAMEWORK_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground"
$CORE_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground.Core"
$NET_CORE_CSPROJ_PATH="$CORE_PROJ_DIR" + "\Net.Sdk.Playground.Core.csproj"
$REPO_OWNER="mwwoda"
$REPO_NAME="net-sdk-playground"
$FRAMEWORK_NUPKG_PATH=$FRAMEWORK_PROJ_DIR + "\Net.Sdk.Playground." + $NextVersion + ".nupkg"
$FRAMEWORK_PDB_PATH=$FRAMEWORK_PROJ_DIR + "\bin\Release\Net.Sdk.Playground.pdb"
$CORE_NUPKG_PATH=$CORE_PROJ_DIR + "\bin\Release\Net.Sdk.Playground.Core." + $NextVersion + ".nupkg"
$CORE_PDB_PATH=$CORE_PROJ_DIR + "\bin\Release\netstandard2.0\Net.Sdk.Playground.Core.pdb"

###########################################################################
# Create git release
###########################################################################

if($DryRun){
    Write-Output "Dry run. Release will not be created."
}else{
    $password = ConvertTo-SecureString "$GithubToken" -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ("Release_Bot", $password)
    Set-GitHubAuthentication -SessionOnly -Credential $Cred
    $releaseParams = @{
        OwnerName = $REPO_OWNER
        RepositoryName = $REPO_NAME
        Tag = "v" + $NextVersion
        Name = "v" + $NextVersion
        Body = $ReleaseNotes
    }
    $release = New-GitHubRelease @releaseParams
 
    $release | New-GitHubReleaseAsset -Path $FRAMEWORK_NUPKG_PATH
    $release | New-GitHubReleaseAsset -Path $FRAMEWORK_PDB_PATH
    $release | New-GitHubReleaseAsset -Path $CORE_NUPKG_PATH
    $release | New-GitHubReleaseAsset -Path $CORE_PDB_PATH

    Clear-GitHubAuthentication
}

exit 0