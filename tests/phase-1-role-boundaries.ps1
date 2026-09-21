$ErrorActionPreference = 'Stop'

$roleFiles = @{
    'external-advisor.md' = @('External Advisor', 'Identity', 'Mission', 'Responsibilities', 'Allowed Actions', 'Forbidden Actions', 'Escalation Rules', 'Silence Rules', 'Context Rules', 'Handoff Rules')
    'core-architect.md'   = @('Core Architect', 'Identity', 'Mission', 'Responsibilities', 'Allowed Actions', 'Forbidden Actions', 'Escalation Rules', 'Silence Rules', 'Context Rules', 'Handoff Rules')
    'mission-planner.md'  = @('Mission Planner', 'Identity', 'Mission', 'Responsibilities', 'Allowed Actions', 'Forbidden Actions', 'Escalation Rules', 'Silence Rules', 'Context Rules', 'Handoff Rules')
    'build-executor.md'   = @('Build Executor', 'Identity', 'Mission', 'Responsibilities', 'Allowed Actions', 'Forbidden Actions', 'Escalation Rules', 'Silence Rules', 'Context Rules', 'Handoff Rules')
}

foreach ($entry in $roleFiles.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot "..\roles\$($entry.Key)"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing role prompt: $path"
    }

    $content = Get-Content -Raw -LiteralPath $path
    foreach ($required in $entry.Value) {
        if ($content -notmatch [regex]::Escape($required)) {
            throw "Missing '$required' in $($entry.Key)"
        }
    }

    if ($content -notmatch 'No AI supervises itself') {
        throw "Missing self-review principle in $($entry.Key)"
    }
}

$boundaries = @{
    'external-advisor.md' = @('ADVISORY', 'Claim:', 'Counter Evidence:', 'MCP')
    'core-architect.md'   = @('MISSION', 'Phase', 'Gate', 'Architecture', 'NO-GO')
    'mission-planner.md'  = @('TASK', 'PASS', 'REWORK', 'BLOCKED', 'ESCALATE')
    'build-executor.md'   = @('HANDOFF', 'TASK-ID:', 'Status: COMPLETE | BLOCKED', 'Commit:', 'Evidence:')
}

foreach ($entry in $boundaries.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot "..\roles\$($entry.Key)"
    $content = Get-Content -Raw -LiteralPath $path
    foreach ($boundary in $entry.Value) {
        if ($content -notmatch [regex]::Escape($boundary)) {
            throw "Missing boundary '$boundary' in $($entry.Key)"
        }
    }
}

Write-Output 'Phase 1 role-boundary tests: PASS'
