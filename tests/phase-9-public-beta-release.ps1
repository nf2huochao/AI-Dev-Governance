$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw -Encoding UTF8
$releaseNotes = Get-Content -LiteralPath (Join-Path $root 'RELEASE-NOTES-v0.1.0-beta.1.md') -Raw
$issueTemplate = Get-Content -LiteralPath (Join-Path $root '.github\ISSUE_TEMPLATE\bug-report.md') -Raw
$license = Get-Content -LiteralPath (Join-Path $root 'LICENSE') -Raw

function Assert-Contains([string]$Text, [string]$Expected, [string]$Message) {
    if (-not $Text.Contains($Expected)) { throw $Message }
}

Assert-Contains $readme 'v0.1.1' 'README must identify the current public beta release.'
Assert-Contains $readme 'TEAM_FIRST_BOOTSTRAP' 'README must describe the approved Team-First order.'
Assert-Contains $readme 'https://github.com/nf2huochao/AI-Dev-Governance.git' 'README install command must use the public repository.'
Assert-Contains $readme 'v0.1.0-beta.1' 'README must distinguish the earlier public beta tag.'
Assert-Contains $readme '--branch v0.1.1' 'README install command must fetch the current release.'
Assert-Contains $readme 'CHANGELOG.md' 'README must link to the current update notes.'
Assert-Contains $readme 'EXTERNAL_VALIDATION_IN_PROGRESS' 'README must separate verified features from external validation.'

Assert-Contains $releaseNotes 'REAL_BOOTSTRAP_HELLO_ACK=PASS' 'Release notes must record the completed real Bootstrap validation.'
Assert-Contains $releaseNotes 'BETA_NOT_STABLE' 'Release notes must state the stability boundary.'

foreach ($category in @('INSTALLATION', 'BOOTSTRAP', 'PROJECT_INITIALIZATION', 'EXTERNAL_ADVISOR_MCP', 'RELAY_DEVELOPMENT', 'OTHER_SUGGESTION')) {
    Assert-Contains $issueTemplate $category "Issue template missing category: $category"
}

Assert-Contains $license 'Apache License' 'LICENSE must contain the Apache License title.'
Assert-Contains $license 'Version 2.0, January 2004' 'LICENSE must be Apache License 2.0.'

$forbiddenTracked = git -C $root ls-files | Where-Object {
    $_ -match '(?i)(\.zip$|\.test-artifacts|^(?:BOOTSTRAP|CURRENT-CONTEXT|PHASE|SKILL-V0|TEAM-FIRST|V0\.1).*REPORT\.md$)'
}
if ($forbiddenTracked) {
    throw "Public release contains internal deliverables: $($forbiddenTracked -join ', ')"
}

Write-Output 'Phase 9 public beta release contract: PASS'
