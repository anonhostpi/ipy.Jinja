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

### Commit 7: `build.ps1` - Remove build.ps1: the pre-build step is no longer needed; wheels are loaded at runtime directly from PyPI.

### build.delete-build-ps1

> **File**: `build.ps1`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove build.ps1: the pre-build step is no longer needed; wheels are loaded at runtime directly from PyPI.

#### Diff

```diff

```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 8: `patches/debug.py.patch` - Remove patches/debug.py.patch: patches are now embedded as inline here-strings in ipy.Jinja.ps1 rather than separate patch files.

### patches.debug.py.delete-debug-patch

> **File**: `patches/debug.py.patch`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove patches/debug.py.patch: patches are now embedded as inline here-strings in ipy.Jinja.ps1 rather than separate patch files.

#### Diff

```diff

```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 9: `ipy.Jinja.psm1` - Remove ipy.Jinja.psm1: replaced by a single-file ipy.Jinja.ps1 that requires no module manifest or Import-Module.

### ipy.Jinja.delete-psm1

> **File**: `ipy.Jinja.psm1`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove ipy.Jinja.psm1: replaced by a single-file ipy.Jinja.ps1 that requires no module manifest or Import-Module.

#### Diff

```diff

```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 10: `ipy.Jinja.psd1` - Remove ipy.Jinja.psd1: module manifest is no longer needed since the module is now a simple dot-sourced script.

### ipy.Jinja.delete-psd1

> **File**: `ipy.Jinja.psd1`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove ipy.Jinja.psd1: module manifest is no longer needed since the module is now a simple dot-sourced script.

#### Diff

```diff

```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 11: `vendor/ipy.Jinja.zip` - Remove vendor/ipy.Jinja.zip: pre-built vendor archive is no longer needed; wheels are downloaded at runtime from PyPI.

### vendor.ipy.Jinja.delete-vendor-zip

> **File**: `vendor/ipy.Jinja.zip`
> **Type**: DELETED
> **Commit**: 1 of 1 for this file

#### Description

Remove vendor/ipy.Jinja.zip: pre-built vendor archive is no longer needed; wheels are downloaded at runtime from PyPI.

#### Diff

```diff

```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | deletion | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 12: `ipy.Jinja.ps1` - Add ipy.Jinja.ps1 scaffold: module header comment, wheel URL constants for Jinja2 2.10.3 and MarkupSafe 1.1.1, and stub Install-IpyJinja function.

### ipy.Jinja.new-module-scaffold

> **File**: `ipy.Jinja.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add ipy.Jinja.ps1 scaffold: module header comment, wheel URL constants for Jinja2 2.10.3 and MarkupSafe 1.1.1, and stub Install-IpyJinja function.

#### Diff

```diff
+# ipy.Jinja.ps1 -- Single-file PowerShell module to load Jinja2 + MarkupSafe
+# into an IronPythonEmbedded engine instance at runtime.
+#
+# Usage:
+#   . "$PSScriptRoot/ipy.Jinja.ps1"
+#   Install-IpyJinja -Engine $engine
+
+$script:jinjaWheelUrl    = 'https://files.pythonhosted.org/packages/65/e0/eb35e762802015cab1ccee04e8a277b03f1d8e53da3ec3106882ec42558b/Jinja2-2.10.3-py2.py3-none-any.whl'
+$script:markupsafeWheelUrl = 'https://files.pythonhosted.org/packages/09/31/fe863b864cf3dfa11bce7a3bd41c4433d59b777ee0750b8d8c9a96f5ca98/MarkupSafe-1.1.1-cp34-cp34m-win_amd64.whl'
+
+# Patched Python source files (full content; loaded after wheel to overwrite originals)
+$script:patchedDebugPy    = $null  # WIP
+$script:patchedCompatPy   = $null  # WIP
+$script:patchedLexerPy    = $null  # WIP
+
+function Install-IpyJinja {
+    param([Parameter(Mandatory)][object]$Engine)
+    # WIP
+}
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 13: `ipy.Jinja.ps1` - Embed patched jinja2/debug.py as here-string: replaces _init_ugly_crap with a no-op stub to avoid ctypes traceback manipulation on IronPython. Full file required since engine.Add overwrites the entire file.

### ipy.Jinja.add-patched-debug-py

> **File**: `ipy.Jinja.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Embed patched jinja2/debug.py as here-string: replaces _init_ugly_crap with a no-op stub to avoid ctypes traceback manipulation on IronPython. Full file required since engine.Add overwrites the entire file.

#### Diff

```diff
-$script:patchedDebugPy    = $null  # WIP
+$script:patchedDebugPy    = @'
+# -*- coding: utf-8 -*-
+"""
+    jinja2.debug
+    ~~~~~~~~~~~~
+
+    Implements the debug interface for Jinja.  This module does some pretty
+    ugly stuff with the Python traceback system in order to achieve tracebacks
+    with correct line numbers, locals and contents.
+
+    :copyright: (c) 2017 by the Jinja Team.
+    :license: BSD, see LICENSE for more details.
+"""
+import sys
+import traceback
+from types import TracebackType, CodeType
+from jinja2.utils import missing, internal_code
+from jinja2.exceptions import TemplateSyntaxError
+from jinja2._compat import iteritems, reraise, PY2
+
+# on pypy we can take advantage of transparent proxies
+try:
+    from __pypy__ import tproxy
+except ImportError:
+    tproxy = None
+
+
+# how does the raise helper look like?
+try:
+    exec("raise TypeError, 'foo'")
+except SyntaxError:
+    raise_helper = 'raise __jinja_exception__[1]'
+except TypeError:
+    raise_helper = 'raise __jinja_exception__[0], __jinja_exception__[1]'
+
+
+class TracebackFrameProxy(object):
+    """Proxies a traceback frame."""
+
+    def __init__(self, tb):
+        self.tb = tb
+        self._tb_next = None
+
+    @property
+    def tb_next(self):
+        return self._tb_next
+
+    def set_next(self, next):
+        if tb_set_next is not None:
+            try:
+                tb_set_next(self.tb, next and next.tb or None)
+            except Exception:
+                # this function can fail due to all the hackery it does
+                # on various python implementations.  We just catch errors
+                # down and ignore them if necessary.
+                pass
+        self._tb_next = next
+
+    @property
+    def is_jinja_frame(self):
+        return '__jinja_template__' in self.tb.tb_frame.f_globals
+
+    def __getattr__(self, name):
+        return getattr(self.tb, name)
+
+
+def make_frame_proxy(frame):
+    proxy = TracebackFrameProxy(frame)
+    if tproxy is None:
+        return proxy
+    def operation_handler(operation, *args, **kwargs):
+        if operation in ('__getattribute__', '__getattr__'):
+            return getattr(proxy, args[0])
+        elif operation == '__setattr__':
+            proxy.__setattr__(*args, **kwargs)
+        else:
+            return getattr(proxy, operation)(*args, **kwargs)
+    return tproxy(TracebackType, operation_handler)
+
+
+class ProcessedTraceback(object):
+    """Holds a Jinja preprocessed traceback for printing or reraising."""
+
+    def __init__(self, exc_type, exc_value, frames):
+        assert frames, 'no frames for this traceback?'
+        self.exc_type = exc_type
+        self.exc_value = exc_value
+        self.frames = frames
+
+        # newly concatenate the frames (which are proxies)
+        prev_tb = None
+        for tb in self.frames:
+            if prev_tb is not None:
+                prev_tb.set_next(tb)
+            prev_tb = tb
+        prev_tb.set_next(None)
+
+    def render_as_text(self, limit=None):
+        """Return a string with the traceback."""
+        lines = traceback.format_exception(self.exc_type, self.exc_value,
+                                           self.frames[0], limit=limit)
+        return ''.join(lines).rstrip()
+
+    def render_as_html(self, full=False):
+        """Return a unicode string with the traceback as rendered HTML."""
+        from jinja2.debugrenderer import render_traceback
+        return u'%s

<!--
%s
-->' % (
+            render_traceback(self, full=full),
+            self.render_as_text().decode('utf-8', 'replace')
+        )
+
+    @property
+    def is_template_syntax_error(self):
+        """`True` if this is a template syntax error."""
+        return isinstance(self.exc_value, TemplateSyntaxError)
+
+    @property
+    def exc_info(self):
+        """Exception info tuple with a proxy around the frame objects."""
+        return self.exc_type, self.exc_value, self.frames[0]
+
+    @property
+    def standard_exc_info(self):
+        """Standard python exc_info for re-raising"""
+        tb = self.frames[0]
+        # the frame will be an actual traceback (or transparent proxy) if
+        # we are on pypy or a python implementation with support for tproxy
+        if type(tb) is not TracebackType:
+            tb = tb.tb
+        return self.exc_type, self.exc_value, tb
+
+
+def make_traceback(exc_info, source_hint=None):
+    """Creates a processed traceback object from the exc_info."""
+    exc_type, exc_value, tb = exc_info
+    if isinstance(exc_value, TemplateSyntaxError):
+        exc_info = translate_syntax_error(exc_value, source_hint)
+        initial_skip = 0
+    else:
+        initial_skip = 1
+    return translate_exception(exc_info, initial_skip)
+
+
+def translate_syntax_error(error, source=None):
+    """Rewrites a syntax error to please traceback systems."""
+    error.source = source
+    error.translated = True
+    exc_info = (error.__class__, error, None)
+    filename = error.filename
+    if filename is None:
+        filename = '<unknown>'
+    return fake_exc_info(exc_info, filename, error.lineno)
+
+
+def translate_exception(exc_info, initial_skip=0):
+    """If passed an exc_info it will automatically rewrite the exceptions
+    all the way down to the correct line numbers and frames.
+    """
+    tb = exc_info[2]
+    frames = []
+
+    # skip some internal frames if wanted
+    for x in range(initial_skip):
+        if tb is not None:
+            tb = tb.tb_next
+    initial_tb = tb
+
+    while tb is not None:
+        # skip frames decorated with @internalcode.  These are internal
+        # calls we can't avoid and that are useless in template debugging
+        # output.
+        if tb.tb_frame.f_code in internal_code:
+            tb = tb.tb_next
+            continue
+
+        # save a reference to the next frame if we override the current
+        # one with a faked one.
+        next = tb.tb_next
+
+        # fake template exceptions
+        template = tb.tb_frame.f_globals.get('__jinja_template__')
+        if template is not None:
+            lineno = template.get_corresponding_lineno(tb.tb_lineno)
+            tb = fake_exc_info(exc_info[:2] + (tb,), template.filename,
+                               lineno)[2]
+
+        frames.append(make_frame_proxy(tb))
+        tb = next
+
+    # if we don't have any exceptions in the frames left, we have to
+    # reraise it unchanged.
+    # XXX: can we backup here?  when could this happen?
+    if not frames:
+        reraise(exc_info[0], exc_info[1], exc_info[2])
+
+    return ProcessedTraceback(exc_info[0], exc_info[1], frames)
+
+
+def get_jinja_locals(real_locals):
+    ctx = real_locals.get('context')
+    if ctx:
+        locals = ctx.get_all().copy()
+    else:
+        locals = {}
+
+    local_overrides = {}
+
+    for name, value in iteritems(real_locals):
+        if not name.startswith('l_') or value is missing:
+            continue
+        try:
+            _, depth, name = name.split('_', 2)
+            depth = int(depth)
+        except ValueError:
+            continue
+        cur_depth = local_overrides.get(name, (-1,))[0]
+        if cur_depth < depth:
+            local_overrides[name] = (depth, value)
+
+    for name, (_, value) in iteritems(local_overrides):
+        if value is missing:
+            locals.pop(name, None)
+        else:
+            locals[name] = value
+
+    return locals
+
+
+def fake_exc_info(exc_info, filename, lineno):
+    """Helper for `translate_exception`."""
+    exc_type, exc_value, tb = exc_info
+
+    # figure the real context out
+    if tb is not None:
+        locals = get_jinja_locals(tb.tb_frame.f_locals)
+
+        # if there is a local called __jinja_exception__, we get
+        # rid of it to not break the debug functionality.
+        locals.pop('__jinja_exception__', None)
+    else:
+        locals = {}
+
+    # assamble fake globals we need
+    globals = {
+        '__name__':             filename,
+        '__file__':             filename,
+        '__jinja_exception__':  exc_info[:2],
+
+        # we don't want to keep the reference to the template around
+        # to not cause circular dependencies, but we mark it as Jinja
+        # frame for the ProcessedTraceback
+        '__jinja_template__':   None
+    }
+
+    # and fake the exception
+    code = compile('
' * (lineno - 1) + raise_helper, filename, 'exec')
+
+    # if it's possible, change the name of the code.  This won't work
+    # on some python environments such as google appengine
+    try:
+        if tb is None:
+            location = 'template'
+        else:
+            function = tb.tb_frame.f_code.co_name
+            if function == 'root':
+                location = 'top-level template code'
+            elif function.startswith('block_'):
+                location = 'block "%s"' % function[6:]
+            else:
+                location = 'template'
+
+        if PY2:
+            code = CodeType(0, code.co_nlocals, code.co_stacksize,
+                            code.co_flags, code.co_code, code.co_consts,
+                            code.co_names, code.co_varnames, filename,
+                            location, code.co_firstlineno,
+                            code.co_lnotab, (), ())
+        else:
+            code = CodeType(0, code.co_kwonlyargcount,
+                            code.co_nlocals, code.co_stacksize,
+                            code.co_flags, code.co_code, code.co_consts,
+                            code.co_names, code.co_varnames, filename,
+                            location, code.co_firstlineno,
+                            code.co_lnotab, (), ())
+    except Exception as e:
+        pass
+
+    # execute the code and catch the new traceback
+    try:
+        exec(code, globals, locals)
+    except:
+        exc_info = sys.exc_info()
+        new_tb = exc_info[2].tb_next
+
+    # return without this frame
+    return exc_info[:2] + (new_tb,)
+
+
+def _init_ugly_crap():
+    # Stub: ctypes traceback rewriting not supported on IronPython.
+    def tb_set_next(tb, next):
+        pass
+    return tb_set_next
+
+# try to get a tb_set_next implementation if we don't have transparent
+# proxies.
+tb_set_next = None
+if tproxy is None:
+    # traceback.tb_next can be modified since CPython 3.7
+    if sys.version_info >= (3, 7):
+        def tb_set_next(tb, next):
+            tb.tb_next = next
+    else:
+        # On Python 3.6 and older, use ctypes
+        try:
+            tb_set_next = _init_ugly_crap()
+        except Exception:
+            pass
+del _init_ugly_crap
+'@
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 321 lines | FAIL |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 14: `ipy.Jinja.ps1` - Embed patched jinja2/_compat.py as here-string: replaces the urllib.parse.quote_from_bytes import with a pure-Python url_quote implementation to avoid IronPythonEmbedded's urllib Shim limitation. Full file required since engine.Add overwrites the entire file.

### ipy.Jinja.add-patched-compat-py

> **File**: `ipy.Jinja.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Embed patched jinja2/_compat.py as here-string: replaces the urllib.parse.quote_from_bytes import with a pure-Python url_quote implementation to avoid IronPythonEmbedded's urllib Shim limitation. Full file required since engine.Add overwrites the entire file.

#### Diff

```diff
-$script:patchedCompatPy   = $null  # WIP
+$script:patchedCompatPy   = @'
+# -*- coding: utf-8 -*-
+"""
+    jinja2._compat
+    ~~~~~~~~~~~~~~
+
+    Some py2/py3 compatibility support based on a stripped down
+    version of six so we don't have to depend on a specific version
+    of it.
+
+    :copyright: Copyright 2013 by the Jinja team, see AUTHORS.
+    :license: BSD, see LICENSE for details.
+"""
+import sys
+
+PY2 = sys.version_info[0] == 2
+PYPY = hasattr(sys, 'pypy_translation_info')
+_identity = lambda x: x
+
+
+if not PY2:
+    unichr = chr
+    range_type = range
+    text_type = str
+    string_types = (str,)
+    integer_types = (int,)
+
+    iterkeys = lambda d: iter(d.keys())
+    itervalues = lambda d: iter(d.values())
+    iteritems = lambda d: iter(d.items())
+
+    import pickle
+    from io import BytesIO, StringIO
+    NativeStringIO = StringIO
+
+    def reraise(tp, value, tb=None):
+        if value.__traceback__ is not tb:
+            raise value.with_traceback(tb)
+        raise value
+
+    ifilter = filter
+    imap = map
+    izip = zip
+    intern = sys.intern
+
+    implements_iterator = _identity
+    implements_to_string = _identity
+    encode_filename = _identity
+
+else:
+    unichr = unichr
+    text_type = unicode
+    range_type = xrange
+    string_types = (str, unicode)
+    integer_types = (int, long)
+
+    iterkeys = lambda d: d.iterkeys()
+    itervalues = lambda d: d.itervalues()
+    iteritems = lambda d: d.iteritems()
+
+    import cPickle as pickle
+    from cStringIO import StringIO as BytesIO, StringIO
+    NativeStringIO = BytesIO
+
+    exec('def reraise(tp, value, tb=None):
 raise tp, value, tb')
+
+    from itertools import imap, izip, ifilter
+    intern = intern
+
+    def implements_iterator(cls):
+        cls.next = cls.__next__
+        del cls.__next__
+        return cls
+
+    def implements_to_string(cls):
+        cls.__unicode__ = cls.__str__
+        cls.__str__ = lambda x: x.__unicode__().encode('utf-8')
+        return cls
+
+    def encode_filename(filename):
+        if isinstance(filename, unicode):
+            return filename.encode('utf-8')
+        return filename
+
+
+def with_metaclass(meta, *bases):
+    """Create a base class with a metaclass."""
+    # This requires a bit of explanation: the basic idea is to make a
+    # dummy metaclass for one level of class instantiation that replaces
+    # itself with the actual metaclass.
+    class metaclass(type):
+        def __new__(cls, name, this_bases, d):
+            return meta(name, bases, d)
+    return type.__new__(metaclass, 'temporary_class', (), {})
+
+
+def url_quote(obj, safe=b'/'):
+    if isinstance(obj, str):
+        obj = obj.encode('utf-8')
+    r = bytearray()
+    for b in obj:
+        c = bytes([b])
+        if (c in (safe if isinstance(safe, bytes) else safe.encode('ascii'))
+                or c.isalnum() or c in b'-._~'):
+            r.extend(c)
+        else:
+            r.extend(('%{:02X}'.format(b)).encode('ascii'))
+    return r.decode('ascii')
+
+
+try:
+    from collections import abc
+except ImportError:
+    import collections as abc
+'@
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 116 lines | FAIL |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 15: `ipy.Jinja.ps1` - Embed patched jinja2/lexer.py as here-string: replaces the Unicode identifier try/except block with a forced ASCII-only name_re pattern to avoid .NET regex incompatibilities on IronPython. Full file required since engine.Add overwrites the entire file.

### ipy.Jinja.add-patched-lexer-py

> **File**: `ipy.Jinja.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Embed patched jinja2/lexer.py as here-string: replaces the Unicode identifier try/except block with a forced ASCII-only name_re pattern to avoid .NET regex incompatibilities on IronPython. Full file required since engine.Add overwrites the entire file.

#### Diff

```diff
-$script:patchedLexerPy    = $null  # WIP
+$script:patchedLexerPy    = @'
+﻿# -*- coding: utf-8 -*-
+"""
+    jinja2.lexer
+    ~~~~~~~~~~~~
+
+    This module implements a Jinja / Python combination lexer. The
+    `Lexer` class provided by this module is used to do some preprocessing
+    for Jinja.
+
+    On the one hand it filters out invalid operators like the bitshift
+    operators we don't allow in templates. On the other hand it separates
+    template code and python code in expressions.
+
+    :copyright: (c) 2017 by the Jinja Team.
+    :license: BSD, see LICENSE for more details.
+"""
+import re
+from collections import deque
+from operator import itemgetter
+
+from jinja2._compat import implements_iterator, intern, iteritems, text_type
+from jinja2.exceptions import TemplateSyntaxError
+from jinja2.utils import LRUCache
+
+# cache for the lexers. Exists in order to be able to have multiple
+# environments with the same lexer
+_lexer_cache = LRUCache(50)
+
+# static regular expressions
+whitespace_re = re.compile(r's+', re.U)
+string_re = re.compile(r"('([^'\]*(?:\.[^'\]*)*)'"
+                       r'|"([^"\]*(?:\.[^"\]*)*)")', re.S)
+integer_re = re.compile(r'd+')
+
+name_re = re.compile(r'[a-zA-Z_][a-zA-Z0-9_]*')
+check_ident = False
+
+float_re = re.compile(r'(?<!.)d+.d+')
+newline_re = re.compile(r'(
||
)')
+
+# internal the tokens and keep references to them
+TOKEN_ADD = intern('add')
+TOKEN_ASSIGN = intern('assign')
+TOKEN_COLON = intern('colon')
+TOKEN_COMMA = intern('comma')
+TOKEN_DIV = intern('div')
+TOKEN_DOT = intern('dot')
+TOKEN_EQ = intern('eq')
+TOKEN_FLOORDIV = intern('floordiv')
+TOKEN_GT = intern('gt')
+TOKEN_GTEQ = intern('gteq')
+TOKEN_LBRACE = intern('lbrace')
+TOKEN_LBRACKET = intern('lbracket')
+TOKEN_LPAREN = intern('lparen')
+TOKEN_LT = intern('lt')
+TOKEN_LTEQ = intern('lteq')
+TOKEN_MOD = intern('mod')
+TOKEN_MUL = intern('mul')
+TOKEN_NE = intern('ne')
+TOKEN_PIPE = intern('pipe')
+TOKEN_POW = intern('pow')
+TOKEN_RBRACE = intern('rbrace')
+TOKEN_RBRACKET = intern('rbracket')
+TOKEN_RPAREN = intern('rparen')
+TOKEN_SEMICOLON = intern('semicolon')
+TOKEN_SUB = intern('sub')
+TOKEN_TILDE = intern('tilde')
+TOKEN_WHITESPACE = intern('whitespace')
+TOKEN_FLOAT = intern('float')
+TOKEN_INTEGER = intern('integer')
+TOKEN_NAME = intern('name')
+TOKEN_STRING = intern('string')
+TOKEN_OPERATOR = intern('operator')
+TOKEN_BLOCK_BEGIN = intern('block_begin')
+TOKEN_BLOCK_END = intern('block_end')
+TOKEN_VARIABLE_BEGIN = intern('variable_begin')
+TOKEN_VARIABLE_END = intern('variable_end')
+TOKEN_RAW_BEGIN = intern('raw_begin')
+TOKEN_RAW_END = intern('raw_end')
+TOKEN_COMMENT_BEGIN = intern('comment_begin')
+TOKEN_COMMENT_END = intern('comment_end')
+TOKEN_COMMENT = intern('comment')
+TOKEN_LINESTATEMENT_BEGIN = intern('linestatement_begin')
+TOKEN_LINESTATEMENT_END = intern('linestatement_end')
+TOKEN_LINECOMMENT_BEGIN = intern('linecomment_begin')
+TOKEN_LINECOMMENT_END = intern('linecomment_end')
+TOKEN_LINECOMMENT = intern('linecomment')
+TOKEN_DATA = intern('data')
+TOKEN_INITIAL = intern('initial')
+TOKEN_EOF = intern('eof')
+
+# bind operators to token types
+operators = {
+    '+':            TOKEN_ADD,
+    '-':            TOKEN_SUB,
+    '/':            TOKEN_DIV,
+    '//':           TOKEN_FLOORDIV,
+    '*':            TOKEN_MUL,
+    '%':            TOKEN_MOD,
+    '**':           TOKEN_POW,
+    '~':            TOKEN_TILDE,
+    '[':            TOKEN_LBRACKET,
+    ']':            TOKEN_RBRACKET,
+    '(':            TOKEN_LPAREN,
+    ')':            TOKEN_RPAREN,
+    '{':            TOKEN_LBRACE,
+    '}':            TOKEN_RBRACE,
+    '==':           TOKEN_EQ,
+    '!=':           TOKEN_NE,
+    '>':            TOKEN_GT,
+    '>=':           TOKEN_GTEQ,
+    '<':            TOKEN_LT,
+    '<=':           TOKEN_LTEQ,
+    '=':            TOKEN_ASSIGN,
+    '.':            TOKEN_DOT,
+    ':':            TOKEN_COLON,
+    '|':            TOKEN_PIPE,
+    ',':            TOKEN_COMMA,
+    ';':            TOKEN_SEMICOLON
+}
+
+reverse_operators = dict([(v, k) for k, v in iteritems(operators)])
+assert len(operators) == len(reverse_operators), 'operators dropped'
+operator_re = re.compile('(%s)' % '|'.join(re.escape(x) for x in
+                         sorted(operators, key=lambda x: -len(x))))
+
+ignored_tokens = frozenset([TOKEN_COMMENT_BEGIN, TOKEN_COMMENT,
+                            TOKEN_COMMENT_END, TOKEN_WHITESPACE,
+                            TOKEN_LINECOMMENT_BEGIN, TOKEN_LINECOMMENT_END,
+                            TOKEN_LINECOMMENT])
+ignore_if_empty = frozenset([TOKEN_WHITESPACE, TOKEN_DATA,
+                             TOKEN_COMMENT, TOKEN_LINECOMMENT])
+
+
+def _describe_token_type(token_type):
+    if token_type in reverse_operators:
+        return reverse_operators[token_type]
+    return {
+        TOKEN_COMMENT_BEGIN:        'begin of comment',
+        TOKEN_COMMENT_END:          'end of comment',
+        TOKEN_COMMENT:              'comment',
+        TOKEN_LINECOMMENT:          'comment',
+        TOKEN_BLOCK_BEGIN:          'begin of statement block',
+        TOKEN_BLOCK_END:            'end of statement block',
+        TOKEN_VARIABLE_BEGIN:       'begin of print statement',
+        TOKEN_VARIABLE_END:         'end of print statement',
+        TOKEN_LINESTATEMENT_BEGIN:  'begin of line statement',
+        TOKEN_LINESTATEMENT_END:    'end of line statement',
+        TOKEN_DATA:                 'template data / text',
+        TOKEN_EOF:                  'end of template'
+    }.get(token_type, token_type)
+
+
+def describe_token(token):
+    """Returns a description of the token."""
+    if token.type == 'name':
+        return token.value
+    return _describe_token_type(token.type)
+
+
+def describe_token_expr(expr):
+    """Like `describe_token` but for token expressions."""
+    if ':' in expr:
+        type, value = expr.split(':', 1)
+        if type == 'name':
+            return value
+    else:
+        type = expr
+    return _describe_token_type(type)
+
+
+def count_newlines(value):
+    """Count the number of newline characters in the string.  This is
+    useful for extensions that filter a stream.
+    """
+    return len(newline_re.findall(value))
+
+
+def compile_rules(environment):
+    """Compiles all the rules from the environment into a list of rules."""
+    e = re.escape
+    rules = [
+        (len(environment.comment_start_string), 'comment',
+         e(environment.comment_start_string)),
+        (len(environment.block_start_string), 'block',
+         e(environment.block_start_string)),
+        (len(environment.variable_start_string), 'variable',
+         e(environment.variable_start_string))
+    ]
+
+    if environment.line_statement_prefix is not None:
+        rules.append((len(environment.line_statement_prefix), 'linestatement',
+                      r'^[ 	]*' + e(environment.line_statement_prefix)))
+    if environment.line_comment_prefix is not None:
+        rules.append((len(environment.line_comment_prefix), 'linecomment',
+                      r'(?:^|(?<=S))[^S
]*' +
+                      e(environment.line_comment_prefix)))
+
+    return [x[1:] for x in sorted(rules, reverse=True)]
+
+
+class Failure(object):
+    """Class that raises a `TemplateSyntaxError` if called.
+    Used by the `Lexer` to specify known errors.
+    """
+
+    def __init__(self, message, cls=TemplateSyntaxError):
+        self.message = message
+        self.error_class = cls
+
+    def __call__(self, lineno, filename):
+        raise self.error_class(self.message, lineno, filename)
+
+
+class Token(tuple):
+    """Token class."""
+    __slots__ = ()
+    lineno, type, value = (property(itemgetter(x)) for x in range(3))
+
+    def __new__(cls, lineno, type, value):
+        return tuple.__new__(cls, (lineno, intern(str(type)), value))
+
+    def __str__(self):
+        if self.type in reverse_operators:
+            return reverse_operators[self.type]
+        elif self.type == 'name':
+            return self.value
+        return self.type
+
+    def test(self, expr):
+        """Test a token against a token expression.  This can either be a
+        token type or ``'token_type:token_value'``.  This can only test
+        against string values and types.
+        """
+        # here we do a regular string equality check as test_any is usually
+        # passed an iterable of not interned strings.
+        if self.type == expr:
+            return True
+        elif ':' in expr:
+            return expr.split(':', 1) == [self.type, self.value]
+        return False
+
+    def test_any(self, *iterable):
+        """Test against multiple token expressions."""
+        for expr in iterable:
+            if self.test(expr):
+                return True
+        return False
+
+    def __repr__(self):
+        return 'Token(%r, %r, %r)' % (
+            self.lineno,
+            self.type,
+            self.value
+        )
+
+
+@implements_iterator
+class TokenStreamIterator(object):
+    """The iterator for tokenstreams.  Iterate over the stream
+    until the eof token is reached.
+    """
+
+    def __init__(self, stream):
+        self.stream = stream
+
+    def __iter__(self):
+        return self
+
+    def __next__(self):
+        token = self.stream.current
+        if token.type is TOKEN_EOF:
+            self.stream.close()
+            raise StopIteration()
+        next(self.stream)
+        return token
+
+
+@implements_iterator
+class TokenStream(object):
+    """A token stream is an iterable that yields :class:`Token`\s.  The
+    parser however does not iterate over it but calls :meth:`next` to go
+    one token ahead.  The current active token is stored as :attr:`current`.
+    """
+
+    def __init__(self, generator, name, filename):
+        self._iter = iter(generator)
+        self._pushed = deque()
+        self.name = name
+        self.filename = filename
+        self.closed = False
+        self.current = Token(1, TOKEN_INITIAL, '')
+        next(self)
+
+    def __iter__(self):
+        return TokenStreamIterator(self)
+
+    def __bool__(self):
+        return bool(self._pushed) or self.current.type is not TOKEN_EOF
+    __nonzero__ = __bool__  # py2
+
+    eos = property(lambda x: not x, doc="Are we at the end of the stream?")
+
+    def push(self, token):
+        """Push a token back to the stream."""
+        self._pushed.append(token)
+
+    def look(self):
+        """Look at the next token."""
+        old_token = next(self)
+        result = self.current
+        self.push(result)
+        self.current = old_token
+        return result
+
+    def skip(self, n=1):
+        """Got n tokens ahead."""
+        for x in range(n):
+            next(self)
+
+    def next_if(self, expr):
+        """Perform the token test and return the token if it matched.
+        Otherwise the return value is `None`.
+        """
+        if self.current.test(expr):
+            return next(self)
+
+    def skip_if(self, expr):
+        """Like :meth:`next_if` but only returns `True` or `False`."""
+        return self.next_if(expr) is not None
+
+    def __next__(self):
+        """Go one token ahead and return the old one.
+
+        Use the built-in :func:`next` instead of calling this directly.
+        """
+        rv = self.current
+        if self._pushed:
+            self.current = self._pushed.popleft()
+        elif self.current.type is not TOKEN_EOF:
+            try:
+                self.current = next(self._iter)
+            except StopIteration:
+                self.close()
+        return rv
+
+    def close(self):
+        """Close the stream."""
+        self.current = Token(self.current.lineno, TOKEN_EOF, '')
+        self._iter = None
+        self.closed = True
+
+    def expect(self, expr):
+        """Expect a given token type and return it.  This accepts the same
+        argument as :meth:`jinja2.lexer.Token.test`.
+        """
+        if not self.current.test(expr):
+            expr = describe_token_expr(expr)
+            if self.current.type is TOKEN_EOF:
+                raise TemplateSyntaxError('unexpected end of template, '
+                                          'expected %r.' % expr,
+                                          self.current.lineno,
+                                          self.name, self.filename)
+            raise TemplateSyntaxError("expected token %r, got %r" %
+                                      (expr, describe_token(self.current)),
+                                      self.current.lineno,
+                                      self.name, self.filename)
+        try:
+            return self.current
+        finally:
+            next(self)
+
+
+def get_lexer(environment):
+    """Return a lexer which is probably cached."""
+    key = (environment.block_start_string,
+           environment.block_end_string,
+           environment.variable_start_string,
+           environment.variable_end_string,
+           environment.comment_start_string,
+           environment.comment_end_string,
+           environment.line_statement_prefix,
+           environment.line_comment_prefix,
+           environment.trim_blocks,
+           environment.lstrip_blocks,
+           environment.newline_sequence,
+           environment.keep_trailing_newline)
+    lexer = _lexer_cache.get(key)
+    if lexer is None:
+        lexer = Lexer(environment)
+        _lexer_cache[key] = lexer
+    return lexer
+
+
+class Lexer(object):
+    """Class that implements a lexer for a given environment. Automatically
+    created by the environment class, usually you don't have to do that.
+
+    Note that the lexer is not automatically bound to an environment.
+    Multiple environments can share the same lexer.
+    """
+
+    def __init__(self, environment):
+        # shortcuts
+        c = lambda x: re.compile(x, re.M | re.S)
+        e = re.escape
+
+        # lexing rules for tags
+        tag_rules = [
+            (whitespace_re, TOKEN_WHITESPACE, None),
+            (float_re, TOKEN_FLOAT, None),
+            (integer_re, TOKEN_INTEGER, None),
+            (name_re, TOKEN_NAME, None),
+            (string_re, TOKEN_STRING, None),
+            (operator_re, TOKEN_OPERATOR, None)
+        ]
+
+        # assemble the root lexing rule. because "|" is ungreedy
+        # we have to sort by length so that the lexer continues working
+        # as expected when we have parsing rules like <% for block and
+        # <%= for variables. (if someone wants asp like syntax)
+        # variables are just part of the rules if variable processing
+        # is required.
+        root_tag_rules = compile_rules(environment)
+
+        # block suffix if trimming is enabled
+        block_suffix_re = environment.trim_blocks and '\n?' or ''
+
+        # strip leading spaces if lstrip_blocks is enabled
+        prefix_re = {}
+        if environment.lstrip_blocks:
+            # use '{%+' to manually disable lstrip_blocks behavior
+            no_lstrip_re = e('+')
+            # detect overlap between block and variable or comment strings
+            block_diff = c(r'^%s(.*)' % e(environment.block_start_string))
+            # make sure we don't mistake a block for a variable or a comment
+            m = block_diff.match(environment.comment_start_string)
+            no_lstrip_re += m and r'|%s' % e(m.group(1)) or ''
+            m = block_diff.match(environment.variable_start_string)
+            no_lstrip_re += m and r'|%s' % e(m.group(1)) or ''
+
+            # detect overlap between comment and variable strings
+            comment_diff = c(r'^%s(.*)' % e(environment.comment_start_string))
+            m = comment_diff.match(environment.variable_start_string)
+            no_variable_re = m and r'(?!%s)' % e(m.group(1)) or ''
+
+            lstrip_re = r'^[ 	]*'
+            block_prefix_re = r'%s%s(?!%s)|%s+?' % (
+                    lstrip_re,
+                    e(environment.block_start_string),
+                    no_lstrip_re,
+                    e(environment.block_start_string),
+                    )
+            comment_prefix_re = r'%s%s%s|%s+?' % (
+                    lstrip_re,
+                    e(environment.comment_start_string),
+                    no_variable_re,
+                    e(environment.comment_start_string),
+                    )
+            prefix_re['block'] = block_prefix_re
+            prefix_re['comment'] = comment_prefix_re
+        else:
+            block_prefix_re = '%s' % e(environment.block_start_string)
+
+        self.newline_sequence = environment.newline_sequence
+        self.keep_trailing_newline = environment.keep_trailing_newline
+
+        # global lexing rules
+        self.rules = {
+            'root': [
+                # directives
+                (c('(.*?)(?:%s)' % '|'.join(
+                    [r'(?P<raw_begin>(?:s*%s-|%s)s*raws*(?:-%ss*|%s))' % (
+                        e(environment.block_start_string),
+                        block_prefix_re,
+                        e(environment.block_end_string),
+                        e(environment.block_end_string)
+                    )] + [
+                        r'(?P<%s_begin>s*%s-|%s)' % (n, r, prefix_re.get(n,r))
+                        for n, r in root_tag_rules
+                    ])), (TOKEN_DATA, '#bygroup'), '#bygroup'),
+                # data
+                (c('.+'), TOKEN_DATA, None)
+            ],
+            # comments
+            TOKEN_COMMENT_BEGIN: [
+                (c(r'(.*?)((?:-%ss*|%s)%s)' % (
+                    e(environment.comment_end_string),
+                    e(environment.comment_end_string),
+                    block_suffix_re
+                )), (TOKEN_COMMENT, TOKEN_COMMENT_END), '#pop'),
+                (c('(.)'), (Failure('Missing end of comment tag'),), None)
+            ],
+            # blocks
+            TOKEN_BLOCK_BEGIN: [
+                (c(r'(?:-%ss*|%s)%s' % (
+                    e(environment.block_end_string),
+                    e(environment.block_end_string),
+                    block_suffix_re
+                )), TOKEN_BLOCK_END, '#pop'),
+            ] + tag_rules,
+            # variables
+            TOKEN_VARIABLE_BEGIN: [
+                (c(r'-%ss*|%s' % (
+                    e(environment.variable_end_string),
+                    e(environment.variable_end_string)
+                )), TOKEN_VARIABLE_END, '#pop')
+            ] + tag_rules,
+            # raw block
+            TOKEN_RAW_BEGIN: [
+                (c(r'(.*?)((?:s*%s-|%s)s*endraws*(?:-%ss*|%s%s))' % (
+                    e(environment.block_start_string),
+                    block_prefix_re,
+                    e(environment.block_end_string),
+                    e(environment.block_end_string),
+                    block_suffix_re
+                )), (TOKEN_DATA, TOKEN_RAW_END), '#pop'),
+                (c('(.)'), (Failure('Missing end of raw directive'),), None)
+            ],
+            # line statements
+            TOKEN_LINESTATEMENT_BEGIN: [
+                (c(r's*(
|$)'), TOKEN_LINESTATEMENT_END, '#pop')
+            ] + tag_rules,
+            # line comments
+            TOKEN_LINECOMMENT_BEGIN: [
+                (c(r'(.*?)()(?=
|$)'), (TOKEN_LINECOMMENT,
+                 TOKEN_LINECOMMENT_END), '#pop')
+            ]
+        }
+
+    def _normalize_newlines(self, value):
+        """Called for strings and template data to normalize it to unicode."""
+        return newline_re.sub(self.newline_sequence, value)
+
+    def tokenize(self, source, name=None, filename=None, state=None):
+        """Calls tokeniter + tokenize and wraps it in a token stream.
+        """
+        stream = self.tokeniter(source, name, filename, state)
+        return TokenStream(self.wrap(stream, name, filename), name, filename)
+
+    def wrap(self, stream, name=None, filename=None):
+        """This is called with the stream as returned by `tokenize` and wraps
+        every token in a :class:`Token` and converts the value.
+        """
+        for lineno, token, value in stream:
+            if token in ignored_tokens:
+                continue
+            elif token == 'linestatement_begin':
+                token = 'block_begin'
+            elif token == 'linestatement_end':
+                token = 'block_end'
+            # we are not interested in those tokens in the parser
+            elif token in ('raw_begin', 'raw_end'):
+                continue
+            elif token == 'data':
+                value = self._normalize_newlines(value)
+            elif token == 'keyword':
+                token = value
+            elif token == 'name':
+                value = str(value)
+                if check_ident and not value.isidentifier():
+                    raise TemplateSyntaxError(
+                        'Invalid character in identifier',
+                        lineno, name, filename)
+            elif token == 'string':
+                # try to unescape string
+                try:
+                    value = self._normalize_newlines(value[1:-1]) +                        .encode('ascii', 'backslashreplace') +                        .decode('unicode-escape')
+                except Exception as e:
+                    msg = str(e).split(':')[-1].strip()
+                    raise TemplateSyntaxError(msg, lineno, name, filename)
+            elif token == 'integer':
+                value = int(value)
+            elif token == 'float':
+                value = float(value)
+            elif token == 'operator':
+                token = operators[value]
+            yield Token(lineno, token, value)
+
+    def tokeniter(self, source, name, filename=None, state=None):
+        """This method tokenizes the text and returns the tokens in a
+        generator.  Use this method if you just want to tokenize a template.
+        """
+        source = text_type(source)
+        lines = source.splitlines()
+        if self.keep_trailing_newline and source:
+            for newline in ('
', '', '
'):
+                if source.endswith(newline):
+                    lines.append('')
+                    break
+        source = '
'.join(lines)
+        pos = 0
+        lineno = 1
+        stack = ['root']
+        if state is not None and state != 'root':
+            assert state in ('variable', 'block'), 'invalid state'
+            stack.append(state + '_begin')
+        else:
+            state = 'root'
+        statetokens = self.rules[stack[-1]]
+        source_length = len(source)
+
+        balancing_stack = []
+
+        while 1:
+            # tokenizer loop
+            for regex, tokens, new_state in statetokens:
+                m = regex.match(source, pos)
+                # if no match we try again with the next rule
+                if m is None:
+                    continue
+
+                # we only match blocks and variables if braces / parentheses
+                # are balanced. continue parsing with the lower rule which
+                # is the operator rule. do this only if the end tags look
+                # like operators
+                if balancing_stack and +                   tokens in ('variable_end', 'block_end',
+                              'linestatement_end'):
+                    continue
+
+                # tuples support more options
+                if isinstance(tokens, tuple):
+                    for idx, token in enumerate(tokens):
+                        # failure group
+                        if token.__class__ is Failure:
+                            raise token(lineno, filename)
+                        # bygroup is a bit more complex, in that case we
+                        # yield for the current token the first named
+                        # group that matched
+                        elif token == '#bygroup':
+                            for key, value in iteritems(m.groupdict()):
+                                if value is not None:
+                                    yield lineno, key, value
+                                    lineno += value.count('
')
+                                    break
+                            else:
+                                raise RuntimeError('%r wanted to resolve '
+                                                   'the token dynamically'
+                                                   ' but no group matched'
+                                                   % regex)
+                        # normal group
+                        else:
+                            data = m.group(idx + 1)
+                            if data or token not in ignore_if_empty:
+                                yield lineno, token, data
+                            lineno += data.count('
')
+
+                # strings as token just are yielded as it.
+                else:
+                    data = m.group()
+                    # update brace/parentheses balance
+                    if tokens == 'operator':
+                        if data == '{':
+                            balancing_stack.append('}')
+                        elif data == '(':
+                            balancing_stack.append(')')
+                        elif data == '[':
+                            balancing_stack.append(']')
+                        elif data in ('}', ')', ']'):
+                            if not balancing_stack:
+                                raise TemplateSyntaxError('unexpected '%s'' %
+                                                          data, lineno, name,
+                                                          filename)
+                            expected_op = balancing_stack.pop()
+                            if expected_op != data:
+                                raise TemplateSyntaxError('unexpected '%s', '
+                                                          'expected '%s'' %
+                                                          (data, expected_op),
+                                                          lineno, name,
+                                                          filename)
+                    # yield items
+                    if data or tokens not in ignore_if_empty:
+                        yield lineno, tokens, data
+                    lineno += data.count('
')
+
+                # fetch new position into new variable so that we can check
+                # if there is a internal parsing error which would result
+                # in an infinite loop
+                pos2 = m.end()
+
+                # handle state changes
+                if new_state is not None:
+                    # remove the uppermost state
+                    if new_state == '#pop':
+                        stack.pop()
+                    # resolve the new state by group checking
+                    elif new_state == '#bygroup':
+                        for key, value in iteritems(m.groupdict()):
+                            if value is not None:
+                                stack.append(key)
+                                break
+                        else:
+                            raise RuntimeError('%r wanted to resolve the '
+                                               'new state dynamically but'
+                                               ' no group matched' %
+                                               regex)
+                    # direct state name given
+                    else:
+                        stack.append(new_state)
+                    statetokens = self.rules[stack[-1]]
+                # we are still at the same position and no stack change.
+                # this means a loop without break condition, avoid that and
+                # raise error
+                elif pos2 == pos:
+                    raise RuntimeError('%r yielded empty string without '
+                                       'stack change' % regex)
+                # publish new function and start again
+                pos = pos2
+                break
+            # if loop terminated without break we haven't found a single match
+            # either we are at the end of the file or we have a problem
+            else:
+                # end of text
+                if pos >= source_length:
+                    return
+                # something went wrong
+                raise TemplateSyntaxError('unexpected char %r at %d' %
+                                          (source[pos], pos), lineno,
+                                          name, filename)
+'@
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 725 lines | FAIL |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 16: `ipy.Jinja.ps1` - Implement Install-IpyJinja function body: load both wheels from PyPI, then overwrite the three patched files and stub out asyncsupport.py and asyncfilters.py.

### ipy.Jinja.implement-install-ipyjinja

> **File**: `ipy.Jinja.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement Install-IpyJinja function body: load both wheels from PyPI, then overwrite the three patched files and stub out asyncsupport.py and asyncfilters.py.

#### Diff

```diff
-    # WIP
+    $Engine.Add('/ipy/lib/site-packages', $script:jinjaWheelUrl)
+    $Engine.Add('/ipy/lib/site-packages', $script:markupsafeWheelUrl)
+    $Engine.Add('/ipy/lib/site-packages/jinja2/debug.py',        $script:patchedDebugPy)
+    $Engine.Add('/ipy/lib/site-packages/jinja2/_compat.py',      $script:patchedCompatPy)
+    $Engine.Add('/ipy/lib/site-packages/jinja2/lexer.py',        $script:patchedLexerPy)
+    $Engine.Add('/ipy/lib/site-packages/jinja2/asyncsupport.py', '# Stub: async not supported on IronPython 3.4')
+    $Engine.Add('/ipy/lib/site-packages/jinja2/asyncfilters.py', '# Stub: async not supported on IronPython 3.4')
+    return $Engine
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 17: `test.ps1` - Update test.ps1: remove Import-Module and instead dot-source ipy.Jinja.ps1 directly; remove ipy.Jinja.psd1 reference. All test logic and assertions remain unchanged.

### test.update-test-ps1

> **File**: `test.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update test.ps1: remove Import-Module and instead dot-source ipy.Jinja.ps1 directly; remove ipy.Jinja.psd1 reference. All test logic and assertions remain unchanged.

#### Diff

```diff
-Import-Module "$PSScriptRoot/ipy.Jinja.psd1" -Force
+. "$PSScriptRoot/ipy.Jinja.ps1"
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 18: `README.md` - Update README.md: replace build-step instructions with the new runtime-only approach; show dot-source usage instead of Import-Module; remove build.ps1 section.

### README.update-readme

> **File**: `README.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update README.md: replace build-step instructions with the new runtime-only approach; show dot-source usage instead of Import-Module; remove build.ps1 section.

#### Diff

```diff
-# ipy.Jinja
-
-Vendored Jinja2 2.10.3 + MarkupSafe 1.1.1 for use with [IronPythonEmbedded](../IronPythonEmbedded).
-
-## Quick Start
-
-```powershell
-Import-Module ./ipy.Jinja.psd1
-$ipy = & ../IronPythonEmbedded/IronPythonEmbedded.ps1
-$engine = $ipy.Build()
-Install-IpyJinja -Engine $engine
-
-$scope = $engine.CreateScope()
-$engine.Execute(@"
-from jinja2 import Environment, DictLoader
-env = Environment(loader=DictLoader({'hello': 'Hello {{ name }}!'}))
-result = env.get_template('hello').render(name='World')
-"@, $scope)
-Write-Host $scope.GetVariable('result')  # Hello World!
-```
-
-## Building the Vendor Archive
-
-```powershell
-./build.ps1
-```
+# ipy.Jinja
+
+Jinja2 2.10.3 + MarkupSafe 1.1.1 for use with [IronPythonEmbedded](../IronPythonEmbedded).
+Wheels are downloaded from PyPI at runtime; no build step required.
+
+## Quick Start
+
+```powershell
+. "$PSScriptRoot/ipy.Jinja.ps1"
+$builder = iwr 'https://raw.githubusercontent.com/anonhostpi/IronPythonEmbedded/main/IronPythonEmbedded.ps1' | iex
+$engine = $builder.Build()
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
+## How It Works
+
+`Install-IpyJinja` loads both Jinja2 and MarkupSafe wheels directly from PyPI into
+the IronPythonEmbedded engine, then overwrites the three files that require IronPython
+compatibility patches (debug.py, _compat.py, lexer.py) and stubs out the async files
+that contain Python 3.5+ syntax incompatible with IronPython 3.4.
```

#### Rule Compliance

> See Operating Procedures for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 54 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
