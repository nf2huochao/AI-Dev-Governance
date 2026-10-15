[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [Parameter(Mandatory=$true)][string]$EventPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedLogHash
)
$ErrorActionPreference='Stop'
$project=(Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd('\','/')
$log=Join-Path $project '.ai-governance/RELAY_EVENTS.jsonl'
if (-not (Test-Path -LiteralPath $log -PathType Leaf)) { throw 'RELAY_HISTORY_RECOVERY_REQUIRED' }
$item=Get-Item -LiteralPath $log
while($item.FullName -ne $project){
    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'RELAY_LOG_LINK_FORBIDDEN'}
    $item=Get-Item -LiteralPath (Split-Path -Parent $item.FullName)
}
$raw=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $EventPath),[Text.Encoding]::UTF8)
if($raw -notmatch '^\s*\{'){throw 'EVENT_OBJECT_REQUIRED'}
$event=$raw|ConvertFrom-Json
if($null -eq $event -or $event -isnot [pscustomobject]){throw 'EVENT_OBJECT_REQUIRED'}
if([string]::IsNullOrWhiteSpace([string]$event.event_id)){throw 'LOCAL_EVENT_ID_REQUIRED: not a platform message ID'}
if([string]$event.schema_version -ne '2'){throw 'NEW_EVENT_SCHEMA_2_REQUIRED'}
# Stable property ordering makes harmless input formatting/order changes idempotent.
function Stable($value){
    if($null -eq $value){return 'null'}
    if($value -is [string] -or $value -is [ValueType]){return (ConvertTo-Json -InputObject $value -Compress -Depth 32)}
    if($value -is [array]){return ('['+(@($value|ForEach-Object{Stable $_}) -join ',')+']')}
    $pairs=@(foreach($p in @($value.PSObject.Properties|Sort-Object Name)){(ConvertTo-Json -InputObject $p.Name -Compress)+':'+(Stable $p.Value)})
    '{'+($pairs -join ',')+'}'
}
$serialized=$event|ConvertTo-Json -Compress -Depth 32
$stream=$null;$appending=$false;$originalLength=0
try{
    # Single writer including non-cooperating appenders; no polling for a lock.
    $stream=[IO.File]::Open($log,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::Read)
    $originalLength=$stream.Length
    $memory=New-Object IO.MemoryStream
    try{$stream.CopyTo($memory);$bytes=$memory.ToArray()}finally{$memory.Dispose()}
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$actualHash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')}finally{$sha.Dispose()}
    $text=[Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
    $lines=@($text -split '\r?\n'|Where-Object{-not [string]::IsNullOrWhiteSpace($_)})
    $duplicates=@($lines|ForEach-Object{$_|ConvertFrom-Json}|Where-Object{[string]$_.event_id -eq [string]$event.event_id})
    if($duplicates.Count){
        if($duplicates.Count -ne 1 -or (Stable $duplicates[0]) -cne (Stable $event)){throw 'EVENT_ID_CONFLICT'}
        $null=& (Join-Path $PSScriptRoot 'check-relay.ps1') -ProjectPath $project -EventLines $lines
        Write-Output 'ALREADY_RECORDED: identical local event; no history change; platform_attestation=false'
        return
    }
    if($actualHash -ne $ExpectedLogHash){throw 'RELAY_LOG_CHANGED: re-read once at the next legitimate event; do not blindly retry'}
    $prospective=@($lines)+@($serialized)
    $null=& (Join-Path $PSScriptRoot 'check-relay.ps1') -ProjectPath $project -EventLines $prospective
    $separator=if($originalLength -gt 0 -and $bytes[-1] -ne 10){"`n"}else{''}
    $addition=[Text.UTF8Encoding]::new($false).GetBytes($separator+$serialized+"`n")
    $stream.Position=$originalLength;$appending=$true
    $stream.Write($addition,0,$addition.Length);$stream.Flush($true);$appending=$false
    Write-Output 'RELAY_EVENT_APPENDED: locally validated; original prefix preserved; platform_attestation=false'
}catch{
    if($stream -and $appending){
        try{$stream.SetLength($originalLength);$stream.Flush($true)}catch{throw 'APPEND_FAILED_RECOVERY_REQUIRED: do not retry or claim a complete event'}
    }
    throw
}finally{if($stream){$stream.Dispose()}}
