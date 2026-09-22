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

    [string]$HumanAuthorizationPath = '',
    [ValidateSet('Initial', 'Recovery')][string]$Mode = 'Initial',
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

foreach ($path in @($RoleMapPath, $EventsPath, $PlatformEvidencePath, $McpEvidencePath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "STARTUP_EVIDENCE_NOT_FOUND: $path" }
}
if ([string]::IsNullOrWhiteSpace($ApprovedSummaryPath)) {
    throw 'APPROVED_SUMMARY_REQUIRED: standalone startup readiness checks must include the user-approved startup summary'
}

$null = & (Join-Path $PSScriptRoot 'check-role-bindings.ps1') -RoleMapPath $RoleMapPath
$null = & (Join-Path $PSScriptRoot 'check-bootstrap.ps1') -EventsPath $EventsPath -RoleMapPath $RoleMapPath -ExecutionId $ExecutionId -Mode $Mode

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

. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$roleMap = Read-RoleMap -Path $RoleMapPath
$receiptStatus = 'NOT_PROVIDED'
# A receipt is an untrusted record, never proof of who authorized it.
if (-not [string]::IsNullOrWhiteSpace($HumanAuthorizationPath)) {
if (-not (Test-Path -LiteralPath $HumanAuthorizationPath -PathType Leaf)) { throw "HUMAN_AUTHORIZATION_NOT_FOUND: $HumanAuthorizationPath" }
try {
    $authorization = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $HumanAuthorizationPath), [Text.Encoding]::UTF8) | ConvertFrom-Json
} catch { throw 'HUMAN_AUTHORIZATION_INVALID_JSON' }

function Get-EvidenceSha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
$required = @{
    authorization_decision = 'ALLOW_FIRST_MISSION'
    verification_status = 'HUMAN_VERIFIED'
    authorized_by = 'HUMAN_GOVERNOR'
    project_id = $roleMap.ProjectId
    execution_id = $ExecutionId
    role_map_sha256 = (Get-EvidenceSha256 $RoleMapPath)
    relay_events_sha256 = (Get-EvidenceSha256 $EventsPath)
    approved_summary_sha256 = (Get-EvidenceSha256 $ApprovedSummaryPath)
    platform_evidence_sha256 = (Get-EvidenceSha256 $PlatformEvidencePath)
    mcp_evidence_sha256 = (Get-EvidenceSha256 $McpEvidencePath)
}
foreach ($name in $required.Keys) {
    if (-not ($authorization.PSObject.Properties.Name -contains $name) -or [string]$authorization.$name -ne [string]$required[$name]) {
        throw "HUMAN_AUTHORIZATION_STALE_OR_MISMATCHED: $name"
    }
}
    $receiptStatus = 'STRUCTURALLY_MATCHED_UNAUTHENTICATED'
}
$result = [ordered]@{
    status = 'MANUAL_REQUIRED'
    structure = 'VALID'
    project_id = $roleMap.ProjectId
    execution_id = $ExecutionId
    mode = $Mode
    receipt = $receiptStatus
    platform_attestation = $false
    authorization_authenticated = $false
    may_start_mission = $false
    next_action = 'Core Architect must inspect actual platform and MCP records, show the user what was verified, and obtain or locate their actual authorization in the conversation. A JSON receipt cannot grant permission.'
}
if ($AsJson) { $result | ConvertTo-Json; return }
Write-Output ($result | ConvertTo-Json -Compress)
throw 'PLATFORM_EVIDENCE_ORIGIN_UNVERIFIABLE: MANUAL_REQUIRED; local structure and matching hashes do not authenticate platform events or Human Governor authorization'
