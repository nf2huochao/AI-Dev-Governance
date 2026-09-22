$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$artifacts = Join-Path $root '.test-artifacts\phase-9-audit-contracts'
if (Test-Path $artifacts) { Remove-Item $artifacts -Recurse -Force }
New-Item -ItemType Directory $artifacts | Out-Null
function W($p,$c) { [IO.File]::WriteAllText($p,$c,(New-Object Text.UTF8Encoding($false))) }
function Sha($p) { (Get-FileHash $p -Algorithm SHA256).Hash.ToLowerInvariant() }
try {
  $map=Join-Path $artifacts 'ROLE-MAP.md'; W $map @'
PROJECT_ID: demo
BOOTSTRAP_STATE: COMPLETE
| ROLE_ID | DISPLAY_NAME | BINDING_MODE | CREATION_MODE | THREAD_ID | COMMUNICATION_TARGET_HANDLE | BINDING_STATUS |
|---|---|---|---|---|---|---|
| CORE_ARCHITECT | Core | CURRENT_CONTEXT | REUSE_CURRENT | tc | hc | BOUND |
| MISSION_PLANNER | Planner | CREATED_THREAD | ENSURE | tp | hp | BOUND |
| BUILD_EXECUTOR | Executor | CREATED_THREAD | ENSURE | te | he | BOUND |
'@
  $events=Join-Path $artifacts 'events.jsonl'; W $events @'
{"event":"ROLE_THREAD_CREATED","project_id":"demo","execution_id":"boot","role_id":"MISSION_PLANNER","thread_id":"tp","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"native-create-p"}
{"event":"ROLE_THREAD_CREATED","project_id":"demo","execution_id":"boot","role_id":"BUILD_EXECUTOR","thread_id":"te","binding_mode":"CREATED_THREAD","creation_mode":"ENSURE","evidence":"native-create-e"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo","execution_id":"boot","role_id":"CORE_ARCHITECT","thread_id":"tc","target_role_id":"MISSION_PLANNER","target_thread_id":"tp","target_handle":"hp","status":"SENT","evidence":"native-send-1"}
{"event":"BOOTSTRAP_ACK","project_id":"demo","execution_id":"boot","role_id":"MISSION_PLANNER","thread_id":"tp","target_role_id":"CORE_ARCHITECT","target_thread_id":"tc","target_handle":"hc","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-1"}
{"event":"BOOTSTRAP_HELLO","project_id":"demo","execution_id":"boot","role_id":"MISSION_PLANNER","thread_id":"tp","target_role_id":"BUILD_EXECUTOR","target_thread_id":"te","target_handle":"he","status":"SENT","evidence":"native-send-2"}
{"event":"BOOTSTRAP_ACK","project_id":"demo","execution_id":"boot","role_id":"BUILD_EXECUTOR","thread_id":"te","target_role_id":"MISSION_PLANNER","target_thread_id":"tp","target_handle":"hp","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-2"}
{"event":"RECOVERY_HELLO","project_id":"demo","execution_id":"recover","role_id":"CORE_ARCHITECT","thread_id":"tc","target_role_id":"MISSION_PLANNER","target_thread_id":"tp","target_handle":"hp","status":"SENT","evidence":"native-send-3"}
{"event":"RECOVERY_ACK","project_id":"demo","execution_id":"recover","role_id":"MISSION_PLANNER","thread_id":"tp","target_role_id":"CORE_ARCHITECT","target_thread_id":"tc","target_handle":"hc","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-3"}
{"event":"RECOVERY_HELLO","project_id":"demo","execution_id":"recover","role_id":"MISSION_PLANNER","thread_id":"tp","target_role_id":"BUILD_EXECUTOR","target_thread_id":"te","target_handle":"he","status":"SENT","evidence":"native-send-4"}
{"event":"RECOVERY_ACK","project_id":"demo","execution_id":"recover","role_id":"BUILD_EXECUTOR","thread_id":"te","target_role_id":"MISSION_PLANNER","target_thread_id":"tp","target_handle":"hp","status":"RECEIVED_AND_REPLIED","evidence":"native-reply-4"}
'@
  $recovery=& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $events -RoleMapPath $map -ExecutionId recover -Mode Recovery | Out-String
  if($LASTEXITCODE -ne 0 -or $recovery -notmatch 'actual_new_threads=0'){throw "Zero-create recovery failed: $recovery"}

  $summary=Join-Path $artifacts 'summary.md'; W $summary "# Summary`n`nApproval Status: APPROVED`n"
  $platform=Join-Path $artifacts 'platform.txt'; W $platform 'original tool records retained'
  $mcp=Join-Path $artifacts 'mcp.txt'; W $mcp 'observed project target retained'
  $auth=Join-Path $artifacts 'authorization.json'
  $receipt=[ordered]@{authorization_decision='ALLOW_FIRST_MISSION';verification_status='HUMAN_VERIFIED';authorized_by='HUMAN_GOVERNOR';project_id='demo';execution_id='boot';role_map_sha256=(Sha $map);relay_events_sha256=(Sha $events);approved_summary_sha256=(Sha $summary);platform_evidence_sha256=(Sha $platform);mcp_evidence_sha256=(Sha $mcp)}
  W $auth ($receipt|ConvertTo-Json)
  $ready=& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-startup-readiness.ps1') -RoleMapPath $map -EventsPath $events -ExecutionId boot -PlatformEvidencePath $platform -McpEvidencePath $mcp -ApprovedSummaryPath $summary -HumanAuthorizationPath $auth -AsJson | Out-String
  $result=$ready|ConvertFrom-Json
  if($LASTEXITCODE -ne 0 -or $result.status -ne 'MANUAL_REQUIRED' -or $result.may_start_mission -ne $false -or $result.authorization_authenticated -ne $false -or $result.platform_attestation -ne $false){throw "Hand-written receipt must never authorize startup: $ready"}
  $recoveryReady=& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-startup-readiness.ps1') -RoleMapPath $map -EventsPath $events -ExecutionId recover -Mode Recovery -PlatformEvidencePath $platform -McpEvidencePath $mcp -ApprovedSummaryPath $summary -AsJson | Out-String
  if($LASTEXITCODE -ne 0 -or ($recoveryReady|ConvertFrom-Json).may_start_mission -ne $false){throw 'Recovery structural check must remain unauthenticated'}
  $history=[IO.File]::ReadAllText($events)
  W $events (($history -split "`n" | Where-Object { $_ -notmatch 'ROLE_THREAD_CREATED' }) -join "`n")
  $oldPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
  $noHistory=& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-bootstrap.ps1') -EventsPath $events -RoleMapPath $map -ExecutionId recover -Mode Recovery 2>&1 | Out-String
  $historyCode=$LASTEXITCODE; $ErrorActionPreference=$oldPreference
  if($historyCode -eq 0 -or $noHistory -notmatch 'RECOVERY_CREATION_HISTORY_REQUIRED'){throw 'Historyless recovery was accepted'}
  W $events ($history + "`n")
  $oldPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
  $changedEvents=& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-startup-readiness.ps1') -RoleMapPath $map -EventsPath $events -ExecutionId boot -PlatformEvidencePath $platform -McpEvidencePath $mcp -ApprovedSummaryPath $summary -HumanAuthorizationPath $auth -AsJson 2>&1 | Out-String
  $eventCode=$LASTEXITCODE; $ErrorActionPreference=$oldPreference
  if($eventCode -eq 0 -or $changedEvents -notmatch 'STALE_OR_MISMATCHED'){throw 'Changed event log did not invalidate receipt consistency'}
  W $events $history
  W $summary "# Summary`n`nApproval Status: APPROVED`nchanged`n"
  $oldPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
  $stale=& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\check-startup-readiness.ps1') -RoleMapPath $map -EventsPath $events -ExecutionId boot -PlatformEvidencePath $platform -McpEvidencePath $mcp -ApprovedSummaryPath $summary -HumanAuthorizationPath $auth 2>&1 | Out-String
  $ErrorActionPreference=$oldPreference
  if($LASTEXITCODE -eq 0 -or $stale -notmatch 'STALE_OR_MISMATCHED'){throw 'Changed summary did not invalidate authorization'}

  $contract=[IO.File]::ReadAllText((Join-Path $root 'protocols\relay-contract.json'),[Text.Encoding]::UTF8)|ConvertFrom-Json
  if($contract.required_fields -notcontains 'project_id' -or $contract.transitions.HANDOFF -notcontains 'BLOCKED'){throw 'Machine-readable relay contract incomplete'}
  $roles=(Get-Content -Raw -Encoding UTF8 (Join-Path $root 'roles\build-executor.md'))+(Get-Content -Raw -Encoding UTF8 (Join-Path $root 'roles\core-architect.md'))
  if($roles -notmatch 'PROJECT_SPEC_PATH' -or $roles -notmatch 'GOVERNANCE_POLICY_PATH'){throw 'Project and governance baselines remain conflated'}
} finally { if(Test-Path $artifacts){Remove-Item $artifacts -Recurse -Force} }
Write-Output 'Phase 9 audit contracts A04-A09: PASS'
