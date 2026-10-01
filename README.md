# PSAIPerplexityDecisions

A PowerShell module project for Perplexity's Decisions API.

The API accepts a `state` value and named questions, then returns structured probabilities instead of generated text. Question types are `noul` (yes/no), `choice` (select from your options), and `score` (estimate a level on an ordered rubric).

## Quickstart

Set `PERPLEXITY_API_KEY` in your environment. Any Perplexity API key works. Then send a JSON request to `POST https://api.perplexity.ai/v1/decisions` using the `pplx-decider-v1-27b` model.

```powershell
# Define a state and three named questions for the Decisions API.
$body = @{
    model = 'pplx-decider-v1-27b'
    state = @{
        title  = 'Battery died after two weeks'
        review = 'The headphones sound great, but the battery stopped charging after two weeks.'
    }
    questions = @{
        defect = @{
            type         = 'noul'
            instructions = 'Does the review report a product defect?'
        }
        sentiment = @{
            type         = 'choice'
            instructions = 'What is the overall sentiment of the review?'
            criteria     = @{
                positive = 'Mostly satisfied'
                mixed    = 'Praise and complaints in one review'
                negative = 'Mostly dissatisfied'
            }
        }
        severity = @{
            type         = 'score'
            instructions = 'How severe is the reported problem?'
            criteria     = @('Cosmetic', 'Inconvenient', 'Product unusable')
        }
    }
} | ConvertTo-Json -Depth 10

# Send the request with the API key in a Bearer authorization header.
$response = Invoke-RestMethod `
    -Uri 'https://api.perplexity.ai/v1/decisions' `
    -Method Post `
    -Headers @{ Authorization = "Bearer $env:PERPLEXITY_API_KEY" } `
    -ContentType 'application/json' `
    -Body $body `
    -TimeoutSec 30

# Inspect the probability and selected answers returned for each question.
$response.answers.defect.noul
$response.answers.sentiment.choice
$response.answers.severity.score
```

## Response shape

- `noul` returns the probability of yes, from 0 to 1.
- `choice` returns the highest-probability option, the full `probabilities` map, and `confidence`.
- `score` returns the probability-weighted rubric score, the rubric `legend`, the full `probabilities` map, and `confidence`.

## Useful limits and pricing

- Up to 128 named questions per request.
- Up to 255 options in a `choice` question and up to 10 levels in a `score` rubric.
- 10 requests per second per organization.
- $0.04 per million input tokens; output tokens are free.

**Tidbit:** One request can ask many different questions about the same state. That makes the Decisions API a natural fit for enriching a PowerShell object in one pass: classify it, choose a route, and score it together.

## Project status

This repository is being set up as a focused PowerShell interface to Perplexity's Decisions API. The quickstart above uses the documented HTTP contract directly; module commands and packaging will be added as the module takes shape.

API reference: [Perplexity Decisions API quickstart](https://docs.perplexity.ai/docs/decisions/quickstart)
