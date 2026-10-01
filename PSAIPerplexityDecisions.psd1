@{
    # Identify the PowerShell module manifest format and module version.
    RootModule        = 'PSAIPerplexityDecisions.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'cf6f39bd-037e-46aa-9bf3-53c5b5f22676'

    # Describe the module for PowerShell discovery and package tooling.
    Author            = 'David Finke'
    Copyright         = '(c) 2026 David Finke'
    Description       = 'A focused PowerShell client for the Perplexity Decisions API.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    # Export only the supported public command.
    FunctionsToExport = @('Invoke-PerplexityDecision', 'New-PerplexityDecisionQuestion', 'New-PerplexityYesNoQuestion')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    # Inventory the module, implementation, tests, examples, documentation, and artwork.
    FileList          = @(
        'PSAIPerplexityDecisions.psd1'
        'PSAIPerplexityDecisions.psm1'
        'Public\Invoke-PerplexityDecision.ps1'
        'Public\New-PerplexityDecisionQuestion.ps1'
        'Public\New-PerplexityYesNoQuestion.ps1'
        'Private\Assert-PerplexityDecisionQuestions.ps1'
        'Private\ConvertTo-PerplexityDecisionQuestionMap.ps1'
        'Private\New-PerplexityDecisionHttpErrorRecord.ps1'
        'Tests\PSAIPerplexityDecisions.Tests.ps1'
        'Examples\DealDesk.ps1'
        'Examples\Excel-IT-Queue.ps1'
        'Examples\NotesToActions.ps1'
        'Examples\PageOnCall.ps1'
        'Examples\PowerShellCommandFinder.ps1'
        'Examples\QuickStart.ps1'
        'Examples\RefundTriage.ps1'
        'Examples\ReleaseNotes.ps1'
        'Examples\SecurityIncidentTriage.ps1'
        'Examples\SemanticLogTriage.ps1'
        'Examples\StandupReport.ps1'
        'InstallModule.ps1'
        'PublishToGallery.ps1'
        'README.md'
        'CHANGELOG.md'
        'LICENSE'
        'assets\perplexity-decisions.png'
    )

    # Include searchable metadata for the PowerShell Gallery.
    PrivateData       = @{
        PSData = @{
            Tags         = @('Perplexity', 'Decisions', 'API', 'PowerShell')
            LicenseUri   = 'https://github.com/dfinke/PSAIPerplexityDecisions/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/dfinke/PSAIPerplexityDecisions'
            IconUri      = 'https://raw.githubusercontent.com/dfinke/PSAIPerplexityDecisions/main/assets/perplexity-decisions.png'
            ReleaseNotes = 'Adds idiomatic question helpers and helper-object invocation while preserving Perplexity API-shaped -Questions input; updates examples and documentation and adds offline Pester coverage.'
        }
    }
}
