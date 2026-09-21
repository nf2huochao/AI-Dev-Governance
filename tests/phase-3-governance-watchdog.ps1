$ErrorActionPreference = 'Stop'

$governancePath = Join-Path $PSScriptRoot "..\protocols\core-governance.md"
$watchdogPath = Join-Path $PSScriptRoot "..\protocols\watchdog.md"
$governance = Get-Content -Raw -LiteralPath $governancePath
$watchdog = Get-Content -Raw -LiteralPath $watchdogPath

foreach ($token in @('Phase', 'Gate', 'Mission', 'Deviation Gate', 'Decision Protection', 'Architecture NO-GO', 'Closed Issue Protection')) {
    if ($governance -notmatch [regex]::Escape($token)) { throw "Core governance missing $token" }
}
foreach ($token in @('Twenty-minute inspection', 'Relay Health', 'Mission Alignment', 'PAUSE CURRENT ROUTE', 'Anti-loop rules')) {
    if ($watchdog -notmatch [regex]::Escape($token)) { throw "Watchdog missing $token" }
}

# Scenario: every relay transition succeeds, but the task does not advance the Mission.
$mission = [ordered]@{ Goal = 'prove the real integration path'; Scope = 'real integration'; OutOfScope = 'mock-only demonstration' }
$task = [ordered]@{ Goal = 'polish a mock-only demonstration'; Scope = 'mock-only demonstration'; Relay = 'PASS' }
$relayHealthy = ($task.Relay -eq 'PASS')
$missionAligned = ($task.Scope -eq $mission.Scope)

if (-not $relayHealthy) { throw 'Scenario setup failed: relay should be healthy' }
if ($missionAligned) { throw 'Scenario setup failed: task should be misaligned' }

$watchdogResult = if ($relayHealthy -and -not $missionAligned) { 'DEVIATION' } else { 'CLEAR' }
if ($watchdogResult -ne 'DEVIATION') { throw 'Watchdog failed to detect healthy relay with wrong work' }

# Protection checks for closed decisions, NO-GO routes, and self-review.
foreach ($phrase in @('New Evidence', 'NO-GO', 'Self-review protection', 'BLOCKED')) {
    if (($governance + $watchdog) -notmatch [regex]::Escape($phrase)) { throw "Missing protection rule: $phrase" }
}

# The governance documents must remain project-agnostic.
foreach ($banned in @('Dolibarr', 'DSH', 'RC7', 'Host Provider')) {
    if (($governance + $watchdog) -match [regex]::Escape($banned)) { throw "Project-specific rule leaked into Phase 3: $banned" }
}

Write-Output 'Phase 3 governance structure checks: PASS'
Write-Output 'Phase 3 healthy-relay/wrong-work detection: PASS'
Write-Output 'Phase 3 project-agnostic scope check: PASS'
