[CmdletBinding()]
param([switch]$AsJson)
$ErrorActionPreference = 'Stop'
$candidate = [Environment]::GetEnvironmentVariable('CODEX_THREAD_ID')
$result = [ordered]@{
    status = 'CURRENT_THREAD_ID_UNAVAILABLE'
    candidate_thread_id = $null
    source = 'DIRECT_EXECUTION_ENVIRONMENT'
    platform_attestation = $false
    may_bind = $false
    next_action = 'Use trustworthy host context; do not guess IDs or create a replacement Core.'
}
if (-not [string]::IsNullOrWhiteSpace($candidate)) {
    $result.status = 'CANDIDATE_REQUIRES_NATIVE_CROSSCHECK'
    $result.candidate_thread_id = $candidate
    $result.next_action = 'One-shot read_thread with this candidate: compare host, workspace and original conversation; verify send_message_to_thread target contract. Environment data is not authentication.'
}
if ($AsJson) { $result | ConvertTo-Json } else {
    Write-Output "$($result.status): $($result.next_action)"
}
