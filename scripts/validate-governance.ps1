[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$governanceRoot = Join-Path $project '.ai-governance'
if (-not (Test-Path -LiteralPath $governanceRoot)) { throw "Missing governance directory: $governanceRoot" }

$required = @(
    'CHARTER.md',
    'CURRENT_PHASE.md',
    'CURRENT_MISSION.md',
    'RELAY_STATE.md',
    'RELAY_EVENTS.jsonl',
    'DECISIONS.md',
    'ARCHITECTURE-NO-GO.md',
    'START-HERE.md',
    'roles/external-advisor.md',
    'roles/core-architect.md',
    'roles/mission-planner.md',
    'roles/build-executor.md'
)

foreach ($relative in $required) {
    $path = Join-Path $governanceRoot $relative
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing governance file: $relative" }
    if ($relative -ne 'RELAY_EVENTS.jsonl' -and [string]::IsNullOrWhiteSpace((Get-Content -Raw -LiteralPath $path))) { throw "Empty governance file: $relative" }
}

$eventsPath = Join-Path $governanceRoot 'RELAY_EVENTS.jsonl'
$lineNumber = 0
foreach ($line in (Get-Content -LiteralPath $eventsPath)) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try { $null = $line | ConvertFrom-Json } catch { throw "Invalid JSON on RELAY_EVENTS.jsonl line $lineNumber" }
}

Write-Output "Governance validation: PASS ($project)"
