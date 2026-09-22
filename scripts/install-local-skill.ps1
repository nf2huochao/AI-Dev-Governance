[CmdletBinding()]
param(
    [string]$SourcePath = '',
    [string]$TargetPath = '',
    [string[]]$DiscoveryRoots = @()
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
} else {
    $SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = Join-Path $env:USERPROFILE '.agents\skills\ai-dev-governance'
}

if (Test-Path -LiteralPath $TargetPath) {
    throw "Target already exists; no files were overwritten: $TargetPath"
}

# Codex versions may discover user Skills from either location. Fail closed on
# duplicate frontmatter names instead of installing a second selectable copy.
if ($DiscoveryRoots.Count -eq 0) {
    $DiscoveryRoots = @((Join-Path $env:USERPROFILE '.agents\skills'), (Join-Path $env:USERPROFILE '.codex\skills'))
}
$duplicates = New-Object System.Collections.Generic.List[string]
foreach ($root in $DiscoveryRoots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    foreach ($entry in Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $entry.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { continue }
        $manifestText = [IO.File]::ReadAllText($manifest, [Text.Encoding]::UTF8)
        if ($manifestText -match '(?im)^name:\s*ai-dev-governance\s*$') { $duplicates.Add($entry.FullName) }
    }
}
if ($duplicates.Count -gt 0) {
    throw "DUPLICATE_SKILL_NAME: ai-dev-governance is already installed at: $($duplicates -join '; '). Back up or remove the old copy explicitly; nothing was overwritten."
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

$targetParent = Split-Path -Parent $TargetPath
New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
$stagingPath = Join-Path $targetParent ('.ai-dev-governance-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stagingPath | Out-Null

try {
    foreach ($relativePath in $runtimeFiles) {
        $sourceItem = Join-Path $SourcePath $relativePath
        $relativeParent = Split-Path -Parent $relativePath
        $destinationParent = if ([string]::IsNullOrWhiteSpace($relativeParent)) { $stagingPath } else { Join-Path $stagingPath $relativeParent }
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
    if (-not (Test-Path -LiteralPath (Join-Path $stagingPath $relativePath))) {
        throw "Installed Skill is incomplete: $relativePath"
    }
}

$forbiddenInstalledPaths = @('.git', 'tests', '.test-artifacts', 'PHASE-8-FIRST-USE-TEST-DELIVERY-REPORT.md', 'LOCAL-FIRST-USE-TEST-INSTALLATION-INSTRUCTIONS.md')
foreach ($relativePath in $forbiddenInstalledPaths) {
    if (Test-Path -LiteralPath (Join-Path $stagingPath $relativePath)) {
        throw "Forbidden development file was packaged: $relativePath"
    }
    }

    Move-Item -LiteralPath $stagingPath -Destination $TargetPath
} finally {
    if (Test-Path -LiteralPath $stagingPath) { Remove-Item -LiteralPath $stagingPath -Recurse -Force }
}

Write-Output "Local Skill installation: PASS"
Write-Output "Installed to: $TargetPath"
Write-Output "Entry point: $(Join-Path $TargetPath 'SKILL.md')"
