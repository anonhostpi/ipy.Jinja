# ipy.Jinja

Jinja2 2.10.3 + MarkupSafe 1.1.1 for use with [IronPythonEmbedded](../IronPythonEmbedded).
Wheels are downloaded from PyPI at runtime; no build step required.

## Quick Start

```powershell
. "$PSScriptRoot/ipy.Jinja.ps1"
$builder = iwr 'https://raw.githubusercontent.com/anonhostpi/IronPythonEmbedded/main/IronPythonEmbedded.ps1' | iex
$engine = $builder.Build()
Install-IpyJinja -Engine $engine

$scope = $engine.CreateScope()
$engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'hello': 'Hello {{ name }}!'}))
result = env.get_template('hello').render(name='World')
"@, $scope)
Write-Host $scope.GetVariable('result')  # Hello World!
```

## How It Works

`Install-IpyJinja` loads both Jinja2 and MarkupSafe wheels directly from PyPI into
the IronPythonEmbedded engine, then overwrites the three files that require IronPython
compatibility patches (debug.py, _compat.py, lexer.py) and stubs out the async files
that contain Python 3.5+ syntax incompatible with IronPython 3.4.
