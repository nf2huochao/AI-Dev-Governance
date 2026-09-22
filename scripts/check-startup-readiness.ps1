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

    [string]$ApprovedSummaryPath = '',

    [string]$HumanAuthorizationPath = ''
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
    $summary = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ApprovedSummaryPath), [Text.Encoding]::UTF8)
    if ($summary -notmatch '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -and $summary -notmatch '(?im)^\s*用户审查与批准状态\s*[:：]\s*APPROVED\s*$') {
        throw 'APPROVAL_REQUIRED: startup summary is not approved'
    }
}

$platformRaw = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $PlatformEvidencePath), [Text.Encoding]::UTF8)
$mcpRaw = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $McpEvidencePath), [Text.Encoding]::UTF8)
if ([string]::IsNullOrWhiteSpace($platformRaw) -or [string]::IsNullOrWhiteSpace($mcpRaw)) {
    throw 'STARTUP_EVIDENCE_EMPTY: preserve the original platform and MCP records for independent review'
}

if ([string]::IsNullOrWhiteSpace($HumanAuthorizationPath)) {
    throw 'PLATFORM_EVIDENCE_ORIGIN_UNVERIFIABLE: no Codex-native attestation verifier is available; MANUAL_REQUIRED. A Human Governor must inspect the original records and provide a bound authorization receipt.'
}
if (-not (Test-Path -LiteralPath $HumanAuthorizationPath -PathType Leaf)) { throw "HUMAN_AUTHORIZATION_NOT_FOUND: $HumanAuthorizationPath" }
try {
    $authorization = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $HumanAuthorizationPath), [Text.Encoding]::UTF8) | ConvertFrom-Json
} catch { throw 'HUMAN_AUTHORIZATION_INVALID_JSON' }

. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$roleMap = Read-RoleMap -Path $RoleMapPath
function Get-EvidenceSha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
$required = @{
    authorization_decision = 'ALLOW_FIRST_MISSION'
    verification_status = 'HUMAN_VERIFIED'
    authorized_by = 'HUMAN_GOVERNOR'
    project_id = $roleMap.ProjectId
    execution_id = $ExecutionId
    role_map_sha256 = (Get-EvidenceSha256 $RoleMapPath)
    approved_summary_sha256 = (Get-EvidenceSha256 $ApprovedSummaryPath)
    platform_evidence_sha256 = (Get-EvidenceSha256 $PlatformEvidencePath)
    mcp_evidence_sha256 = (Get-EvidenceSha256 $McpEvidencePath)
}
foreach ($name in $required.Keys) {
    if (-not ($authorization.PSObject.Properties.Name -contains $name) -or [string]$authorization.$name -ne [string]$required[$name]) {
        throw "HUMAN_AUTHORIZATION_STALE_OR_MISMATCHED: $name"
    }
}

Write-Output "STARTUP_READY: authorization=HUMAN_VERIFIED; platform_attestation=false; PROJECT_ID=$($roleMap.ProjectId); EXECUTION_ID=$ExecutionId"
Write-Output 'EVIDENCE_BOUNDARY: the receipt records a Human Governor decision; it does not convert user-supplied evidence into platform-attested evidence'
