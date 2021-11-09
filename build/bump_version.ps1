Param
(
    [Alias('dr')]
    [bool]$DryRun = $true,

    [Parameter(Mandatory)]
    [Alias('gh')]
    [string]$GithubToken,

    [Alias('b')]
    [string]$Branch="main"
)

$ErrorActionPreference = "Stop"

$ROOT_DIR=$pwd
$GIT_SCRIPT="$PSScriptRoot" + "\ensure_git_clean.ps1"
$CHANGELOG_PATH="$ROOT_DIR" + "\CHANGELOG.md"
$FRAMEWORK_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground"
$CORE_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground.Core"
$CORE_CSPROJ_PATH="$CORE_PROJ_DIR" + "\Net.Sdk.Playground.Core.csproj"
$ASSEMBLYINFO_PATH="$FRAMEWORK_PROJ_DIR" + "\Utility\AssemblyInfo.cs"
$FRAMEWORK_NUSPEC_PATH="$FRAMEWORK_PROJ_DIR" + "\Net.Sdk.Playground.nuspec"
$REPO_OWNER="mwwoda"
$REPO_NAME="net-sdk-playground"

###########################################################################
# Ensure git tree is clean
###########################################################################

Invoke-Expression "& `"$GIT_SCRIPT`" -b $Branch"
if ($LASTEXITCODE -ne 0) {
    exit 1
}

###########################################################################
# Update changelog
###########################################################################

standard-version release --skip.commit --skip.tag
$NEXT_VERSION = (Select-String -Pattern [0-9]+\.[0-9]+\.[0-9]+ -Path $CHANGELOG_PATH | Select-Object -First 1).Matches.Value
$NEXT_VERSION_TAG = "v" + "$NEXT_VERSION"
$RELEASE_DATE = (Select-String -Pattern "\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])" -Path $CHANGELOG_PATH | Select-Object -First 1).Matches.Value
$RELEASE_NOTE_LINK = $NEXT_VERSION.Replace(".", "") + "-" + "$RELEASE_DATE"

###########################################################################
# Bump version files
###########################################################################

(Get-Content $CORE_CSPROJ_PATH) -replace '(?<=<Version>).*(?=</Version>)', $NEXT_VERSION | Set-Content $CORE_CSPROJ_PATH
(Get-Content $CORE_CSPROJ_PATH) -replace '(?<=CHANGELOG\.md#).*(?=</PackageReleaseNotes>)', $RELEASE_NOTE_LINK | Set-Content $CORE_CSPROJ_PATH
(Get-Content $FRAMEWORK_NUSPEC_PATH) -replace '(?<=<version>).*(?=</version>)', $NEXT_VERSION | Set-Content $FRAMEWORK_NUSPEC_PATH
(Get-Content $FRAMEWORK_NUSPEC_PATH) -replace '(?<=CHANGELOG\.md#).*(?=</releaseNotes>)', $RELEASE_NOTE_LINK | Set-Content $FRAMEWORK_NUSPEC_PATH
(Get-Content $ASSEMBLYINFO_PATH) -replace '(?<=NuGetVersion = ").*(?=";)', $NEXT_VERSION | Set-Content $ASSEMBLYINFO_PATH

###########################################################################
# Create PR with version bump
###########################################################################

if($DryRun){
    Write-Output "Dry run. PR with version bump will not be created."
}else{
    git branch -D $NEXT_VERSION_TAG
    git checkout -b $NEXT_VERSION_TAG
    git commit -am $NEXT_VERSION_TAG
    git push --set-upstream origin $NEXT_VERSION_TAG

    $password = ConvertTo-SecureString "$GithubToken" -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ("Release_Bot", $password)
    Set-GitHubAuthentication -SessionOnly -Credential $Cred
    
    $prParams = @{
        OwnerName = $REPO_OWNER
        RepositoryName = $REPO_NAME
        Title = "chore: " + $NEXT_VERSION_TAG 
        Head = $NEXT_VERSION_TAG
        Base = 'main'
        Body = "Bumping version files for the next release! " + $NEXT_VERSION_TAG
        MaintainerCanModify = $true
    }
    New-GitHubPullRequest @prParams

    Clear-GitHubAuthentication
}

exit 0