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
        if ($LASTEXITCODE -eq 0) { throw 'Expected failure did not occur' }
        return $output
    } catch {
        return $_.ToString()
    }
}

$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'SKILL.md')
$onboarding = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'references\BOOTSTRAP-RUNBOOK.md')
$roleMap = Get-Content -Raw -LiteralPath (Join-Path $root 'governance\ROLE-MAP.template.md')

Assert-True ($onboarding -match 'CORE_ARCHITECT_SOURCE = CURRENT ORIGINAL CONVERSATION') 'Skill must bind the first Codex conversation to CORE_ARCHITECT'
Assert-True ($onboarding -match 'BOOTSTRAP_STATE.*ACTIVE' -and $onboarding -match 'BOOTSTRAP_STATE.*COMPLETE') 'Skill must define Bootstrap as a Core Architect state transition'
Assert-True ($skill -match 'TEAM-FIRST') 'Skill must define the team-first startup order'
Assert-True ($onboarding -match 'CORE_ARCHITECT' -and $onboarding -match 'BOOTSTRAP_HELLO' -and $onboarding -match 'BOOTSTRAP_ACK') 'Onboarding must require the two bootstrap HELLO/ACK checks'
Assert-True ($onboarding -match '通信经原始证据核实后，才转 ChatGPT') 'Communication must be verified before project planning'
Assert-True ($onboarding -match '不能创建第二个 Core Architect') 'Onboarding must prevent a second Core Architect'
Assert-True ($onboarding -match '无需每一步再自然语言询问') 'Onboarding must not require confirmation after every role or routine message'
foreach ($field in @('PROJECT_ID', 'ROLE_ID', 'THREAD_ID', 'TASK_ID', 'EXECUTION_ID', 'OUTER_TASK_ID')) {
    Assert-True ($roleMap -match $field) "Role registry is missing identity field: $field"
}
Assert-True (Test-Path -LiteralPath (Join-Path $root 'scripts\check-role-bindings.ps1')) 'Missing role binding validator'
Assert-True (Test-Path -LiteralPath (Join-Path $root 'scripts\check-bootstrap.ps1')) 'Missing bootstrap communication validator'

$artifactRoot = Join-Path $root '.test-artifacts\phase-8-team-first-bootstrap'
if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
try {
    $bootstrapProject = Join-Path $artifactRoot 'bootstrap-project'
    New-Item -ItemType Directory -Path $bootstrapProject -Force | Out-Null
    $initOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\init-governance.ps1') -ProjectPath $bootstrapProject -BootstrapOnly -ProjectId 'demo-project' -ProjectName 'Demo Project' -ProjectShortName 'demo' | Out-String
    Assert-True ($initOutput -match 'Team-first bootstrap') 'Bootstrap-only initialization did not report its safety boundary'
    Assert-True (Test-Path -LiteralPath (Join-Path $bootstrapProject '.ai-governance\ROLE-MAP.md')) 'Bootstrap-only initialization did not create ROLE-MAP.md'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $bootstrapProject '.ai-governance\PROJECT-STARTUP-SUMMARY.md'))) 'Bootstrap-only initialization created a project summary before approval'
    $generatedRoleMapPath = Join-Path $bootstrapProject '.ai-governance\ROLE-MAP.md'
    $generatedRoleMap = Get-Content -Raw -LiteralPath $generatedRoleMapPath
    $generatedRoleMap = $generatedRoleMap -replace '(?m)^\|\s*CORE_ARCHITECT\s*\|([^|]+)\|\s*CURRENT_CONTEXT\s*\|\s*REUSE_CURRENT\s*\|\s*CURRENT_THREAD_ID_UNAVAILABLE\s*\|\s*CURRENT_THREAD_TARGET_UNAVAILABLE\s*\|\s*BINDING_BLOCKED\s*\|\r?$', '| CORE_ARCHITECT |$1| CURRENT_CONTEXT | REUSE_CURRENT | thread-core-001 | target-core-001 | BOUND |'
    $generatedRoleMap = $generatedRoleMap -replace '(?m)^\|\s*MISSION_PLANNER\s*\|([^|]+)\|\s*CREATED_THREAD\s*\|\s*ENSURE\s*\|\s*NOT_CREATED\s*\|\s*NOT_CREATED\s*\|\s*PENDING_CREATION\s*\|\r?$', '| MISSION_PLANNER |$1| CREATED_THREAD | ENSURE | thread-planner-001 | target-planner-001 | BOUND |'
    $generatedRoleMap = $generatedRoleMap -replace '(?m)^\|\s*BUILD_EXECUTOR\s*\|([^|]+)\|\s*CREATED_THREAD\s*\|\s*ENSURE\s*\|\s*NOT_CREATED\s*\|\s*NOT_CREATED\s*\|\s*PENDING_CREATION\s*\|\r?$', '| BUILD_EXECUTOR |$1| CREATED_THREAD | ENSURE | thread-executor-001 | target-executor-001 | BOUND |'
    $generatedRoleMap | Set-Content -LiteralPath $generatedRoleMapPath -Encoding utf8
    $generatedBindingOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-role-bindings.ps1') -RoleMapPath $generatedRoleMapPath | Out-String
    Assert-True ($generatedBindingOutput -match 'ROLE_BINDINGS_STRUCTURALLY_VALID') 'Generated bootstrap role registry could not be structurally checked after platform IDs were recorded'

    $roleMapPath = Join-Path $artifactRoot 'ROLE-MAP.md'
    @'
# Role Binding Registry

PROJECT_ID: demo-project
BOOTSTRAP_STATE: ACTIVE

| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| CORE_ARCHITECT | Demo Architect | CURRENT_CONTEXT | REUSE_CURRENT | thread-core-001 | target-core-001 | BOUND |
| MISSION_PLANNER | Demo Planner | CREATED_THREAD | ENSURE | thread-planner-001 | target-planner-001 | BOUND |
| BUILD_EXECUTOR | Demo Executor | CREATED_THREAD | ENSURE | thread-executor-001 | target-executor-001 | BOUND |

OUTER_TASK_ID: outer-ignored
'@ | Set-Content -LiteralPath $roleMapPath -Encoding utf8

    $bindingOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-role-bindings.ps1') -RoleMapPath $roleMapPath | Out-String
    Assert-True ($bindingOutput -match 'ROLE_BINDINGS_STRUCTURALLY_VALID') 'Valid role binding registry was rejected'

    $duplicateRoleMap = Join-Path $artifactRoot 'ROLE-MAP-DUPLICATE.md'
    ((Get-Content -Raw -LiteralPath $roleMapPath) -replace '\| BUILD_EXECUTOR \| Demo Executor \| CREATED_THREAD \| ENSURE \| thread-executor-001 \| target-executor-001 \| BOUND \|', '| MISSION_PLANNER | Duplicate Planner | CREATED_THREAD | ENSURE | thread-duplicate-001 | target-duplicate-001 | BOUND |') | Set-Content -LiteralPath $duplicateRoleMap -Encoding utf8
    $duplicateOutput = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-role-bindings.ps1') -Arguments @{ RoleMapPath = $duplicateRoleMap }
    Assert-True ($duplicateOutput -match 'ROLE_BINDING_CONFLICT') 'Duplicate role binding was not blocked'

    $eventsPath = Join-Path $artifactRoot 'RELAY_EVENTS.jsonl'
    @'
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"platform-create-planner"}
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"boot-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"platform-create-executor"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"boot-001","role_id":"CORE_ARCHITECT","thread_id":"thread-core-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"target-planner-001","status":"SENT","evidence":"platform-send-1","platform_evidence_status":"RECEIVED","platform_message_id":"message-1"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"CORE_ARCHITECT","target_thread_id":"thread-core-001","target_handle":"target-core-001","status":"RECEIVED_AND_REPLIED","evidence":"platform-reply-1","platform_evidence_status":"RECEIVED","platform_message_id":"message-2"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"BUILD_EXECUTOR","target_thread_id":"thread-executor-001","target_handle":"target-executor-001","status":"SENT","evidence":"platform-send-2","platform_evidence_status":"RECEIVED","platform_message_id":"message-3"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"boot-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"target-planner-001","status":"RECEIVED_AND_REPLIED","evidence":"platform-reply-2","platform_evidence_status":"RECEIVED","platform_message_id":"message-4"}
'@ | Set-Content -LiteralPath $eventsPath -Encoding utf8

    $bootstrapOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $eventsPath -RoleMapPath $roleMapPath -ExecutionId 'boot-001' | Out-String
    Assert-True ($bootstrapOutput -match 'BOOTSTRAP_COMMUNICATION_STRUCTURALLY_VALID') 'Valid bootstrap communication structure was rejected'

    $badEventsPath = Join-Path $artifactRoot 'RELAY_EVENTS-BAD.jsonl'
    ((Get-Content -Raw -LiteralPath $eventsPath) -replace 'thread-planner-001', 'outer-ignored') | Set-Content -LiteralPath $badEventsPath -Encoding utf8
    $badBootstrapOutput = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-bootstrap.ps1') -Arguments @{ EventsPath = $badEventsPath; RoleMapPath = $roleMapPath; ExecutionId = 'boot-001' }
    Assert-True ($badBootstrapOutput -match 'COMMUNICATION_TARGET_NOT_REGISTERED|THREAD_ID_NOT_REGISTERED|THREAD_TARGET_NOT_REGISTERED|CREATED_THREAD_NOT_REGISTERED|OUTER_TASK_ID') 'Outer task identifier was accepted as a communication target'
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 8 team-first bootstrap contract: PASS'
