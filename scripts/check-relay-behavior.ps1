[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TracePath,
    [Parameter(Mandatory=$true)][string]$SendCallId
)
$ErrorActionPreference='Stop'
$data=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $TracePath),[Text.Encoding]::UTF8)|ConvertFrom-Json
# Accept a raw read_thread JSON response or its original text content wrapper.
if(-not $data.turns -and $data.content){
    $block=@($data.content|Where-Object type -eq 'text')[0]
    if($block){$data=$block.text|ConvertFrom-Json}
}
$found=0;$violations=@();$observedTurn=$null;$finished=$false
foreach($turn in @($data.turns)){
    $after=$false
    foreach($item in @($turn.items)){
        if($item.id -eq $SendCallId){
            if($item.type -ne 'mcpToolCall' -or $item.tool -ne 'send_message_to_thread'){throw 'SEND_REFERENCE_NOT_A_NATIVE_SEND'}
            $found++;$after=$true;$observedTurn=$turn.id
            $finished=($turn.status -eq 'completed' -or @($turn.items|Where-Object{ $_.type -eq 'agentMessage' -and $_.phase -eq 'final_answer' }).Count -gt 0)
            continue
        }
        if(-not $after -or $item.type -ne 'mcpToolCall'){continue}
        if($item.tool -in @('read_thread','wait_threads','sleep')){
            $violations+=@{turn_id=$turn.id;call_id=$item.id;tool=$item.tool}
        }
    }
}
if($found -ne 1){throw 'SEND_REFERENCE_NOT_FOUND_OR_AMBIGUOUS'}
if($violations.Count){throw ('SEND_YIELD_VIOLATION: '+($violations|ConvertTo-Json -Compress))}
if(-not $finished){throw 'TURN_NOT_FINISHED: partial trace is not a completed yield'}
[ordered]@{status='NO_POLLING_OBSERVED';send_call_id=$SendCallId;turn_id=$observedTurn;scope='provided native action items after this boundary in the same turn only';platform_attestation=$false;may_start_mission=$false;live_compliance='MANUAL_REQUIRED'}|ConvertTo-Json
