[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$ProjectPath = (Get-Location).Path,
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
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$projectItem = Get-Item -LiteralPath $ProjectPath
if (-not $projectItem.PSIsContainer) { throw 'WORKSPACE_NOT_DIRECTORY' }
$project = $projectItem.FullName.TrimEnd('\', '/')
$skillRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if ($project -eq $skillRoot) { throw 'SKILL_REPOSITORY_IS_NOT_A_USER_PROJECT: choose an independent project workspace' }
$targetRoot = Join-Path $project '.ai-governance'
$formal = -not [string]::IsNullOrWhiteSpace($ApprovedSummaryPath)
if ($BootstrapOnly -and $formal) { throw 'BOOTSTRAP_ONLY_CANNOT_USE_APPROVED_SUMMARY' }
$roleMapPath = Join-Path $targetRoot 'ROLE-MAP.md'
$registered = $null
if ((Test-Path -LiteralPath $targetRoot) -and -not (Test-Path -LiteralPath $roleMapPath -PathType Leaf)) {
    if (@(Get-ChildItem -LiteralPath $targetRoot -Force).Count) {
        throw 'ROLE_MAP_RECOVERY_REQUIRED: existing governance records have no role registry; restore its recorded identity before resuming'
    }
}
if (Test-Path -LiteralPath $roleMapPath -PathType Leaf) {
    $registered = Read-RoleMap $roleMapPath
    if ($ProjectId -and $ProjectId -ne $registered.ProjectId) { throw 'PROJECT_IDENTITY_CONFLICT: resume the recorded project or request an explicit migration' }
    if (-not $registered.ProjectPath -or [IO.Path]::GetFullPath($registered.ProjectPath).TrimEnd('\','/') -ne $project) {
        throw 'WORKSPACE_IDENTITY_CONFLICT: the registry belongs to another or unknown workspace; do not silently rebind'
    }
    $ProjectId = $registered.ProjectId
    if (-not (Test-Path -LiteralPath (Join-Path $targetRoot 'RELAY_EVENTS.jsonl') -PathType Leaf)) {
        throw 'RELAY_HISTORY_RECOVERY_REQUIRED: restore the missing event log; initialization must not replace history with an empty log'
    }
    if ($registered.ProjectName) { $ProjectName = $registered.ProjectName }
    if ($registered.ProjectShortName) { $ProjectShortName = $registered.ProjectShortName }
}
if (-not $ProjectName) { $ProjectName = $projectItem.Name }
if (-not $ProjectShortName) { $ProjectShortName = $ProjectName }
if (-not $ProjectId) { $ProjectId = 'project-' + [guid]::NewGuid().ToString('N') }
foreach ($value in @($ProjectId, $ProjectName, $ProjectShortName, $HumanGovernor)) {
    if ($value -match '[\r\n|]' -or $value.Contains('{{')) { throw 'PROJECT_IDENTITY_INVALID: names must be single-line values without table delimiters' }
}

$names = @{
    EXTERNAL_ADVISOR = $ExternalAdvisorDisplayName
    CORE_ARCHITECT = $CoreArchitectDisplayName
    MISSION_PLANNER = $MissionPlannerDisplayName
    BUILD_EXECUTOR = $BuildExecutorDisplayName
}
$defaults = @{ EXTERNAL_ADVISOR='External-Advisor'; CORE_ARCHITECT='Core-Architect'; MISSION_PLANNER='Mission-Planner'; BUILD_EXECUTOR='Build-Executor' }
foreach ($role in @($names.Keys)) {
    if ($null -ne $registered) {
        $entry = @($registered.Rows | Where-Object RoleId -eq $role)
        if ($entry.Count -ne 1) { throw "ROLE_BINDING_MISSING: $role; restore the existing registry before resuming" }
        $names[$role] = $entry[0].DisplayName
    }
    if (-not $names[$role]) { $names[$role] = "$ProjectShortName-$($defaults[$role])" }
    if ($names[$role] -match '[\r\n|]' -or $names[$role].Contains('{{')) { throw "ROLE_DISPLAY_NAME_INVALID: $role" }
}
if (@($names.Values | Select-Object -Unique).Count -ne 4) { throw 'ROLE_DISPLAY_NAME_CONFLICT: choose distinct display names' }

$summaryDestination = Join-Path $targetRoot 'PROJECT-STARTUP-SUMMARY.md'
if ($formal) {
    if (-not (Test-Path -LiteralPath $ApprovedSummaryPath -PathType Leaf)) { throw 'APPROVED_SUMMARY_NOT_FOUND' }
    $summary = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ApprovedSummaryPath), [Text.Encoding]::UTF8)
    if ($summary -notmatch '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -and
        $summary -notmatch '(?im)^\s*用户审查与批准状态\s*[:：]\s*APPROVED\s*$') {
        throw 'APPROVAL_REQUIRED: preserve the summary approved in the real user conversation'
    }
    if (Test-Path -LiteralPath $summaryDestination) {
        if ((Get-FileHash -LiteralPath $summaryDestination).Hash -ne (Get-FileHash -LiteralPath $ApprovedSummaryPath).Hash) {
            throw 'APPROVED_SUMMARY_CONFLICT: explicit Human Governor migration is required'
        }
    }
}

# Prepare every output before writing so a missing package file cannot leave half a skeleton.
$replacements = [ordered]@{
    '{{PROJECT_ID}}'=$ProjectId; '{{PROJECT_NAME}}'=$ProjectName; '{{PROJECT_SHORT_NAME}}'=$ProjectShortName
    '{{WORKSPACE_PATH}}'=$project; '{{HUMAN_GOVERNOR}}'=$HumanGovernor
    '{{EXTERNAL_ADVISOR_DISPLAY_NAME}}'=$names.EXTERNAL_ADVISOR
    '{{CORE_ARCHITECT_DISPLAY_NAME}}'=$names.CORE_ARCHITECT
    '{{MISSION_PLANNER_DISPLAY_NAME}}'=$names.MISSION_PLANNER
    '{{BUILD_EXECUTOR_DISPLAY_NAME}}'=$names.BUILD_EXECUTOR
}
$sources = [ordered]@{
    'CHARTER.md'='governance/CHARTER.template.md'
    'CURRENT_PHASE.md'='governance/CURRENT_PHASE.template.md'
    'CURRENT_MISSION.md'='governance/CURRENT_MISSION.template.md'
    'RELAY_STATE.md'='governance/RELAY_STATE.template.md'
    'RELAY_EVENTS.jsonl'='governance/RELAY_EVENTS.template.jsonl'
    'DECISIONS.md'='governance/DECISIONS.template.md'
    'ARCHITECTURE-NO-GO.md'='governance/ARCHITECTURE-NO-GO.template.md'
    'ROLE-MAP.md'='governance/ROLE-MAP.template.md'
    'START-HERE.md'='governance/START-HERE.template.md'
    'roles/external-advisor.md'='roles/external-advisor.md'
    'roles/core-architect.md'='roles/core-architect.md'
    'roles/mission-planner.md'='roles/mission-planner.md'
    'roles/build-executor.md'='roles/build-executor.md'
}
if ($formal) {
    $sources['PROJECT-INDEX.md']='governance/PROJECT-INDEX.template.md'
    $sources['DEVELOPMENT-RULES.md']='governance/DEVELOPMENT-RULES.template.md'
}
$pending = [ordered]@{}
$skipped = New-Object 'System.Collections.Generic.List[string]'
foreach ($relative in $sources.Keys) {
    $source = Join-Path $skillRoot $sources[$relative]
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing skill template: $source" }
    $destination = Join-Path $targetRoot $relative
    if (Test-Path -LiteralPath $destination) {
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "GOVERNANCE_PATH_CONFLICT: $relative" }
        $skipped.Add($relative); continue
    }
    $text = [IO.File]::ReadAllText($source, [Text.Encoding]::UTF8)
    foreach ($key in $replacements.Keys) { $text = $text.Replace($key, [string]$replacements[$key]) }
    if ($relative -eq 'RELAY_EVENTS.jsonl') { $text = '' }
    $pending[$relative] = [Text.UTF8Encoding]::new($false).GetBytes($text)
}
if ($formal -and -not (Test-Path -LiteralPath $summaryDestination)) {
    $pending['PROJECT-STARTUP-SUMMARY.md'] = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $ApprovedSummaryPath))
}
$created = New-Object 'System.Collections.Generic.List[string]'
foreach ($relative in $pending.Keys) {
    $destination = Join-Path $targetRoot $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    $stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $bytes = $pending[$relative]; $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
    $created.Add($relative)
}
$startupReadiness = 'MANUAL_REQUIRED'
if ($formal -and $BootstrapExecutionId -and $PlatformEvidencePath -and $McpEvidencePath) {
    $readiness = & (Join-Path $PSScriptRoot 'check-startup-readiness.ps1') -RoleMapPath $roleMapPath -EventsPath (Join-Path $targetRoot 'RELAY_EVENTS.jsonl') -ExecutionId $BootstrapExecutionId -PlatformEvidencePath $PlatformEvidencePath -McpEvidencePath $McpEvidencePath -ApprovedSummaryPath $summaryDestination -HumanAuthorizationPath $HumanAuthorizationPath -AsJson | ConvertFrom-Json
    $startupReadiness = $readiness.status
}
Write-Output "Initialized governance at $targetRoot"
if (-not $formal) {
    if ($null -ne $registered) {
        Write-Output "Governance resume: BOOTSTRAP_STATE=$($registered.BootstrapState); existing identity and history preserved; inspect recorded progress before continuing"
    } else {
        Write-Output 'BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT: CURRENT_CONTEXT / REUSE_CURRENT'
        Write-Output 'Team-first bootstrap: BOOTSTRAP_STATE=ACTIVE; EXPECTED_NEW_CODEX_THREADS=2; no Mission, TASK or business-code operation was created'
    }
} else {
    Write-Output 'Project records: APPROVED summary preserved with matching project identity; this is not permission to start development'
    Write-Output "Startup readiness: $startupReadiness; actual platform review and user authorization remain outside this file checker"
}
Write-Output "Created: $($created -join ', ')"
if ($skipped.Count) { Write-Output "Reused existing: $($skipped -join ', ')" }
