$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$run = Join-Path $root ('.test-artifacts/v013-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run | Out-Null
$shell = (Get-Process -Id $PID).Path
$failed = New-Object 'System.Collections.Generic.List[string]'
$passed = 0
function W($p,$s) { [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
function Assert($c,$m) { if (-not $c) { throw $m } }
function Case($name,[scriptblock]$body) {
    try { & $body; $script:passed++; Write-Output "PASS $name" }
    catch { $script:failed.Add("$name : $($_.Exception.Message)"); Write-Output "FAIL $name : $($_.Exception.Message)" }
}
function Run($script,[string[]]$arguments) {
    $old=$ErrorActionPreference; $ErrorActionPreference='Continue'
    try {
        $text=& $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts/$script") @arguments 2>&1 | Out-String
        [pscustomobject]@{Code=$LASTEXITCODE;Text=$text}
    } finally { $ErrorActionPreference=$old }
}
$p=Join-Path $run 'project'; $g=Join-Path $p '.ai-governance'
New-Item -ItemType Directory -Path $g -Force | Out-Null
$map=@'
PROJECT_ID: fixture-project
BOOTSTRAP_STATE: COMPLETE
RELAY_SCHEMA_VERSION: 2
| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| CORE_ARCHITECT | Core | CURRENT_CONTEXT | REUSE_CURRENT | tc | tc | BOUND |
| MISSION_PLANNER | Planner | CREATED_THREAD | ENSURE | tp | tp | BOUND |
| BUILD_EXECUTOR | Executor | CREATED_THREAD | ENSURE | te | te | BOUND |
'@
W (Join-Path $g 'ROLE-MAP.md') $map
foreach($name in @('raw','contract','handoff','review','error')) {
    W (Join-Path $g "$name.md") "PROJECT_ID: fixture-project`nTASK_ID: TASK-1`nSynthetic regression fixture; NOT platform evidence.`n"
}
function E($state,$actor='') {
    if(-not $actor){$actor=if($state -in @('ACK','WORKING','HANDOFF')){'build-executor'}else{'mission-planner'}}
    $thread=if($actor -eq 'build-executor'){'te'}else{'tp'}
    $e=[ordered]@{schema_version=2;event=$state;status=$state;project_id='fixture-project';mission_id='M-1';task_id='TASK-1';execution_id='E-1';actor=$actor;thread_id=$thread;evidence_ref='.ai-governance/raw.md'}
    if($state -eq 'DISPATCH'){$e.contract_ref='.ai-governance/contract.md';$e.target_thread_id='te';$e.target_handle='te'}
    if($state -eq 'HANDOFF'){$e.handoff_ref='.ai-governance/handoff.md';$e.target_thread_id='tp';$e.target_handle='tp'}
    if($state -in @('REVIEW','PASS')){$e.review_ref='.ai-governance/review.md'}
    if($state -eq 'BLOCKED'){$e.error_ref='.ai-governance/error.md'}
    $e
}
function Relay([object[]]$events) {
    W (Join-Path $g 'RELAY_EVENTS.jsonl') (($events|ForEach-Object{$_|ConvertTo-Json -Compress}) -join "`n")
    Run 'check-relay.ps1' @('-ProjectPath',$p)
}
try {
    Case 'pre-ACK failure records BLOCKED without a fake ACK' {
        $r=Relay @((E 'DISPATCH'),(E 'BLOCKED')); Assert ($r.Code -eq 0 -and $r.Text -match 'final_state=BLOCKED') $r.Text
    }
    Case 'pre-ACK blocking requires an actual local error reference' {
        $e=E 'BLOCKED';$e.Remove('error_ref');$r=Relay @((E 'DISPATCH'),$e)
        Assert ($r.Code -ne 0 -and $r.Text -match 'error_ref') $r.Text
    }
    Case 'same executor thread cannot pose as planner' {
        $events=@((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),(E 'HANDOFF'),(E 'REVIEW'),(E 'PASS'))
        $events[-1].thread_id='te';$r=Relay $events
        Assert ($r.Code -ne 0 -and $r.Text -match 'RELAY_ROLE_THREAD_MISMATCH') $r.Text
    }
    Case 'registry and event project must agree' {
        $e=E 'DISPATCH';$e.project_id='other-project';$r=Relay @($e)
        Assert ($r.Code -ne 0 -and $r.Text -match 'RELAY_PROJECT_MISMATCH') $r.Text
    }
    Case 'strict formal relay requires a handoff artifact' {
        $h=E 'HANDOFF';$h.Remove('handoff_ref');$r=Relay @((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),$h)
        Assert ($r.Code -ne 0 -and $r.Text -match 'handoff_ref') $r.Text
    }
    Case 'dispatch uses the registered executor communication target' {
        $e=E 'DISPATCH';$e.target_handle='outer-task-id';$r=Relay @($e)
        Assert ($r.Code -ne 0 -and $r.Text -match 'RELAY_TARGET_MISMATCH') $r.Text
    }
    Case 'evidence cannot escape the project' {
        $e=E 'DISPATCH';$e.evidence_ref='../outside.md';$r=Relay @($e)
        Assert ($r.Code -ne 0 -and $r.Text -match 'EVIDENCE_PATH_OUTSIDE_PROJECT') $r.Text
    }
    Case 'linked evidence is not authenticated completion' {
        $r=Relay @((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),(E 'HANDOFF'),(E 'REVIEW'),(E 'PASS'))
        Assert ($r.Code -eq 0 -and $r.Text -match 'evidence_linked_tasks=1' -and $r.Text -match 'platform_attestation=false' -and $r.Text -match 'completed_tasks=0') $r.Text
    }
    Case 'legacy logs are retained and cannot inflate verified task counts' {
        $legacy=Join-Path $run 'legacy'; New-Item -ItemType Directory -Path (Join-Path $legacy '.ai-governance') -Force|Out-Null
        $events=foreach($state in @('DISPATCH','ACK','WORKING','HANDOFF','REVIEW','PASS')){$e=E $state;$e.Remove('schema_version');$e.Remove('thread_id');$e.Remove('evidence_ref');$e}
        $path=Join-Path $legacy '.ai-governance/RELAY_EVENTS.jsonl'; W $path (($events|ForEach-Object{$_|ConvertTo-Json -Compress})-join "`n");$hash=(Get-FileHash $path).Hash
        $r=Run 'check-relay.ps1' @('-ProjectPath',$legacy)
        Assert ($r.Code -eq 0 -and $r.Text -match 'LEGACY_EVIDENCE_GAP' -and $r.Text -match 'declared_tasks=1' -and $r.Text -match 'completed_tasks=0') $r.Text
        Assert ((Get-FileHash $path).Hash -eq $hash) 'History was rewritten'
    }
    Case 'mission completion ends work without manufacturing a next task' {
        $done=[ordered]@{event='MISSION_COMPLETE';project_id='fixture-project';mission_id='M-1';execution_id='E-1';role_id='MISSION_PLANNER';thread_id='tp';evidence='synthetic-local-fixture';evidence_ref='.ai-governance/raw.md'}
        $chain=@((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),(E 'HANDOFF'),(E 'REVIEW'),(E 'PASS'),$done)
        $r=Relay $chain;Assert ($r.Code -eq 0) $r.Text
        $next=E 'DISPATCH';$next.task_id='TASK-2';$next.execution_id='E-2'
        $r=Relay @($chain + @($next));Assert ($r.Code -ne 0 -and $r.Text -match 'MISSION_ALREADY_COMPLETED') $r.Text
        $r=Relay @((E 'DISPATCH'),$done);Assert ($r.Code -ne 0 -and $r.Text -match 'MISSION_COMPLETION_INVALID') $r.Text
    }
    Case 'legacy prefix can gain strict new tasks without rewriting history' {
        W (Join-Path $g 'ROLE-MAP.md') ($map.Replace('RELAY_SCHEMA_VERSION: 2','RELAY_SCHEMA_VERSION: 1'))
        $old=foreach($state in @('DISPATCH','ACK','WORKING','HANDOFF','REVIEW','PASS')){$e=E $state;$e.Remove('schema_version');$e.task_id='OLD-TASK';$e.execution_id='OLD-EXEC';$e}
        $r=Relay @($old+@((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),(E 'HANDOFF'),(E 'REVIEW'),(E 'PASS')))
        Assert ($r.Code -eq 0 -and $r.Text -match 'declared_tasks=2' -and $r.Text -match 'evidence_linked_tasks=1' -and $r.Text -match 'LEGACY_EVIDENCE_GAP') $r.Text
        $downgrade=E 'DISPATCH';$downgrade.Remove('schema_version');$downgrade.task_id='TASK-2';$downgrade.execution_id='E-2'
        $r=Relay @((E 'DISPATCH'),(E 'ACK'),(E 'WORKING'),(E 'HANDOFF'),(E 'REVIEW'),(E 'PASS'),$downgrade)
        Assert ($r.Code -ne 0 -and $r.Text -match 'schema_version') $r.Text
        W (Join-Path $g 'ROLE-MAP.md') $map
    }
    Case 'current environment identity remains a candidate, not attestation' {
        $r=Run 'get-current-context.ps1' @('-AsJson');Assert ($r.Code -eq 0) $r.Text
        $data=$r.Text|ConvertFrom-Json;Assert ($data.platform_attestation -eq $false -and $data.may_bind -eq $false) 'Environment authenticated itself'
    }
    Case 'new project tracks policy; custom edits are reported without overwrite' {
        $project=Join-Path $run 'new-project';New-Item -ItemType Directory -Path $project|Out-Null
        $r=Run 'init-governance.ps1' @('-ProjectPath',$project,'-BootstrapOnly');Assert ($r.Code -eq 0) $r.Text
        $r=Run 'check-policy-version.ps1' @('-ProjectPath',$project,'-AsJson');Assert ($r.Code -eq 0) $r.Text
        Assert (($r.Text|ConvertFrom-Json).status -eq 'MATCH') $r.Text
        $registryPath=Join-Path $project '.ai-governance/ROLE-MAP.md';$registryText=[IO.File]::ReadAllText($registryPath)
        W $registryPath ([regex]::Replace($registryText,'(?m)^POLICY_BUILD_EXECUTOR_SHA256:.*(?:\r?\n|$)',''))
        $r=Run 'check-policy-version.ps1' @('-ProjectPath',$project,'-AsJson')
        Assert (($r.Text|ConvertFrom-Json).status -eq 'METADATA_INCOMPLETE') 'Missing role provenance was reported as a match'
        W $registryPath $registryText
        $role=Join-Path $project '.ai-governance/roles/build-executor.md';$text=[IO.File]::ReadAllText($role);W $role ($text+"`nUser local customization`n");$hash=(Get-FileHash $role).Hash
        $r=Run 'check-policy-version.ps1' @('-ProjectPath',$project,'-AsJson');Assert (($r.Text|ConvertFrom-Json).status -eq 'LOCALLY_MODIFIED') $r.Text
        Assert ((Get-FileHash $role).Hash -eq $hash) 'User role was overwritten'
    }
} finally {
    $full=[IO.Path]::GetFullPath($run);$parent=[IO.Path]::GetFullPath((Join-Path $root '.test-artifacts'))+[IO.Path]::DirectorySeparatorChar
    if($full.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)){Remove-Item -LiteralPath $full -Recurse -Force}
}
Write-Output "V0.1.3 reliability: $passed passed, $($failed.Count) failed; synthetic inputs only, not real multi-chat evidence"
if($failed.Count){throw ($failed -join "`n")}
