---
topic: IPY.JINJA
phase: discovery
rule: 0
feedback_iteration: 0
baseline_commit: 9388e7172cf6b1169a003cab306c805d67fcc676
last_squashed_commit: null
created: 2026-03-07
branch: feat/vendor-jinja2
worktree: ../ipy.Jinja.worktrees/feat/vendor-jinja2
pr_number: 1
pr_url: https://github.com/anonhostpi/ipy.Jinja/pull/1
pr_state: draft
---

# RESEARCH: Vendoring Jinja2 + MarkupSafe for IronPython 3.4.2

## Problem Statement

IronPython 3.4.2 (via IronPythonEmbedded) needs Jinja2 templating support. IronPythonEmbedded loads all modules in-memory from zip archives -- no disk writes, no pip, no C extensions. We need to vendor Jinja2 and MarkupSafe as pure-Python packages that work within this constrained environment.

## Context

### IronPythonEmbedded API Surface

The embedding system (at `D:\Orchestrations\IronPythonEmbedded\IronPythonEmbedded.ps1`) provides:

- **`engine.Add(path, content)`** -- Add a file (raw text, file path, URL, byte[], or zip archive) at a virtual path. If the content is a valid zip, entries are unpacked under `path` as a root.
- **`engine.Has(path)`** -- Check if a module file exists at a virtual path.
- **Virtual root**: `/ipy/` with search paths `/ipy/lib/` and `/ipy/lib/site-packages/`.
- **Module resolution**: Custom `sys.meta_path` finder/loader that looks for `<module>.py` and `<module>/__init__.py` under the search roots.
- **In-memory loading**: Source is compiled via `exec(compile(source, name, 'exec'), mod.__dict__)`.
- **Zip support**: `AddArchive(stream, prefixes, root)` extracts zip entries under a root, stripping prefix paths.

### IronPython 3.4.2 Constraints

- Targets **Python 3.4** language level
- **No `async`/`await` syntax** (introduced in Python 3.5, PEP 492)
- **No async generators** (introduced in Python 3.6, PEP 525)
- **No f-strings** (introduced in Python 3.6, PEP 498)
- **`ctypes` partially supported** -- IronPython has ctypes but with differences from CPython; pointer manipulation for traceback rewriting will not work
- **No C extensions** -- runs on .NET CLR, not CPython; `_speedups.c` cannot be loaded
- **`marshal` may have limitations** -- IronPython's marshal module may not support all bytecode formats
- **`_thread` module** -- available in IronPython 3.x (renamed from `thread` in Python 2)

## Investigation

### Recommended Versions

| Package | Version | Rationale |
|---------|---------|-----------|
| **Jinja2** | **2.10** | Last version with explicit Python 3.4 classifier. 2.10.1+ dropped 3.4 from classifiers. 2.11+ explicitly excludes 3.4 via `python_requires`. |
| **MarkupSafe** | **1.1.1** | Last 1.x release. Supports Python 2.7, 3.4-3.7. Version 2.0+ dropped Python 3.4 support. |

### Jinja2 2.10 File Inventory

All 27 `.py` files in `jinja2/`:

| File | Required | Notes |
|------|----------|-------|
| `__init__.py` | Yes | Entry point; conditionally patches async support |
| `_compat.py` | Yes | Python 2/3 compatibility layer |
| `_identifier.py` | Yes | Unicode identifier checking |
| `asyncfilters.py` | **No** | Contains `async def` syntax -- SyntaxError on Python 3.4 |
| `asyncsupport.py` | **No** | Contains `async def` syntax -- SyntaxError on Python 3.4 |
| `bccache.py` | Yes* | Bytecode caching; uses `marshal` -- may need shim |
| `compiler.py` | Yes | Template compiler |
| `constants.py` | Yes | String constants |
| `debug.py` | Yes* | Uses `ctypes` for traceback rewriting -- **needs patching** |
| `defaults.py` | Yes | Default filters and tests |
| `environment.py` | Yes | Core Environment class |
| `exceptions.py` | Yes | Exception classes |
| `ext.py` | Yes | Extension system (i18n, etc.) |
| `filters.py` | Yes | Built-in filters |
| `idtracking.py` | Yes | Identifier tracking for compiler |
| `lexer.py` | Yes | Template lexer |
| `loaders.py` | Yes | Template loaders (FileSystemLoader, etc.) |
| `meta.py` | Yes | Template metadata |
| `nativetypes.py` | Yes | Native Python type rendering |
| `nodes.py` | Yes | AST node types |
| `optimizer.py` | Yes | Template optimizer |
| `parser.py` | Yes | Template parser |
| `runtime.py` | Yes | Runtime support |
| `sandbox.py` | Yes | Sandboxed execution |
| `tests.py` | Yes | Built-in test functions |
| `utils.py` | Yes | Utilities including `have_async_gen` check |
| `visitor.py` | Yes | AST visitor pattern |

### MarkupSafe 1.1.1 File Inventory

| File | Required | Notes |
|------|----------|-------|
| `__init__.py` | Yes | Core `Markup` class; imports from `_speedups` with fallback to `_native` |
| `_compat.py` | Yes | Python 2/3 compat (`text_type`, `string_types`, `Mapping`) |
| `_constants.py` | Yes | HTML entity constants |
| `_native.py` | Yes | Pure-Python implementations of `escape`, `escape_silent`, `soft_unicode` |
| `_speedups.c` | **No** | C extension -- cannot load in IronPython |
| `_speedups.pyd`/`.so` | **No** | Compiled C extension -- cannot load in IronPython |

### Known Compatibility Issues and Required Fixes

#### 1. Async Files -- EXCLUDE (Critical)

**Files**: `asyncsupport.py`, `asyncfilters.py`

**Problem**: These files contain `async def` and `async for` syntax that is invalid in Python 3.4. While Jinja2's `__init__.py` guards the import with `have_async_gen` (which will be `False` on IronPython 3.4), the files should be **excluded entirely** from the vendored package to avoid any attempt at byte-compilation or accidental import.

**Fix**: Simply omit these files from the zip archive. The `_patch_async()` function in `__init__.py` checks `have_async_gen` before importing, so excluding the files is safe.

#### 2. debug.py ctypes Usage -- PATCH (Critical)

**Problem**: `debug.py` uses `ctypes` to manipulate CPython traceback internals (`tb_next` pointer via `_PyObject` and `_Traceback` ctypes structures). This is deeply CPython-specific and will fail on IronPython.

**Code path**: `_init_ugly_crap()` function defines ctypes structures for `_PyObject` and `_Traceback`, then uses them in `tb_set_next()` to chain traceback frames.

**Fix**: Patch `debug.py` to make `tb_set_next` a no-op or remove the `_init_ugly_crap()` call. The function is wrapped in a try/except already, so the graceful degradation path exists -- but it may raise `AccessViolationException` on IronPython before the except catches it. Safest approach: replace the ctypes block with a stub that immediately sets `tb_set_next = None`.

#### 3. MarkupSafe _speedups Import -- AUTOMATIC (No action needed)

**Problem**: `__init__.py` does `from ._speedups import escape, ...` with fallback to `from ._native import ...`.

**Fix**: No fix needed. When `_speedups` is not present, the `ImportError` is caught and `_native` is used. Since we exclude the C extension, the pure-Python fallback activates automatically.

#### 4. bccache.py marshal Usage -- MONITOR (Low risk)

**Problem**: `bccache.py` uses `marshal.dumps`/`marshal.loads` for bytecode caching. IronPython's `marshal` module may not support all operations.

**Fix**: Bytecode caching is optional and only used when `FileSystemBytecodeCache` or similar is configured. For in-memory template rendering (the primary use case), this code path is never hit. **No patch needed** unless bytecode caching is required.

#### 5. MarkupSafe _compat.py `collections.Mapping` -- MONITOR (Low risk)

**Problem**: `_compat.py` imports `Mapping` from `collections` (Python 2) or `collections.abc` (Python 3). On Python 3.4, `collections.Mapping` is still available (deprecated in 3.3, removed in 3.10), so this works fine.

**Fix**: No fix needed for Python 3.4.

#### 6. Template Loader Considerations -- DESIGN NEEDED

**Problem**: Jinja2's built-in loaders (`FileSystemLoader`, `PackageLoader`, etc.) expect filesystem access. In IronPythonEmbedded, templates exist in-memory.

**Fix**: Provide a custom loader class that integrates with IronPythonEmbedded's virtual filesystem:

```python
class IronPythonLoader(BaseLoader):
    def __init__(self, engine):
        self.engine = engine

    def get_source(self, environment, template):
        # Look up template in the virtual filesystem
        path = '/ipy/lib/site-packages/templates/' + template
        source = self.engine.GetString(path)
        if source is None:
            raise TemplateNotFound(template)
        return source, template, lambda: True
```

Alternatively, use `DictLoader` which already works with in-memory string dictionaries and requires no filesystem access.

#### 7. `_identifier.py` Non-ASCII Content -- MONITOR

**Problem**: This file contains Unicode character ranges for identifier validation. Ensure IronPython handles the source encoding correctly.

**Fix**: The IronPythonEmbedded loader uses UTF-8 encoding (`[Encoding]::UTF8.GetString`), which should handle this correctly. Monitor for encoding issues.

## Proposed Architecture

### Option 1: Pre-built Zip Archive (Recommended)

Create a zip archive containing the vendored packages, ready for `engine.Add()`:

```
ipy.Jinja.zip
  markupsafe/
    __init__.py
    _compat.py
    _constants.py
    _native.py
  jinja2/
    __init__.py
    _compat.py
    _identifier.py
    bccache.py
    compiler.py
    constants.py
    debug.py          (patched -- ctypes removed)
    defaults.py
    environment.py
    exceptions.py
    ext.py
    filters.py
    idtracking.py
    lexer.py
    loaders.py
    meta.py
    nativetypes.py
    nodes.py
    optimizer.py
    parser.py
    runtime.py
    sandbox.py
    tests.py
    utils.py
    visitor.py
```

**Usage in PowerShell:**
```powershell
$ipy = (& "$PSScriptRoot/IronPythonEmbedded.ps1")
$engine = $ipy.Build()

# Add vendored Jinja2+MarkupSafe
$engine.Add("/ipy/lib/site-packages", "$PSScriptRoot/ipy.Jinja.zip")

# Use Jinja2
$scope = $engine.CreateScope()
$engine.Execute(@"
from jinja2 import Environment, DictLoader
env = Environment(loader=DictLoader({'hello': 'Hello {{ name }}!'}))
template = env.get_template('hello')
result = template.render(name='World')
"@, $scope)
```

### Option 2: PowerShell Module with Build Script

Create a PowerShell module (`ipy.Jinja.psm1`) that:
1. Downloads Jinja2 2.10 and MarkupSafe 1.1.1 wheels from PyPI
2. Extracts the pure-Python files
3. Applies patches (debug.py ctypes removal)
4. Excludes async files
5. Produces the zip archive
6. Provides `Install-IpyJinja` cmdlet to add to an engine

### Recommendation: Option 1 with a Build Script

Combine both approaches:
- A **build script** (`build.ps1`) that downloads, patches, and packages
- A **pre-built zip** checked into the repo for convenience
- A **PowerShell function** to install into an engine instance

### Repository Structure

```
ipy.Jinja/
  ipy.Jinja.psm1          # PowerShell module -- Install-IpyJinja function
  ipy.Jinja.psd1           # Module manifest
  build.ps1                # Downloads + patches + zips
  vendor/
    ipy.Jinja.zip          # Pre-built vendored archive
  patches/
    debug.py.patch         # ctypes removal patch for debug.py
  RESEARCH.ipy.Jinja.md    # This document
```

### Patch Details: debug.py

The ctypes block in `_init_ugly_crap()` needs to be neutralized. The cleanest approach:

```python
# Original (in _init_ugly_crap):
#   import ctypes
#   ... ctypes structure definitions ...
#   def tb_set_next(tb, next):
#       ... ctypes pointer manipulation ...

# Patched: skip the entire ctypes approach
def tb_set_next(tb, next):
    pass  # No-op on IronPython -- ctypes traceback rewriting not supported
```

The function `_init_ugly_crap()` is called in a try/except at module level, and `tb_set_next` is used in `translate_exception_info()`. Making it a no-op means Jinja2 error messages may show less precise tracebacks, but template rendering itself is unaffected.

## Files to Modify (in vendored copies)

| File | Change |
|------|--------|
| `jinja2/debug.py` | Remove ctypes traceback manipulation; make `tb_set_next` a no-op |
| `jinja2/asyncsupport.py` | **Exclude entirely** from zip |
| `jinja2/asyncfilters.py` | **Exclude entirely** from zip |

## Open Questions

1. **IronPython `exec(compile(...))` behavior**: Does IronPython's `compile()` handle all Python 3.4 syntax that Jinja2's template compiler generates? The compiler produces Python source code from templates and executes it via `compile()` + `exec()`. Need integration testing.

2. **`collections.OrderedDict` in Jinja2**: Jinja2 uses `OrderedDict` in some code paths. Verify IronPython 3.4.2 provides this (it should -- `collections.OrderedDict` exists since Python 2.7/3.1).

3. **Thread safety**: IronPython's threading model differs from CPython (no GIL). Jinja2's `Environment` is documented as thread-safe for rendering, but verify under .NET threading.

4. **`re` module compatibility**: Jinja2's lexer makes heavy use of regex. IronPython uses .NET's regex engine under the hood. Verify all Jinja2 regex patterns work correctly.

5. **`DictLoader` vs custom loader**: For the initial implementation, `DictLoader` is the simplest path. A custom `IronPythonEmbeddedLoader` that reads from the virtual filesystem can be added later if needed.

6. **Jinja2 2.10 vs 2.10.3**: Version 2.10 has explicit Python 3.4 classifier. Versions 2.10.1-2.10.3 dropped the classifier but made no syntax changes requiring 3.5+. Using 2.10.3 (latest 2.10.x patch) is likely safe and includes bugfixes. **Recommend 2.10.3 with testing.**

---

**Status**: Rule 0 - Discovery (awaiting approval to proceed to Rule 1)
