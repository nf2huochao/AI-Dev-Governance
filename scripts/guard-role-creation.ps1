[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CORE_ARCHITECT', 'MISSION_PLANNER', 'BUILD_EXECUTOR', 'EXTERNAL_ADVISOR')]
    [string]$RoleId,

    [string]$RoleMapPath = ''
)

$ErrorActionPreference = 'Stop'

if ($RoleId -eq 'CORE_ARCHITECT') {
    throw 'CORE_ARCHITECT_CREATION_FORBIDDEN: CURRENT_CONTEXT_MUST_BE_REUSED'
}
if ($RoleId -notin @('MISSION_PLANNER', 'BUILD_EXECUTOR')) {
    throw "ROLE_CREATION_FORBIDDEN: $RoleId is not a Codex create_thread role"
}

if (-not [string]::IsNullOrWhiteSpace($RoleMapPath)) {
    if (-not (Test-Path -LiteralPath $RoleMapPath)) { throw "ROLE_MAP_NOT_FOUND: $RoleMapPath" }
    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($line in ((Get-Content -Raw -LiteralPath $RoleMapPath) -split "`r?`n")) {
        $row = [regex]::Match($line, "^\|\s*$RoleId\s*\|\s*[^|]+\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$")
        if ($row.Success) {
            $matches.Add([pscustomobject]@{
                BindingMode = $row.Groups[1].Value.Trim()
                CreationMode = $row.Groups[2].Value.Trim()
                ThreadId = $row.Groups[3].Value.Trim()
                TargetHandle = $row.Groups[4].Value.Trim()
                BindingStatus = $row.Groups[5].Value.Trim()
            })
        }
    }
    if ($matches.Count -gt 1) { throw "ROLE_BINDING_CONFLICT: $RoleId appears more than once" }
    if ($matches.Count -eq 1 -and $matches[0].BindingStatus -eq 'BOUND') {
        if ($matches[0].BindingMode -ne 'CREATED_THREAD' -or $matches[0].CreationMode -ne 'ENSURE' -or $matches[0].ThreadId -match '^(NOT_CREATED|UNKNOWN|UNVERIFIED)') {
            throw "ROLE_BINDING_CONFLICT: $RoleId has an invalid bound lifecycle"
        }
        Write-Output "ROLE_ALREADY_BOUND: ROLE_ID=$RoleId; ACTION=REUSE_EXISTING_THREAD; THREAD_ID=$($matches[0].ThreadId)"
        exit 0
    }
}

Write-Output "ROLE_CREATION_ALLOWED: ROLE_ID=$RoleId; BINDING_MODE=CREATED_THREAD; CREATION_MODE=ENSURE"
