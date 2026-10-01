# Convert PowerShell-friendly question objects into the named API question map.
function ConvertTo-PerplexityDecisionQuestionMap {
    <#
    .SYNOPSIS
    Converts named question objects into the Perplexity request representation.

    .DESCRIPTION
    Uses each question's Name as its map key and serializes only the documented
    type, instructions, and optional criteria fields.

    .PARAMETER Question
    One or more question objects created by a public question helper.
    #>
    [CmdletBinding()]
    param (
        # Receive the helper-created question objects from the public command.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]] $Question
    )

    # Create an ordered map to preserve the user's question order when serializing.
    $questionMap = [ordered]@{}

    # Convert every named object to the Perplexity wire fields.
    foreach ($questionObject in $Question) {
        # Require question objects to expose all public helper properties.
        if ($null -eq $questionObject -or
            $null -eq $questionObject.PSObject.Properties['Name'] -or
            $null -eq $questionObject.PSObject.Properties['Type'] -or
            $null -eq $questionObject.PSObject.Properties['Instructions']) {
            throw [System.ArgumentException]::new('Each Question must include Name, Type, and Instructions properties.', 'Question')
        }

        # Convert the question name to a string and reject blank or duplicate names.
        $questionName = [string]$questionObject.Name
        if ([string]::IsNullOrWhiteSpace($questionName)) {
            throw [System.ArgumentException]::new('Each Question must have a non-empty Name.', 'Question')
        }
        if ($questionMap.Contains($questionName)) {
            throw [System.ArgumentException]::new("Question names must be unique. Duplicate name: '$questionName'.", 'Question')
        }

        # Build the lowercase type and instructions fields expected by the API.
        $wireQuestion = [ordered]@{
            type         = ([string]$questionObject.Type).ToLowerInvariant()
            instructions = $questionObject.Instructions
        }

        # Include criteria only when the question object provides a non-null value.
        if ($null -ne $questionObject.Criteria) {
            $wireQuestion['criteria'] = $questionObject.Criteria
        }

        # Store the question under its name without sending Name as a payload field.
        $questionMap[$questionName] = $wireQuestion
    }

    # Return the map for validation and API serialization.
    return $questionMap
}
