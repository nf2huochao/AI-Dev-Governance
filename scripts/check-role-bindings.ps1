[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RoleMapPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')

$roleMap = Read-RoleMap -Path $RoleMapPath
if ([string]::IsNullOrWhiteSpace($roleMap.ProjectId) -or $roleMap.ProjectId -match '^\{\{') {
    throw 'PROJECT_ID_MISSING: role registry must contain a concrete PROJECT_ID'
}
$projectId = $roleMap.ProjectId
if ($roleMap.BootstrapState -notin @('ACTIVE', 'COMPLETE')) { throw 'BOOTSTRAP_STATE_INVALID: expected ACTIVE or COMPLETE without changing the Core Architect role' }
$bootstrapState = $roleMap.BootstrapState
$outerTaskId = $roleMap.OuterTaskId
$rows = @($roleMap.Rows)
if ($rows.Count -eq 0) { throw 'ROLE_TABLE_MISSING: role registry has no lifecycle-aware role binding rows' }

foreach ($requiredRole in @('CORE_ARCHITECT', 'MISSION_PLANNER', 'BUILD_EXECUTOR')) {
    $matches = @($rows | Where-Object RoleId -eq $requiredRole)
    if ($matches.Count -eq 0) { throw "ROLE_BINDING_MISSING: $requiredRole" }
    if ($matches.Count -gt 1) { throw "ROLE_BINDING_CONFLICT: $requiredRole appears more than once" }
}
if (@($rows | Where-Object RoleId -eq 'EXTERNAL_ADVISOR').Count -gt 1) { throw 'ROLE_BINDING_CONFLICT: EXTERNAL_ADVISOR appears more than once' }

$core = @($rows | Where-Object RoleId -eq 'CORE_ARCHITECT')[0]
if ($core.BindingMode -ne 'CURRENT_CONTEXT' -or $core.CreationMode -ne 'REUSE_CURRENT') {
    throw 'CORE_ARCHITECT_LIFECYCLE_INVALID: BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT requires CURRENT_CONTEXT / REUSE_CURRENT'
}
if ($core.ThreadId -in @('CURRENT_THREAD_ID_UNAVAILABLE', 'UNAVAILABLE') -or $core.BindingStatus -eq 'BINDING_BLOCKED') {
    throw 'CURRENT_THREAD_ID_UNAVAILABLE: CAPABILITY GAP; keep the original context as Core Architect and do not create a replacement'
}

foreach ($entry in @($rows | Where-Object RoleId -in @('MISSION_PLANNER', 'BUILD_EXECUTOR'))) {
    if ($entry.BindingMode -ne 'CREATED_THREAD' -or $entry.CreationMode -ne 'ENSURE') {
        throw "ROLE_LIFECYCLE_INVALID: $($entry.RoleId) requires CREATED_THREAD / ENSURE"
    }
}

$threadIds = @()
$targetHandles = @()
foreach ($entry in $rows) {
    # The Advisor is a ChatGPT conversation, not a Codex message destination.
    if ($entry.RoleId -eq 'EXTERNAL_ADVISOR') { continue }
    foreach ($field in @('DisplayName', 'ThreadId', 'TargetHandle')) {
        if ([string]::IsNullOrWhiteSpace($entry.$field)) { throw "ROLE_BINDING_INCOMPLETE: $($entry.RoleId) requires DISPLAY_NAME, THREAD_ID and COMMUNICATION_TARGET_HANDLE" }
    }
    if (-not (Test-ConcreteRoleIdentity $entry.ThreadId)) {
        throw "ROLE_BINDING_INCOMPLETE: $($entry.RoleId) has no bound THREAD_ID"
    }
    if (-not (Test-ConcreteRoleIdentity $entry.TargetHandle)) {
        throw "ROLE_BINDING_INCOMPLETE: $($entry.RoleId) has no bound COMMUNICATION_TARGET_HANDLE"
    }
    if ($entry.ThreadId -eq $entry.DisplayName -or $entry.TargetHandle -eq $entry.DisplayName) {
        throw "THREAD_OR_TARGET_INVALID: $($entry.RoleId) uses DISPLAY_NAME as an identity or communication target"
    }
    if ($entry.BindingStatus -ne 'BOUND') { throw "ROLE_BINDING_UNBOUND: $($entry.RoleId) status is $($entry.BindingStatus)" }
    if ($threadIds -contains $entry.ThreadId) { throw "ROLE_BINDING_CONFLICT: THREAD_ID is reused: $($entry.ThreadId)" }
    if ($targetHandles -contains $entry.TargetHandle) { throw "ROLE_BINDING_CONFLICT: COMMUNICATION_TARGET_HANDLE is reused: $($entry.TargetHandle)" }
    $threadIds += $entry.ThreadId
    $targetHandles += $entry.TargetHandle
    if (-not [string]::IsNullOrWhiteSpace($outerTaskId) -and ($entry.ThreadId -eq $outerTaskId -or $entry.TargetHandle -eq $outerTaskId)) {
        throw "OUTER_TASK_ID_NOT_A_ROUTING_TARGET: $($entry.RoleId) uses OUTER_TASK_ID as THREAD_ID or communication target"
    }
}

Write-Output "ROLE_BINDINGS_STRUCTURALLY_VALID: PROJECT_ID=$projectId; BOOTSTRAP_STATE=$bootstrapState; CORE_ARCHITECT_SOURCE=CURRENT_CONTEXT; created_roles=2; platform_evidence_required_before_mission=true"
