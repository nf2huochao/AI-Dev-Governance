[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CORE_ARCHITECT', 'MISSION_PLANNER', 'BUILD_EXECUTOR', 'EXTERNAL_ADVISOR')]
    [string]$RoleId,

    [string]$RoleMapPath = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')

if ($RoleId -eq 'CORE_ARCHITECT') {
    throw 'CORE_ARCHITECT_CREATION_FORBIDDEN: CURRENT_CONTEXT_MUST_BE_REUSED'
}
if ($RoleId -notin @('MISSION_PLANNER', 'BUILD_EXECUTOR')) {
    throw "ROLE_CREATION_FORBIDDEN: $RoleId is not a Codex create_thread role"
}

if ([string]::IsNullOrWhiteSpace($RoleMapPath)) {
    throw 'ROLE_MAP_REQUIRED: creation decisions must use the canonical role registry'
}
$roleMap = Read-RoleMap -Path $RoleMapPath
$matches = @($roleMap.Rows | Where-Object RoleId -eq $RoleId)
if ($matches.Count -ne 1) { throw "ROLE_BINDING_CONFLICT: $RoleId must appear exactly once; found $($matches.Count)" }
$entry = $matches[0]
if ($entry.BindingMode -ne 'CREATED_THREAD' -or $entry.CreationMode -ne 'ENSURE') {
    throw "ROLE_BINDING_CONFLICT: $RoleId has an invalid lifecycle"
}
if ($entry.BindingStatus -eq 'BOUND') {
    if (-not (Test-ConcreteRoleIdentity $entry.ThreadId) -or -not (Test-ConcreteRoleIdentity $entry.TargetHandle) -or $entry.ThreadId -eq $entry.DisplayName -or $entry.TargetHandle -eq $entry.DisplayName) {
        throw "ROLE_BINDING_CONFLICT: $RoleId has an invalid bound identity"
    }
    foreach ($other in @($roleMap.Rows | Where-Object { $_.RoleId -ne $RoleId -and $_.BindingStatus -eq 'BOUND' })) {
        if ($entry.ThreadId -eq $other.ThreadId -or $entry.TargetHandle -eq $other.TargetHandle) { throw 'ROLE_BINDING_CONFLICT: role identity or target reused' }
    }
    Write-Output "ROLE_ALREADY_BOUND: ROLE_ID=$RoleId; ACTION=REUSE_EXISTING_THREAD; THREAD_ID=$($entry.ThreadId)"
    return
}
if ($entry.BindingStatus -ne 'PENDING_CREATION' -or $entry.ThreadId -ne 'NOT_CREATED' -or $entry.TargetHandle -notin @('NOT_CREATED', 'PENDING_CREATION')) {
    throw "ROLE_CREATION_BLOCKED: $RoleId is not in the explicit PENDING_CREATION state"
}

Write-Output "ROLE_CREATION_ALLOWED: ROLE_ID=$RoleId; BINDING_MODE=CREATED_THREAD; CREATION_MODE=ENSURE"
