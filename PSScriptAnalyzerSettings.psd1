@{
    ExcludeRules = @(
        # Interactive console scripts: colored Write-Host progress output is intentional.
        'PSAvoidUsingWriteHost'
    )
}
