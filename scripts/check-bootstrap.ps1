[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EventsPath,

    [Parameter(Mandatory = $true)]
    [string]$RoleMapPath,

    [Parameter(Mandatory = $true)]
    [string]$ExecutionId,

    [ValidateSet('Initial', 'Recovery')]
    [string]$Mode = 'Initial'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')

if (-not (Test-Path -LiteralPath $EventsPath)) {
    throw "RELAY_EVENTS_NOT_FOUND: $EventsPath"
}
if ([string]::IsNullOrWhiteSpace($ExecutionId) -or $ExecutionId -match '(?i)^(NOT_ASSIGNED|UNKNOWN|UNVERIFIED)') {
    throw 'BOOTSTRAP_EXECUTION_ID_REQUIRED: select the real bootstrap execution; historical events are never overwritten'
}

$bindingOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-role-bindings.ps1') -RoleMapPath $RoleMapPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $bindingOutput -notmatch 'ROLE_BINDINGS_STRUCTURALLY_VALID') {
    throw "ROLE_BINDINGS_REQUIRED: $($bindingOutput.Trim())"
}

$roleMap = Read-RoleMap -Path $RoleMapPath
$projectId = $roleMap.ProjectId
$roleTargets = @{}
foreach ($row in $roleMap.Rows) {
    $roleTargets[$row.RoleId] = $row
}

$allEvents = New-Object System.Collections.Generic.List[object]
$lineNumber = 0
foreach ($line in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $EventsPath), [Text.Encoding]::UTF8)) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try { $allEvents.Add(($line | ConvertFrom-Json)) } catch { throw "INVALID_RELAY_EVENT_JSON: line $lineNumber" }
}

$executionEvents = @($allEvents | Where-Object { [string]$_.execution_id -eq $ExecutionId })
if ($executionEvents.Count -eq 0) { throw "BOOTSTRAP_EXECUTION_NOT_FOUND: no events for EXECUTION_ID=$ExecutionId" }
$handshakeNames = if ($Mode -eq 'Initial') { @('BOOTSTRAP_HELLO', 'BOOTSTRAP_ACK') } else { @('RECOVERY_HELLO', 'RECOVERY_ACK') }
$allowedEvents = @('ROLE_THREAD_CREATED') + $handshakeNames
$unknownEvents = @($executionEvents | Where-Object { [string]$_.event -notin $allowedEvents })
if ($unknownEvents.Count -gt 0) { throw "BOOTSTRAP_SCOPE_INVALID: unexpected event $($unknownEvents[0].event) before Bootstrap completion" }

$creationEvents = @($executionEvents | Where-Object event -eq 'ROLE_THREAD_CREATED')
if (@($creationEvents | Where-Object role_id -eq 'CORE_ARCHITECT').Count -gt 0) {
    throw 'UNEXPECTED_CORE_ARCHITECT_CREATION: CORE_ARCHITECT_CREATION_FORBIDDEN; CURRENT_CONTEXT_MUST_BE_REUSED'
}
if ($Mode -eq 'Initial' -and $creationEvents.Count -ne 2) { throw "BOOTSTRAP_CREATED_THREAD_COUNT_INVALID: EXPECTED_NEW_CODEX_THREADS=2; got $($creationEvents.Count)" }
if ($Mode -eq 'Recovery' -and $creationEvents.Count -gt 1) { throw "RECOVERY_CREATED_THREAD_COUNT_INVALID: recovery may create only one genuinely missing role; got $($creationEvents.Count)" }
$rolesToValidate = if ($Mode -eq 'Initial') { @('MISSION_PLANNER', 'BUILD_EXECUTOR') } else { @($creationEvents | ForEach-Object role_id) }
foreach ($roleId in $rolesToValidate) {
    $matches = @($creationEvents | Where-Object role_id -eq $roleId)
    if ($matches.Count -ne 1) { throw "ROLE_DUPLICATION_OR_UNKNOWN_THREAD: $roleId creation count is $($matches.Count)" }
    $created = $matches[0]
    foreach ($property in @('event', 'project_id', 'execution_id', 'role_id', 'thread_id', 'binding_mode', 'creation_mode', 'evidence')) {
        if (-not ($created.PSObject.Properties.Name -contains $property) -or [string]::IsNullOrWhiteSpace([string]$created.$property)) {
            throw "ROLE_CREATION_EVENT_INCOMPLETE: $roleId missing $property"
        }
    }
    if ($created.project_id -ne $projectId -or $created.binding_mode -ne 'CREATED_THREAD' -or $created.creation_mode -ne 'ENSURE') {
        throw "ROLE_CREATION_EVENT_INVALID: $roleId"
    }
    if (-not $roleTargets.ContainsKey($roleId) -or $roleTargets[$roleId].ThreadId -ne $created.thread_id) {
        throw "CREATED_THREAD_NOT_REGISTERED: $roleId"
    }
}

$events = @($executionEvents | Where-Object { [string]$_.event -in $handshakeNames })
if ($events.Count -ne 4) { throw "BOOTSTRAP_EVENT_COUNT_INVALID: expected 4 HELLO/ACK events for EXECUTION_ID=$ExecutionId, got $($events.Count); historical events were preserved" }

$expected = @(
    @{ Event = $handshakeNames[0]; Role = 'CORE_ARCHITECT'; TargetRole = 'MISSION_PLANNER'; Status = 'SENT' },
    @{ Event = $handshakeNames[1]; Role = 'MISSION_PLANNER'; TargetRole = 'CORE_ARCHITECT'; Status = 'RECEIVED_AND_REPLIED' },
    @{ Event = $handshakeNames[0]; Role = 'MISSION_PLANNER'; TargetRole = 'BUILD_EXECUTOR'; Status = 'SENT' },
    @{ Event = $handshakeNames[1]; Role = 'BUILD_EXECUTOR'; TargetRole = 'MISSION_PLANNER'; Status = 'RECEIVED_AND_REPLIED' }
)

for ($i = 0; $i -lt $expected.Count; $i++) {
    $event = $events[$i]
    $rule = $expected[$i]
    foreach ($property in @('event', 'project_id', 'execution_id', 'role_id', 'thread_id', 'target_role_id', 'target_thread_id', 'target_handle', 'status', 'evidence')) {
        if (-not ($event.PSObject.Properties.Name -contains $property) -or [string]::IsNullOrWhiteSpace([string]$event.$property)) {
            throw "BOOTSTRAP_EVENT_INCOMPLETE: event $($i + 1) missing $property"
        }
    }
    if ($event.event -ne $rule.Event -or $event.role_id -ne $rule.Role -or $event.target_role_id -ne $rule.TargetRole -or $event.status -ne $rule.Status) {
        throw "BOOTSTRAP_SEQUENCE_INVALID: event $($i + 1) does not match the required HELLO/ACK sequence"
    }
    if ($event.project_id -ne $projectId -or $event.execution_id -ne $ExecutionId) { throw "PROJECT_OR_EXECUTION_ID_MISMATCH: event $($i + 1)" }
    if ([string]$event.evidence -match '(?i)REPLACE_WITH|SIMULATED|FAKE|TEMPLATE') {
        throw "PLATFORM_EVIDENCE_PLACEHOLDER: event $($i + 1)"
    }
    if (-not $roleTargets.ContainsKey([string]$event.role_id) -or $roleTargets[$event.role_id].ThreadId -ne $event.thread_id) {
        throw "THREAD_ID_NOT_REGISTERED: sender $($event.role_id)"
    }
    if (-not $roleTargets.ContainsKey([string]$event.target_role_id)) {
        throw "THREAD_TARGET_NOT_REGISTERED: $($event.target_role_id)"
    }
    if ($roleTargets[$event.target_role_id].ThreadId -ne $event.target_thread_id) {
        throw "THREAD_TARGET_NOT_REGISTERED: $($event.target_thread_id)"
    }
    if ($roleTargets[$event.target_role_id].TargetHandle -ne $event.target_handle) {
        throw "COMMUNICATION_TARGET_NOT_REGISTERED: $($event.target_handle)"
    }
}

Write-Output "BOOTSTRAP_COMMUNICATION_STRUCTURALLY_VALID: EXECUTION_ID=$ExecutionId; identity, order, evidence references and registered communication targets are structurally consistent"
Write-Output "BOOTSTRAP_TEAM_STRUCTURALLY_VALID: MODE=$Mode; CORE_ARCHITECT_SOURCE=CURRENT_ORIGINAL_CONVERSATION; actual_new_threads=$($creationEvents.Count)"
Write-Output 'PLATFORM_DELIVERY_AND_WAKE: optional native message IDs are preserved when present; execution references, target threads and raw records require independent platform review'
