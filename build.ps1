param(
    [string]$OutputDir = "$PSScriptRoot/vendor",
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Wheel { param([string]$Package, [string]$Version, [string]$DestDir) }
function Expand-Wheel { param([string]$WheelPath, [string]$DestDir) }
function Apply-Patches { param([string]$PackageDir) }
function Build-VendorZip { param([string]$SourceDir, [string]$OutputZip) }

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "ipy-jinja-build-$(Get-Random)"
New-Item -ItemType Directory -Path $workDir | Out-Null
try {
    Get-Wheel 'Jinja2' '2.10.3' $workDir
    Get-Wheel 'MarkupSafe' '1.1.1' $workDir
    Expand-Wheel "$workDir/Jinja2-2.10.3-py2.py3-none-any.whl" $workDir
    Expand-Wheel "$workDir/MarkupSafe-1.1.1-py2.py3-none-any.whl" $workDir
    Apply-Patches $workDir
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Build-VendorZip $workDir "$OutputDir/ipy.Jinja.zip"
    Write-Host "Build complete: $OutputDir/ipy.Jinja.zip"
} finally {
    Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
}
