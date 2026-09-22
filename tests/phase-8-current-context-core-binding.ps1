$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-ExpectedFailure {
    param([string]$ScriptPath, [hashtable]$Arguments)
    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { throw "Expected failure did not occur: $ScriptPath" }
        return $output
    } catch {
        return $_.ToString()
    }
}

$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'SKILL.md')
$onboarding = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'references\BOOTSTRAP-RUNBOOK.md')
$recovery = $onboarding
$roleMapTemplate = Get-Content -Raw -LiteralPath (Join-Path $root 'governance\ROLE-MAP.template.md')
$guardPath = Join-Path $root 'scripts\guard-role-creation.ps1'

Assert-True ($skill -match 'BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT') 'Skill must bind the original context as Core Architect'
Assert-True ($skill -match 'EXPECTED_NEW_CODEX_THREADS\s*=\s*2') 'Skill must declare that Bootstrap creates exactly two Codex threads'
Assert-True ($onboarding -match 'BOOTSTRAP_STATE\s*=\s*ACTIVE' -and $onboarding -match 'BOOTSTRAP_STATE\s*=\s*COMPLETE') 'Bootstrap must change state without changing the Core Architect role'
Assert-True ($onboarding -match 'CURRENT ORIGINAL CONVERSATION') 'First-use wording must tell the user that the current conversation is Core Architect'
Assert-True ($onboarding -match 'EXPECTED_NEW_CODEX_THREADS\s*=\s*2') 'First-use wording must describe exactly two new Codex conversations'
Assert-True ($recovery -match 'REUSE_CURRENT' -and $recovery -match 'CURRENT_CONTEXT') 'Recovery rules must reuse the original Core Architect context'
Assert-True ($roleMapTemplate -match 'BINDING_MODE' -and $roleMapTemplate -match 'CREATION_MODE') 'Role map must record binding and creation modes'
Assert-True (Test-Path -LiteralPath $guardPath) 'Missing deterministic role-creation guard'

$coreGuard = Invoke-ExpectedFailure -ScriptPath $guardPath -Arguments @{ RoleId = 'CORE_ARCHITECT' }
Assert-True ($coreGuard -match 'CORE_ARCHITECT_CREATION_FORBIDDEN' -and $coreGuard -match 'CURRENT_CONTEXT_MUST_BE_REUSED') 'Core Architect reached the create-thread route'
foreach ($roleId in @('MISSION_PLANNER', 'BUILD_EXECUTOR')) {
    $guardOutput = Invoke-ExpectedFailure -ScriptPath $guardPath -Arguments @{ RoleId = $roleId }
    Assert-True ($guardOutput -match 'ROLE_MAP_REQUIRED') "$roleId creation did not fail closed without ROLE-MAP"
}

$artifactRoot = Join-Path $root '.test-artifacts\phase-8-current-context-core-binding'
if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
try {
    $projectPath = Join-Path $artifactRoot 'project'
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    $initPath = Join-Path $root 'scripts\init-governance.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $initPath -ProjectPath $projectPath -BootstrapOnly -ProjectId 'demo-project' -ProjectName 'Demo Project' -ProjectShortName 'demo' -CoreArchitectDisplayName 'Custom Architect' | Out-Null
    $generatedMapPath = Join-Path $projectPath '.ai-governance\ROLE-MAP.md'
    $generatedMap = Get-Content -Raw -LiteralPath $generatedMapPath
    Assert-True ($generatedMap -match '\| CORE_ARCHITECT \| Custom Architect \| CURRENT_CONTEXT \| REUSE_CURRENT \|') 'Custom Core Architect display name changed the current-context lifecycle'
    Assert-True ($generatedMap -match 'CURRENT_THREAD_ID_UNAVAILABLE' -and $generatedMap -match 'BINDING_BLOCKED') 'Unavailable current thread must be an explicit capability gap'
    $mapHashBefore = (Get-FileHash -LiteralPath $generatedMapPath).Hash
    & powershell -NoProfile -ExecutionPolicy Bypass -File $initPath -ProjectPath $projectPath -BootstrapOnly -ProjectId 'demo-project' -ProjectName 'Demo Project' -ProjectShortName 'demo' -CoreArchitectDisplayName 'Different Name' | Out-Null
    Assert-True ((Get-FileHash -LiteralPath $generatedMapPath).Hash -eq $mapHashBefore) 'Interrupted Bootstrap recovery replaced the original Core Architect binding'

    $blockedBinding = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-role-bindings.ps1') -Arguments @{ RoleMapPath = $generatedMapPath }
    Assert-True ($blockedBinding -match 'CURRENT_THREAD_ID_UNAVAILABLE' -and $blockedBinding -match 'CAPABILITY GAP') 'Unavailable current thread did not enter an explicit capability gap'

    $boundRoleMapPath = Join-Path $artifactRoot 'ROLE-MAP-BOUND.md'
    $boundRoleMap = @'
# Role Binding Registry

PROJECT_ID: demo-project
BOOTSTRAP_STATE: ACTIVE
TASK_ID: NOT_ASSIGNED_UNTIL_MISSION
EXECUTION_ID: bootstrap-001
OUTER_TASK_ID: NOT_A_ROUTING_TARGET

| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| CORE_ARCHITECT | Demo Architect | CURRENT_CONTEXT | REUSE_CURRENT | thread-core-001 | thread-core-001 | BOUND |
| MISSION_PLANNER | Demo Planner | CREATED_THREAD | ENSURE | thread-planner-001 | thread-planner-001 | BOUND |
| BUILD_EXECUTOR | Demo Executor | CREATED_THREAD | ENSURE | thread-executor-001 | thread-executor-001 | BOUND |
'@
    $boundRoleMap | Set-Content -LiteralPath $boundRoleMapPath -Encoding utf8

    foreach ($roleId in @('MISSION_PLANNER', 'BUILD_EXECUTOR')) {
        $recoveryGuard = & powershell -NoProfile -ExecutionPolicy Bypass -File $guardPath -RoleId $roleId -RoleMapPath $boundRoleMapPath | Out-String
        Assert-True ($recoveryGuard -match 'ROLE_ALREADY_BOUND' -and $recoveryGuard -match 'REUSE_EXISTING_THREAD' -and $recoveryGuard -notmatch 'ROLE_CREATION_ALLOWED') "$roleId was recreated during interrupted Bootstrap recovery"
    }

    $eventsPath = Join-Path $artifactRoot 'RELAY_EVENTS.jsonl'
    $bootstrapEvents = @'
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"native-create-result-planner"}
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"native-create-result-executor"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"CORE_ARCHITECT","thread_id":"thread-core-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"thread-planner-001","status":"SENT","evidence":"native-send-result-1"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"CORE_ARCHITECT","target_thread_id":"thread-core-001","target_handle":"thread-core-001","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-record-1"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"BUILD_EXECUTOR","target_thread_id":"thread-executor-001","target_handle":"thread-executor-001","status":"SENT","evidence":"native-send-result-2"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"thread-planner-001","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-record-2"}
'@
    $bootstrapEvents | Set-Content -LiteralPath $eventsPath -Encoding utf8

    $bootstrapOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $eventsPath -RoleMapPath $boundRoleMapPath -ExecutionId 'bootstrap-001' | Out-String
    Assert-True ($bootstrapOutput -match 'actual_new_threads=2' -and $bootstrapOutput -match 'CORE_ARCHITECT_SOURCE=CURRENT_ORIGINAL_CONVERSATION') 'Bootstrap did not assert the two-thread current-context model'

    $thirdThreadEventsPath = Join-Path $artifactRoot 'RELAY_EVENTS-THIRD-THREAD.jsonl'
    $thirdThread = '{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"bootstrap-001","role_id":"CORE_ARCHITECT","thread_id":"thread-core-new","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"unexpected-create-result"}'
    @($thirdThread, (Get-Content -LiteralPath $eventsPath)) | Set-Content -LiteralPath $thirdThreadEventsPath -Encoding utf8
    $thirdThreadOutput = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-bootstrap.ps1') -Arguments @{ EventsPath = $thirdThreadEventsPath; RoleMapPath = $boundRoleMapPath; ExecutionId = 'bootstrap-001' }
    Assert-True ($thirdThreadOutput -match 'UNEXPECTED_CORE_ARCHITECT_CREATION|ROLE_DUPLICATION_OR_UNKNOWN_THREAD') 'A third Core Architect thread did not fail Bootstrap'
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 8 current-context Core Architect binding: PASS'
