[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path
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

function Require-Text([object]$Event, [string]$Property, [int]$Number) {
    if (-not ($Event.PSObject.Properties.Name -contains $Property) -or [string]::IsNullOrWhiteSpace([string]$Event.$Property)) {
        throw "Event $Number missing or empty $Property"
    }
}

$previous = $null
$active = $null
$count = 0
$formalCount = 0
$controlCount = 0
$completedTasks = 0

foreach ($line in [IO.File]::ReadAllLines($eventsPath, [Text.Encoding]::UTF8)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $count++
    try { $event = $line | ConvertFrom-Json } catch { throw "Invalid JSON at event $count" }

    if ([string]$event.event -in $controlEvents) {
        $controlCount++
        continue
    }

    $formalCount++
    foreach ($property in @($contract.required_fields)) {
        Require-Text $event $property $count
    }

    $state = [string]$event.status
    if ($state -notin $validTransitions.Keys) { throw "Unknown relay state '$state' at event $count" }
    if ([string]$event.event -ne $state) { throw "EVENT_STATUS_MISMATCH: event=$($event.event), status=$state at event $count" }
    if ($actorRules[$state] -notcontains [string]$event.actor) { throw "Invalid actor '$($event.actor)' for state '$state' at event $count" }

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
        if ($previous -eq 'ESCALATE') {
            Require-Text $event 'resolution_ref' $count
        }
        $active = $context
    } else {
        foreach ($field in @('ProjectId', 'MissionId', 'TaskId', 'ExecutionId')) {
            if ($context.$field -ne $active.$field) {
                throw "RELAY_CONTEXT_MISMATCH: $field changed from '$($active.$field)' to '$($context.$field)' at event $count"
            }
        }
    }

    if ($state -eq 'PASS') { $completedTasks++ }
    $previous = $state
}

if ($count -eq 0) {
    Write-Output 'Relay validation: PASS (empty initial log; no formal relay or control event has occurred)'
    exit 0
}
if ($formalCount -eq 0) {
    Write-Output "Relay validation: PASS (structure valid; $controlCount control events; formal relay not started)"
    exit 0
}

$completion = if ($previous -eq 'PASS') { 'true' } else { 'false' }
$waiting = if ($previous -eq 'DISPATCH') { '; runtime_state=WAITING_ACK' } else { '' }
Write-Output "Relay validation: PASS (structure valid; events=$count; formal_events=$formalCount; completed_tasks=$completedTasks; final_state=$previous; completion=$completion$waiting)"
