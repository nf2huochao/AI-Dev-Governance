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
    'ROLE-MAP.md',
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

. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$registry = Read-RoleMap (Join-Path $governanceRoot 'ROLE-MAP.md')
if (-not $registry.ProjectPath -or [IO.Path]::GetFullPath($registry.ProjectPath).TrimEnd('\','/') -ne $project.TrimEnd('\','/')) {
    throw 'WORKSPACE_IDENTITY_CONFLICT: role registry does not belong to this workspace'
}
foreach ($role in @('CORE_ARCHITECT','MISSION_PLANNER','BUILD_EXECUTOR','EXTERNAL_ADVISOR')) {
    if (@($registry.Rows | Where-Object RoleId -eq $role).Count -ne 1) { throw "ROLE_BINDING_MISSING: $role" }
}

$eventsPath = Join-Path $governanceRoot 'RELAY_EVENTS.jsonl'
$lineNumber = 0
foreach ($line in (Get-Content -LiteralPath $eventsPath)) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try { $null = $line | ConvertFrom-Json } catch { throw "Invalid JSON on RELAY_EVENTS.jsonl line $lineNumber" }
}

Write-Output "Governance validation: PASS ($project)"
