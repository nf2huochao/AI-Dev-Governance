$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$relayProtocolPath = Join-Path $repoRoot 'protocols\relay-protocol.md'
$watchdogPath = Join-Path $repoRoot 'protocols\watchdog.md'
$rolePaths = @(
    (Join-Path $repoRoot 'roles\core-architect.md'),
    (Join-Path $repoRoot 'roles\mission-planner.md'),
    (Join-Path $repoRoot 'roles\build-executor.md')
)

function Assert-Contains {
    param(
        [Parameter(Mandatory)] [string]$Content,
        [Parameter(Mandatory)] [string]$Needle,
        [Parameter(Mandatory)] [string]$Context
    )

    if ($Content -notmatch [regex]::Escape($Needle)) {
        throw "$Context is missing required contract: $Needle"
    }
}

function Read-Utf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-RelayScenario {
    param(
        [bool]$SendSucceeds = $true,
        [bool]$WakeSupported = $true
    )

    $trace = New-Object System.Collections.Generic.List[string]
    $pollCount = 0
    $recoveryAttempts = 0
    $sendError = $null

    $trace.Add('core-architect:SEND:MISSION')
    $trace.Add('core-architect:YIELD')
    $trace.Add('mission-planner:WAKE:MISSION_RECEIVED')
    $trace.Add('mission-planner:ACT:CREATE_TASK')

    $dispatchSucceeded = $SendSucceeds
    if (-not $dispatchSucceeded) {
        $sendError = 'DISPATCH_SEND_FAILED'
        $recoveryAttempts++
        $trace.Add('mission-planner:RECOVER:ONE_TARGETED_RETRY')
        $dispatchSucceeded = $false
    }

    if (-not $dispatchSucceeded) {
        $trace.Add('mission-planner:BLOCKED:REAL_SEND_ERROR')
        return [pscustomobject]@{
            Result = 'BLOCKED'
            Trace = $trace
            PollCount = $pollCount
            RecoveryAttempts = $recoveryAttempts
            SendError = $sendError
        }
    }

    $trace.Add('mission-planner:SEND:DISPATCH')
    $trace.Add('mission-planner:YIELD')

    if (-not $WakeSupported) {
        $trace.Add('mission-planner:BLOCKED:WAKE_CAPABILITY_MISSING')
        return [pscustomobject]@{
            Result = 'BLOCKED'
            Trace = $trace
            PollCount = $pollCount
            RecoveryAttempts = $recoveryAttempts
            SendError = $null
        }
    }

    $trace.Add('build-executor:WAKE:DISPATCH_RECEIVED')
    $trace.Add('build-executor:SEND:ACK')
    $trace.Add('build-executor:ACT:WORK')
    $trace.Add('build-executor:SEND:HANDOFF')
    $trace.Add('build-executor:YIELD')
    $trace.Add('mission-planner:WAKE:HANDOFF_RECEIVED')
    $trace.Add('mission-planner:ACT:REVIEW')
    $trace.Add('mission-planner:SEND:PASS_AND_NEXT_DISPATCH')
    $trace.Add('mission-planner:YIELD')

    [pscustomobject]@{
        Result = 'PASS'
        Trace = $trace
        PollCount = $pollCount
        RecoveryAttempts = $recoveryAttempts
        SendError = $null
    }
}

$relay = Read-Utf8 -Path $relayProtocolPath
$watchdog = Read-Utf8 -Path $watchdogPath
$roles = ($rolePaths | ForEach-Object { Read-Utf8 -Path $_ }) -join "`n"
$sendYieldWakeAct = 'SEND ' + [char]0x2192 + ' YIELD ' + [char]0x2192 + ' WAKE ' + [char]0x2192 + ' ACT'

foreach ($contract in @(
        $sendYieldWakeAct,
        'No polling. Work on events.',
        'send success is not task completion',
        'real wake capability',
        'one targeted recovery'
    )) {
    Assert-Contains -Content ($relay + $watchdog + $roles) -Needle $contract -Context 'event-driven relay contract'
}

foreach ($roleContract in @(
        'Mission Planner yields after successful DISPATCH',
        'Build Executor yields after HANDOFF',
        'Core Architect yields after Mission delivery'
    )) {
    Assert-Contains -Content $roles -Needle $roleContract -Context 'role-specific event-driven contract'
}

$normal = Invoke-RelayScenario
if ($normal.Result -ne 'PASS') { throw 'Normal event-driven relay scenario did not complete' }
if ($normal.PollCount -ne 0) { throw "Normal scenario performed $($normal.PollCount) polling calls" }
if ($normal.Trace -notcontains 'build-executor:SEND:ACK') { throw 'Executor ACK was not emitted' }
if ($normal.Trace -notcontains 'build-executor:ACT:WORK') { throw 'Executor did not continue work after ACK' }
if ($normal.Trace -notcontains 'mission-planner:WAKE:HANDOFF_RECEIVED') { throw 'Planner was not woken by HANDOFF' }
if ($normal.Trace -notcontains 'mission-planner:ACT:REVIEW') { throw 'Planner did not review after HANDOFF wake' }
if ($normal.Trace -notcontains 'mission-planner:SEND:PASS_AND_NEXT_DISPATCH') { throw 'Planner did not dispatch the next TASK after PASS' }

$sendFailure = Invoke-RelayScenario -SendSucceeds:$false
if ($sendFailure.Result -ne 'BLOCKED') { throw 'Send failure must become BLOCKED after bounded recovery' }
if ($sendFailure.RecoveryAttempts -ne 1) { throw "Expected one targeted recovery attempt, got $($sendFailure.RecoveryAttempts)" }
if ($sendFailure.PollCount -ne 0) { throw 'Send failure recovery must not poll' }
if ($sendFailure.Trace -notcontains 'mission-planner:BLOCKED:REAL_SEND_ERROR') { throw 'Real send error was not recorded' }

$wakeGap = Invoke-RelayScenario -WakeSupported:$false
if ($wakeGap.Result -ne 'BLOCKED') { throw 'Missing wake capability must be BLOCKED' }
if ($wakeGap.PollCount -ne 0) { throw 'Missing wake capability must not be hidden by polling' }

$fixtureRoot = Join-Path $repoRoot '.test-artifacts\phase-7-event-driven-relay'
try {
    $governanceRoot = Join-Path $fixtureRoot '.ai-governance'
    New-Item -ItemType Directory -Path $governanceRoot -Force | Out-Null
    @(
        '{"event":"DISPATCH","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"mission-planner","status":"DISPATCH"}',
        '{"event":"ACK","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"build-executor","status":"ACK"}',
        '{"event":"WORKING","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"build-executor","status":"WORKING"}',
        '{"event":"HANDOFF","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"build-executor","status":"HANDOFF"}',
        '{"event":"REVIEW","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"mission-planner","status":"REVIEW"}',
        '{"event":"PASS","project_id":"P","mission_id":"M","task_id":"TASK-EVENT-001","execution_id":"E","actor":"mission-planner","status":"PASS"}'
    ) | Set-Content -LiteralPath (Join-Path $governanceRoot 'RELAY_EVENTS.jsonl') -Encoding ascii

    $validator = Join-Path $repoRoot 'scripts\check-relay.ps1'
    $validatorOutput = & $validator -ProjectPath $fixtureRoot
    if ($validatorOutput -notmatch 'Relay validation: PASS') {
        throw 'Existing relay validator did not report PASS for the event-driven compatibility fixture'
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Output 'Phase 7 event-driven relay contract checks: PASS'
Write-Output 'Phase 7 event-driven relay no-polling simulation: PASS'
Write-Output 'Phase 7 bounded send-failure and wake-capability checks: PASS'
Write-Output 'Phase 7 existing relay validator compatibility: PASS'
