# Load private helper functions before loading the public module commands.
$privateScripts = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File -ErrorAction SilentlyContinue)
foreach ($script in $privateScripts) {
    # Dot-source each private helper into this module's scope.
    . $script.FullName
}

# Load public functions after their private dependencies are available.
$publicScripts = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File -ErrorAction SilentlyContinue)
foreach ($script in $publicScripts) {
    # Dot-source each public function into this module's scope.
    . $script.FullName
}

# Export only the supported public command from the module.
Export-ModuleMember -Function Invoke-PerplexityDecision
