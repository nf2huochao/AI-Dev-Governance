[CmdletBinding()]
param(
    [string]$SourcePath = '',
    [string]$TargetPath = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
} else {
    $SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = Join-Path $env:USERPROFILE '.codex\skills\ai-dev-governance-v0.1.0-beta.1'
}

if (Test-Path -LiteralPath $TargetPath) {
    throw "Target already exists; no files were overwritten: $TargetPath"
}

$runtimeFiles = @(
    'SKILL.md',
    'README.md',
    'SPEC-V0.1.md',
    'LICENSE',
    'roles',
    'protocols',
    'governance',
    'scripts',
    'docs\FIRST-USE-ONBOARDING.zh-CN.md',
    'docs\PROJECT-PLANNING-PROMPT.zh-CN.md',
    'docs\MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md',
    'docs\FAILURE-RECOVERY.zh-CN.md'
)

foreach ($relativePath in $runtimeFiles) {
    $sourceItem = Join-Path $SourcePath $relativePath
    if (-not (Test-Path -LiteralPath $sourceItem)) {
        throw "Required Skill file is missing: $relativePath"
    }
}

New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null

foreach ($relativePath in $runtimeFiles) {
    $sourceItem = Join-Path $SourcePath $relativePath
    $relativeParent = Split-Path -Parent $relativePath
    $destinationParent = if ([string]::IsNullOrWhiteSpace($relativeParent)) { $TargetPath } else { Join-Path $TargetPath $relativeParent }
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    Copy-Item -LiteralPath $sourceItem -Destination $destinationParent -Recurse
}

$requiredInstalledFiles = @(
    'SKILL.md',
    'roles\core-architect.md',
    'roles\mission-planner.md',
    'roles\build-executor.md',
    'roles\external-advisor.md',
    'docs\FIRST-USE-ONBOARDING.zh-CN.md',
    'scripts\init-governance.ps1'
)
foreach ($relativePath in $requiredInstalledFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $TargetPath $relativePath))) {
        throw "Installed Skill is incomplete: $relativePath"
    }
}

$forbiddenInstalledPaths = @('.git', 'tests', '.test-artifacts', 'PHASE-8-FIRST-USE-TEST-DELIVERY-REPORT.md', 'LOCAL-FIRST-USE-TEST-INSTALLATION-INSTRUCTIONS.md')
foreach ($relativePath in $forbiddenInstalledPaths) {
    if (Test-Path -LiteralPath (Join-Path $TargetPath $relativePath)) {
        throw "Forbidden development file was packaged: $relativePath"
    }
}

Write-Output "Local Skill installation: PASS"
Write-Output "Installed to: $TargetPath"
Write-Output "Entry point: $(Join-Path $TargetPath 'SKILL.md')"
