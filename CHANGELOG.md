# Changelog

Notable changes to PSAIPerplexityDecisions are recorded here.

## [0.1.0] - 2026-10-01

### Added

- Added `New-PerplexityDecisionQuestion` to create named `Noul`, `Choice`, and `Score` question objects with type-specific criteria validation.
- Added `New-PerplexityYesNoQuestion` as a concise constructor for `Noul` questions.
- Added `Invoke-PerplexityDecision -Question` to convert helper objects into Perplexity's named `questions` map. The existing `-Questions` parameter remains available for API-shaped maps.

### Updated

- Updated every example and the README quickstart to use the question helpers while preserving the Perplexity request and response contract.
- Documented the helpers, direct-map invocation, timeout range, validation, and HTTP error behavior in the README.
- Added links to related PowerShell decision modules for other providers.
- Added offline Pester coverage for helper serialization and validation.
