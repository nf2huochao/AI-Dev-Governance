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

$templatePath = Join-Path $root 'governance\RELAY_EVENTS.template.jsonl'
Assert-True ([string]::IsNullOrWhiteSpace((Get-Content -Raw -LiteralPath $templatePath)) -or (Get-Item -LiteralPath $templatePath).Length -eq 0) 'Formal RELAY_EVENTS template must start empty'

$artifactRoot = Join-Path $root '.test-artifacts\phase-8-final-correction'
if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
try {
    $roleMapPath = Join-Path $artifactRoot 'ROLE-MAP.md'
    @'
# Role Binding Registry

PROJECT_ID: demo-project
BOOTSTRAP_STATE: ACTIVE
TASK_ID: NOT_ASSIGNED_UNTIL_MISSION
EXECUTION_ID: NOT_ASSIGNED_UNTIL_TASK
OUTER_TASK_ID: outer-ignored

| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| CORE_ARCHITECT | Demo Architect | CURRENT_CONTEXT | REUSE_CURRENT | thread-core-001 | target-core-001 | BOUND |
| MISSION_PLANNER | Demo Planner | CREATED_THREAD | ENSURE | thread-planner-001 | target-planner-001 | BOUND |
| BUILD_EXECUTOR | Demo Executor | CREATED_THREAD | ENSURE | thread-executor-001 | target-executor-001 | BOUND |
'@ | Set-Content -LiteralPath $roleMapPath -Encoding utf8

    $eventsPath = Join-Path $artifactRoot 'RELAY_EVENTS.jsonl'
    @'
{"event":"DISPATCH","project_id":"demo-project","execution_id":"old-exec","task_id":"old-task","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"BUILD_EXECUTOR","target_thread_id":"thread-executor-001","target_handle":"target-executor-001","status":"SENT","evidence":"old-event"}
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"platform-create-planner"}
{"event":"ROLE_THREAD_CREATED","project_id":"demo-project","execution_id":"boot-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"platform-create-executor"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"boot-001","role_id":"CORE_ARCHITECT","thread_id":"thread-core-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"target-planner-001","status":"SENT","evidence":"platform-send-1","platform_evidence_status":"RECEIVED","platform_message_id":"message-1"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"CORE_ARCHITECT","target_thread_id":"thread-core-001","target_handle":"target-core-001","status":"RECEIVED_AND_REPLIED","evidence":"platform-reply-1","platform_evidence_status":"RECEIVED","platform_message_id":"message-2"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo-project","execution_id":"boot-001","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","target_role_id":"BUILD_EXECUTOR","target_thread_id":"thread-executor-001","target_handle":"target-executor-001","status":"SENT","evidence":"platform-send-2","platform_evidence_status":"RECEIVED","platform_message_id":"message-3"}
{"event":"BOOTSTRAP_ACK","project_id":"demo-project","execution_id":"boot-001","role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","target_role_id":"MISSION_PLANNER","target_thread_id":"thread-planner-001","target_handle":"target-planner-001","status":"RECEIVED_AND_REPLIED","evidence":"platform-reply-2","platform_evidence_status":"RECEIVED","platform_message_id":"message-4"}
{"event":"PASS","project_id":"demo-project","execution_id":"old-exec","task_id":"old-task","role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","status":"PASS","evidence":"old-event"}
'@ | Set-Content -LiteralPath $eventsPath -Encoding utf8

    $bootstrapOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $eventsPath -RoleMapPath $roleMapPath -ExecutionId 'boot-001' | Out-String
    Assert-True ($bootstrapOutput -match 'BOOTSTRAP_COMMUNICATION_STRUCTURALLY_VALID') 'Bootstrap checker must validate the selected execution inside a historical event log'

    $eventsWithoutOptionalMessageFieldsPath = Join-Path $artifactRoot 'RELAY_EVENTS-NO-OPTIONAL-MESSAGE-FIELDS.jsonl'
    ((Get-Content -Raw -LiteralPath $eventsPath) -replace ',"platform_message_id":"message-[1-4]"', '' -replace ',"platform_evidence_status":"RECEIVED"', '') | Set-Content -LiteralPath $eventsWithoutOptionalMessageFieldsPath -Encoding utf8
    $messageCompatibleOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $eventsWithoutOptionalMessageFieldsPath -RoleMapPath $roleMapPath -ExecutionId 'boot-001' | Out-String
    Assert-True ($messageCompatibleOutput -match 'BOOTSTRAP_COMMUNICATION_STRUCTURALLY_VALID') 'Bootstrap checker must not require platform message fields that the platform does not provide'

    $approvedSummary = Join-Path $artifactRoot 'APPROVED-SUMMARY.md'
    @'
# Startup Summary

Approval Status: APPROVED
'@ | Set-Content -LiteralPath $approvedSummary -Encoding utf8

    $manualPlatformEvidence = Join-Path $artifactRoot 'MANUALLY-WRITTEN-PLATFORM-EVIDENCE.json'
    @'
{"source":"codex_native_message","verification_status":"VERIFIED_BY_PLATFORM","project_id":"demo-project","execution_id":"boot-001","roles":[{"role_id":"CORE_ARCHITECT","thread_id":"thread-core-001","communication_target_handle":"target-core-001","identity_evidence":"codex-thread-read-001","target_evidence":"codex-send-result-001","wake_evidence":"codex-reply-read-001"},{"role_id":"MISSION_PLANNER","thread_id":"thread-planner-001","communication_target_handle":"target-planner-001","identity_evidence":"codex-thread-read-002","target_evidence":"codex-send-result-002","wake_evidence":"codex-reply-read-002"},{"role_id":"BUILD_EXECUTOR","thread_id":"thread-executor-001","communication_target_handle":"target-executor-001","identity_evidence":"codex-thread-read-003","target_evidence":"codex-send-result-003","wake_evidence":"codex-reply-read-003"}]}
'@ | Set-Content -LiteralPath $manualPlatformEvidence -Encoding utf8
    $mcpEvidence = Join-Path $artifactRoot 'MCP-EVIDENCE.txt'
    @'
MCP_TARGET_MATCH: PASS
MCP_PLATFORM_EVIDENCE: VERIFIED
'@ | Set-Content -LiteralPath $mcpEvidence -Encoding utf8
    $manualEvidenceOutput = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-startup-readiness.ps1') -Arguments @{
        RoleMapPath = $roleMapPath
        EventsPath = $eventsPath
        ExecutionId = 'boot-001'
        PlatformEvidencePath = $manualPlatformEvidence
        McpEvidencePath = $mcpEvidence
        ApprovedSummaryPath = $approvedSummary
    }
    Assert-True ([bool]($manualEvidenceOutput -match 'PLATFORM_EVIDENCE_ORIGIN_UNVERIFIABLE|MANUAL_REQUIRED|RAW_PLATFORM_EVIDENCE_REQUIRED')) 'Manually written platform evidence was accepted as authenticated'

    $missingApprovalOutput = Invoke-ExpectedFailure -ScriptPath (Join-Path $root 'scripts\check-startup-readiness.ps1') -Arguments @{
        RoleMapPath = $roleMapPath
        EventsPath = $eventsPath
        ExecutionId = 'boot-001'
        PlatformEvidencePath = $manualPlatformEvidence
        McpEvidencePath = $mcpEvidence
    }
    Assert-True ([bool]($missingApprovalOutput -match 'APPROVED_SUMMARY_REQUIRED|APPROVAL_REQUIRED')) 'Standalone startup readiness check allowed the approval path to be omitted'

    $formalProject = Join-Path $artifactRoot 'formal-project'
    New-Item -ItemType Directory -Path $formalProject -Force | Out-Null
    $initOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\init-governance.ps1') `
        -ProjectPath $formalProject `
        -ApprovedSummaryPath $approvedSummary `
        -ProjectId 'demo-project' `
        -ProjectName 'Demo Project' `
        -ProjectShortName 'demo' | Out-String
    Assert-True ([bool]($initOutput -match 'Startup readiness: MANUAL_REQUIRED')) 'Formal startup must not be marked ready without platform evidence'
    Assert-True ([bool]($initOutput -notmatch 'Formal project initialization:')) 'Formal startup must not report readiness before the preflight gate passes'
    Assert-True ((Get-Item -LiteralPath (Join-Path $formalProject '.ai-governance\RELAY_EVENTS.jsonl')).Length -eq 0) 'Formal initialization must create an empty event log'
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 8 final correction contract: PASS'
