[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path,

    [string]$ApprovedSummaryPath = '',
    [switch]$BootstrapOnly,
    [string]$ProjectId = '',
    [string]$ProjectName = '',
    [string]$ProjectShortName = '',
    [string]$HumanGovernor = 'Human Governor',
    [string]$ExternalAdvisorDisplayName = '',
    [string]$CoreArchitectDisplayName = '',
    [string]$MissionPlannerDisplayName = '',
    [string]$BuildExecutorDisplayName = '',
    [string]$BootstrapExecutionId = '',
    [string]$PlatformEvidencePath = '',
    [string]$McpEvidencePath = '',
    [string]$HumanAuthorizationPath = ''
)

$ErrorActionPreference = 'Stop'

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$skillRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$targetRoot = Join-Path $project '.ai-governance'
$formalInitialization = -not [string]::IsNullOrWhiteSpace($ApprovedSummaryPath)

if ($BootstrapOnly -and $formalInitialization) {
    throw 'BOOTSTRAP_ONLY_CANNOT_USE_APPROVED_SUMMARY: run formal initialization only after bootstrap communication passes'
}
if (($BootstrapOnly -or $formalInitialization) -and ([string]::IsNullOrWhiteSpace($ProjectName) -or [string]::IsNullOrWhiteSpace($ProjectShortName))) {
    throw 'PROJECT_IDENTITY_REQUIRED: provide ProjectName and ProjectShortName for team bootstrap or formal initialization'
}
if ([string]::IsNullOrWhiteSpace($ProjectId)) { $ProjectId = $ProjectShortName }

if ($formalInitialization) {
    if (-not (Test-Path -LiteralPath $ApprovedSummaryPath)) {
        throw "APPROVED_SUMMARY_NOT_FOUND: $ApprovedSummaryPath"
    }
    if ([string]::IsNullOrWhiteSpace($ProjectName) -or [string]::IsNullOrWhiteSpace($ProjectShortName)) {
        throw 'FORMAL_INIT_REQUIRES_PROJECT_IDENTITY: provide ProjectName and ProjectShortName'
    }

    $approvedSummary = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ApprovedSummaryPath), [Text.Encoding]::UTF8)
    if ($approvedSummary -notmatch '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -and $approvedSummary -notmatch '(?im)^\s*\u7528\u6237\u5ba1\u67e5\u4e0e\u6279\u51c6\u72b6\u6001\s*[:\uFF1A]\s*APPROVED\s*$') {
        throw 'APPROVAL_REQUIRED: the original startup summary must contain Approval Status: APPROVED after user review'
    }

    if ([string]::IsNullOrWhiteSpace($ExternalAdvisorDisplayName)) { $ExternalAdvisorDisplayName = "$ProjectShortName-External-Advisor" }
    if ([string]::IsNullOrWhiteSpace($CoreArchitectDisplayName)) { $CoreArchitectDisplayName = "$ProjectShortName-Core-Architect" }
    if ([string]::IsNullOrWhiteSpace($MissionPlannerDisplayName)) { $MissionPlannerDisplayName = "$ProjectShortName-Mission-Planner" }
    if ([string]::IsNullOrWhiteSpace($BuildExecutorDisplayName)) { $BuildExecutorDisplayName = "$ProjectShortName-Build-Executor" }
}

if ($BootstrapOnly) {
    if ([string]::IsNullOrWhiteSpace($ExternalAdvisorDisplayName)) { $ExternalAdvisorDisplayName = "$ProjectShortName-External-Advisor" }
    if ([string]::IsNullOrWhiteSpace($CoreArchitectDisplayName)) { $CoreArchitectDisplayName = "$ProjectShortName-Core-Architect" }
    if ([string]::IsNullOrWhiteSpace($MissionPlannerDisplayName)) { $MissionPlannerDisplayName = "$ProjectShortName-Mission-Planner" }
    if ([string]::IsNullOrWhiteSpace($BuildExecutorDisplayName)) { $BuildExecutorDisplayName = "$ProjectShortName-Build-Executor" }
}

# Preflight existing project identity and approved baseline before writing anything.
if (($BootstrapOnly -or $formalInitialization) -and (Test-Path -LiteralPath $targetRoot)) {
    $existingRoleMap = Join-Path $targetRoot 'ROLE-MAP.md'
    if (Test-Path -LiteralPath $existingRoleMap -PathType Leaf) {
        . (Join-Path $PSScriptRoot 'role-map-parser.ps1')
        $registered = Read-RoleMap -Path $existingRoleMap
        if (-not [string]::IsNullOrWhiteSpace($registered.ProjectId) -and $registered.ProjectId -ne $ProjectId) {
            throw "PROJECT_IDENTITY_CONFLICT: existing PROJECT_ID=$($registered.ProjectId); requested PROJECT_ID=$ProjectId"
        }
    }
}
if ($formalInitialization) {
    $existingSummary = Join-Path $targetRoot 'PROJECT-STARTUP-SUMMARY.md'
    if (Test-Path -LiteralPath $existingSummary -PathType Leaf) {
        $existingHash = (Get-FileHash -LiteralPath $existingSummary -Algorithm SHA256).Hash
        $requestedHash = (Get-FileHash -LiteralPath $ApprovedSummaryPath -Algorithm SHA256).Hash
        if ($existingHash -ne $requestedHash) {
            throw "APPROVED_SUMMARY_CONFLICT: existing and requested approved summaries differ; explicit Human Governor migration is required"
        }
        $existingText = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $existingSummary), [Text.Encoding]::UTF8)
        if ($existingText -notmatch '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -and $existingText -notmatch '(?im)^\s*用户审查与批准状态\s*[:：]\s*APPROVED\s*$') {
            throw 'EXISTING_SUMMARY_NOT_APPROVED: an existing DRAFT cannot be treated as the approved baseline'
        }
    }
}

New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

$templateMap = [ordered]@{
    'CHARTER.template.md' = 'CHARTER.md'
    'CURRENT_PHASE.template.md' = 'CURRENT_PHASE.md'
    'CURRENT_MISSION.template.md' = 'CURRENT_MISSION.md'
    'RELAY_STATE.template.md' = 'RELAY_STATE.md'
    'RELAY_EVENTS.template.jsonl' = 'RELAY_EVENTS.jsonl'
    'DECISIONS.template.md' = 'DECISIONS.md'
    'ARCHITECTURE-NO-GO.template.md' = 'ARCHITECTURE-NO-GO.md'
}

$created = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
foreach ($sourceName in $templateMap.Keys) {
    $source = Join-Path $skillRoot "governance\$sourceName"
    $destination = Join-Path $targetRoot $templateMap[$sourceName]
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing skill template: $source" }
    if (Test-Path -LiteralPath $destination) {
        $skipped.Add($templateMap[$sourceName])
        continue
    }
    Copy-Item -LiteralPath $source -Destination $destination
    $created.Add($templateMap[$sourceName])
}

$rolesTarget = Join-Path $targetRoot 'roles'
New-Item -ItemType Directory -Path $rolesTarget -Force | Out-Null
foreach ($roleName in @('external-advisor.md', 'core-architect.md', 'mission-planner.md', 'build-executor.md')) {
    $source = Join-Path $skillRoot "roles\$roleName"
    $destination = Join-Path $rolesTarget $roleName
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing role prompt: $source" }
    if (Test-Path -LiteralPath $destination) {
        $skipped.Add("roles/$roleName")
        continue
    }
    Copy-Item -LiteralPath $source -Destination $destination
    $created.Add("roles/$roleName")
}

$startHere = Join-Path $targetRoot 'START-HERE.md'
if (-not (Test-Path -LiteralPath $startHere)) {
    if ($formalInitialization) {
        $text = @"
# AI Governance Project Ready

1. BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT: this original Codex conversation is the only `CORE_ARCHITECT` and uses CURRENT_CONTEXT / REUSE_CURRENT. Never create another one.
2. EXPECTED_NEW_CODEX_THREADS = 2. Before every native create_thread call, run `guard-role-creation.ps1`; only Mission Planner and Build Executor may pass.
3. Confirm real project/thread identities and native communication target handles, then run `check-role-bindings.ps1`; this is structural only.
4. Complete Core Architect -> Mission Planner and Mission Planner -> Build Executor `BOOTSTRAP_HELLO/BOOTSTRAP_ACK` checks.
5. Run `check-bootstrap.ps1` with the real bootstrap `EXECUTION_ID`; a failure is `MANUAL_REQUIRED` / `CAPABILITY GAP`, not a reason to retry blindly. Historical events remain in the append-only log.
6. Only after bootstrap passes may the External Advisor ChatGPT conversation be created for project planning.
7. The approved startup summary must be returned to this original Core Architect conversation before formal project initialization.
8. Confirm External Advisor MCP target and capability; a missing or wrong target is a capability gap, not a PASS.
9. Run `check-startup-readiness.ps1` with preserved native platform and MCP records. Without a Human Governor receipt it remains `MANUAL_REQUIRED`; a hash-bound `HUMAN_VERIFIED` receipt may authorize startup but never becomes platform attestation.

Normal relay uses SEND -> YIELD -> WAKE -> ACT. Do not poll role threads.
"@
    } else {
        $text = @"
# AI Governance Project Setup

1. Fill the placeholders in CHARTER.md, CURRENT_PHASE.md and CURRENT_MISSION.md.
2. Run team bootstrap with the current Codex conversation as the only Core Architect.
3. Bind this original conversation as Core Architect with CURRENT_CONTEXT / REUSE_CURRENT. Create exactly one Mission Planner and one Build Executor through `guard-role-creation.ps1`, then verify ROLE-MAP.md.
4. Complete both `BOOTSTRAP_HELLO -> BOOTSTRAP_ACK` checks before any Mission or TASK.
5. Create the External Advisor planning conversation only after bootstrap passes.
6. Return the approved summary to the original Core Architect, then run formal initialization.
7. Ask Mission Planner to dispatch the first TASK only after the startup checklist passes.
8. Let Build Executor implement, test, commit and hand off; Mission Planner performs Review.
9. Keep RELAY_STATE.md and RELAY_EVENTS.jsonl current. The event log starts empty; never copy the example JSONL into it.

Run the skill repository scripts validate-governance.ps1 and check-relay.ps1 against this project when needed.
"@
    }
    [System.IO.File]::WriteAllText($startHere, $text, (New-Object System.Text.UTF8Encoding($false)))
    $created.Add('START-HERE.md')
} else {
    $skipped.Add('START-HERE.md')
}

if ($BootstrapOnly -or $formalInitialization) {
    $roleMapDestination = Join-Path $targetRoot 'ROLE-MAP.md'
    if (Test-Path -LiteralPath $roleMapDestination) {
        $skipped.Add('ROLE-MAP.md')
    } else {
        $roleMapSource = Join-Path $skillRoot 'governance\ROLE-MAP.template.md'
        if (-not (Test-Path -LiteralPath $roleMapSource)) { throw "Missing skill template: $roleMapSource" }
        $roleMapText = [System.IO.File]::ReadAllText($roleMapSource, (New-Object System.Text.UTF8Encoding($false)))
        $roleMapReplacements = [ordered]@{
            '{{PROJECT_ID}}' = $ProjectId
            '{{WORKSPACE_PATH}}' = $project
            '{{EXTERNAL_ADVISOR_DISPLAY_NAME}}' = $ExternalAdvisorDisplayName
            '{{CORE_ARCHITECT_DISPLAY_NAME}}' = $CoreArchitectDisplayName
            '{{MISSION_PLANNER_DISPLAY_NAME}}' = $MissionPlannerDisplayName
            '{{BUILD_EXECUTOR_DISPLAY_NAME}}' = $BuildExecutorDisplayName
        }
        foreach ($placeholder in $roleMapReplacements.Keys) {
            $roleMapText = $roleMapText.Replace($placeholder, [string]$roleMapReplacements[$placeholder])
        }
        [System.IO.File]::WriteAllText($roleMapDestination, $roleMapText, (New-Object System.Text.UTF8Encoding($false)))
        $created.Add('ROLE-MAP.md')
    }
}

if ($formalInitialization) {
    $summaryDestination = Join-Path $targetRoot 'PROJECT-STARTUP-SUMMARY.md'
    if (Test-Path -LiteralPath $summaryDestination) {
        $skipped.Add('PROJECT-STARTUP-SUMMARY.md')
    } else {
        Copy-Item -LiteralPath $ApprovedSummaryPath -Destination $summaryDestination
        $created.Add('PROJECT-STARTUP-SUMMARY.md')
    }

    $replacementMap = [ordered]@{
        '{{PROJECT_NAME}}' = $ProjectName
        '{{PROJECT_SHORT_NAME}}' = $ProjectShortName
        '{{PROJECT_ID}}' = $ProjectId
        '{{WORKSPACE_PATH}}' = $project
        '{{HUMAN_GOVERNOR}}' = $HumanGovernor
        '{{EXTERNAL_ADVISOR_DISPLAY_NAME}}' = $ExternalAdvisorDisplayName
        '{{CORE_ARCHITECT_DISPLAY_NAME}}' = $CoreArchitectDisplayName
        '{{MISSION_PLANNER_DISPLAY_NAME}}' = $MissionPlannerDisplayName
        '{{BUILD_EXECUTOR_DISPLAY_NAME}}' = $BuildExecutorDisplayName
    }

    $generatedTemplates = [ordered]@{
        'PROJECT-INDEX.template.md' = 'PROJECT-INDEX.md'
        'DEVELOPMENT-RULES.template.md' = 'DEVELOPMENT-RULES.md'
        'ROLE-MAP.template.md' = 'ROLE-MAP.md'
    }

    foreach ($sourceName in $generatedTemplates.Keys) {
        $source = Join-Path $skillRoot "governance\$sourceName"
        $destinationName = $generatedTemplates[$sourceName]
        $destination = Join-Path $targetRoot $destinationName
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing skill template: $source" }
        if (Test-Path -LiteralPath $destination) {
            $skipped.Add($destinationName)
            continue
        }
        $generated = [System.IO.File]::ReadAllText($source, (New-Object System.Text.UTF8Encoding($false)))
        foreach ($placeholder in $replacementMap.Keys) {
            $generated = $generated.Replace($placeholder, [string]$replacementMap[$placeholder])
        }
        [System.IO.File]::WriteAllText($destination, $generated, (New-Object System.Text.UTF8Encoding($false)))
        $created.Add($destinationName)
    }
}

$startupReadiness = 'NOT_APPLICABLE'
if ($formalInitialization) {
    $startupReadiness = 'MANUAL_REQUIRED'
    $roleMapForReadiness = Join-Path $targetRoot 'ROLE-MAP.md'
    $eventsForReadiness = Join-Path $targetRoot 'RELAY_EVENTS.jsonl'
    if (-not [string]::IsNullOrWhiteSpace($BootstrapExecutionId) -and -not [string]::IsNullOrWhiteSpace($PlatformEvidencePath) -and -not [string]::IsNullOrWhiteSpace($McpEvidencePath)) {
        $readinessOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-startup-readiness.ps1') `
            -RoleMapPath $roleMapForReadiness `
            -EventsPath $eventsForReadiness `
            -ExecutionId $BootstrapExecutionId `
            -PlatformEvidencePath $PlatformEvidencePath `
            -McpEvidencePath $McpEvidencePath `
            -HumanAuthorizationPath $HumanAuthorizationPath `
            -ApprovedSummaryPath (Join-Path $targetRoot 'PROJECT-STARTUP-SUMMARY.md') 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            if ($readinessOutput -match 'PLATFORM_EVIDENCE_ORIGIN_UNVERIFIABLE|MANUAL_REQUIRED') {
                $startupReadiness = 'MANUAL_REQUIRED'
            } else {
                throw "STARTUP_PREREQUISITES_NOT_MET: $($readinessOutput.Trim())"
            }
        } else {
            $startupReadiness = 'PASS'
        }
    }
}

Write-Output "Initialized governance at $targetRoot"
if ($BootstrapOnly) {
    Write-Output 'BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT: CURRENT_CONTEXT / REUSE_CURRENT'
    Write-Output 'Team-first bootstrap: BOOTSTRAP_STATE=ACTIVE; EXPECTED_NEW_CODEX_THREADS=2; no Mission, TASK or business-code operation was created'
}
if ($formalInitialization) {
    Write-Output "Project records: APPROVED summary hash matched or was preserved; generated without overwriting existing files"
    Write-Output "Startup readiness: $startupReadiness; no first Mission may be published until deterministic checks and a bound Human Governor authorization pass"
}
Write-Output "Created: $($created -join ', ')"
if ($skipped.Count -gt 0) { Write-Output "Skipped existing: $($skipped -join ', ')" }
