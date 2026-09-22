function Remove-RoleMapCodeTicks {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return $Value.Trim().Trim([char]96).Trim()
}

function Get-RoleMapField {
    param([string]$Text, [string]$Name)
    $found = [regex]::Matches($Text, '(?im)^\s*' + [regex]::Escape($Name) + '\s*:\s*([^\r\n]*)\r?$')
    if ($found.Count -gt 1) { throw "ROLE_MAP_MALFORMED: duplicate $Name field" }
    if ($found.Count -eq 0) { return '' }
    Remove-RoleMapCodeTicks $found[0].Groups[1].Value
}

function Test-ConcreteRoleIdentity {
    param([string]$Value)
    return (-not [string]::IsNullOrWhiteSpace($Value) -and $Value -notmatch '^(?:\{\{|NOT_|UNKNOWN|UNVERIFIED|UNAVAILABLE|PENDING|CURRENT_THREAD_.*UNAVAILABLE|OUTER_TASK_ID|TASK_ID|EXECUTION_ID|DISPLAY_NAME)')
}

function Read-RoleMap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "ROLE_MAP_NOT_FOUND: $Path"
    }

    $text = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path), [Text.Encoding]::UTF8)
    $projectId = Get-RoleMapField $text 'PROJECT_ID'
    if (-not (Test-ConcreteRoleIdentity $projectId)) { throw 'PROJECT_ID_MISSING: a concrete project identity is required' }
    $bootstrap = Get-RoleMapField $text 'BOOTSTRAP_STATE'
    if ($bootstrap -notin @('ACTIVE', 'COMPLETE')) { throw 'BOOTSTRAP_STATE_INVALID: expected ACTIVE or COMPLETE' }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($line in ($text -split '\r?\n')) {
        if (-not $line.TrimStart().StartsWith('|')) { continue }
        $trimmed = $line.Trim()
        $body = $trimmed.Substring(1)
        if ($body.EndsWith('|')) { $body = $body.Substring(0, $body.Length - 1) }
        $cells = @($body.Split('|') | ForEach-Object { Remove-RoleMapCodeTicks $_ })
        if ($cells[0] -notin @('CORE_ARCHITECT', 'MISSION_PLANNER', 'BUILD_EXECUTOR', 'EXTERNAL_ADVISOR')) { continue }
        if ($cells.Count -ne 7) { throw "ROLE_MAP_MALFORMED: $($cells[0]) must have seven columns" }
        if (@($rows | Where-Object RoleId -eq $cells[0]).Count) { throw "ROLE_BINDING_CONFLICT: duplicate $($cells[0])" }
        $rows.Add([pscustomobject]@{
            RoleId = $cells[0]
            DisplayName = $cells[1]
            BindingMode = $cells[2]
            CreationMode = $cells[3]
            ThreadId = $cells[4]
            TargetHandle = $cells[5]
            BindingStatus = $cells[6]
        })
    }

    [pscustomobject]@{
        ProjectId = $projectId
        ProjectPath = Get-RoleMapField $text 'PROJECT_PATH'
        ProjectName = Get-RoleMapField $text 'PROJECT_NAME'
        ProjectShortName = Get-RoleMapField $text 'PROJECT_SHORT_NAME'
        BootstrapState = $bootstrap
        OuterTaskId = Get-RoleMapField $text 'OUTER_TASK_ID'
        Rows = $rows.ToArray()
    }
}
