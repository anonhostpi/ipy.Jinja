# ipy.Jinja.ps1 -- Single-file PowerShell module to load Jinja2 + MarkupSafe
# into an IronPythonEmbedded engine instance at runtime.
#
# Usage:
#   . "$PSScriptRoot/ipy.Jinja.ps1"
#   Install-IpyJinja -Engine $engine

$script:jinjaWheelUrl    = 'https://files.pythonhosted.org/packages/65/e0/eb35e762802015cab1ccee04e8a277b03f1d8e53da3ec3106882ec42558b/Jinja2-2.10.3-py2.py3-none-any.whl'
$script:markupsafeWheelUrl = 'https://files.pythonhosted.org/packages/09/31/fe863b864cf3dfa11bce7a3bd41c4433d59b777ee0750b8d8c9a96f5ca98/MarkupSafe-1.1.1-cp34-cp34m-win_amd64.whl'

# Patched Python source files (full content; loaded after wheel to overwrite originals)
$script:patchedDebugPy    = $null  # WIP
$script:patchedCompatPy   = $null  # WIP
$script:patchedLexerPy    = $null  # WIP

function Install-IpyJinja {
    param([Parameter(Mandatory)][object]$Engine)
    # WIP
}
