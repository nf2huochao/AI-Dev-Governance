[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RoleMapPath,

    [Parameter(Mandatory = $true)]
    [string]$EventsPath,

    [Parameter(Mandatory = $true)]
    [string]$ExecutionId,

    [Parameter(Mandatory = $true)]
    [string]$PlatformEvidencePath,

    [Parameter(Mandatory = $true)]
    [string]$McpEvidencePath,

    [string]$ApprovedSummaryPath = ''
)

$ErrorActionPreference = 'Stop'

foreach ($path in @($RoleMapPath, $EventsPath, $PlatformEvidencePath, $McpEvidencePath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "STARTUP_EVIDENCE_NOT_FOUND: $path" }
}
if ([string]::IsNullOrWhiteSpace($ApprovedSummaryPath)) {
    throw 'APPROVED_SUMMARY_REQUIRED: standalone startup readiness checks must include the user-approved startup summary'
}

$bindingOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-role-bindings.ps1') -RoleMapPath $RoleMapPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $bindingOutput -notmatch 'ROLE_BINDINGS_STRUCTURALLY_VALID') {
    throw "STARTUP_PREREQUISITES_NOT_MET: $($bindingOutput.Trim())"
}

$bootstrapOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-bootstrap.ps1') -EventsPath $EventsPath -RoleMapPath $RoleMapPath -ExecutionId $ExecutionId 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $bootstrapOutput -notmatch 'BOOTSTRAP_COMMUNICATION_STRUCTURALLY_VALID') {
    throw "STARTUP_PREREQUISITES_NOT_MET: $($bootstrapOutput.Trim())"
}

if (-not [string]::IsNullOrWhiteSpace($ApprovedSummaryPath)) {
    if (-not (Test-Path -LiteralPath $ApprovedSummaryPath)) { throw "APPROVED_SUMMARY_NOT_FOUND: $ApprovedSummaryPath" }
    $summary = Get-Content -Raw -LiteralPath $ApprovedSummaryPath
    if ($summary -notmatch '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -and $summary -notmatch '(?im)^\s*用户审查与批准状态\s*[:：]\s*APPROVED\s*$') {
        throw 'APPROVAL_REQUIRED: startup summary is not approved'
    }
}

$platformRaw = Get-Content -Raw -LiteralPath $PlatformEvidencePath
$mcpRaw = Get-Content -Raw -LiteralPath $McpEvidencePath
if ([string]::IsNullOrWhiteSpace($platformRaw) -or [string]::IsNullOrWhiteSpace($mcpRaw)) {
    throw 'STARTUP_EVIDENCE_EMPTY: preserve the original platform and MCP records for independent review'
}

throw 'PLATFORM_EVIDENCE_ORIGIN_UNVERIFIABLE: this Skill has no Codex-native raw evidence reader or attestation verifier; MANUAL_REQUIRED. Do not treat hand-written JSON, VERIFIED fields, or send-tool success as authenticated platform proof.'
