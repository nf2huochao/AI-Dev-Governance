$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$artifactRoot = Join-Path $root 'tests\.artifacts\phase-8-first-use-onboarding'
$workspace = Join-Path $artifactRoot 'approved-project'
$existingWorkspace = Join-Path $artifactRoot 'existing-project'
$missingWorkspace = Join-Path $artifactRoot 'missing-project'
$summary = Join-Path $artifactRoot 'PROJECT-STARTUP-SUMMARY.md'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-ExpectedFailure {
    param([string]$ScriptPath, [hashtable]$Arguments)
    $nativeArguments = @()
    foreach ($key in $Arguments.Keys) { $nativeArguments += "-$key"; $nativeArguments += [string]$Arguments[$key] }
    $previous = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $output = & (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @nativeArguments 2>&1 | Out-String; $code = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
    if ($code -eq 0) { throw "Expected failure from $ScriptPath, but it completed successfully" }
    return $output
}

if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null

try {
    $workspaceCheck = Join-Path $root 'scripts\check-workspace.ps1'
    $mcpCheck = Join-Path $root 'scripts\check-mcp-target.ps1'
    $init = Join-Path $root 'scripts\init-governance.ps1'
    $validate = Join-Path $root 'scripts\validate-governance.ps1'
    $relayCheck = Join-Path $root 'scripts\check-relay.ps1'
    $onboarding = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'docs\FIRST-USE-ONBOARDING.zh-CN.md')

    # A. A missing path is reported and no directory is created.
    $missingOutput = Invoke-ExpectedFailure -ScriptPath $workspaceCheck -Arguments @{ ProjectPath = $missingWorkspace }
    Assert-True ($missingOutput -match 'WORKSPACE_NOT_FOUND') 'A: missing workspace was not reported'
    Assert-True (-not (Test-Path -LiteralPath $missingWorkspace)) 'A: missing workspace was created unexpectedly'
    Write-Output 'A missing workspace: PASS'

    # B. An existing non-empty path is reported for user confirmation.
    New-Item -ItemType Directory -Path $existingWorkspace -Force | Out-Null
    'existing project marker' | Set-Content -LiteralPath (Join-Path $existingWorkspace 'README.md') -Encoding utf8
    $existingOutput = & $workspaceCheck -ProjectPath $existingWorkspace | Out-String
    Assert-True ($existingOutput -match 'NON_EMPTY') 'B: non-empty workspace was not reported'
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $existingWorkspace 'README.md')) -match 'existing project marker') 'B: existing workspace was modified'
    Write-Output 'B existing non-empty workspace: PASS'

    # C. A draft summary cannot start formal initialization.
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null
    $draft = @"
# PROJECT STARTUP SUMMARY
Approval Status: DRAFT
Project Name: Draft Only
"@
    $draft | Set-Content -LiteralPath $summary -Encoding utf8
    $draftOutput = Invoke-ExpectedFailure -ScriptPath $init -Arguments @{
        ProjectPath = $workspace
        ApprovedSummaryPath = $summary
        ProjectName = 'Draft Only'
        ProjectShortName = 'draft'
    }
    Assert-True ($draftOutput -match 'APPROVAL_REQUIRED') 'C: unapproved summary was accepted'
    Write-Output 'C unapproved summary gate: PASS'

    # D/E/J. Approved initialization preserves the source summary, writes project records,
    # maps custom display names, and is safe to rerun without overwriting existing files.
    $approved = @"
# PROJECT STARTUP SUMMARY

Approval Status: APPROVED
Approved By: Human Governor Test
Approved At: 2026-09-21
Project Name: First Use Test Project
Project Short Name: fut
Overall Goal: Verify first-use onboarding.
Target Users: Test users.
First Version Scope: Initialization and evidence checks.
First Version Out of Scope: Production deployment.
Acceptance Standard: A local regression verifies the onboarding gates.
Undecided Items: Real platform communication requires manual verification.
"@
    $approved | Set-Content -LiteralPath $summary -Encoding utf8
    $initOutput = & $init -ProjectPath $workspace -ApprovedSummaryPath $summary -ProjectName 'First Use Test Project' -ProjectShortName 'fut' -HumanGovernor 'Human Governor Test' -ExternalAdvisorDisplayName 'fut-advisor' -CoreArchitectDisplayName 'fut-architect' -MissionPlannerDisplayName 'fut-planner' -BuildExecutorDisplayName 'fut-executor' | Out-String
    Assert-True ($initOutput -match 'Project records:' -and $initOutput -match 'Startup readiness: MANUAL_REQUIRED') 'D: formal initialization did not preserve records while blocking readiness'
    $governance = Join-Path $workspace '.ai-governance'
    $validationOutput = & $validate -ProjectPath $workspace | Out-String
    Assert-True ($validationOutput -match 'Governance validation: PASS') 'D: initialized governance failed structural validation'
    foreach ($required in @('PROJECT-STARTUP-SUMMARY.md','PROJECT-INDEX.md','DEVELOPMENT-RULES.md','ROLE-MAP.md','roles\core-architect.md','roles\mission-planner.md','roles\build-executor.md')) {
        Assert-True (Test-Path -LiteralPath (Join-Path $governance $required)) "D: missing initialized file $required"
    }
    Assert-True ((Get-FileHash -LiteralPath $summary).Hash -eq (Get-FileHash -LiteralPath (Join-Path $governance 'PROJECT-STARTUP-SUMMARY.md')).Hash) 'D: approved summary was rewritten instead of copied'
    $roleMap = Get-Content -Raw -LiteralPath (Join-Path $governance 'ROLE-MAP.md')
    Assert-True ($roleMap -match 'fut-advisor' -and $roleMap -match 'EXTERNAL_ADVISOR') 'E: External Advisor display/internal mapping missing'
    Assert-True ($roleMap -match 'fut-executor' -and $roleMap -match 'BUILD_EXECUTOR') 'E: Build Executor display/internal mapping missing'
    $executorBefore = Get-FileHash -LiteralPath (Join-Path $governance 'roles\build-executor.md')
    $summaryBefore = Get-FileHash -LiteralPath (Join-Path $governance 'PROJECT-STARTUP-SUMMARY.md')
    $approvedChanged = $approved + "`nChanged after first init for idempotence check.`n"
    $approvedChanged | Set-Content -LiteralPath $summary -Encoding utf8
    $conflictOutput = Invoke-ExpectedFailure -ScriptPath $init -Arguments @{ ProjectPath=$workspace; ApprovedSummaryPath=$summary; ProjectName='First Use Test Project'; ProjectShortName='fut'; HumanGovernor='Human Governor Test'; ExternalAdvisorDisplayName='fut-advisor'; CoreArchitectDisplayName='fut-architect'; MissionPlannerDisplayName='fut-planner'; BuildExecutorDisplayName='fut-executor' }
    Assert-True ($conflictOutput -match 'APPROVED_SUMMARY_CONFLICT') 'J: changed approved summary did not fail closed'
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $governance 'PROJECT-STARTUP-SUMMARY.md')).Hash -eq $summaryBefore.Hash) 'J: rerun overwrote the original approved summary'
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $governance 'roles\build-executor.md')).Hash -eq $executorBefore.Hash) 'J: rerun overwrote an existing role prompt'
    Write-Output 'D approved project records: PASS'
    Write-Output 'E custom display names with fixed internal IDs: PASS'
    Write-Output 'J interrupted/idempotent recovery: PASS'

    # F. Real independent Codex thread communication is a platform/manual gate, not a local simulation.
    Assert-True ($onboarding -match 'MANUAL_REQUIRED' -and $onboarding -match '不能用脚本通过替代') 'F: onboarding docs do not disclose manual real-thread verification'
    Write-Output 'F real independent Codex conversations: MANUAL_REQUIRED (not simulated)'

    # G/H. MCP checks compare an observed platform target; they do not claim a connection.
    $wrongMcp = Invoke-ExpectedFailure -ScriptPath $mcpCheck -Arguments @{ ExpectedProjectPath = $workspace; ObservedProjectPath = $existingWorkspace }
    Assert-True ($wrongMcp -match 'MCP_TARGET_MISMATCH') 'G: wrong MCP target was not detected'
    $missingMcp = Invoke-ExpectedFailure -ScriptPath $mcpCheck -Arguments @{ ExpectedProjectPath = $workspace }
    Assert-True ($missingMcp -match 'MCP_CAPABILITY_GAP') 'H: missing MCP observation was not reported as a capability gap'
    $rightMcp = & $mcpCheck -ExpectedProjectPath $workspace -ObservedProjectPath $workspace | Out-String
    Assert-True ($rightMcp -match 'MCP_TARGET_MATCH') 'G: matching observed MCP target was not accepted'
    Write-Output 'G MCP wrong-target detection: PASS'
    Write-Output 'H MCP unavailable capability gap: PASS'

    # I. Existing relay validation remains compatible; this is structural evidence only,
    # never proof of real independent conversations.
    $events = @(
        '{"event":"DISPATCH","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"mission-planner","status":"DISPATCH"}',
        '{"event":"ACK","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"build-executor","status":"ACK"}',
        '{"event":"WORKING","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"build-executor","status":"WORKING"}',
        '{"event":"HANDOFF","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"build-executor","status":"HANDOFF"}',
        '{"event":"REVIEW","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"mission-planner","status":"REVIEW"}',
        '{"event":"PASS","project_id":"fut","mission_id":"M1","task_id":"TASK-ONBOARD-001","execution_id":"E1","actor":"mission-planner","status":"PASS"}'
    )
    $events | Set-Content -LiteralPath (Join-Path $governance 'RELAY_EVENTS.jsonl') -Encoding ascii
    $relayOutput = & $relayCheck -ProjectPath $workspace | Out-String
    Assert-True ($relayOutput -match 'Relay validation: PASS') 'I: relay validation failed for the onboarding fixture'
    Assert-True ($onboarding -match '普通接力不用你复制消息') 'I: onboarding docs do not explain routine relay does not need manual copying'
    Write-Output 'I relay continuation structure: PASS (not real multi-chat proof)'

    Write-Output 'Phase 8 first-use onboarding regression: PASS'
}
finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}
