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

Test-BasicRender
Test-FilterRender
Test-ErrorHandling
Write-Host ''
Write-Host "Results: $passed passed, $failed failed"
if ($failed -gt 0) { exit 1 }
