# Create a named Perplexity Decisions question using familiar PowerShell parameters.
function New-PerplexityDecisionQuestion {
    <#
    .SYNOPSIS
    Creates a named Noul, Choice, or Score question for Perplexity Decisions.

    .DESCRIPTION
    Returns a PowerShell question object that can be passed to
    Invoke-PerplexityDecision -Question. The invocation command converts the
    object into the named questions map required by the Perplexity API.

    .PARAMETER Name
    The key used to identify this question in the response.

    .PARAMETER Type
    The Perplexity question type: Noul, Choice, or Score.

    .PARAMETER Instructions
    The instructions Perplexity should use to answer this question.

    .PARAMETER Criteria
    A name-to-description map for Choice or an ordered array for Score.

    .EXAMPLE
    New-PerplexityDecisionQuestion -Name sentiment -Type Choice `
        -Instructions 'What is the overall sentiment?' `
        -Criteria @{ positive = 'Mostly satisfied'; negative = 'Mostly dissatisfied' }
    #>
    [CmdletBinding()]
    param (
        # Require a non-empty response key for this question.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # Limit the type to the three question types in Perplexity's contract.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Noul', 'Choice', 'Score')]
        [string] $Type,

        # Require the API instructions field for each question type.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Instructions,

        # Accept the type-specific criteria object when the question requires it.
        [Parameter()]
        [AllowNull()]
        [object] $Criteria
    )

    # Validate Choice criteria as a named map and enforce its documented maximum.
    if ($Type -eq 'Choice') {
        if ($null -eq $Criteria -or $Criteria -isnot [System.Collections.IDictionary]) {
            throw [System.ArgumentException]::new("Choice question '$Name' requires Criteria as a hashtable of named options.", 'Criteria')
        }
        if ($Criteria.Count -gt 255) {
            throw [System.ArgumentException]::new("Choice question '$Name' cannot include more than 255 named options.", 'Criteria')
        }
    }

    # Validate Score criteria as an ordered array and enforce its documented maximum.
    if ($Type -eq 'Score') {
        if ($null -eq $Criteria -or $Criteria -isnot [System.Array]) {
            throw [System.ArgumentException]::new("Score question '$Name' requires Criteria as an array of rubric levels.", 'Criteria')
        }
        if ($Criteria.Count -gt 10) {
            throw [System.ArgumentException]::new("Score question '$Name' cannot include more than 10 rubric levels.", 'Criteria')
        }
    }

    # Reject criteria for Noul because the Perplexity contract uses instructions alone.
    if ($Type -eq 'Noul' -and $null -ne $Criteria) {
        throw [System.ArgumentException]::new("Noul question '$Name' uses Instructions and does not accept Criteria in the Perplexity contract.", 'Criteria')
    }

    # Return a PowerShell-friendly object; the request converter maps Name to a question key.
    return [pscustomobject][ordered]@{
        Name         = $Name
        Type         = $Type
        Instructions = $Instructions
        Criteria     = $Criteria
    }
}
