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
$CORE_ASSEMBLY_NAME="Net.Sdk.Playground.Core"
$NUGET_URL="https://api.nuget.org/v3/index.json"
$NET_CORE_VER="netcoreapp2.0"
$FRAMEWORK_ASSEMBLY_NAME="Net.Sdk.Playground"
$SLN_PATH="$ROOT_DIR" + "\Net.Sdk.Playground.sln"
$NET_FRAMEWORK_VER="net45"
$FRAMEWORK_PDB_PATH=$FRAMEWORK_PROJ_DIR + "\bin\Release\Net.Sdk.Playground.pdb"
$CORE_PDB_PATH=$CORE_PROJ_DIR + "\bin\Release\netstandard2.0\Net.Sdk.Playground.Core.pdb"
$PFX_PATH="$FRAMEWORK_PROJ_DIR" + "\AssemblySigningKey.pfx"