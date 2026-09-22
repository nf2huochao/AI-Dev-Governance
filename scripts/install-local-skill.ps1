[CmdletBinding()]
param([string]$SourcePath = '', [string]$TargetPath = '', [string[]]$DiscoveryRoots = @())
$ErrorActionPreference = 'Stop'
if (-not $SourcePath) { $SourcePath = Join-Path $PSScriptRoot '..' }
$SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
if (-not $TargetPath) { $TargetPath = Join-Path $env:USERPROFILE '.agents\skills\ai-dev-governance' }
$TargetPath = [IO.Path]::GetFullPath($TargetPath)
if (Test-Path -LiteralPath $TargetPath) { throw "Target already exists; no files were overwritten: $TargetPath" }
if ($DiscoveryRoots.Count -eq 0) {
    $DiscoveryRoots = @((Join-Path $env:USERPROFILE '.agents\skills'), (Join-Path $env:USERPROFILE '.codex\skills'))
    if ($env:CODEX_HOME) { $DiscoveryRoots += Join-Path $env:CODEX_HOME 'skills' }
}
$targetParent = Split-Path -Parent $TargetPath
$duplicates = New-Object 'System.Collections.Generic.List[string]'
foreach ($root in @($DiscoveryRoots + @($targetParent) | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    foreach ($entry in Get-ChildItem -LiteralPath $root -Directory) {
        # A checkout used as the installation source is not a competing installation.
        if ($entry.FullName -eq $SourcePath) { continue }
        $manifestPath = Join-Path $entry.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
        $text = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8)
        if ($text -match '(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)') {
            if ($Matches[1] -match '(?im)^name:\s*[''"]?ai-dev-governance[''"]?\s*(?:#.*)?$') { $duplicates.Add($entry.FullName) }
        }
    }
}
if ($duplicates.Count) { throw "DUPLICATE_SKILL_NAME: $($duplicates -join '; '). Back up the existing installation outside all Skill discovery folders before an explicit update; nothing was overwritten." }
$package = [IO.File]::ReadAllText((Join-Path $SourcePath 'runtime-files.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$runtimeFiles = @($package.files)
if (-not $package.package_version -or $runtimeFiles.Count -lt 1) { throw 'RUNTIME_MANIFEST_INVALID' }
$seen = @{}
foreach ($relative in $runtimeFiles) {
    if ($relative -isnot [string] -or $relative -match '(^|[\\/])(\.\.?|\.git|tests|\.test-artifacts)([\\/]|$)' -or
        [IO.Path]::IsPathRooted($relative) -or $relative.Contains(':') -or $seen.ContainsKey($relative)) { throw "RUNTIME_PATH_INVALID: $relative" }
    $seen[$relative] = $true
    $sourceItem = Join-Path $SourcePath $relative
    if (-not (Test-Path -LiteralPath $sourceItem -PathType Leaf)) { throw "Required Skill file is missing: $relative" }
    $item = Get-Item -LiteralPath $sourceItem
    while ($item.FullName -ne $SourcePath) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "RUNTIME_LINK_FORBIDDEN: $relative" }
        $item = Get-Item -LiteralPath (Split-Path -Parent $item.FullName)
    }
}
foreach ($required in @('SKILL.md','LICENSE','runtime-files.json','roles/core-architect.md','roles/mission-planner.md','roles/build-executor.md','roles/external-advisor.md','scripts/init-governance.ps1','protocols/relay-contract.json')) {
    if (-not $seen.ContainsKey($required)) { throw "RUNTIME_MANIFEST_INCOMPLETE: $required" }
}
# Staging is outside the discovery directory and on the destination volume.
$stagingParent = Split-Path -Parent $targetParent
if (-not $stagingParent) { throw 'TARGET_PARENT_INVALID' }
New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
$stagingPath = Join-Path $stagingParent ('.ai-dev-governance-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stagingPath | Out-Null
try {
    $hashes = [ordered]@{}
    foreach ($relative in $runtimeFiles) {
        $from = Join-Path $SourcePath $relative
        $to = Join-Path $stagingPath $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $to) -Force | Out-Null
        Copy-Item -LiteralPath $from -Destination $to
        $hashes[$relative] = (Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash
        if ($hashes[$relative] -ne (Get-FileHash -LiteralPath $from -Algorithm SHA256).Hash) { throw "COPY_VERIFICATION_FAILED: $relative" }
    }
    $revision = $null; $dirty = $null
    if ((Test-Path -LiteralPath (Join-Path $SourcePath '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $revision = & git -C $SourcePath rev-parse HEAD
        if ($LASTEXITCODE -ne 0) { throw 'SOURCE_REVISION_READ_FAILED' }
        $gitStatus = & git -C $SourcePath status --porcelain
        if ($LASTEXITCODE -ne 0) { throw 'SOURCE_STATUS_READ_FAILED' }
        $dirty = [bool]$gitStatus
    }
    $receipt = [ordered]@{package_version=$package.package_version; source_revision=$revision; source_dirty=$dirty; file_sha256=$hashes; codex_discovery='NOT_TESTED'; platform_communication='NOT_TESTED'}
    [IO.File]::WriteAllText((Join-Path $stagingPath 'INSTALLATION.json'), ($receipt | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
    # Directory.Move fails if a concurrent installation created TargetPath. Never nest/overwrite it.
    [IO.Directory]::Move($stagingPath, $TargetPath)
} finally {
    $resolvedStage = [IO.Path]::GetFullPath($stagingPath)
    $expectedParent = [IO.Path]::GetFullPath($stagingParent).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if ($resolvedStage.StartsWith($expectedParent, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedStage) -like '.ai-dev-governance-install-*' -and (Test-Path -LiteralPath $resolvedStage)) {
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
Write-Output 'Local Skill installation: PASS (package copy only; Codex discovery and communication NOT_TESTED)'
Write-Output "Installed to: $TargetPath"
Write-Output 'Open a new Codex task and invoke $ai-dev-governance. If it is not discovered, restart Codex.'
