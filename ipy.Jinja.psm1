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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Engine,
        [string]$ZipPath = (Get-IpyJinjaZipPath)
    )
    Write-Verbose "Loading ipy.Jinja from: $ZipPath"
    $Engine.Add('/ipy/lib/site-packages', $ZipPath)
    if (-not $Engine.Has('/ipy/lib/site-packages/jinja2/__init__.py')) {
        throw "Install-IpyJinja: jinja2 package not found after loading zip. Verify zip contents."
    }
    Write-Verbose "Install-IpyJinja: jinja2 + markupsafe loaded successfully"
}

Export-ModuleMember -Function Install-IpyJinja
