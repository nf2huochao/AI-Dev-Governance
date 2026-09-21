[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExpectedProjectPath,

    [Parameter(Mandatory = $false)]
    [string]$ObservedProjectPath = ''
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ExpectedProjectPath)) {
    throw "EXPECTED_PROJECT_NOT_FOUND: $ExpectedProjectPath"
}

if ([string]::IsNullOrWhiteSpace($ObservedProjectPath)) {
    throw 'MCP_CAPABILITY_GAP: no observed Codex/MCP project path was provided; connection and target are not verified.'
}

if (-not (Test-Path -LiteralPath $ObservedProjectPath)) {
    throw "OBSERVED_PROJECT_NOT_FOUND: $ObservedProjectPath"
}

$expected = (Get-Item -LiteralPath $ExpectedProjectPath).FullName.TrimEnd('\')
$observed = (Get-Item -LiteralPath $ObservedProjectPath).FullName.TrimEnd('\')

if (-not [string]::Equals($expected, $observed, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "MCP_TARGET_MISMATCH: expected '$expected' but observed '$observed'"
}

Write-Output 'MCP_TARGET_MATCH: PASS'
Write-Output "Observed project path: $observed"
Write-Output 'This confirms only the observed target path; it does not prove a message channel or independent audit until a real platform operation succeeds.'
