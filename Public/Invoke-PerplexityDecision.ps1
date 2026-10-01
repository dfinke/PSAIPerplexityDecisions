# Send named decision questions to Perplexity and return its parsed response.
function Invoke-PerplexityDecision {
    <#
    .SYNOPSIS
    Sends named decision questions to the Perplexity Decisions API.

    .DESCRIPTION
    Submits a state object and named noul, choice, and score questions to the
    documented Perplexity Decisions endpoint, then returns its parsed response.
    The API key is read from the PERPLEXITY_API_KEY environment variable.

    .PARAMETER State
    The state object that provides context for the named questions.

    .PARAMETER Questions
    A hashtable of questions already arranged as named Perplexity API fields.

    .PARAMETER Question
    One or more questions created with New-PerplexityDecisionQuestion or
    New-PerplexityYesNoQuestion.

    .PARAMETER TimeoutSec
    The HTTP request timeout in seconds. The default is 30 seconds.

    .EXAMPLE
    $state = @{ title = 'Battery failure'; review = 'The battery stopped charging.' }
    $question = New-PerplexityYesNoQuestion -Name defect -Question 'Does this report a defect?'
    $result = Invoke-PerplexityDecision -State $state -Question $question
    $result.answers.defect.noul

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .NOTES
    This command makes a live API request. Tests should mock Invoke-RestMethod.
    #>
    [CmdletBinding(DefaultParameterSetName = 'QuestionMap')]
    param (
        # Accept a JSON object as a PowerShell hashtable for the state.
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [hashtable] $State,

        # Accept a map already arranged with the exact Perplexity question fields.
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'QuestionMap')]
        [ValidateNotNull()]
        [System.Collections.IDictionary] $Questions,

        # Accept one or more questions returned by the PowerShell helper functions.
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'QuestionObjects')]
        [ValidateNotNullOrEmpty()]
        [object[]] $Question,

        # Bound the HTTP timeout to a practical range and default to 30 seconds.
        [Parameter()]
        [ValidateRange(1, 600)]
        [int] $TimeoutSec = 30
    )

    # Require the documented API key without ever including its value in an error.
    if ([string]::IsNullOrWhiteSpace($env:PERPLEXITY_API_KEY)) {
        throw [System.InvalidOperationException]::new('PERPLEXITY_API_KEY is not set. Set it in the environment before calling this command.')
    }

    # Convert helper-created question objects to the named map expected by the API.
    if ($PSCmdlet.ParameterSetName -eq 'QuestionObjects') {
        $Questions = ConvertTo-PerplexityDecisionQuestionMap -Question $Question
    }

    # Validate all question definitions before creating or sending a request.
    Assert-PerplexityDecisionQuestions -Questions $Questions

    # Build the API payload from only the documented request fields.
    $payload = @{
        model     = 'pplx-decider-v1-27b'
        state     = $State
        questions = $Questions
    }

    # Convert the request to compact JSON while preserving nested objects.
    $requestBody = ConvertTo-Json -InputObject $payload -Depth 100 -Compress

    # Construct the documented bearer header without displaying or logging the key.
    $headers = @{ Authorization = "Bearer $env:PERPLEXITY_API_KEY" }

    # Send the request and return the parsed response from Invoke-RestMethod.
    try {
        return Invoke-RestMethod `
            -Uri 'https://api.perplexity.ai/v1/decisions' `
            -Method Post `
            -Headers $headers `
            -ContentType 'application/json' `
            -Body $requestBody `
            -TimeoutSec $TimeoutSec `
            -ErrorAction Stop
    }
    catch {
        # Convert HTTP and transport failures into a concise error that excludes request credentials.
        $httpError = New-PerplexityDecisionHttpErrorRecord -ErrorRecord $_
        throw $httpError
    }
}
