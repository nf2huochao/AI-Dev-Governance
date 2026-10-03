[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ProjectPath, [switch]$AsJson)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$map = Join-Path $project '.ai-governance/ROLE-MAP.md'
$null = Read-RoleMap $map
$text = [IO.File]::ReadAllText($map,[Text.Encoding]::UTF8)
$current = ([IO.File]::ReadAllText((Join-Path $root 'runtime-files.json')) | ConvertFrom-Json).package_version
$recorded = Get-RoleMapField $text 'POLICY_PACKAGE_VERSION'
$changed = @(); $modified = @(); $missing = @()
foreach ($name in @('core-architect','mission-planner','build-executor','external-advisor')) {
    $field = 'POLICY_' + $name.Replace('-','_').ToUpperInvariant() + '_SHA256'
    $hash = Get-RoleMapField $text $field
    if (-not $hash -or $hash -notmatch '^[a-fA-F0-9]{64}$') { $missing += $name; continue }
    $local = Join-Path $project ".ai-governance/roles/$name.md"
    if (-not (Test-Path -LiteralPath $local -PathType Leaf) -or (Get-FileHash -LiteralPath $local).Hash -ne $hash) { $modified += $name }
    if ((Get-FileHash -LiteralPath (Join-Path $root "roles/$name.md")).Hash -ne $hash) { $changed += $name }
}
$status = if (-not $recorded) { 'LEGACY_UNTRACKED' } elseif ($missing.Count) { 'METADATA_INCOMPLETE' } elseif ($modified.Count) { 'LOCALLY_MODIFIED' } elseif ($recorded -ne $current -or $changed.Count) { 'VERSION_DIFFERENCE' } else { 'MATCH' }
$result = [ordered]@{status=$status;project_policy_version=$recorded;installed_package_version=$current;changed_upstream_roles=@($changed);locally_modified_roles=@($modified);missing_provenance_roles=@($missing);read_only=$true;may_start_mission=$false}
if ($AsJson) { $result | ConvertTo-Json -Depth 3 } else { Write-Output "Policy version: $status; compare at the task boundary; preserve local changes, bindings and history. No migration performed." }
