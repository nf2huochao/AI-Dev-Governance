[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$eventsPath = Join-Path (Join-Path $project '.ai-governance') 'RELAY_EVENTS.jsonl'
if (-not (Test-Path -LiteralPath $eventsPath)) { throw "Missing relay events: $eventsPath" }

$contractPath = Join-Path (Join-Path $PSScriptRoot '..\protocols') 'relay-contract.json'
$contract = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $contractPath), [Text.Encoding]::UTF8) | ConvertFrom-Json
$validTransitions = @{}; foreach ($p in $contract.transitions.PSObject.Properties) { $validTransitions[$p.Name] = @($p.Value) }
$actorRules = @{}; foreach ($p in $contract.actors.PSObject.Properties) { $actorRules[$p.Name] = @($p.Value) }
$controlEvents = @($contract.control_events)
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$mapPath = Join-Path $project '.ai-governance/ROLE-MAP.md'
$registry = $null
$mapText = ''
if (Test-Path -LiteralPath $mapPath -PathType Leaf) {
    $registry = Read-RoleMap $mapPath
    $mapText = [IO.File]::ReadAllText($mapPath, [Text.Encoding]::UTF8)
}
$lines = [IO.File]::ReadAllLines($eventsPath, [Text.Encoding]::UTF8)
# New projects/explicit Strict check all events. Legacy projects can upgrade at
# a task boundary without rewriting their earlier unverified history.
$strictMode = [bool]$Strict -or (Get-RoleMapField $mapText 'RELAY_SCHEMA_VERSION') -eq '2'
$roleIds = @{'mission-planner'='MISSION_PLANNER';'build-executor'='BUILD_EXECUTOR';'core-architect'='CORE_ARCHITECT';'external-advisor'='EXTERNAL_ADVISOR'}

function Require-Text([object]$Event, [string]$Property, [int]$Number) {
    if (-not ($Event.PSObject.Properties.Name -contains $Property) -or [string]::IsNullOrWhiteSpace([string]$Event.$Property)) {
        throw "Event $Number missing or empty $Property"
    }
}

function Check-Reference($Event, [string]$Property, [int]$Number, [switch]$TaskArtifact) {
    Require-Text $Event $Property $Number
    $ref = [string]$Event.$Property
    if ([IO.Path]::IsPathRooted($ref)) { throw "EVIDENCE_PATH_OUTSIDE_PROJECT: $Property" }
    $path = [IO.Path]::GetFullPath((Join-Path $project $ref))
    $prefix = $project.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "EVIDENCE_PATH_OUTSIDE_PROJECT: $Property" }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "RELAY_EVIDENCE_NOT_FOUND: $Property" }
    $item = Get-Item -LiteralPath $path
    while ($item.FullName -ne $project) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "RELAY_EVIDENCE_LINK_FORBIDDEN: $Property" }
        $item = Get-Item -LiteralPath (Split-Path -Parent $item.FullName)
    }
    if ((Get-Item -LiteralPath $path).Length -eq 0) { throw "RELAY_EVIDENCE_EMPTY: $Property" }
    if ($TaskArtifact) {
        $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
        foreach ($field in @('PROJECT_ID','TASK_ID')) {
            $value = Get-RoleMapField $text $field
            if ($value -ne [string]$Event.($field.ToLowerInvariant())) { throw "RELAY_ARTIFACT_CONTEXT_MISMATCH: $Property / $field" }
        }
    }
    # Existence and context establish a local link, never platform authenticity.
}

$previous = $null
$active = $null
$count = 0
$formalCount = 0
$controlCount = 0
$completedTasks = 0
$projectIdentity = $null
$closedTasks = @{}
$usedExecutions = @{}
$evidenceLinkedTasks = 0
$legacyFormalEvents = 0
$closedMissions = @{}

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $count++
    try {
        $event = $line | ConvertFrom-Json
        if ($null -eq $event -or $event -is [array] -or $event -isnot [pscustomobject]) { throw 'expected event object' }
    } catch { throw "Invalid JSON object at event $count" }
    Require-Text $event 'event' $count
    Require-Text $event 'project_id' $count
    if ($null -eq $projectIdentity) { $projectIdentity = [string]$event.project_id }
    if ($event.project_id -ne $projectIdentity) { throw "RELAY_CONTEXT_MISMATCH: project changed at event $count" }
    if ($registry -and $event.project_id -ne $registry.ProjectId) { throw "RELAY_PROJECT_MISMATCH: event $count differs from ROLE-MAP" }

    if ([string]$event.event -in $controlEvents) {
        foreach ($field in @('execution_id','role_id','thread_id','evidence')) { Require-Text $event $field $count }
        if ($event.event -eq 'MISSION_COMPLETE') {
            if ($previous -ne 'PASS' -or $event.role_id -ne 'MISSION_PLANNER' -or $event.mission_id -ne $active.MissionId -or $closedMissions.ContainsKey([string]$event.mission_id)) { throw 'MISSION_COMPLETION_INVALID: completion requires the current reviewed PASS and a unique Planner report' }
            if (-not $registry) { throw 'MISSION_COMPLETION_REQUIRES_ROLE_MAP' }
            $planner = @($registry.Rows | Where-Object RoleId -eq 'MISSION_PLANNER')[0]
            if ($planner.BindingStatus -ne 'BOUND' -or $event.thread_id -ne $planner.ThreadId) { throw 'RELAY_ROLE_THREAD_MISMATCH: mission completion' }
            Check-Reference $event 'evidence_ref' $count
            $closedMissions[[string]$event.mission_id] = $true
        }
        $controlCount++
        continue
    }

    $formalCount++
    if ($event.PSObject.Properties.Name -contains 'schema_version') {
        if ([string]$event.schema_version -ne '2') { throw 'UNSUPPORTED_RELAY_SCHEMA' }
        if (-not $strictMode -and $null -ne $previous -and $previous -notin @('PASS','ESCALATE')) { throw 'RELAY_SCHEMA_UPGRADE_REQUIRES_TASK_BOUNDARY' }
        $strictMode = $true
    }
    foreach ($property in @($contract.required_fields)) {
        Require-Text $event $property $count
    }

    $state = [string]$event.status
    if ($state -notin $validTransitions.Keys) { throw "Unknown relay state '$state' at event $count" }
    if ([string]$event.event -ne $state) { throw "EVENT_STATUS_MISMATCH: event=$($event.event), status=$state at event $count" }
    if ($actorRules[$state] -notcontains [string]$event.actor) { throw "Invalid actor '$($event.actor)' for state '$state' at event $count" }
    if ($state -eq 'DISPATCH' -and $closedMissions.ContainsKey([string]$event.mission_id)) { throw 'MISSION_ALREADY_COMPLETED: obtain a new approved Mission instead of manufacturing tasks' }
    if ($registry -and ($event.PSObject.Properties.Name -contains 'thread_id')) {
        $role = @($registry.Rows | Where-Object RoleId -eq $roleIds[[string]$event.actor])
        if ($role.Count -ne 1 -or $role[0].BindingStatus -ne 'BOUND' -or $event.thread_id -ne $role[0].ThreadId) { throw "RELAY_ROLE_THREAD_MISMATCH: event $count" }
    }
    if ($strictMode) {
        if (-not $registry) { throw 'ROLE_MAP_REQUIRED_FOR_STRICT_RELAY' }
        $null = & (Join-Path $PSScriptRoot 'check-role-bindings.ps1') -RoleMapPath $mapPath
        Require-Text $event 'thread_id' $count
        Require-Text $event 'schema_version' $count
        Check-Reference $event 'evidence_ref' $count
        if ($state -eq 'DISPATCH') { Check-Reference $event 'contract_ref' $count -TaskArtifact }
        if ($state -eq 'HANDOFF') { Check-Reference $event 'handoff_ref' $count -TaskArtifact }
        if ($state -in @('REVIEW','PASS','REWORK')) { Check-Reference $event 'review_ref' $count -TaskArtifact }
        if ($state -in @('DISPATCH','HANDOFF')) {
            $targetId = if ($state -eq 'DISPATCH') { 'BUILD_EXECUTOR' } else { 'MISSION_PLANNER' }
            $target = @($registry.Rows | Where-Object RoleId -eq $targetId)[0]
            Require-Text $event 'target_thread_id' $count; Require-Text $event 'target_handle' $count
            if ($event.target_thread_id -ne $target.ThreadId -or $event.target_handle -ne $target.TargetHandle) { throw "RELAY_TARGET_MISMATCH: event $count" }
        }
        if ($event.PSObject.Properties.Name -contains 'commit_id') {
            if ([string]$event.commit_id -notmatch '^[a-fA-F0-9]{40,64}$') { throw 'INVALID_RELAY_COMMIT' }
            $null = & git -C $project cat-file -e "$($event.commit_id)^{commit}" 2>&1
            if ($LASTEXITCODE -ne 0) { throw 'RELAY_COMMIT_NOT_FOUND' }
        }
    }
    if (-not $strictMode) { $legacyFormalEvents++ }
    if ($previous -eq 'DISPATCH' -and $state -eq 'BLOCKED') { Check-Reference $event 'error_ref' $count }

    if ($null -eq $previous) {
        if ($state -ne 'DISPATCH') { throw "FORMAL_RELAY_MUST_START_WITH_DISPATCH: got $state at event $count" }
    } elseif ($validTransitions[$previous] -notcontains $state) {
        throw "Invalid relay transition $previous -> $state at event $count"
    }

    $context = [pscustomobject]@{
        ProjectId = [string]$event.project_id
        MissionId = [string]$event.mission_id
        TaskId = [string]$event.task_id
        ExecutionId = [string]$event.execution_id
    }
    $startsNewTask = $state -eq 'DISPATCH' -and $previous -in @($null, 'PASS', 'ESCALATE')
    if ($startsNewTask) {
        if ($closedMissions.ContainsKey($context.MissionId)) { throw 'MISSION_ALREADY_COMPLETED: obtain a new approved Mission instead of manufacturing tasks' }
        if ($closedTasks.ContainsKey($context.TaskId)) { throw "TASK_ALREADY_COMPLETED: $($context.TaskId); a completed TASK must not be silently reopened" }
        if ($usedExecutions.ContainsKey($context.ExecutionId)) { throw "EXECUTION_ALREADY_USED: $($context.ExecutionId); retries and new tasks need a distinct execution" }
        if ($previous -eq 'ESCALATE') {
            Require-Text $event 'resolution_ref' $count
        }
        $usedExecutions[$context.ExecutionId] = $true
        $active = $context
    } else {
        foreach ($field in @('ProjectId', 'MissionId', 'TaskId', 'ExecutionId')) {
            if ($context.$field -ne $active.$field) {
                throw "RELAY_CONTEXT_MISMATCH: $field changed from '$($active.$field)' to '$($context.$field)' at event $count"
            }
        }
    }

    if ($state -eq 'PASS') {
        $completedTasks++; $closedTasks[$context.TaskId] = $true
        if ($strictMode) { $evidenceLinkedTasks++ }
    }
    $previous = $state
}

if ($count -eq 0) {
    Write-Output 'Relay validation: PASS (empty initial log; no formal relay or control event has occurred)'
    return
}
if ($formalCount -eq 0) {
    Write-Output "Relay validation: PASS (structure valid; $controlCount control events; formal relay not started)"
    return
}

$completion = if ($previous -eq 'PASS') { 'true' } else { 'false' }
$waiting = if ($previous -eq 'DISPATCH') { '; runtime_state=WAITING_ACK' } else { '' }
$evidenceStatus = if ($legacyFormalEvents -eq 0) { 'LOCAL_LINKS_VALID' } else { 'LEGACY_EVIDENCE_GAP' }
Write-Output "Relay validation: PASS (structure valid; events=$count; formal_events=$formalCount; completed_tasks=0; declared_tasks=$completedTasks; evidence_linked_tasks=$evidenceLinkedTasks; evidence_status=$evidenceStatus; platform_attestation=false; final_state=$previous; structural_completion=$completion$waiting)"
