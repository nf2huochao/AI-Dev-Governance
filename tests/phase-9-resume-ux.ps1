$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$run = Join-Path $root ('.test-artifacts/resume-ux-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run | Out-Null
$shell = (Get-Process -Id $PID).Path
$failed = New-Object 'System.Collections.Generic.List[string]'
$passed = 0
function Write-Utf8($Path, $Text) { [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }
function Run($Name, [hashtable]$Arguments) {
    $argsList = @()
    foreach ($key in $Arguments.Keys) { $argsList += "-$key"; $argsList += [string]$Arguments[$key] }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $output = & $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts/$Name") @argsList 2>&1 | Out-String
        return [pscustomobject]@{ Code=$LASTEXITCODE; Text=$output }
    } finally { $ErrorActionPreference = $old }
}
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
function Case($Name, [scriptblock]$Body) {
    try { & $Body; $script:passed++; Write-Output "PASS $Name" }
    catch { $script:failed.Add("$Name : $($_.Exception.Message)"); Write-Output "FAIL $Name" }
}
function New-Project($Name) {
    $path = Join-Path $run $Name
    New-Item -ItemType Directory -Path $path | Out-Null
    $r = Run 'init-governance.ps1' @{ProjectPath=$path;ProjectId='resume-fixture'}
    Assert ($r.Code -eq 0) $r.Text
    return $path
}
try {
    # All messages below are synthetic local fixtures, not platform evidence.
    $project = New-Project 'complete'
    $g = Join-Path $project '.ai-governance'
    $mapPath = Join-Path $g 'ROLE-MAP.md'
    $map = [IO.File]::ReadAllText($mapPath)
    foreach ($role in @('CORE_ARCHITECT','MISSION_PLANNER','BUILD_EXECUTOR')) {
        $thread = @{CORE_ARCHITECT='thread-core-example';MISSION_PLANNER='thread-planner-example';BUILD_EXECUTOR='thread-executor-example'}[$role]
        $mode = if ($role -eq 'CORE_ARCHITECT') { 'CURRENT_CONTEXT | REUSE_CURRENT' } else { 'CREATED_THREAD | ENSURE' }
        $map = $map -replace "(?m)^\| $role \|.*$", "| $role | $role | $mode | $thread | $thread | BOUND |"
    }
    Write-Utf8 $mapPath $map
    $eventsPath = Join-Path $g 'RELAY_EVENTS.jsonl'
    $events = [IO.File]::ReadAllText((Join-Path $root 'examples/RELAY_EVENTS.bootstrap.example.jsonl'))
    $events = $events.Replace('example-project','resume-fixture') -replace 'REPLACE_WITH_REAL_PLATFORM_[A-Z_]+','unit-fixture/reference'
    Write-Utf8 $eventsPath $events
    $summary = Join-Path $run 'approved.md'
    Write-Utf8 $summary "# Project`nApproval Status: APPROVED`n"
    $r = Run 'init-governance.ps1' @{ProjectPath=$project;ApprovedSummaryPath=$summary}
    Assert ($r.Code -eq 0) $r.Text

    Case 'saved summary skips repeat planning while retaining review boundary' {
        $state = & (Join-Path $root 'scripts/get-onboarding-status.ps1') -ProjectPath $project -AsJson | ConvertFrom-Json
        Assert ($state.stage -eq 'VERIFY_STARTUP' -and $state.summary_saved) 'Saved summary sent back to planning'
        Assert (-not $state.may_start_mission) 'Local files granted mission authority'
    }
    $map = $map.Replace('BOOTSTRAP_STATE: `ACTIVE`','BOOTSTRAP_STATE: `COMPLETE`')
    Write-Utf8 $mapPath $map
    $formal = foreach ($state in @('DISPATCH','ACK','WORKING','HANDOFF')) {
        @{event=$state;status=$state;project_id='resume-fixture';mission_id='M-1';task_id='T-1';execution_id='E-1';actor=$(if($state -eq 'DISPATCH'){'mission-planner'}else{'build-executor'})} | ConvertTo-Json -Compress
    }
    Write-Utf8 $eventsPath ($events.TrimEnd() + "`n" + ($formal -join "`n") + "`n")
    Case 'completed startup shows current handoff without restarting bootstrap' {
        $before = (Get-FileHash -LiteralPath $eventsPath).Hash
        $state = & (Join-Path $root 'scripts/get-onboarding-status.ps1') -ProjectPath $project -AsJson | ConvertFrom-Json
        Assert ($state.stage -eq 'RESUME_RELAY') 'Completed startup was reset'
        Assert ($state.current_task -eq 'T-1' -and $state.relay_status -eq 'HANDOFF') 'Current task handoff was hidden'
        Assert (-not $state.may_start_mission) 'COMPLETE was treated as authenticated authorization'
        Assert ((Get-FileHash -LiteralPath $eventsPath).Hash -eq $before) 'Read-only status modified history'
    }
    Case 'repeat initialization reports recorded complete state accurately' {
        $r = Run 'init-governance.ps1' @{ProjectPath=$project}
        Assert ($r.Code -eq 0 -and $r.Text -match 'BOOTSTRAP_STATE=COMPLETE' -and $r.Text -notmatch 'BOOTSTRAP_STATE=ACTIVE') 'Resume falsely reports active initialization'
    }
    Case 'orphaned event history cannot acquire a new project registry' {
        $orphan = Join-Path $run 'orphan'; $og = Join-Path $orphan '.ai-governance'
        New-Item -ItemType Directory -Path $og -Force | Out-Null
        Write-Utf8 (Join-Path $og 'RELAY_EVENTS.jsonl') $events
        $r = Run 'init-governance.ps1' @{ProjectPath=$orphan}
        Assert ($r.Code -ne 0 -and $r.Text -match 'ROLE_MAP_RECOVERY_REQUIRED') 'Existing history received a fresh identity'
        Assert (@(Get-ChildItem -LiteralPath $og -Recurse -File).Count -eq 1) 'Failed recovery wrote new records'
    }
    Case 'missing historical log cannot be replaced with an empty log' {
        $missing = Join-Path $run 'missing-log'; $mg = Join-Path $missing '.ai-governance'
        New-Item -ItemType Directory -Path $mg -Force | Out-Null
        Write-Utf8 (Join-Path $mg 'ROLE-MAP.md') ($map.Replace($project,$missing))
        $r = Run 'init-governance.ps1' @{ProjectPath=$missing}
        Assert ($r.Code -ne 0 -and $r.Text -match 'RELAY_HISTORY_RECOVERY_REQUIRED') 'Missing history was silently reinitialized'
        Assert (-not (Test-Path -LiteralPath (Join-Path $mg 'RELAY_EVENTS.jsonl'))) 'Empty replacement history created'
    }
    Case 'general validator detects a lost registry in an otherwise intact project' {
        $broken = New-Project 'lost-registry'
        Move-Item -LiteralPath (Join-Path $broken '.ai-governance/ROLE-MAP.md') -Destination (Join-Path $run 'saved-role-map.md')
        $r = Run 'validate-governance.ps1' @{ProjectPath=$broken}
        Assert ($r.Code -ne 0 -and $r.Text -match 'ROLE-MAP') 'General validation passed without any role registry'
    }
    Case 'complete marker cannot conceal a missing approved summary' {
        $savedSummary = Join-Path $g 'PROJECT-STARTUP-SUMMARY.md'
        $backup = Join-Path $run 'saved-summary.md'
        Move-Item -LiteralPath $savedSummary -Destination $backup
        try {
            $state = & (Join-Path $root 'scripts/get-onboarding-status.ps1') -ProjectPath $project -AsJson | ConvertFrom-Json
            Assert ($state.stage -eq 'REPAIR_RECORDS' -and $state.structure -eq 'INVALID' -and -not $state.may_start_mission) 'Incomplete records reported as resumable'
            Assert ($state.diagnostic -eq 'COMPLETED_STARTUP_SUMMARY_MISSING_OR_UNAPPROVED') 'Missing summary diagnostic was lost'
        } finally { Move-Item -LiteralPath $backup -Destination $savedSummary }
    }
    Case 'latest incomplete recovery blocks stale completed handshake reuse' {
        $hello = ($events -split "`n" | Where-Object { $_ -match '"event":"BOOTSTRAP_HELLO"' } | Select-Object -First 1) | ConvertFrom-Json
        $hello.event='RECOVERY_HELLO'; $hello.execution_id='recovery-new'
        [IO.File]::AppendAllText($eventsPath, (($hello | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        $state = & (Join-Path $root 'scripts/get-onboarding-status.ps1') -ProjectPath $project -AsJson | ConvertFrom-Json
        Assert ($state.stage -eq 'VERIFY_COMMUNICATION' -and $state.structure -ne 'VALID' -and $state.diagnostic) 'Incomplete recovery was hidden by old success'
    }
} finally {
    $parent = [IO.Path]::GetFullPath((Join-Path $root '.test-artifacts')) + [IO.Path]::DirectorySeparatorChar
    if ([IO.Path]::GetFullPath($run).StartsWith($parent, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $run -Recurse -Force }
}
Write-Output "Resume UX regressions: $passed passed, $($failed.Count) failed (local fixtures only)"
if ($failed.Count) { throw ($failed -join "`n") }
