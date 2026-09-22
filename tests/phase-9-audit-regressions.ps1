$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$artifactRoot = Join-Path $root '.test-artifacts\phase-9-audit-regressions'
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null

function Write-Utf8([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}

function Invoke-RelayCase([string]$Name, [object[]]$Events, [bool]$ShouldPass, [string]$ExpectedText = '') {
    $project = Join-Path $artifactRoot $Name
    $governance = Join-Path $project '.ai-governance'
    New-Item -ItemType Directory -Path $governance -Force | Out-Null
    $lines = @($Events | ForEach-Object { $_ | ConvertTo-Json -Compress })
    Write-Utf8 (Join-Path $governance 'RELAY_EVENTS.jsonl') (($lines -join "`n") + "`n")
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-relay.ps1') -ProjectPath $project 2>&1 | Out-String
    $passed = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $oldPreference
    if ($passed -ne $ShouldPass) { throw "$Name expected pass=$ShouldPass, got pass=$passed. Output: $output" }
    if ($ExpectedText -and $output -notmatch [regex]::Escape($ExpectedText)) { throw "$Name missing output: $ExpectedText. Output: $output" }
}

function E([string]$State, [string]$Task = 'TASK-001', [string]$Execution = 'EXEC-001', [string]$Actor = '') {
    if (-not $Actor) {
        $Actor = if ($State -in @('DISPATCH', 'REVIEW', 'PASS', 'REWORK')) { 'mission-planner' } else { 'build-executor' }
    }
    return [ordered]@{ event = $State; project_id = 'PROJECT-001'; mission_id = 'MISSION-001'; task_id = $Task; execution_id = $Execution; actor = $Actor; status = $State }
}

Invoke-RelayCase 'isolated-pass' @(E 'PASS') $false
Invoke-RelayCase 'dispatch-only' @(E 'DISPATCH') $true 'WAITING_ACK'
Invoke-RelayCase 'cross-task' @((E 'DISPATCH' 'TASK-A'), (E 'ACK' 'TASK-B')) $false
Invoke-RelayCase 'cross-execution' @((E 'DISPATCH'), (E 'ACK' 'TASK-001' 'EXEC-002')) $false
$emptyTask = E 'DISPATCH'; $emptyTask.task_id = ''
Invoke-RelayCase 'empty-task' @($emptyTask) $false
$mismatch = E 'DISPATCH'; $mismatch.event = 'PASS'
Invoke-RelayCase 'event-status-mismatch' @($mismatch) $false
$full = @((E 'DISPATCH'), (E 'ACK'), (E 'WORKING'), (E 'HANDOFF'), (E 'REVIEW'), (E 'PASS'))
Invoke-RelayCase 'full-chain' $full $true 'completion=true'
$next = @($full + @((E 'DISPATCH' 'TASK-002' 'EXEC-002')))
Invoke-RelayCase 'pass-next-dispatch' $next $true 'WAITING_ACK'

$roleMap = Join-Path $artifactRoot 'ROLE-MAP.md'
$roleMapText = @'
PROJECT_ID: demo
BOOTSTRAP_STATE: COMPLETE
| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| `CORE_ARCHITECT` | Core | CURRENT_CONTEXT | REUSE_CURRENT | thread-core | target-core | BOUND |
| `MISSION_PLANNER` | Planner | CREATED_THREAD | ENSURE | thread-planner | target-planner | `BOUND` |
| `BUILD_EXECUTOR` | Executor | CREATED_THREAD | ENSURE | NOT_CREATED | PENDING_CREATION | PENDING_CREATION |
'@
Write-Utf8 $roleMap $roleMapText

$guard = Join-Path $root 'scripts\guard-role-creation.ps1'
$boundOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $guard -RoleId MISSION_PLANNER -RoleMapPath $roleMap 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $boundOutput -notmatch 'REUSE_EXISTING_THREAD') { throw "Backticked BOUND role was not reused: $boundOutput" }
$createOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $guard -RoleId BUILD_EXECUTOR -RoleMapPath $roleMap 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $createOutput -notmatch 'ROLE_CREATION_ALLOWED') { throw "Explicit pending role was not allowed: $createOutput" }
$oldPreference = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
$missingOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $guard -RoleId BUILD_EXECUTOR 2>&1 | Out-String
$ErrorActionPreference = $oldPreference
if ($LASTEXITCODE -eq 0) { throw "Missing role map must fail closed: $missingOutput" }

Write-Output 'Phase 9 audit regressions A01-A03: PASS'
