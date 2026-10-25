[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TracePath,
    [string]$SendCallId = '',
    [switch]$AuditAll
)
$ErrorActionPreference='Stop'
if($AuditAll -ne [string]::IsNullOrWhiteSpace($SendCallId)){throw 'SELECT_SEND_CALL_ID_OR_AUDIT_ALL'}
$data=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $TracePath),[Text.Encoding]::UTF8)|ConvertFrom-Json
# Accept a raw read_thread JSON response or its original text content wrapper.
if(-not $data.turns -and $data.content){
    $block=@($data.content|Where-Object type -eq 'text')[0]
    if($block){$data=$block.text|ConvertFrom-Json}
}
$found=0;$violations=@();$observedTurn=$null;$unfinished=$false
foreach($turn in @($data.turns)){
    $after=$false
    foreach($item in @($turn.items)){
        if(($AuditAll -and $item.type -eq 'mcpToolCall' -and $item.tool -eq 'send_message_to_thread') -or (-not $AuditAll -and $item.id -eq $SendCallId)){
            if($item.type -ne 'mcpToolCall' -or $item.tool -ne 'send_message_to_thread'){throw 'SEND_REFERENCE_NOT_A_NATIVE_SEND'}
            $found++;$after=$true;$observedTurn=$turn.id
            if($turn.status -ne 'completed' -and @($turn.items|Where-Object{ $_.type -eq 'agentMessage' -and $_.phase -eq 'final_answer' }).Count -eq 0){$unfinished=$true}
            continue
        }
        if(-not $after -or $item.type -ne 'mcpToolCall'){continue}
        if($item.tool -in @('read_thread','wait_threads','sleep')){
            $violations+=@{turn_id=$turn.id;call_id=$item.id;tool=$item.tool}
        }
    }
}
if(($AuditAll -and $found -eq 0) -or (-not $AuditAll -and $found -ne 1)){throw 'SEND_REFERENCE_NOT_FOUND_OR_AMBIGUOUS'}
if($violations.Count){throw ('SEND_YIELD_VIOLATION: '+($violations|ConvertTo-Json -Compress))}
if($unfinished){throw 'TURN_NOT_FINISHED: partial trace is not a completed yield'}
[ordered]@{status='NO_POLLING_OBSERVED';send_call_id=if($AuditAll){'ALL'}else{$SendCallId};audited_sends=$found;turn_id=$observedTurn;scope='provided native action items after each selected send in the same turn only';platform_attestation=$false;may_start_mission=$false;live_compliance='MANUAL_REQUIRED'}|ConvertTo-Json
