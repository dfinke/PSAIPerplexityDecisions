# Create a safe, concise PowerShell error from an HTTP or transport failure.
function New-PerplexityDecisionHttpErrorRecord {
    <#
    .SYNOPSIS
    Creates a useful error record for a failed Decisions API request.

    .DESCRIPTION
    Extracts the HTTP status and response content when available without
    including request headers, credentials, or the serialized request body.

    .PARAMETER ErrorRecord
    The original PowerShell error record caught from Invoke-RestMethod.
    #>
    [CmdletBinding()]
    param (
        # Receive the original HTTP or transport failure from the public command.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord
    )

    # Start with no status or response content until an HTTP response is found.
    $statusCode = $null
    $responseBody = $null
    $httpResponse = $ErrorRecord.Exception.Response

    # Read status and response content without exposing request headers or credentials.
    if ($null -ne $httpResponse) {
        # Capture a numeric HTTP status when the response exposes one.
        try {
            $statusCode = [int]$httpResponse.StatusCode
        }
        catch {
            $statusCode = $null
        }

        # Read response content from either Windows PowerShell or modern .NET responses.
        try {
            if ($httpResponse.PSObject.Methods.Name -contains 'GetResponseStream') {
                # Read the WebResponse stream used by Windows PowerShell HTTP exceptions.
                $reader = [System.IO.StreamReader]::new($httpResponse.GetResponseStream())
                try {
                    $responseBody = $reader.ReadToEnd()
                }
                finally {
                    # Dispose the reader and its response stream after reading the body.
                    $reader.Dispose()
                }
            }
            elseif ($null -ne $httpResponse.Content -and $httpResponse.Content -is [System.Net.Http.HttpContent]) {
                # Read HttpResponseMessage content used by modern PowerShell HTTP exceptions.
                $responseBody = $httpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            }
        }
        catch {
            # Keep the status code even if the response body cannot be read.
            $responseBody = $null
        }
    }

    # Prefer server-provided details and otherwise use a safe generic transport message.
    if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
        $detail = $responseBody.Trim()
    }
    elseif ($null -ne $statusCode) {
        $detail = "The API returned HTTP $statusCode."
    }
    else {
        $detail = 'The request could not be completed. Check network connectivity and try again.'
    }

    # Include an HTTP status when available and avoid echoing exception text that could contain sensitive data.
    if ($null -ne $statusCode) {
        $exception = [System.Net.Http.HttpRequestException]::new("Perplexity Decisions API request failed (HTTP $statusCode): $detail")
    }
    else {
        $exception = [System.Net.Http.HttpRequestException]::new("Perplexity Decisions API request failed: $detail")
    }

    # Preserve the original error as the inner exception for deeper diagnostics.
    $exception = [System.Net.Http.HttpRequestException]::new($exception.Message, $ErrorRecord.Exception)

    # Return an error record that callers can handle by identifier or category.
    return [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'PerplexityDecisionRequestFailed',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null
    )
}
