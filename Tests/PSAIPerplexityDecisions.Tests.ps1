# Import the local module and mock its HTTP boundary so every test stays offline.
BeforeAll {
    # Resolve the manifest from this test file's repository location.
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'PSAIPerplexityDecisions.psd1'

    # Import the module under test into the Pester session.
    Import-Module $modulePath -Force

    # Provide a harmless placeholder key that must never be sent to a real service.
    $env:PERPLEXITY_API_KEY = 'test-key-never-used-for-network'

    # Define a reusable valid request fixture from the documented request schema.
    $testState = @{ item = 'Headphones'; review = 'The battery stopped charging.' }
    $testQuestions = @{
        defect = @{ type = 'noul'; instructions = 'Does this report a defect?' }
        sentiment = @{
            type = 'choice'
            instructions = 'What is the sentiment?'
            criteria = @{ positive = 'Mostly satisfied'; negative = 'Mostly dissatisfied' }
        }
        severity = @{
            type = 'score'
            instructions = 'How severe is the problem?'
            criteria = @('Minor', 'Major')
        }
    }
}

# Verify the command sends the documented request and returns the parsed answer object.
Describe 'Invoke-PerplexityDecision' {
    # Return a representative typed response without contacting the API.
    BeforeEach {
        Mock Invoke-RestMethod -ModuleName PSAIPerplexityDecisions {
            [pscustomobject] @{
                answers = [pscustomobject] @{
                    defect = [pscustomobject] @{ noul = 0.9 }
                }
            }
        }
    }

    # Confirm endpoint, model, request data, bearer header, and timeout.
    It 'posts the documented payload and returns the API response' {
        $result = Invoke-PerplexityDecision -State $testState -Questions $testQuestions -TimeoutSec 45

        $result.answers.defect.noul | Should -Be 0.9

        Should -Invoke Invoke-RestMethod -ModuleName PSAIPerplexityDecisions -Times 1 -ParameterFilter {
            $Uri -eq 'https://api.perplexity.ai/v1/decisions' -and
            $Method -eq 'Post' -and
            $Headers.Authorization -eq 'Bearer test-key-never-used-for-network' -and
            $ContentType -eq 'application/json' -and
            $TimeoutSec -eq 45 -and
            (($Body | ConvertFrom-Json).model -eq 'pplx-decider-v1-27b') -and
            (($Body | ConvertFrom-Json).questions.defect.type -eq 'noul')
        }
    }

    # Verify that PowerShell question helpers are converted to the same named wire map.
    It 'converts helper question objects to the documented API question fields' {
        $questions = @(
            New-PerplexityYesNoQuestion -Name urgent -Question 'Does this need attention today?'
            New-PerplexityDecisionQuestion -Name route -Type Choice `
                -Instructions 'Which team should handle this?' `
                -Criteria @{ support = 'Technical issue'; sales = 'Pricing or renewal issue' }
        )

        $null = Invoke-PerplexityDecision -State $testState -Question $questions

        Should -Invoke Invoke-RestMethod -ModuleName PSAIPerplexityDecisions -Times 1 -ParameterFilter {
            $payload = $Body | ConvertFrom-Json
            $payload.questions.urgent.type -eq 'noul' -and
            $payload.questions.urgent.instructions -eq 'Does this need attention today?' -and
            $null -eq $payload.questions.urgent.criteria -and
            $payload.questions.route.type -eq 'choice' -and
            $payload.questions.route.criteria.support -eq 'Technical issue'
        }
    }

    # Ensure the helper does not add Jev-only criteria to the Perplexity Noul contract.
    It 'rejects criteria on a Noul question' {
        {
            New-PerplexityDecisionQuestion -Name binary -Type Noul `
                -Instructions 'Is the issue urgent?' `
                -Criteria @{ true = 'Urgent'; false = 'Not urgent' }
        } | Should -Throw '*does not accept Criteria in the Perplexity contract*'
    }

    # Reject unsupported question types before the mocked HTTP command is reached.
    It 'rejects an unsupported question type without making an HTTP request' {
        $invalidQuestions = @{ invalid = @{ type = 'text'; instructions = 'Unsupported type.' } }

        { Invoke-PerplexityDecision -State $testState -Questions $invalidQuestions } |
            Should -Throw "*Question 'invalid' type must be noul, choice, or score.*"

        Should -Invoke Invoke-RestMethod -ModuleName PSAIPerplexityDecisions -Times 0
    }

    # Return a synthetic HTTP error and make sure its status reaches the caller.
    It 'includes the HTTP status in a useful terminating error' {
        Mock Invoke-RestMethod -ModuleName PSAIPerplexityDecisions {
            $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)
            $response.Content = [System.Net.Http.StringContent]::new('{"error":"invalid request"}')
            $exception = [System.Net.Http.HttpRequestException]::new('Bad request')
            $exception | Add-Member -MemberType NoteProperty -Name Response -Value $response -Force
            throw $exception
        }

        { Invoke-PerplexityDecision -State $testState -Questions $testQuestions } |
            Should -Throw '*HTTP 400*invalid request*'
    }

    # Ensure the missing-key path fails before any request is attempted.
    It 'requires the environment key before making an HTTP request' {
        $previousKey = $env:PERPLEXITY_API_KEY
        Remove-Item Env:PERPLEXITY_API_KEY -ErrorAction SilentlyContinue

        try {
            { Invoke-PerplexityDecision -State $testState -Questions $testQuestions } |
                Should -Throw '*PERPLEXITY_API_KEY is not set*'

            Should -Invoke Invoke-RestMethod -ModuleName PSAIPerplexityDecisions -Times 0
        }
        finally {
            $env:PERPLEXITY_API_KEY = $previousKey
        }
    }
}
