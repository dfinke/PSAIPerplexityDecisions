# Require ImportExcel to read the sample workbook.
#requires -Modules ImportExcel

# Accept the workbook path instead of assuming an external sample file exists here.
[CmdletBinding()]
param(
    # Point to a workbook with the documented example columns and an IT Queue sheet.
    [Parameter(Mandatory = $true)]
    [string] $Path
)

# Import the Perplexity-only module from this repository.
Import-Module (Join-Path $PSScriptRoot '..' 'PSAIPerplexityDecisions.psd1') -Force

# Read the IT request rows from the supplied workbook.
$tickets = @(Import-Excel -Path $Path -WorksheetName 'IT Queue')

# Describe why IT should prioritize a request today.
$questions = @{
    investigateToday = @{
        type         = 'noul'
        instructions = 'Should IT investigate this request today because waiting could disrupt a time-sensitive business process?'
    }
}

# Evaluate each row as a separate state and retain the returned yes probability.
$results = foreach ($ticket in $tickets) {
    $state = @{}
    foreach ($property in $ticket.PSObject.Properties) {
        $state[$property.Name] = $property.Value
    }
    $answer = (Invoke-PerplexityDecision -State $state -Questions $questions).answers.investigateToday
    [pscustomobject]@{
        Ticket        = $ticket.Ticket
        Service       = $ticket.Service
        UsersAffected = $ticket.UsersAffected
        Deadline      = $ticket.Deadline
        Decision      = [double]$answer.noul
    }
}

# Sort by the probability of investigating today and display the queue summary.
$results | Sort-Object Decision -Descending | Format-Table Ticket, Service, UsersAffected, Deadline, Decision -AutoSize
