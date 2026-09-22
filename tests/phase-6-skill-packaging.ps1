$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
foreach ($path in @('SKILL.md', 'README.md', 'LICENSE', 'scripts/init-governance.ps1', 'scripts/install-local-skill.ps1', 'scripts/check-workspace.ps1', 'scripts/check-mcp-target.ps1', 'scripts/guard-role-creation.ps1', 'scripts/check-role-bindings.ps1', 'scripts/check-bootstrap.ps1', 'scripts/check-startup-readiness.ps1', 'scripts/validate-governance.ps1', 'scripts/check-relay.ps1', 'governance/PROJECT-STARTUP-SUMMARY.template.md', 'governance/PROJECT-INDEX.template.md', 'governance/DEVELOPMENT-RULES.template.md', 'governance/ROLE-MAP.template.md', 'governance/RELAY_EVENTS.template.jsonl', 'examples/RELAY_EVENTS.bootstrap.example.jsonl', 'docs/FIRST-USE-ONBOARDING.zh-CN.md', 'docs/PROJECT-PLANNING-PROMPT.zh-CN.md', 'docs/MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md', 'docs/FAILURE-RECOVERY.zh-CN.md', 'examples/example-project/README.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path))) { throw "Missing Phase 6 artifact: $path" }
}

$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'SKILL.md')
$readme = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'README.md')
foreach ($token in @('External Advisor', 'Core Architect', 'Mission Planner', 'Build Executor', 'references/BOOTSTRAP-RUNBOOK.md', 'docs/FIRST-USE-ONBOARDING.zh-CN.md', 'MCP', 'No AI supervises itself', 'SEND → YIELD → WAKE → ACT')) {
    if (($skill + $readme) -notmatch [regex]::Escape($token)) { throw "Skill packaging missing $token" }
}

$artifactRoot = Join-Path $root 'tests/.artifacts/phase-6'
if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
try {
    $init = Join-Path $root 'scripts/init-governance.ps1'
    $validate = Join-Path $root 'scripts/validate-governance.ps1'
    $check = Join-Path $root 'scripts/check-relay.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $init -ProjectPath $artifactRoot | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'init-governance failed' }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validate -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'validate-governance failed' }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $check -ProjectPath $artifactRoot
    if ($LASTEXITCODE -ne 0) { throw 'check-relay failed' }
} finally {
    if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Recurse -Force }
}

Write-Output 'Phase 6 skill packaging and ten-minute initialization test: PASS'
