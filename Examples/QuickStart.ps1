# Require the modern PowerShell runtime used by these runnable examples.
#requires -Version 7.0

# Import the Perplexity-only module from this repository.
# Import-Module (Join-Path $PSScriptRoot '..' 'PSAIPerplexityDecisions.psd1') -Force

# Provide the context once and ask three differently typed questions in one request.
$state = @{
    message = 'The customer is blocked by an outage and may cancel.'
}
$questions = @{
    churn = @{
        type         = 'noul'
        instructions = 'Is this an active churn threat?'
    }
    route = @{
        type         = 'choice'
        instructions = 'Which team should handle this?'
        criteria     = @{
            support = 'The issue needs technical support.'
            sales   = 'The issue concerns pricing or renewal.'
        }
    }
    urgency = @{
        type         = 'score'
        instructions = 'How urgent is this?'
        criteria     = @('Can wait', 'This week', 'Today')
    }
}

# Send one live request; set PERPLEXITY_API_KEY before running this example.
$result = Invoke-PerplexityDecision -State $state -Questions $questions

# Keep the raw answer object available for callers and print a compact readable view.
$result
$summary = @(
    [pscustomobject]@{ Question = 'churn'; Type = 'noul'; Result = $result.answers.churn.noul }
    [pscustomobject]@{ Question = 'route'; Type = 'choice'; Result = $result.answers.route.choice; Confidence = $result.answers.route.confidence; Probabilities = $result.answers.route.probabilities }
    [pscustomobject]@{ Question = 'urgency'; Type = 'score'; Result = $result.answers.urgency.score; Confidence = $result.answers.urgency.confidence; Probabilities = $result.answers.urgency.probabilities }
)
$summary | Format-Table -AutoSize -Wrap
