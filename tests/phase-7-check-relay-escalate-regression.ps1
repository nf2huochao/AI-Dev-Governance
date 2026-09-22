$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$artifactRoot = Join-Path $root 'tests/.artifacts/phase-7-escalate'
$governanceRoot = Join-Path $artifactRoot '.ai-governance'
$eventsPath = Join-Path $governanceRoot 'RELAY_EVENTS.jsonl'

if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $governanceRoot -Force | Out-Null
try {
    @(
        '{"event":"DISPATCH","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"mission-planner","status":"DISPATCH"}',
        '{"event":"ACK","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"build-executor","status":"ACK"}',
        '{"event":"WORKING","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"build-executor","status":"WORKING"}',
        '{"event":"HANDOFF","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"build-executor","status":"HANDOFF"}',
        '{"event":"REVIEW","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"mission-planner","status":"REVIEW"}',
        '{"event":"BLOCKED","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"mission-planner","status":"BLOCKED"}',
        '{"event":"ESCALATE","project_id":"P","mission_id":"M","task_id":"TASK-REG-001","execution_id":"E1","actor":"core-architect","status":"ESCALATE"}'
    ) | Set-Content -LiteralPath $eventsPath -Encoding utf8
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/check-relay.ps1') -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'check-relay rejected a valid final ESCALATE state' }
    @(
        '{"event":"DISPATCH","project_id":"P","mission_id":"M","task_id":"TASK-REG-002","execution_id":"E2","actor":"mission-planner","status":"DISPATCH","resolution_ref":"DECISION-001"}',
        '{"event":"ACK","project_id":"P","mission_id":"M","task_id":"TASK-REG-002","execution_id":"E2","actor":"build-executor","status":"ACK"}'
    ) | Add-Content -LiteralPath $eventsPath -Encoding utf8
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/check-relay.ps1') -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'check-relay rejected safe continuation after ESCALATE' }
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 7 check-relay ESCALATE regression: PASS'
