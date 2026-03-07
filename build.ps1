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
