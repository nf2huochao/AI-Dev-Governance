$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$run=Join-Path $root ('.test-artifacts/usage-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run|Out-Null
$shell=(Get-Process -Id $PID).Path
$failed=New-Object 'System.Collections.Generic.List[string]';$passed=0
function W($p,$s){[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false))}
function Assert($v,$m){if(-not $v){throw $m}}
function Case($n,[scriptblock]$b){try{& $b;$script:passed++;Write-Output "PASS $n"}catch{$script:failed.Add("$n : $($_.Exception.Message)");Write-Output "FAIL $n : $($_.Exception.Message)"}}
function Run($name,[string[]]$a){$old=$ErrorActionPreference;$ErrorActionPreference='Continue';try{$o=& $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts/$name") @a 2>&1|Out-String;[pscustomobject]@{Code=$LASTEXITCODE;Text=$o}}finally{$ErrorActionPreference=$old}}
function New-Project($name){
    $p=Join-Path $run $name;New-Item -ItemType Directory -Path $p|Out-Null
    $r=Run 'init-governance.ps1' @('-ProjectPath',$p,'-ProjectId','usage-fixture');Assert ($r.Code -eq 0) $r.Text
    $g=Join-Path $p '.ai-governance';$m=Join-Path $g 'ROLE-MAP.md';$t=[IO.File]::ReadAllText($m)
    foreach($id in @('CORE_ARCHITECT','MISSION_PLANNER','BUILD_EXECUTOR')){
        $thread=@{CORE_ARCHITECT='tc';MISSION_PLANNER='tp';BUILD_EXECUTOR='te'}[$id]
        $mode=if($id -eq 'CORE_ARCHITECT'){'CURRENT_CONTEXT | REUSE_CURRENT'}else{'CREATED_THREAD | ENSURE'}
        $t=$t -replace "(?m)^\| $id \|.*$", "| $id | $id | $mode | $thread | $thread | BOUND |"
    }
    W $m $t
    W (Join-Path $g 'task.md') "PROJECT_ID: usage-fixture`nTASK_ID: T1`nSynthetic local regression artifact, not platform evidence.`n"
    $p
}
function Event($state){
    $actor=if($state -in @('ACK','WORKING','HANDOFF')){'build-executor'}else{'mission-planner'}
    $thread=if($actor -eq 'build-executor'){'te'}else{'tp'}
    $e=[ordered]@{event_id="local-$state";schema_version=2;event=$state;status=$state;project_id='usage-fixture';mission_id='M1';task_id='T1';execution_id='E1';actor=$actor;thread_id=$thread;evidence_ref='.ai-governance/task.md'}
    if($state -eq 'DISPATCH'){$e.contract_ref='.ai-governance/task.md';$e.target_thread_id='te';$e.target_handle='te'}
    if($state -eq 'HANDOFF'){$e.handoff_ref='.ai-governance/task.md';$e.target_thread_id='tp';$e.target_handle='tp'}
    if($state -in @('REVIEW','PASS','REWORK')){$e.review_ref='.ai-governance/task.md'}
    $e
}
function Append($p,$e,$hash=''){
    $log=Join-Path $p '.ai-governance/RELAY_EVENTS.jsonl'
    if(-not $hash){$hash=(Get-FileHash $log).Hash}
    $inputPath=Join-Path $run 'candidate.json';W $inputPath ($e|ConvertTo-Json -Depth 12)
    Run 'add-relay-event.ps1' @('-ProjectPath',$p,'-EventPath',$inputPath,'-ExpectedLogHash',$hash)
}
function Trace($items){
    $path=Join-Path $run 'native-trace.json'
    @{thread=@{id='tp'};turns=@(@{id='turn-one';status='completed';items=@($items)})}|ConvertTo-Json -Depth 14|ForEach-Object{W $path $_}
    Run 'check-relay-behavior.ps1' @('-TracePath',$path,'-SendCallId','send-1')
}
function TraceAll($turns){
    $path=Join-Path $run 'native-trace-all.json'
    @{thread=@{id='tp'};turns=@($turns)}|ConvertTo-Json -Depth 14|ForEach-Object{W $path $_}
    Run 'check-relay-behavior.ps1' @('-TracePath',$path,'-AuditAll')
}
$send=@{type='mcpToolCall';id='send-1';tool='send_message_to_thread';status='completed';arguments=@{threadId='te';prompt='DISPATCH T1'}}
try{
    $p=New-Project 'relay';$log=Join-Path $p '.ai-governance/RELAY_EVENTS.jsonl'
    Case 'validated writer executes the real local relay chain' {
        foreach($s in @('DISPATCH','ACK','WORKING','HANDOFF','REVIEW','PASS')){$r=Append $p (Event $s);Assert ($r.Code -eq 0) $r.Text}
        $r=Run 'check-relay.ps1' @('-ProjectPath',$p);Assert ($r.Code -eq 0 -and $r.Text -match 'evidence_linked_tasks=1') $r.Text
    }
    Case 'identical local event is idempotent even with a stale expected hash' {
        $before=(Get-FileHash $log).Hash;$r=Append $p (Event 'PASS') ('0'*64)
        Assert ($r.Code -eq 0 -and $r.Text -match 'ALREADY_RECORDED') $r.Text
        Assert ((Get-FileHash $log).Hash -eq $before) 'Duplicate changed history'
        $original=Event 'PASS';$reordered=[ordered]@{}
        foreach($key in @($original.Keys|Sort-Object -Descending)){$reordered[$key]=$original[$key]}
        $r=Append $p $reordered ('0'*64)
        Assert ($r.Code -eq 0 -and $r.Text -match 'ALREADY_RECORDED') 'Object property order changed event identity'
    }
    Case 'invalid review-to-working and conflicting IDs never modify history' {
        $q=New-Project 'invalid-transition';$ql=Join-Path $q '.ai-governance/RELAY_EVENTS.jsonl'
        $es=foreach($s in @('DISPATCH','ACK','WORKING','HANDOFF','REVIEW')){Event $s|ConvertTo-Json -Compress}
        W $ql ($es -join "`n");$hash=(Get-FileHash $ql).Hash
        $bad=Event 'WORKING';$bad.event_id='local-working-again';$r=Append $q $bad
        Assert ($r.Code -ne 0) 'Invalid transition was accepted'
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'Invalid event changed original bytes'
        $bad=Event 'REVIEW';$bad.evidence_ref='.ai-governance/different.md';$r=Append $q $bad
        Assert ($r.Code -ne 0 -and $r.Text -match 'EVENT_ID_CONFLICT') $r.Text
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'Conflict changed original bytes'
    }
    Case 'stale writers and already-invalid history fail closed without repair' {
        $q=New-Project 'stale';$ql=Join-Path $q '.ai-governance/RELAY_EVENTS.jsonl';$hash=(Get-FileHash $ql).Hash
        $r=Append $q (Event 'DISPATCH') ('0'*64);Assert ($r.Code -ne 0 -and $r.Text -match 'RELAY_LOG_CHANGED') $r.Text
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'Stale write changed bytes'
        W $ql '{invalid historical record';$hash=(Get-FileHash $ql).Hash
        $r=Append $q (Event 'DISPATCH');Assert ($r.Code -ne 0) 'Invalid history was discarded'
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'History was repaired or truncated'
    }
    Case 'an existing exclusive writer cannot be bypassed' {
        $q=New-Project 'locked';$ql=Join-Path $q '.ai-governance/RELAY_EVENTS.jsonl';$hash=(Get-FileHash $ql).Hash
        $lock=[IO.File]::Open($ql,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try{$r=Append $q (Event 'DISPATCH') $hash;Assert ($r.Code -ne 0) 'Concurrent writer bypassed the lock'}finally{$lock.Dispose()}
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'Locked history changed'
    }
    Case 'a JSON array cannot impersonate one event object' {
        $q=New-Project 'array-input';$ql=Join-Path $q '.ai-governance/RELAY_EVENTS.jsonl';$hash=(Get-FileHash $ql).Hash
        $inputPath=Join-Path $run 'array-candidate.json';W $inputPath ('['+((Event 'DISPATCH')|ConvertTo-Json -Compress)+']')
        $r=Run 'add-relay-event.ps1' @('-ProjectPath',$q,'-EventPath',$inputPath,'-ExpectedLogHash',$hash)
        Assert ($r.Code -ne 0 -and $r.Text -match 'EVENT_OBJECT_REQUIRED') $r.Text
        Assert ((Get-FileHash $ql).Hash -eq $hash) 'Array input changed log'
    }
    Case 'active manual-review exception stays visible without granting authority' {
        $q=New-Project 'exception';$g=Join-Path $q '.ai-governance';$m=Join-Path $g 'ROLE-MAP.md'
        $t=[IO.File]::ReadAllText($m)+"`nPROJECT_OVERRIDE: decision-ref-only`nEXTERNAL_REVIEW_TRANSPORT: MANUAL_COPY`n";W $m $t
        $boot=[IO.File]::ReadAllText((Join-Path $root 'examples/RELAY_EVENTS.bootstrap.example.jsonl')).Replace('example-project','usage-fixture').Replace('thread-core-example','tc').Replace('thread-planner-example','tp').Replace('thread-executor-example','te') -replace 'REPLACE_WITH_REAL_PLATFORM_[A-Z_]+','synthetic/reference'
        W (Join-Path $g 'RELAY_EVENTS.jsonl') ($boot.TrimEnd()+"`n"+((Event 'DISPATCH')|ConvertTo-Json -Compress)+"`n")
        $summary=Join-Path $run 'approved-fixture.md';W $summary "Approval Status: APPROVED`nSynthetic record, no real authorization."
        $init=Run 'init-governance.ps1' @('-ProjectPath',$q,'-ApprovedSummaryPath',$summary);Assert ($init.Code -eq 0) $init.Text
        $r=Run 'get-onboarding-status.ps1' @('-ProjectPath',$q,'-AsJson');Assert ($r.Code -eq 0) $r.Text;$v=$r.Text|ConvertFrom-Json
        Assert ($v.stage -eq 'REVIEW_PROJECT_EXCEPTION' -and $v.current_task -eq 'T1') $r.Text
        Assert (-not $v.may_start_mission -and $v.recorded_bootstrap_state -eq 'ACTIVE') 'Exception authenticated itself'
        $bad=Event 'WORKING';W (Join-Path $g 'RELAY_EVENTS.jsonl') ($boot.TrimEnd()+"`n"+($bad|ConvertTo-Json -Compress)+"`n")
        $r=Run 'get-onboarding-status.ps1' @('-ProjectPath',$q,'-AsJson');$v=$r.Text|ConvertFrom-Json
        Assert ($v.stage -eq 'REPAIR_RELAY' -and $v.structure -eq 'INVALID' -and $v.current_task -eq 'T1') $r.Text
    }
    Case 'successful send followed by peer waits is detected in actual action items' {
        $r=Trace @($send,@{type='mcpToolCall';id='wait-1';tool='wait_threads';status='completed';arguments=@{timeoutMs=30000}})
        Assert ($r.Code -ne 0 -and $r.Text -match 'SEND_YIELD_VIOLATION') $r.Text
    }
    Case 'send then final answer passes; quoted polling and other turns do not count' {
        $r=Trace @($send,@{type='agentMessage';phase='final_answer';text='Yield. Example of what not to do: wait_threads(30000).'})
        Assert ($r.Code -eq 0) $r.Text;$v=$r.Text|ConvertFrom-Json
        Assert (-not $v.platform_attestation -and $v.status -eq 'NO_POLLING_OBSERVED') $r.Text
        $r=Trace @(@{type='mcpToolCall';id='before';tool='wait_threads';status='completed';arguments=@{timeoutMs=0}},$send)
        Assert ($r.Code -eq 0) $r.Text
    }
    Case 'trace check refuses an absent send reference' {
        $r=Trace @(@{type='agentMessage';text='I sent a message and yielded.'})
        Assert ($r.Code -ne 0 -and $r.Text -match 'SEND_REFERENCE_NOT_FOUND') $r.Text
    }
    Case 'in-progress turn cannot be claimed as a completed yield' {
        $path=Join-Path $run 'in-progress.json'
        @{thread=@{id='tp'};turns=@(@{id='turn-live';status='inProgress';items=@($send)})}|ConvertTo-Json -Depth 12|ForEach-Object{W $path $_}
        $r=Run 'check-relay-behavior.ps1' @('-TracePath',$path,'-SendCallId','send-1')
        Assert ($r.Code -ne 0 -and $r.Text -match 'TURN_NOT_FINISHED') $r.Text
    }
    Case 'whole-thread audit finds polling after any send without manual call ID selection' {
        $good=@{id='good';status='completed';items=@($send,@{type='agentMessage';phase='final_answer';text='Yield'})}
        $bad=@{id='bad';status='completed';items=@(@{type='mcpToolCall';id='send-2';tool='send_message_to_thread';status='completed'},@{type='mcpToolCall';id='wait-2';tool='wait_threads';status='completed'})}
        $r=TraceAll @($good,$bad)
        Assert ($r.Code -ne 0 -and $r.Text -match 'SEND_YIELD_VIOLATION' -and $r.Text -match 'wait-2') $r.Text
        $r=TraceAll @($good)
        Assert ($r.Code -eq 0) $r.Text
        $v=$r.Text|ConvertFrom-Json
        Assert ($v.audited_sends -eq 1 -and -not $v.platform_attestation) $r.Text
    }
    Case 'advisor connection request uses this project identity and demands actual reads' {
        $q=New-Project 'advisor-request'
        $r=Run 'get-advisor-connection-request.ps1' @('-ProjectPath',$q)
        Assert ($r.Code -eq 0 -and $r.Text -match 'usage-fixture' -and $r.Text.Contains($q)) $r.Text
        Assert ($r.Text -match 'ROLE-MAP.md' -and $r.Text -match 'CURRENT_PHASE.md' -and $r.Text -match 'MCP_TARGET_MISMATCH') $r.Text
        Assert ($r.Text -match '未验证' -and $r.Text -notmatch 'MCP_TARGET_MATCH: PASS') $r.Text
        $other=New-Project 'advisor-other'
        W (Join-Path $other '.ai-governance/ROLE-MAP.md') ([IO.File]::ReadAllText((Join-Path $q '.ai-governance/ROLE-MAP.md')))
        $r=Run 'get-advisor-connection-request.ps1' @('-ProjectPath',$other)
        Assert ($r.Code -ne 0 -and $r.Text -match 'PROJECT_PATH_CONFLICT') 'A copied old project binding was accepted'
    }
    Case 'installation inspection detects duplicate versions without copying anything' {
        $discovery=Join-Path $run 'discovery';New-Item -ItemType Directory -Path $discovery|Out-Null
        foreach($name in @('current','old-test')){
            $dir=Join-Path $discovery $name;New-Item -ItemType Directory -Path $dir|Out-Null
            W (Join-Path $dir 'SKILL.md') "---`nname: ai-dev-governance`ndescription: Synthetic regression fixture.`n---`n"
        }
        $target=Join-Path $discovery 'target'
        $r=Run 'install-local-skill.ps1' @('-TargetPath',$target,'-DiscoveryRoots',$discovery,'-InspectOnly')
        Assert ($r.Code -eq 0) $r.Text;$v=$r.Text|ConvertFrom-Json
        Assert ($v.conflict -and $v.installations.Count -eq 2 -and $v.read_only) $r.Text
        Assert (-not (Test-Path $target) -and @(Get-ChildItem $discovery -Directory).Count -eq 2) 'Inspection mutated installations'
    }
}finally{
    $parent=[IO.Path]::GetFullPath((Join-Path $root '.test-artifacts'))+[IO.Path]::DirectorySeparatorChar
    if([IO.Path]::GetFullPath($run).StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)){Remove-Item -LiteralPath $run -Recurse -Force}
}
Write-Output "Usage reliability: $passed passed, $($failed.Count) failed; isolated synthetic fixtures, not live multi-chat acceptance"
if($failed.Count){throw ($failed -join "`n")}
