# Validate the question collection against the request contract documented in this repository.
function Assert-PerplexityDecisionQuestions {
    <#
    .SYNOPSIS
    Validates named Decisions API question definitions.

    .DESCRIPTION
    Checks the documented question types, required instructions, criteria forms,
    and maximum question and option counts before an HTTP request is made.

    .PARAMETER Questions
    A hashtable of named question definitions supplied to the public command.
    #>
    [CmdletBinding()]
    param (
        # Receive the named question set from the public command.
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary] $Questions
    )

    # Require no more than the documented 128 named questions per request.
    if ($Questions.Count -lt 1 -or $Questions.Count -gt 128) {
        throw [System.ArgumentException]::new('Questions must contain between 1 and 128 named questions.', 'Questions')
    }

    # Validate every question definition before serializing the request.
    foreach ($questionName in $Questions.Keys) {
        # Read the current named question definition.
        $question = $Questions[$questionName]

        # Require each question definition to be a dictionary with its documented fields.
        if ($question -isnot [System.Collections.IDictionary]) {
            throw [System.ArgumentException]::new("Question '$questionName' must be a hashtable with type and instructions fields.", 'Questions')
        }

        # Require one of the three documented question types.
        if (-not $question.Contains('type') -or $question.type -notin @('noul', 'choice', 'score')) {
            throw [System.ArgumentException]::new("Question '$questionName' type must be noul, choice, or score.", 'Questions')
        }

        # Require non-empty instructions as shown in the documented examples.
        if (-not $question.Contains('instructions') -or [string]::IsNullOrWhiteSpace([string]$question.instructions)) {
            throw [System.ArgumentException]::new("Question '$questionName' must include non-empty instructions.", 'Questions')
        }

        # Require choice criteria to be a named map and enforce the documented option maximum.
        if ($question.type -eq 'choice') {
            if (-not $question.Contains('criteria') -or $question.criteria -isnot [System.Collections.IDictionary]) {
                throw [System.ArgumentException]::new("Choice question '$questionName' must include criteria as a hashtable of named options.", 'Questions')
            }
            if ($question.criteria.Count -gt 255) {
                throw [System.ArgumentException]::new("Choice question '$questionName' cannot include more than 255 named options.", 'Questions')
            }
        }

        # Require score criteria to be an ordered rubric and enforce the documented maximum.
        if ($question.type -eq 'score') {
            if (-not $question.Contains('criteria') -or $question.criteria -isnot [System.Array]) {
                throw [System.ArgumentException]::new("Score question '$questionName' must include criteria as an array of rubric levels.", 'Questions')
            }
            if ($question.criteria.Count -gt 10) {
                throw [System.ArgumentException]::new("Score question '$questionName' cannot include more than 10 rubric levels.", 'Questions')
            }
        }
    }
}
