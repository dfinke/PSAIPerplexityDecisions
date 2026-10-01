# Create a Noul question with yes/no wording while retaining Perplexity's schema.
function New-PerplexityYesNoQuestion {
    <#
    .SYNOPSIS
    Creates a named Noul question for the Perplexity Decisions API.

    .DESCRIPTION
    Provides a friendly yes/no constructor. The question text becomes the
    Perplexity instructions field; it does not add unsupported Noul criteria.

    .PARAMETER Name
    The key used to identify this question in the response.

    .PARAMETER Question
    The yes/no question Perplexity should answer.

    .EXAMPLE
    New-PerplexityYesNoQuestion -Name pageOnCall `
        -Question 'Should the on-call engineer be paged now?'
    #>
    [CmdletBinding()]
    param (
        # Require a non-empty response key for this question.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # Require the question text that maps to the API instructions field.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Question
    )

    # Delegate to the general constructor with Perplexity's Noul type and field mapping.
    return New-PerplexityDecisionQuestion -Name $Name -Type Noul -Instructions $Question
}
