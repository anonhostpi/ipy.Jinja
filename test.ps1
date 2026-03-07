param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot/ipy.Jinja.psd1" -Force
$builder = iwr 'https://raw.githubusercontent.com/anonhostpi/IronPythonEmbedded/main/IronPythonEmbedded.ps1' | iex
$engine = $builder.Build()
Install-IpyJinja -Engine $engine
$passed = 0; $failed = 0
function Assert-Equal {
    param($Actual, $Expected, $Name)
    if ($Actual -eq $Expected) { Write-Host "[PASS] $Name"; $script:passed++ }
    else { Write-Host "[FAIL] $Name`n  Expected: $Expected`n  Actual: $Actual"; $script:failed++ }
}
function Test-BasicRender {
    $scope = $engine.CreateScope()
    $engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'t': 'Hello {{ name }}!'}))
result = env.get_template('t').render(name='World')
"@, $scope)
    Assert-Equal $scope.GetVariable('result') 'Hello World!' 'BasicRender'
}
function Test-FilterRender { <# WIP #> }
function Test-ErrorHandling { <# WIP #> }
