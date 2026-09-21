[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$governanceRoot = Join-Path $project '.ai-governance'
$eventsPath = Join-Path $governanceRoot 'RELAY_EVENTS.jsonl'
if (-not (Test-Path -LiteralPath $eventsPath)) { throw "Missing relay events: $eventsPath" }

$validTransitions = @{
    'DISPATCH' = @('ACK')
    'ACK' = @('WORKING')
    'WORKING' = @('HANDOFF', 'BLOCKED')
    'HANDOFF' = @('REVIEW')
    'REVIEW' = @('PASS', 'REWORK', 'BLOCKED', 'ESCALATE')
    'PASS' = @('DISPATCH')
    'REWORK' = @('WORKING')
    'BLOCKED' = @('ESCALATE')
    'ESCALATE' = @('DISPATCH')
}
$actorRules = @{
    'DISPATCH' = @('mission-planner')
    'ACK' = @('build-executor')
    'WORKING' = @('build-executor')
    'HANDOFF' = @('build-executor')
    'REVIEW' = @('mission-planner')
    'PASS' = @('mission-planner')
    'REWORK' = @('mission-planner')
    'BLOCKED' = @('build-executor', 'mission-planner')
    'ESCALATE' = @('mission-planner', 'core-architect', 'external-advisor')
}

$previous = $null
$count = 0
$bootstrapCount = 0
$formalRelayStarted = $false
foreach ($line in (Get-Content -LiteralPath $eventsPath)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $count++
    try { $event = $line | ConvertFrom-Json } catch { throw "Invalid JSON at event $count" }
    if ([string]$event.event -in @('ROLE_THREAD_CREATED', 'BOOTSTRAP_HELLO', 'BOOTSTRAP_ACK') -or [string]$event.status -in @('BOOTSTRAP_HELLO', 'BOOTSTRAP_ACK')) {
        if ($formalRelayStarted) { throw "BOOTSTRAP_AFTER_FORMAL_RELAY: event $count" }
        $bootstrapCount++
        continue
    }
    $formalRelayStarted = $true
    foreach ($property in @('event', 'task_id', 'actor', 'status')) {
        if ($null -eq $event.$property) { throw "Event $count missing $property" }
    }

    $state = [string]$event.status
    if ($state -notin $validTransitions.Keys) { throw "Unknown relay state '$state' at event $count" }
    if ($null -ne $previous -and $validTransitions[$previous] -notcontains $state) {
        throw "Invalid relay transition $previous -> $state at event $count"
    }
    if ($actorRules[$state] -notcontains [string]$event.actor) {
        throw "Invalid actor '$($event.actor)' for state '$state' at event $count"
    }
    if ($state -eq 'PASS' -and [string]$event.actor -eq 'build-executor') {
        throw 'Build Executor cannot self-accept with PASS'
    }
    $previous = $state
}

if ($count -eq 0) {
    Write-Output 'Relay validation: PASS (empty initial log; no formal relay or bootstrap event has occurred)'
    exit 0
}
if (-not $formalRelayStarted) {
    Write-Output "Relay validation: PASS ($bootstrapCount bootstrap events; formal relay not started)"
    exit 0
}
if ($previous -notin @('ACK', 'WORKING', 'HANDOFF', 'REVIEW', 'PASS', 'REWORK', 'BLOCKED', 'ESCALATE')) {
    throw "Unexpected final relay state: $previous"
}

Write-Output "Relay validation: PASS ($count events, final state $previous)"
