$ErrorActionPreference = 'Stop'

$protocolPath = Join-Path $PSScriptRoot "..\protocols\external-advisor-audit.md"
$protocol = Get-Content -Raw -LiteralPath $protocolPath

foreach ($token in @('MCP', 'Claim', 'Evidence', 'Counter Evidence', 'Root Cause', 'Advisory', 'Internal PASS / External FAIL scenario')) {
    if ($protocol -notmatch [regex]::Escape($token)) { throw "Audit protocol missing $token" }
}
foreach ($token in @('not an Agent communication bus', 'does not directly dispatch ordinary TASKs', 'modify business code')) {
    if ($protocol -notmatch [regex]::Escape($token)) { throw "MCP boundary wording missing $token" }
}

# Scenario: all internal roles report PASS while the real engineering state disproves completion.
$internal = [ordered]@{
    CoreArchitect = 'PASS'
    MissionPlanner = 'PASS'
    BuildExecutor = 'PASS'
}
$realEvidence = [ordered]@{
    cleanRun = $true
    realEntryReachable = $false
    testFixtureUsed = $true
}

if (($internal.Values | Where-Object { $_ -ne 'PASS' }).Count -ne 0) { throw 'Scenario setup failed: internal roles must all PASS' }
if ($realEvidence.realEntryReachable -or -not $realEvidence.testFixtureUsed) { throw 'Scenario setup failed: real evidence must disprove completion' }

$finding = if ($internal.Values -notcontains 'PASS') { 'INTERNAL_NOT_PASS' } elseif (-not $realEvidence.realEntryReachable) { 'DISPROVED' } else { 'VERIFIED' }
if ($finding -ne 'DISPROVED') { throw 'External Advisor failed to disprove the internal PASS' }

if ($protocol -notmatch 'does not directly') { throw 'Advisor independence boundary is missing' }
if ($protocol -notmatch 'PARTIALLY VERIFIED') { throw 'Uncertain audit finding is missing' }

Write-Output 'Phase 4 audit contract checks: PASS'
Write-Output 'Phase 4 internal-PASS/external-FAIL scenario: PASS'
