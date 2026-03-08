#region MARK: Setup
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/ipy.Jinja.ps1"
$builder = iwr 'https://raw.githubusercontent.com/anonhostpi/IronPythonEmbedded/main/IronPythonEmbedded.ps1' | iex
$engine = $builder.Build()
Install-IpyJinja -Engine $engine

$diskInstallPath = Join-Path $env:TEMP "ipy-jinja-test-$(Get-Random)"
#endregion

#region MARK: Helpers
$passed = 0; $failed = 0

function Assert-Equal {
    param($Actual, $Expected, $Name)
    if ($Actual -eq $Expected) { Write-Host "[PASS] $Name"; $script:passed++ }
    else { Write-Host "[FAIL] $Name`n  Expected: $Expected`n  Actual: $Actual"; $script:failed++ }
}
#endregion

#region MARK: Tests
function Test-BasicRender {
    $scope = $engine.CreateScope()
    $engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'t': 'Hello {{ name }}!'}))
result = env.get_template('t').render(name='World')
"@, $scope)
    Assert-Equal $scope.GetVariable('result') 'Hello World!' 'BasicRender'
}

function Test-FilterRender {
    $scope = $engine.CreateScope()
    $engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'t': '{{ name|upper }} {{ items|join(",") }}'}))
result = env.get_template('t').render(name='test', items=['a','b','c'])
"@, $scope)
    Assert-Equal $scope.GetVariable('result') 'TEST a,b,c' 'FilterRender'
}

function Test-ErrorHandling {
    $scope = $engine.CreateScope()
    $engine.Execute(@"
from jinja2 import Environment, DictLoader, StrictUndefined, TemplateNotFound
env = Environment(loader=DictLoader({}), undefined=StrictUndefined)
try:
    env.get_template('missing')
    not_found = False
except TemplateNotFound:
    not_found = True
"@, $scope)
    Assert-Equal $scope.GetVariable('not_found') $true 'ErrorHandling_TemplateNotFound'
}
#endregion

function Test-DiskInstall {
    Install-IpyJinja -Path $diskInstallPath
    $sitePackages = Join-Path $diskInstallPath "lib/site-packages"

    # Verify key files exist on disk
    $jinja2Init = Join-Path $sitePackages "jinja2/__init__.py"
    $markupsafeInit = Join-Path $sitePackages "markupsafe/__init__.py"
    $patchedDebug = Join-Path $sitePackages "jinja2/debug.py"

    Assert-Equal (Test-Path $jinja2Init) $true 'DiskInstall_Jinja2Exists'
    Assert-Equal (Test-Path $markupsafeInit) $true 'DiskInstall_MarkupSafeExists'
    Assert-Equal (Test-Path $patchedDebug) $true 'DiskInstall_PatchedDebugExists'

    # Verify patched file contains expected content (not the original)
    $debugContent = Get-Content $patchedDebug -Raw
    Assert-Equal ($debugContent.Contains('jinja2.debug')) $true 'DiskInstall_PatchedDebugContent'
}

function Test-NoArgsThrows {
    $threw = $false
    try { Install-IpyJinja } catch { $threw = $true }
    Assert-Equal $threw $true 'NoArgsThrows'
}
#endregion

#region MARK: Runner
Test-BasicRender
Test-FilterRender
Test-ErrorHandling
Test-DiskInstall
Test-NoArgsThrows

Write-Host ''
Write-Host "Results: $passed passed, $failed failed"

# Cleanup disk install test directory
if (Test-Path $diskInstallPath) {
    Remove-Item -Recurse -Force $diskInstallPath
}

if ($failed -gt 0) { exit 1 }
#endregion
