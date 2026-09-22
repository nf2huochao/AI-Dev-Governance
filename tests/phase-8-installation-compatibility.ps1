$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$skillPath = Join-Path $root 'SKILL.md'
$installerPath = Join-Path $root 'scripts\install-local-skill.ps1'
$artifactRoot = Join-Path $root '.test-artifacts\phase-8-installation-compatibility'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

Assert-True (Test-Path -LiteralPath $skillPath) 'Missing root SKILL.md'
$skillText = [System.IO.File]::ReadAllText($skillPath, (New-Object System.Text.UTF8Encoding($false)))
Assert-True ($skillText -match '(?ms)^---\s*\r?\nname:\s*ai-dev-governance\s*\r?\ndescription:\s*Use when .+?\r?\n---\s*\r?\n') 'SKILL.md is missing valid discovery frontmatter'
Assert-True (Test-Path -LiteralPath $installerPath) 'Missing local Skill installer'

$installerText = [System.IO.File]::ReadAllText($installerPath, (New-Object System.Text.UTF8Encoding($false)))
foreach ($token in @('$env:USERPROFILE', 'TargetPath', 'already exists', 'Copy-Item', 'SKILL.md', 'roles', 'protocols', 'governance', 'scripts')) {
    Assert-True ($installerText -match [regex]::Escape($token)) "Installer missing required token: $token"
}

foreach ($forbidden in @('.git', 'tests', '.test-artifacts', 'PHASE-8-FIRST-USE-TEST-DELIVERY-REPORT.md', 'LOCAL-FIRST-USE-TEST-INSTALLATION-INSTRUCTIONS.md')) {
    Assert-True ($installerText -notmatch [regex]::Escape("Copy-Item.*$forbidden")) "Installer may package forbidden path: $forbidden"
}

try {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
    $installTarget = Join-Path $artifactRoot 'isolated-skill'
    $installOutput = & $installerPath -SourcePath $root -TargetPath $installTarget -DiscoveryRoots @((Join-Path $artifactRoot 'discovery')) | Out-String
    Assert-True ($installOutput -match 'Local Skill installation: PASS') 'Isolated Skill installation did not pass'
    foreach ($required in @('SKILL.md', 'roles\core-architect.md', 'roles\mission-planner.md', 'roles\build-executor.md', 'roles\external-advisor.md', 'docs\FIRST-USE-ONBOARDING.zh-CN.md', 'scripts\init-governance.ps1')) {
        Assert-True (Test-Path -LiteralPath (Join-Path $installTarget $required)) "Installed package is missing: $required"
    }
    foreach ($forbiddenPath in @('.git', 'tests', '.test-artifacts', 'PHASE-8-FIRST-USE-TEST-DELIVERY-REPORT.md', 'LOCAL-FIRST-USE-TEST-INSTALLATION-INSTRUCTIONS.md')) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $installTarget $forbiddenPath))) "Forbidden path was installed: $forbiddenPath"
    }

    $secondInstall = try { & $installerPath -SourcePath $root -TargetPath $installTarget 2>&1 | Out-String } catch { $_.ToString() }
    Assert-True ($secondInstall -match 'Target already exists') 'Existing install target was not protected'
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 8 installation compatibility contract: PASS'
