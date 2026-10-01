# PSAIPerplexityDecisions

<p align="center">
  <img src="assets/perplexity-decisions.png" alt="Perplexity Decisions API illustration" width="180">
</p>

A PowerShell module project for Perplexity's Decisions API.

The API accepts a `state` value and named questions, then returns structured probabilities instead of generated text. Question types are `noul` (yes/no), `choice` (select from your options), and `score` (estimate a level on an ordered rubric).

## Quickstart

Set `PERPLEXITY_API_KEY` in your environment, then import the module and call `Invoke-PerplexityDecision`. The module sends a JSON request to `POST https://api.perplexity.ai/v1/decisions` using the `pplx-decider-v1-27b` model.

```powershell
# Import the module manifest from this repository.
Import-Module ./PSAIPerplexityDecisions.psd1

# Define the state and three named questions for one Decisions API request.
$state = @{
    title  = 'Battery died after two weeks'
    review = 'The headphones sound great, but the battery stopped charging after two weeks.'
}
$questions = @{
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

# Submit the state and questions; the command reads the key from the environment.
$response = Invoke-PerplexityDecision -State $state -Questions $questions

# Inspect the probabilities and typed answers returned for each named question.
$response.answers.defect.noul
$response.answers.sentiment.choice
$response.answers.severity.score
```

Use the `TimeoutSec` parameter to change the 30-second default. The command validates documented question types and criteria limits before sending the request. API keys are read from `PERPLEXITY_API_KEY` and are not included in command output.

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

## Development

The module manifest is `PSAIPerplexityDecisions.psd1`; its public commands and private helpers are loaded from `Public` and `Private`. Offline Pester tests mock `Invoke-RestMethod`; run them with `Invoke-Pester ./Tests`.

### Examples

The scripts in `Examples` adapt the use cases in [dfinke/Jev's examples folder](https://github.com/dfinke/Jev/tree/main/Examples) to this module and the Perplexity request contract. They make live API requests when run, so set `PERPLEXITY_API_KEY` only when you intend to use the API. `DealDesk.ps1` and `Excel-IT-Queue.ps1` also require ImportExcel and input workbooks.

Included examples are `QuickStart`, `RefundTriage`, `SecurityIncidentTriage`, `SemanticLogTriage`, `PageOnCall`, `NotesToActions`, `PowerShellCommandFinder`, `ReleaseNotes`, `StandupReport`, `Excel-IT-Queue`, and `DealDesk`.

### Manual installation and publishing

Run `InstallModule.ps1` to copy the module runtime into the first suitable path in `PSModulePath`, or specify a destination with `-FullPath`. It copies the manifest, module loader, and function folders without mirroring or deleting destination contents.

To check packaging without publishing, set `NuGetApiKey` in your environment and run `./PublishToGallery.ps1 -WhatIf`. To publish manually to a registered repository, run `./PublishToGallery.ps1 -Repository PSGallery` and confirm the prompt. The script validates the module manifest and does not display the key.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

API reference: [Perplexity Decisions API quickstart](https://docs.perplexity.ai/docs/decisions/quickstart)
