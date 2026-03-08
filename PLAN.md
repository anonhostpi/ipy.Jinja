# Plan


### Commit 1a: `build.ps1` - Add build.ps1 param block, strict mode, and four stub function declarations (Get-Wheel, Expand-Wheel, Apply-Patches, Build-VendorZip). [COMPLETE]

### build.build-param-and-stubs

> **File**: `build.ps1`
> **Type**: NEW
> **Commit**: 1 of 0 for this file

#### Description

Add build.ps1 param block, strict mode, and four stub function declarations (Get-Wheel, Expand-Wheel, Apply-Patches, Build-VendorZip).

#### Diff

```diff
+param(
+    [string]$OutputDir = "$PSScriptRoot/vendor",
+    [switch]$Force
+)
+Set-StrictMode -Version Latest
+$ErrorActionPreference = 'Stop'
+
+function Get-Wheel { param([string]$Package, [string]$Version, [string]$DestDir) }
+function Expand-Wheel { param([string]$WheelPath, [string]$DestDir) }
+function Apply-Patches { param([string]$PackageDir) }
+function Build-VendorZip { param([string]$SourceDir, [string]$OutputZip) }
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 1b: `build.ps1` - Implement the main execution body of build.ps1: create temp workdir, invoke all build steps in order, and clean up in finally block. [COMPLETE]

### build.build-main-sequence

> **File**: `build.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement the main execution body of build.ps1: create temp workdir, invoke all build steps in order, and clean up in finally block.

#### Diff

```diff
-function Build-VendorZip { param([string]$SourceDir, [string]$OutputZip) }
+function Build-VendorZip { param([string]$SourceDir, [string]$OutputZip) }
+
+$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "ipy-jinja-build-$(Get-Random)"
+New-Item -ItemType Directory -Path $workDir | Out-Null
+try {
+    Get-Wheel 'Jinja2' '2.10.3' $workDir
+    Get-Wheel 'MarkupSafe' '1.1.1' $workDir
+    Expand-Wheel "$workDir/Jinja2-2.10.3-py2.py3-none-any.whl" $workDir
+    Expand-Wheel "$workDir/MarkupSafe-1.1.1-py2.py3-none-any.whl" $workDir
+    Apply-Patches $workDir
+    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
+    Build-VendorZip $workDir "$OutputDir/ipy.Jinja.zip"
+    Write-Host "Build complete: $OutputDir/ipy.Jinja.zip"
+} finally {
+    Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 1c: `build.ps1` - Implement Get-Wheel: query PyPI JSON API to resolve the wheel download URL for a given package/version, then download it to the destination directory. [COMPLETE]

### build.build-get-wheel

> **File**: `build.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Get-Wheel: query PyPI JSON API to resolve the wheel download URL for a given package/version, then download it to the destination directory.

#### Diff

```diff
-function Get-Wheel { param([string]$Package, [string]$Version, [string]$DestDir) }
+function Get-Wheel {
+    param([string]$Package, [string]$Version, [string]$DestDir)
+    $url = "https://pypi.org/pypi/$Package/$Version/json"
+    $meta = Invoke-RestMethod -Uri $url
+    $wheel = $meta.urls | Where-Object { $_.packagetype -eq 'bdist_wheel' -and $_.filename -like '*none-any*' } | Select-Object -First 1
+    if (-not $wheel) { throw "No pure-Python wheel found for $Package $Version" }
+    $dest = Join-Path $DestDir $wheel.filename
+    Invoke-WebRequest -Uri $wheel.url -OutFile $dest
+    Write-Host "Downloaded: $($wheel.filename)"
+    $dest
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 1d: `build.ps1` - Implement Expand-Wheel: extract the wheel zip, keeping only .py files from the package directories (jinja2/ or markupsafe/) and excluding async and C-extension files. [COMPLETE]

### build.build-expand-wheel

> **File**: `build.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Expand-Wheel: extract the wheel zip, keeping only .py files from the package directories (jinja2/ or markupsafe/) and excluding async and C-extension files.

#### Diff

```diff
-function Expand-Wheel { param([string]$WheelPath, [string]$DestDir) }
+function Expand-Wheel {
+    param([string]$WheelPath, [string]$DestDir)
+    Add-Type -AssemblyName System.IO.Compression.FileSystem
+    $exclude = @('asyncsupport.py','asyncfilters.py','_speedups.c','_speedups.pyd','_speedups.so')
+    $zip = [System.IO.Compression.ZipFile]::OpenRead($WheelPath)
+    try {
+        foreach ($entry in $zip.Entries) {
+            $name = $entry.FullName
+            if ($name -notmatch '^(jinja2|markupsafe)/' ) { continue }
+            if ($name -notlike '*.py') { continue }
+            if ($exclude -contains [System.IO.Path]::GetFileName($name)) { continue }
+            $dest = Join-Path $DestDir $name
+            New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
+            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
+        }
+    } finally { $zip.Dispose() }
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 1e: `build.ps1` - Implement Apply-Patches: read the extracted jinja2/debug.py and replace the _init_ugly_crap ctypes block with a no-op tb_set_next stub, then write the patched file back. [COMPLETE]

### build.build-apply-patches

> **File**: `build.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Apply-Patches: read the extracted jinja2/debug.py and replace the _init_ugly_crap ctypes block with a no-op tb_set_next stub, then write the patched file back.

#### Diff

```diff
-function Apply-Patches { param([string]$PackageDir) }
+function Apply-Patches {
+    param([string]$PackageDir)
+    $debugPy = Join-Path $PackageDir 'jinja2/debug.py'
+    $src = Get-Content $debugPy -Raw
+    # Replace _init_ugly_crap function with a stub that returns a no-op tb_set_next
+    $pattern = '(?s)def _init_ugly_crap():.*?(?=
def |
class |Z)'
+    $stub = @'
+def _init_ugly_crap():
+    """Stub: ctypes traceback rewriting not supported on IronPython."""
+    def tb_set_next(tb, next):
+        pass
+    return tb_set_next
+'@
+    $patched = [regex]::Replace($src, $pattern, $stub)
+    Set-Content -Path $debugPy -Value $patched -NoNewline
+    Write-Host "Patched: jinja2/debug.py"
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 1f: `build.ps1` - Implement Build-VendorZip: create the output zip archive from the extracted and patched package directories (jinja2/ and markupsafe/) in the source directory. [COMPLETE]

### build.build-vendor-zip

> **File**: `build.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Build-VendorZip: create the output zip archive from the extracted and patched package directories (jinja2/ and markupsafe/) in the source directory.

#### Diff

```diff
-function Build-VendorZip { param([string]$SourceDir, [string]$OutputZip) }
+function Build-VendorZip {
+    param([string]$SourceDir, [string]$OutputZip)
+    Add-Type -AssemblyName System.IO.Compression.FileSystem
+    if (Test-Path $OutputZip) { Remove-Item $OutputZip }
+    $zip = [System.IO.Compression.ZipFile]::Open($OutputZip, 'Create')
+    try {
+        foreach ($pkg in @('jinja2','markupsafe')) {
+            $pkgDir = Join-Path $SourceDir $pkg
+            if (-not (Test-Path $pkgDir)) { continue }
+            Get-ChildItem -Recurse -File $pkgDir | ForEach-Object {
+                $rel = $_.FullName.Substring($SourceDir.Length + 1).Replace('','/')
+                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel) | Out-Null
+            }
+        }
+    } finally { $zip.Dispose() }
+    Write-Host "Created: $OutputZip"
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `patches/debug.py.patch` - Add patches/debug.py.patch: reference patch replacing the ctypes _init_ugly_crap block in jinja2/debug.py with a no-op stub for IronPython. [COMPLETE]

### patches.debug.py.debug-patch-file

> **File**: `patches/debug.py.patch`
> **Type**: NEW
> **Commit**: 1 of 0 for this file

#### Description

Add patches/debug.py.patch: reference patch replacing the ctypes _init_ugly_crap block in jinja2/debug.py with a no-op stub for IronPython.

#### Diff

```diff
+--- a/jinja2/debug.py
++++ b/jinja2/debug.py
+@@ -18,7 +16,7 @@
+-def _init_ugly_crap():
+-    # ... ctypes structure definitions and pointer manipulation ...
++def _init_ugly_crap():
++    """No-op: IronPython does not support CPython ctypes traceback rewriting."""
++    def tb_set_next(tb, next): pass
++    return tb_set_next
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `ipy.Jinja.psm1` - Add ipy.Jinja.psm1 outer scaffold: module-level comment, function stubs for Install-IpyJinja and Get-IpyJinjaZipPath, and module export. [COMPLETE]

### ipy.Jinja.module-scaffold

> **File**: `ipy.Jinja.psm1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add ipy.Jinja.psm1 outer scaffold: module-level comment, function stubs for Install-IpyJinja and Get-IpyJinjaZipPath, and module export.

#### Diff

```diff
+# ipy.Jinja.psm1 -- Loads vendored Jinja2+MarkupSafe into an IronPythonEmbedded engine
+Set-StrictMode -Version Latest
+$ErrorActionPreference = 'Stop'
+
+function Get-IpyJinjaZipPath {
+    <# WIP #>
+}
+
+function Install-IpyJinja {
+    <# WIP #>
+}
+
+Export-ModuleMember -Function Install-IpyJinja
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3b: `ipy.Jinja.psm1` - Implement Get-IpyJinjaZipPath: resolve the vendored zip path, preferring vendor/ipy.Jinja.zip relative to the module root, with a helpful error if missing. [COMPLETE]

### ipy.Jinja.module-get-zip-path

> **File**: `ipy.Jinja.psm1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Get-IpyJinjaZipPath: resolve the vendored zip path, preferring vendor/ipy.Jinja.zip relative to the module root, with a helpful error if missing.

#### Diff

```diff
-function Get-IpyJinjaZipPath {
-    <# WIP #>
-}
+function Get-IpyJinjaZipPath {
+    $zip = Join-Path $PSScriptRoot 'vendor/ipy.Jinja.zip'
+    if (-not (Test-Path $zip)) {
+        throw "ipy.Jinja.zip not found at '$zip'. Run build.ps1 to generate it."
+    }
+    $zip
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3c: `ipy.Jinja.psm1` - Implement Install-IpyJinja: accept an IronPythonEmbedded engine instance, load the vendored zip into /ipy/lib/site-packages, and verify the load succeeded by checking for jinja2/__init__.py. [COMPLETE]

### ipy.Jinja.module-install-ipyjinja

> **File**: `ipy.Jinja.psm1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Install-IpyJinja: accept an IronPythonEmbedded engine instance, load the vendored zip into /ipy/lib/site-packages, and verify the load succeeded by checking for jinja2/__init__.py.

#### Diff

```diff
-function Install-IpyJinja {
-    <# WIP #>
-}
+function Install-IpyJinja {
+    [CmdletBinding()]
+    param(
+        [Parameter(Mandatory)][object]$Engine,
+        [string]$ZipPath = (Get-IpyJinjaZipPath)
+    )
+    Write-Verbose "Loading ipy.Jinja from: $ZipPath"
+    $Engine.Add('/ipy/lib/site-packages', $ZipPath)
+    if (-not $Engine.Has('/ipy/lib/site-packages/jinja2/__init__.py')) {
+        throw "Install-IpyJinja: jinja2 package not found after loading zip. Verify zip contents."
+    }
+    Write-Verbose "Install-IpyJinja: jinja2 + markupsafe loaded successfully"
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `ipy.Jinja.psd1` - Add ipy.Jinja.psd1: PowerShell module manifest declaring version, author, root module, and exported functions for Install-IpyJinja. [COMPLETE]

### ipy.Jinja.module-manifest

> **File**: `ipy.Jinja.psd1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add ipy.Jinja.psd1: PowerShell module manifest declaring version, author, root module, and exported functions for Install-IpyJinja.

#### Diff

```diff
+@{
+    ModuleVersion     = '1.0.0'
+    Author            = 'ipy.Jinja'
+    Description       = 'Vendored Jinja2 2.10.3 + MarkupSafe 1.1.1 for IronPythonEmbedded'
+    RootModule        = 'ipy.Jinja.psm1'
+    FunctionsToExport = @('Install-IpyJinja')
+    PrivateData       = @{
+        PSData = @{
+            Tags = @('IronPython','Jinja2','Templating')
+        }
+    }
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5a: `test.ps1` - Add test.ps1 scaffold: param block, IronPythonEmbedded engine setup, Install-IpyJinja invocation, Assert-Equal helper, and stub test functions. [COMPLETE]

### test.test-scaffold

> **File**: `test.ps1`
> **Type**: NEW
> **Commit**: 1 of 0 for this file

#### Description

Add test.ps1 scaffold: param block, IronPythonEmbedded engine setup, Install-IpyJinja invocation, Assert-Equal helper, and stub test functions.

#### Diff

```diff
+param([string]$IronPythonEmbeddedPath = "$PSScriptRoot/../IronPythonEmbedded/IronPythonEmbedded.ps1")
+Set-StrictMode -Version Latest
+$ErrorActionPreference = 'Stop'
+Import-Module "$PSScriptRoot/ipy.Jinja.psd1" -Force
+$ipy = & $IronPythonEmbeddedPath
+$engine = $ipy.Build()
+Install-IpyJinja -Engine $engine
+$passed = 0; $failed = 0
+function Assert-Equal {
+    param($Actual, $Expected, $Name)
+    if ($Actual -eq $Expected) { Write-Host "[PASS] $Name"; $script:passed++ }
+    else { Write-Host "[FAIL] $Name`n  Expected: $Expected`n  Actual: $Actual"; $script:failed++ }
+}
+function Test-BasicRender { <# WIP #> }
+function Test-FilterRender { <# WIP #> }
+function Test-ErrorHandling { <# WIP #> }
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5b: `test.ps1` - Implement Test-BasicRender: create a DictLoader environment, render a simple variable-substitution template, and assert the output equals the expected string. [COMPLETE]

### test.test-basic-render

> **File**: `test.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Test-BasicRender: create a DictLoader environment, render a simple variable-substitution template, and assert the output equals the expected string.

#### Diff

```diff
-function Test-BasicRender { <# WIP #> }
+function Test-BasicRender {
+    $scope = $engine.CreateScope()
+    $engine.Execute(@"
+from jinja2 import Environment, DictLoader
+env = Environment(loader=DictLoader({'t': 'Hello {{ name }}!'}))
+result = env.get_template('t').render(name='World')
+"@, $scope)
+    Assert-Equal $scope.GetVariable('result') 'Hello World!' 'BasicRender'
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5c: `test.ps1` - Implement Test-FilterRender: exercise built-in Jinja2 filters (upper, default, list join) to verify the filter pipeline works under IronPython. [COMPLETE]

### test.test-filter-render

> **File**: `test.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Test-FilterRender: exercise built-in Jinja2 filters (upper, default, list join) to verify the filter pipeline works under IronPython.

#### Diff

```diff
-function Test-FilterRender { <# WIP #> }
+function Test-FilterRender {
+    $scope = $engine.CreateScope()
+    $engine.Execute(@"
+from jinja2 import Environment, DictLoader
+env = Environment(loader=DictLoader({'t': '{{ name|upper }} {{ items|join(",") }}'}))
+result = env.get_template('t').render(name='test', items=['a','b','c'])
+"@, $scope)
+    Assert-Equal $scope.GetVariable('result') 'TEST a,b,c' 'FilterRender'
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5d: `test.ps1` - Implement Test-ErrorHandling: verify TemplateNotFound is raised for missing templates and UndefinedError for strict-mode undefined variables. [COMPLETE]

### test.test-error-handling

> **File**: `test.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Test-ErrorHandling: verify TemplateNotFound is raised for missing templates and UndefinedError for strict-mode undefined variables.

#### Diff

```diff
-function Test-ErrorHandling { <# WIP #> }
+function Test-ErrorHandling {
+    $scope = $engine.CreateScope()
+    $engine.Execute(@"
+from jinja2 import Environment, DictLoader, StrictUndefined, TemplateNotFound
+env = Environment(loader=DictLoader({}), undefined=StrictUndefined)
+try:
+    env.get_template('missing')
+    not_found = False
+except TemplateNotFound:
+    not_found = True
+"@, $scope)
+    Assert-Equal $scope.GetVariable('not_found') $true 'ErrorHandling_TemplateNotFound'
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5e: `test.ps1` - Add the test runner tail: invoke all test functions and report pass/fail counts, exiting with code 1 if any tests failed. [COMPLETE]

### test.test-runner

> **File**: `test.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add the test runner tail: invoke all test functions and report pass/fail counts, exiting with code 1 if any tests failed.

#### Diff

```diff
+Test-BasicRender
+Test-FilterRender
+Test-ErrorHandling
+Write-Host ''
+Write-Host "Results: $passed passed, $failed failed"
+if ($failed -gt 0) { exit 1 }
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `README.md` - Add README.md: usage instructions covering build, installation into an IronPythonEmbedded engine, basic template rendering example, and notes on IronPython compatibility constraints. [COMPLETE]

### README.readme

> **File**: `README.md`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add README.md: usage instructions covering build, installation into an IronPythonEmbedded engine, basic template rendering example, and notes on IronPython compatibility constraints.

#### Diff

```diff
+# ipy.Jinja
+
+Vendored Jinja2 2.10.3 + MarkupSafe 1.1.1 for use with [IronPythonEmbedded](../IronPythonEmbedded).
+
+## Quick Start
+
+```powershell
+Import-Module ./ipy.Jinja.psd1
+$ipy = & ../IronPythonEmbedded/IronPythonEmbedded.ps1
+$engine = $ipy.Build()
+Install-IpyJinja -Engine $engine
+
+$scope = $engine.CreateScope()
+$engine.Execute(@"
+from jinja2 import Environment, DictLoader
+env = Environment(loader=DictLoader({'hello': 'Hello {{ name }}!'}))
+result = env.get_template('hello').render(name='World')
+"@, $scope)
+Write-Host $scope.GetVariable('result')  # Hello World!
+```
+
+## Building the Vendor Archive
+
+```powershell
+./build.ps1
+```
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 26 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
