$ErrorActionPreference = 'Stop'

$relayPath = Join-Path $PSScriptRoot "..\protocols\relay-protocol.md"
$reviewPath = Join-Path $PSScriptRoot "..\protocols\review-protocol.md"
$escalationPath = Join-Path $PSScriptRoot "..\protocols\escalation-protocol.md"

foreach ($path in @($relayPath, $reviewPath, $escalationPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing protocol: $path" }
}

$relay = Get-Content -Raw -LiteralPath $relayPath
$review = Get-Content -Raw -LiteralPath $reviewPath
$escalation = Get-Content -Raw -LiteralPath $escalationPath

foreach ($token in @('DISPATCH', 'ACK', 'WORKING', 'HANDOFF', 'REVIEW', 'PASS', 'REWORK', 'BLOCKED', 'ESCALATE')) {
    if ($relay -notmatch [regex]::Escape($token)) { throw "Relay protocol missing $token" }
}
foreach ($token in @('PASS', 'REWORK', 'BLOCKED', 'ESCALATE', 'Self-review prevention')) {
    if ($review -notmatch [regex]::Escape($token)) { throw "Review protocol missing $token" }
}
foreach ($token in @('Technical Blocked', 'Architecture Conflict', 'Independent Audit Needed', 'Human-only')) {
    if ($escalation -notmatch [regex]::Escape($token)) { throw "Escalation protocol missing $token" }
}

$validTransitions = @{
    'DISPATCH' = @('ACK')
    'ACK'      = @('WORKING')
    'WORKING'  = @('HANDOFF', 'BLOCKED')
    'HANDOFF'  = @('REVIEW')
    'REVIEW'   = @('PASS', 'REWORK', 'BLOCKED', 'ESCALATE')
    'PASS'     = @('DISPATCH')
    'REWORK'   = @('WORKING')
    'BLOCKED'  = @('ESCALATE')
}

$events = New-Object System.Collections.Generic.List[string]
$taskNumber = 0
for ($cycle = 1; $cycle -le 20; $cycle++) {
    $taskNumber++
    $taskId = "TASK-{0:D3}" -f $taskNumber
    $state = 'DISPATCH'
    $events.Add("${taskId}:$state")

    foreach ($next in @('ACK', 'WORKING', 'HANDOFF', 'REVIEW', 'PASS', 'DISPATCH')) {
        if ($validTransitions[$state] -notcontains $next) { throw "Invalid transition $state -> $next in cycle $cycle" }
        $state = $next
        $events.Add("${taskId}:$state")
    }
}

if ($events.Count -ne 140) { throw "Expected 140 events for 20 relay cycles, got $($events.Count)" }

# Negative-path checks: the protocol must expose the protections needed to reject them.
if ($review -notmatch 'Self-review prevention') { throw 'Self-review prevention is missing' }
if ($relay -notmatch 'Invalid') { throw 'Invalid transition rule is missing' }
if ($review -notmatch 'REWORK' -or $review -notmatch 'ESCALATE') { throw 'Repeated REWORK escalation is missing' }
if ($escalation -notmatch 'Human-only') { throw 'Human-only route is missing' }

Write-Output 'Phase 2 relay simulation: 20 consecutive cycles PASS'
Write-Output 'Phase 2 negative-path and boundary checks: PASS'
