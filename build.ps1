param(
    [string]$OutputDir = "$PSScriptRoot/vendor",
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Wheel {
    param([string]$Package, [string]$Version, [string]$DestDir)
    $url = "https://pypi.org/pypi/$Package/$Version/json"
    $meta = Invoke-RestMethod -Uri $url
    $wheel = $meta.urls | Where-Object { $_.packagetype -eq 'bdist_wheel' -and $_.filename -like '*none-any*' } | Select-Object -First 1
    if (-not $wheel) {
        # Fall back to any wheel (we'll extract only .py files)
        $wheel = $meta.urls | Where-Object { $_.packagetype -eq 'bdist_wheel' } | Select-Object -First 1
    }
    if (-not $wheel) { throw "No wheel found for $Package $Version" }
    $dest = Join-Path $DestDir $wheel.filename
    Invoke-WebRequest -Uri $wheel.url -OutFile $dest
    Write-Host "Downloaded: $($wheel.filename)"
    $dest
}
function Expand-Wheel {
    param([string]$WheelPath, [string]$DestDir)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $exclude = @('asyncsupport.py','asyncfilters.py','_speedups.c','_speedups.pyd','_speedups.so')
    $zip = [System.IO.Compression.ZipFile]::OpenRead($WheelPath)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName
            if ($name -notmatch '^(jinja2|markupsafe)/' ) { continue }
            if ($name -notlike '*.py') { continue }
            if ($exclude -contains [System.IO.Path]::GetFileName($name)) { continue }
            $dest = Join-Path $DestDir $name
            New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dest, $true)
        }
    } finally { $zip.Dispose() }
}
function Apply-Patches {
    param([string]$PackageDir)
    $debugPy = Join-Path $PackageDir 'jinja2/debug.py'
    $src = Get-Content $debugPy -Raw
    $pattern = '(?s)def _init_ugly_crap\(\):.*?(?=\ndef |\nclass |\Z)'
    $stub = @'
def _init_ugly_crap():
    # Stub: ctypes traceback rewriting not supported on IronPython.
    def tb_set_next(tb, next):
        pass
    return tb_set_next
'@
    $patched = [regex]::Replace($src, $pattern, $stub)
    Set-Content -Path $debugPy -Value $patched -NoNewline
    Write-Host "Patched: jinja2/debug.py"
    Patch-Compat $PackageDir
}
function Patch-Compat {
    param([string]$PackageDir)
    $file = Join-Path $PackageDir 'jinja2/_compat.py'
    $src = Get-Content $file -Raw
    $stub = "def url_quote(obj, safe=b'/'):`n    if isinstance(obj, str): obj = obj.encode('utf-8')`n    r = bytearray()`n    for b in obj:`n        c = bytes([b])`n        if c in (safe if isinstance(safe,bytes) else safe.encode('ascii')) or c.isalnum() or c in b'-._~': r.extend(c)`n        else: r.extend(('%{:02X}'.format(b)).encode('ascii'))`n    return r.decode('ascii')"
    $old = "try:`n    from urllib.parse import quote_from_bytes as url_quote`nexcept ImportError:`n    from urllib import quote as url_quote"
    $patched = $src.Replace($old, $stub)
    Set-Content -Path $file -Value $patched -NoNewline
    Write-Host "Patched: jinja2/_compat.py"
}
function Build-VendorZip {
    param([string]$SourceDir, [string]$OutputZip)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path $OutputZip) { Remove-Item $OutputZip }
    $zip = [System.IO.Compression.ZipFile]::Open($OutputZip, 'Create')
    try {
        foreach ($pkg in @('jinja2','markupsafe')) {
            $pkgDir = Join-Path $SourceDir $pkg
            if (-not (Test-Path $pkgDir)) { continue }
            Get-ChildItem -Recurse -File $pkgDir | ForEach-Object {
                $rel = $_.FullName.Substring($SourceDir.Length + 1).Replace('\','/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel) | Out-Null
            }
        }
    } finally { $zip.Dispose() }
    Write-Host "Created: $OutputZip"
}

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "ipy-jinja-build-$(Get-Random)"
New-Item -ItemType Directory -Path $workDir | Out-Null
try {
    $jinja2Whl = Get-Wheel 'Jinja2' '2.10.3' $workDir
    $markupSafeWhl = Get-Wheel 'MarkupSafe' '1.1.1' $workDir
    Expand-Wheel $jinja2Whl $workDir
    Expand-Wheel $markupSafeWhl $workDir
    Apply-Patches $workDir
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Build-VendorZip $workDir "$OutputDir/ipy.Jinja.zip"
    Write-Host "Build complete: $OutputDir/ipy.Jinja.zip"
} finally {
    Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
}
