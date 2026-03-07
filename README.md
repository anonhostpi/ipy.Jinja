# ipy.Jinja

Vendored Jinja2 2.10.3 + MarkupSafe 1.1.1 for use with [IronPythonEmbedded](../IronPythonEmbedded).

## Quick Start

```powershell
Import-Module ./ipy.Jinja.psd1
$ipy = & ../IronPythonEmbedded/IronPythonEmbedded.ps1
$engine = $ipy.Build()
Install-IpyJinja -Engine $engine

$scope = $engine.CreateScope()
$engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'hello': 'Hello {{ name }}!'}))
result = env.get_template('hello').render(name='World')
"@, $scope)
Write-Host $scope.GetVariable('result')  # Hello World!
```

## Building the Vendor Archive

```powershell
./build.ps1
```
