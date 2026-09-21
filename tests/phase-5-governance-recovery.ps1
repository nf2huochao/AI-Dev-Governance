$ErrorActionPreference = 'Stop'

$root = Join-Path $PSScriptRoot '..'
$governanceDir = Join-Path $root 'governance'
$requiredTemplates = @(
    'CHARTER.template.md',
    'CURRENT_PHASE.template.md',
    'CURRENT_MISSION.template.md',
    'RELAY_STATE.template.md',
    'RELAY_EVENTS.template.jsonl',
    'DECISIONS.template.md',
    'ARCHITECTURE-NO-GO.template.md'
)

foreach ($name in $requiredTemplates) {
    $path = Join-Path $governanceDir $name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing governance template: $name" }
}

$charter = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'CHARTER.template.md')
$phase = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'CURRENT_PHASE.template.md')
$mission = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'CURRENT_MISSION.template.md')
$relay = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'RELAY_STATE.template.md')
$events = Get-Content -Raw -LiteralPath (Join-Path $root 'examples/RELAY_EVENTS.bootstrap.example.jsonl')
$decisions = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'DECISIONS.template.md')
$noGo = Get-Content -Raw -LiteralPath (Join-Path $governanceDir 'ARCHITECTURE-NO-GO.template.md')

foreach ($token in @('Human Governor', 'Single Writer', 'External Advisor', 'Core Architect', 'Mission Planner', 'Build Executor', 'MCP')) {
    if ($charter -notmatch [regex]::Escape($token)) { throw "Charter missing $token" }
}
foreach ($token in @('Phase ID', 'Current Gate', 'Entry Criteria', 'Exit Criteria')) {
    if ($phase -notmatch [regex]::Escape($token)) { throw "Phase template missing $token" }
}
foreach ($token in @('Mission ID', 'Why now', 'Out of Scope', 'Target Gate', 'Completion Standard')) {
    if ($mission -notmatch [regex]::Escape($token)) { throw "Mission template missing $token" }
}
foreach ($token in @('Current Task', 'Current Owner', 'Last Handoff', 'Next Expected Action')) {
    if ($relay -notmatch [regex]::Escape($token)) { throw "Relay state missing $token" }
}
foreach ($token in @('DECISION-ID', 'PROPOSED', 'ACCEPTED', 'SUPERSEDED', 'CLOSED')) {
    if ($decisions -notmatch [regex]::Escape($token)) { throw "Decision template missing $token" }
}
foreach ($token in @('NO-GO-ID', 'Rejected Route', 'New Evidence Required')) {
    if ($noGo -notmatch [regex]::Escape($token)) { throw "NO-GO template missing $token" }
}

# Parse the bootstrap example as JSONL; the formal event template is intentionally empty.
foreach ($line in ($events -split "`r?`n" | Where-Object { $_.Trim() })) {
    $event = $line | ConvertFrom-Json
    $requiredProperties = if ([string]$event.event -eq 'ROLE_THREAD_CREATED') {
        @('event', 'project_id', 'execution_id', 'role_id', 'thread_id', 'binding_mode', 'creation_mode', 'evidence')
    } elseif ([string]$event.event -in @('BOOTSTRAP_HELLO', 'BOOTSTRAP_ACK')) {
        @('event', 'project_id', 'execution_id', 'role_id', 'thread_id', 'target_role_id', 'target_thread_id', 'target_handle', 'status', 'evidence')
    } else {
        @('event', 'task_id', 'actor', 'status', 'timestamp', 'evidence')
    }
    foreach ($property in $requiredProperties) {
        if ($null -eq $event.$property) { throw "Event template missing property $property" }
    }
}

# Lost-conversation recovery: prompts + governance snapshot + repository contracts are sufficient inputs.
$roleFiles = @('external-advisor.md', 'core-architect.md', 'mission-planner.md', 'build-executor.md')
foreach ($role in $roleFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $root "roles\$role"))) { throw "Recovery missing role prompt $role" }
}
foreach ($protocol in @('relay-protocol.md', 'review-protocol.md', 'escalation-protocol.md', 'core-governance.md', 'watchdog.md', 'external-advisor-audit.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root "protocols\$protocol"))) { throw "Recovery missing protocol $protocol" }
}

Write-Output 'Phase 5 governance template checks: PASS'
Write-Output 'Phase 5 lost-conversation recovery inputs: PASS'
