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
$questions = @(
    New-PerplexityYesNoQuestion -Name defect `
        -Question 'Does the review report a product defect?'
    New-PerplexityDecisionQuestion -Name sentiment -Type Choice `
        -Instructions 'What is the overall sentiment of the review?' `
        -Criteria @{
            positive = 'Mostly satisfied'
            mixed    = 'Praise and complaints in one review'
            negative = 'Mostly dissatisfied'
        }
    New-PerplexityDecisionQuestion -Name severity -Type Score `
        -Instructions 'How severe is the reported problem?' `
        -Criteria @('Cosmetic', 'Inconvenient', 'Product unusable')
)

# Submit the state and questions; the command reads the key from the environment.
$response = Invoke-PerplexityDecision -State $state -Question $questions

# Inspect the probabilities and typed answers returned for each named question.
$response.answers.defect.noul
$response.answers.sentiment.choice
$response.answers.severity.score
```

Use the `TimeoutSec` parameter to change the 30-second default. The command validates documented question types and criteria limits before sending the request. API keys are read from `PERPLEXITY_API_KEY` and are not included in command output.

`New-PerplexityDecisionQuestion` creates a named `Noul`, `Choice`, or `Score` question. `New-PerplexityYesNoQuestion` is a convenience wrapper for a `Noul` question; its `-Question` text becomes the API's `instructions` value. Pass one or more helper results to `Invoke-PerplexityDecision -Question`; the command uses each helper's `-Name` as a key in the API's named `questions` map. The helpers return PowerShell objects and do not change Perplexity's request or response contract.

For `Choice`, provide `-Criteria` as a hashtable that maps option names to descriptions. For `Score`, provide `-Criteria` as an ordered array of rubric levels. `Noul` uses instructions alone and does not accept criteria. If you already have questions in the API shape, pass the map directly with `-Questions` instead of using the helpers.

`Invoke-PerplexityDecision` sends the documented `model`, `state`, and `questions` fields, reads its bearer token from `PERPLEXITY_API_KEY`, and returns the parsed API response. `-TimeoutSec` defaults to 30 seconds and accepts values from 1 through 600. Request validation errors and HTTP or transport failures are terminating errors; when available, an HTTP failure includes the status and response details without including request credentials.

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

The module manifest is `PSAIPerplexityDecisions.psd1`; its public commands and private helpers are loaded from `Public` and `Private`. Offline Pester tests mock `Invoke-RestMethod`; run them with `Invoke-Pester ./Tests`. See [CHANGELOG.md](CHANGELOG.md) for project changes.

### Examples

The scripts in `Examples` adapt the use cases in [dfinke/Jev's examples folder](https://github.com/dfinke/Jev/tree/main/Examples) to this module and the Perplexity request contract. They make live API requests when run, so set `PERPLEXITY_API_KEY` only when you intend to use the API. `DealDesk.ps1` and `Excel-IT-Queue.ps1` also require ImportExcel and input workbooks.

Included examples are `QuickStart`, `RefundTriage`, `SecurityIncidentTriage`, `SemanticLogTriage`, `PageOnCall`, `NotesToActions`, `PowerShellCommandFinder`, `ReleaseNotes`, `StandupReport`, `Excel-IT-Queue`, and `DealDesk`.

### Manual installation and publishing

Run `InstallModule.ps1` to copy the module runtime into the first suitable path in `PSModulePath`, or specify a destination with `-FullPath`. It copies the manifest, module loader, and function folders without mirroring or deleting destination contents.

To check packaging without publishing, set `NuGetApiKey` in your environment and run `./PublishToGallery.ps1 -WhatIf`. To publish manually to a registered repository, run `./PublishToGallery.ps1 -Repository PSGallery` and confirm the prompt. The script validates the module manifest and does not display the key.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

API reference: [Perplexity Decisions API quickstart](https://docs.perplexity.ai/docs/decisions/quickstart)
