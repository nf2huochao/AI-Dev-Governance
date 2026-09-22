$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$run = Join-Path $root ('.test-artifacts/user-journey-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run | Out-Null
$shell = (Get-Process -Id $PID).Path
$failures = New-Object 'System.Collections.Generic.List[string]'
$passed = 0
function Write-Utf8($Path, $Text) { [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false)) }
function Invoke-Product($Name, [hashtable]$Arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $nativeArguments = @()
        foreach ($key in $Arguments.Keys) {
            if ($Arguments[$key] -is [bool]) { if ($Arguments[$key]) { $nativeArguments += "-$key" } }
            else { $nativeArguments += "-$key"; $nativeArguments += [string]$Arguments[$key] }
        }
        $output = & $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "scripts/$Name") @nativeArguments 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Text = $output }
    } finally { $ErrorActionPreference = $previous }
}
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
function Case($Name, [scriptblock]$Body) {
    try { & $Body; $script:passed++; Write-Output "PASS $Name" }
    catch { $script:failures.Add("$Name : $($_.Exception.Message)"); Write-Output "FAIL $Name" }
}
try {
    # Fixtures below prove local product behavior only, never real role communication.
    $project = Join-Path $run 'project'
    New-Item -ItemType Directory -Path $project | Out-Null
    $init = Invoke-Product 'init-governance.ps1' @{ProjectPath=$project;BootstrapOnly=$true;ProjectId='ux';ProjectName='UX';ProjectShortName='ux';MissionPlannerDisplayName='Custom Planner'}
    Assert ($init.Code -eq 0) $init.Text
    $mapPath = Join-Path $project '.ai-governance/ROLE-MAP.md'
    $originalMap = [IO.File]::ReadAllText($mapPath)
    Case 'generated registry and creation guard compose' {
        $r = Invoke-Product 'guard-role-creation.ps1' @{RoleId='MISSION_PLANNER';RoleMapPath=$mapPath}
        Assert ($r.Code -eq 0 -and $r.Text -match 'ROLE_CREATION_ALLOWED') $r.Text
    }
    Case 'resume reuses recorded project identity and display names' {
        $r = Invoke-Product 'init-governance.ps1' @{ProjectPath=$project;BootstrapOnly=$true}
        Assert ($r.Code -eq 0) $r.Text
        Assert ([IO.File]::ReadAllText($mapPath) -eq $originalMap) 'Registry changed during resume'
    }
    Case 'copied workspace cannot silently retain old project binding' {
        $other = Join-Path $run 'other-project'
        New-Item -ItemType Directory -Path $other | Out-Null
        Copy-Item -LiteralPath (Join-Path $project '.ai-governance') -Destination $other -Recurse
        $r = Invoke-Product 'init-governance.ps1' @{ProjectPath=$other;BootstrapOnly=$true;ProjectId='ux';ProjectName='UX';ProjectShortName='ux'}
        Assert ($r.Code -ne 0 -and $r.Text -match 'WORKSPACE_IDENTITY_CONFLICT') 'Copied registry was accepted'
    }
    Case 'malformed duplicate role cannot disappear from parsing' {
        $bad = Join-Path $run 'bad-map.md'
        Write-Utf8 $bad ($originalMap + "`n| MISSION_PLANNER | broken |`n")
        $r = Invoke-Product 'guard-role-creation.ps1' @{RoleId='MISSION_PLANNER';RoleMapPath=$bad}
        Assert ($r.Code -ne 0 -and $r.Text -match 'ROLE_MAP_MALFORMED|ROLE_BINDING_CONFLICT') 'Malformed role ignored'
    }
    Case 'missing project identity fails closed before creation' {
        $bad = Join-Path $run 'no-project.md'
        Write-Utf8 $bad ($originalMap -replace '(?m)^PROJECT_ID:.*$', '')
        $r = Invoke-Product 'guard-role-creation.ps1' @{RoleId='MISSION_PLANNER';RoleMapPath=$bad}
        Assert ($r.Code -ne 0 -and $r.Text -match 'PROJECT_ID_MISSING') 'Missing project was accepted'
    }
    Case 'bootstrap START-HERE does not claim development readiness' {
        $text = [IO.File]::ReadAllText((Join-Path $project '.ai-governance/START-HERE.md'))
        Assert ($text -notmatch 'Project Ready|Fill the placeholders') 'Misleading readiness/manual-template instruction'
        Assert (-not $text.Contains([string][char]8)) 'PowerShell backtick escaped into backspace'
    }
    Case 'formal records retain custom role names' {
        $summary = Join-Path $run 'approved.md'
        Write-Utf8 $summary "# Project`nApproval Status: APPROVED`n"
        $r = Invoke-Product 'init-governance.ps1' @{ProjectPath=$project;ApprovedSummaryPath=$summary;ProjectId='ux';ProjectName='UX';ProjectShortName='ux'}
        Assert ($r.Code -eq 0) $r.Text
        $rules = [IO.File]::ReadAllText((Join-Path $project '.ai-governance/PROJECT-INDEX.md'))
        Assert ($rules -match 'ux|UX') 'Missing project identity'
        Assert ([IO.File]::ReadAllText($mapPath) -eq $originalMap) 'Existing roles changed'
    }
    Case 'quoted skill names are detected across installation folders' {
        $discovery = Join-Path $run 'discovery'
        $existing = Join-Path $discovery 'old-skill'
        New-Item -ItemType Directory -Path $existing -Force | Out-Null
        Write-Utf8 (Join-Path $existing 'SKILL.md') "---`nname: 'ai-dev-governance'`ndescription: test`n---`n"
        $target = Join-Path $run 'duplicate-install'
        $r = Invoke-Product 'install-local-skill.ps1' @{SourcePath=$root;TargetPath=$target;DiscoveryRoots=$discovery}
        Assert ($r.Code -ne 0 -and $r.Text -match 'DUPLICATE_SKILL_NAME') 'Quoted duplicate name installed'
        Assert (-not (Test-Path -LiteralPath $target)) 'Duplicate install left a target'
    }
    Case 'installed runtime excludes unlisted local files and keeps all runtime links' {
        $source = Join-Path $run 'source'
        New-Item -ItemType Directory -Path $source | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $root -Force) {
            if ($item.Name -notin @('.git', '.test-artifacts', 'tests')) { Copy-Item -LiteralPath $item.FullName -Destination $source -Recurse }
        }
        Write-Utf8 (Join-Path $source 'scripts/local-private-config.env') 'UNIT_TEST_PRIVATE_MARKER=1'
        $target = Join-Path $run 'clean-install'
        $r = Invoke-Product 'install-local-skill.ps1' @{SourcePath=$source;TargetPath=$target;DiscoveryRoots=(Join-Path $run 'empty-discovery')}
        Assert ($r.Code -eq 0) $r.Text
        Assert (-not (Test-Path -LiteralPath (Join-Path $target 'scripts/local-private-config.env'))) 'Unlisted local configuration shipped'
        foreach ($f in @('SKILL.md','agents/openai.yaml','references/BOOTSTRAP-RUNBOOK.md','scripts/role-map-parser.ps1','protocols/relay-contract.json')) {
            Assert (Test-Path -LiteralPath (Join-Path $target $f)) "Missing installed resource $f"
        }
        Assert (Test-Path -LiteralPath (Join-Path $target 'INSTALLATION.json')) 'No installed version/evidence manifest'
    }
    Case 'completed task cannot be silently redispatched' {
        $relay = Join-Path $run 'relay'; $g = Join-Path $relay '.ai-governance'
        New-Item -ItemType Directory -Path $g -Force | Out-Null
        $events = foreach ($s in @('DISPATCH','ACK','WORKING','HANDOFF','REVIEW','PASS','DISPATCH')) {
            @{event=$s;status=$s;project_id='P';mission_id='M';task_id='T';execution_id='E';actor=$(if($s -in @('ACK','WORKING','HANDOFF')){'build-executor'}else{'mission-planner'})} | ConvertTo-Json -Compress
        }
        Write-Utf8 (Join-Path $g 'RELAY_EVENTS.jsonl') ($events -join "`n")
        $r = Invoke-Product 'check-relay.ps1' @{ProjectPath=$relay}
        Assert ($r.Code -ne 0 -and $r.Text -match 'TASK_ALREADY_COMPLETED|EXECUTION_ALREADY_USED') 'Closed task was reopened without evidence'
    }
    Case 'read-only status explains the next action without creating roles' {
        $before = (Get-FileHash -LiteralPath $mapPath).Hash
        $r = Invoke-Product 'get-onboarding-status.ps1' @{ProjectPath=$project;AsJson=$true}
        Assert ($r.Code -eq 0) $r.Text
        $state = $r.Text | ConvertFrom-Json
        Assert ($state.stage -eq 'BIND_CURRENT_CONTEXT' -and $state.may_start_mission -eq $false) 'Wrong next step'
        Assert (-not [string]::IsNullOrWhiteSpace($state.next_action)) 'No next action for user'
        Assert ((Get-FileHash -LiteralPath $mapPath).Hash -eq $before) 'Status check mutated registry'
    }
} finally {
    $full = [IO.Path]::GetFullPath($run)
    $expectedParent = [IO.Path]::GetFullPath((Join-Path $root '.test-artifacts')) + [IO.Path]::DirectorySeparatorChar
    if ($full.StartsWith($expectedParent, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $full -Recurse -Force }
}
Write-Output "User journey regressions: $passed passed, $($failures.Count) failed (local deterministic checks only)"
if ($failures.Count) { throw ($failures -join "`n") }
