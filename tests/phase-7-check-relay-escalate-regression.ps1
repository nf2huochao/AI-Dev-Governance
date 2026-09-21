$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$artifactRoot = Join-Path $root 'tests/.artifacts/phase-7-escalate'
$governanceRoot = Join-Path $artifactRoot '.ai-governance'
$eventsPath = Join-Path $governanceRoot 'RELAY_EVENTS.jsonl'

if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $governanceRoot -Force | Out-Null
try {
    @(
        '{"event":"DISPATCH","task_id":"TASK-REG-001","actor":"mission-planner","status":"DISPATCH"}',
        '{"event":"ACK","task_id":"TASK-REG-001","actor":"build-executor","status":"ACK"}',
        '{"event":"WORKING","task_id":"TASK-REG-001","actor":"build-executor","status":"WORKING"}',
        '{"event":"HANDOFF","task_id":"TASK-REG-001","actor":"build-executor","status":"HANDOFF"}',
        '{"event":"REVIEW","task_id":"TASK-REG-001","actor":"mission-planner","status":"REVIEW"}',
        '{"event":"BLOCKED","task_id":"TASK-REG-001","actor":"mission-planner","status":"BLOCKED"}',
        '{"event":"ESCALATE","task_id":"TASK-REG-001","actor":"core-architect","status":"ESCALATE"}'
    ) | Set-Content -LiteralPath $eventsPath -Encoding utf8
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/check-relay.ps1') -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'check-relay rejected a valid final ESCALATE state' }
    @(
        '{"event":"DISPATCH","task_id":"TASK-REG-002","actor":"mission-planner","status":"DISPATCH"}',
        '{"event":"ACK","task_id":"TASK-REG-002","actor":"build-executor","status":"ACK"}'
    ) | Add-Content -LiteralPath $eventsPath -Encoding utf8
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/check-relay.ps1') -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'check-relay rejected safe continuation after ESCALATE' }
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 7 check-relay ESCALATE regression: PASS'
