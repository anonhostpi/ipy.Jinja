@{
    ModuleVersion     = '1.0.0'
    Author            = 'ipy.Jinja'
    Description       = 'Vendored Jinja2 2.10.3 + MarkupSafe 1.1.1 for IronPythonEmbedded'
    RootModule        = 'ipy.Jinja.psm1'
    FunctionsToExport = @('Install-IpyJinja')
    PrivateData       = @{
        PSData = @{
            Tags = @('IronPython','Jinja2','Templating')
        }
    }
}
