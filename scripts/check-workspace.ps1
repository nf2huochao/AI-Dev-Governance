[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ProjectPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ProjectPath)) {
    throw "WORKSPACE_NOT_FOUND: $ProjectPath"
}

$item = Get-Item -LiteralPath $ProjectPath
if (-not $item.PSIsContainer) {
    throw "WORKSPACE_NOT_DIRECTORY: $ProjectPath"
}

$resolved = $item.FullName
$entries = @(Get-ChildItem -LiteralPath $resolved -Force)
$hasGit = Test-Path -LiteralPath (Join-Path $resolved '.git')
$state = if ($entries.Count -eq 0) { 'EMPTY' } else { 'NON_EMPTY' }

Write-Output "Workspace check: PASS"
Write-Output "Path: $resolved"
Write-Output "State: $state"
Write-Output "Git repository marker: $hasGit"
Write-Output 'Codex project binding: UNKNOWN - path visibility does not prove the current Codex project is bound to this directory.'
Write-Output 'User confirmation required before any initialization write.'
