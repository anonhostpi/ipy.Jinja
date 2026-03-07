# ipy.Jinja.psm1 -- Loads vendored Jinja2+MarkupSafe into an IronPythonEmbedded engine
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-IpyJinjaZipPath {
    $zip = Join-Path $PSScriptRoot 'vendor/ipy.Jinja.zip'
    if (-not (Test-Path $zip)) {
        throw "ipy.Jinja.zip not found at '$zip'. Run build.ps1 to generate it."
    }
    $zip
}

function Install-IpyJinja {
    <# WIP #>
}

Export-ModuleMember -Function Install-IpyJinja
