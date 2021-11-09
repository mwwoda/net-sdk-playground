Param
(
    [Alias('dr')]
    [bool]$DryRun = $true,

    [Parameter(Mandatory)]
    [Alias('ng')]
    [string]$NugetKey,

    [Parameter(Mandatory)]
    [Alias('nv')]
    [string]$NextVersion,

    [Alias('b')]
    [string]$Branch="main",

    [Alias('cf')]
    [string]$PfxAsBase64,

    [Alias('pw')]
    [string]$PfxPassword,

    [Alias('bt')]
    [bool]$BuildAndTest =  $true
)

$ErrorActionPreference = "Stop"

$ROOT_DIR=$pwd
$GIT_SCRIPT="$PSScriptRoot" + "\ensure_git_clean.ps1"
$FRAMEWORK_PROJ_DIR="$ROOT_DIR" + "\Net.Sdk.Playground"
$FRAMEWORK_ASSEMBLY_NAME="Net.Sdk.Playground"
$NUGET_URL="https://api.nuget.org/v3/index.json"
$FRAMEWORK_NUPKG_PATH="$FRAMEWORK_PROJ_DIR" + "\bin\Release\" + "$FRAMEWORK_ASSEMBLY_NAME" + "." + "$NextVersion" + ".nupkg"
$NET_FRAMEWORK_VER="net45"

###########################################################################
# Ensure git tree is clean
###########################################################################

Invoke-Expression "& `"$GIT_SCRIPT`" -b $Branch"
if ($LASTEXITCODE -ne 0) {
   exit 1
}

###########################################################################
# Install dependencies
###########################################################################

Invoke-WebRequest https://github.com/honzajscz/SnInstallPfx/releases/download/0.1.2-beta/SnInstallPfx.exe -SkipCertificateCheck -OutFile SnInstallPfx.exe

###########################################################################
# Setup Pfx
###########################################################################

$Bytes = [Convert]::FromBase64String($PfxAsBase64)
$PfxPath = "$FRAMEWORK_PROJ_DIR" + "\AssemblySigningKey.pfx"
[IO.File]::WriteAllBytes($pfxPath, $Bytes)
.\SnInstallPfx.exe $PfxPath $PfxPassword
Remove-Item $PfxPath 

###########################################################################
# Build and Test
###########################################################################

if($BuildAndTest){
    msbuild $FRAMEWORK_PROJ_DIR /property:Configuration=Release
    dotnet test -f $NET_FRAMEWORK_VER --verbosity normal
    dotnet clean $FRAMEWORK_PROJ_DIR
    if (test-path ("$FRAMEWORK_PROJ_DIR" + "\bin")) { Remove-Item ("$FRAMEWORK_PROJ_DIR" + "\bin") -r }
    if (test-path ("$FRAMEWORK_PROJ_DIR" + "\obj")) { Remove-Item ("$FRAMEWORK_PROJ_DIR" + "\obj") -r }
}else{
    Write-Output "Skipping build and test step."
}

###########################################################################
# Pack Framework
###########################################################################

nuget pack $FRAMEWORK_PROJ_DIR -Build -Prop Configuration=Release

###########################################################################
# Publish Framework to the Nuget
###########################################################################

if ($DryRun) { 
    Write-Output "Running in Dry Run mode. Package will not be published"
}else{
    dotnet nuget push $FRAMEWORK_NUPKG_PATH -k $NugetKey -s $NUGET_URL
}

###########################################################################
# Clean all VS_KEY_* containers
###########################################################################

certutil -csp "Microsoft Strong Cryptographic Provider" -key | Select-String -Pattern "VS_KEY" | ForEach-Object{ $_.ToString().Trim()} | ForEach-Object{ certutil -delkey -csp "Microsoft Strong Cryptographic Provider" $_}

exit 0