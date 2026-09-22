Set-StrictMode -Version Latest

function Remove-RoleMapCodeTicks {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return ($Value.Trim() -replace '^`|`$', '').Trim()
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
    $projectMatch = [regex]::Match($text, '(?im)^\s*PROJECT_ID\s*:\s*`?([^`\r\n]+)`?\s*$')
    $bootstrapMatch = [regex]::Match($text, '(?im)^\s*BOOTSTRAP_STATE\s*:\s*`?(ACTIVE|COMPLETE)`?\s*$')
    $outerMatch = [regex]::Match($text, '(?im)^\s*OUTER_TASK_ID\s*:\s*`?([^`\r\n]+)`?\s*$')

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($line in ($text -split "`r?`n")) {
        if (-not $line.TrimStart().StartsWith('|')) { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { Remove-RoleMapCodeTicks $_ })
        if ($cells.Count -ne 7 -or $cells[0] -notin @('CORE_ARCHITECT', 'MISSION_PLANNER', 'BUILD_EXECUTOR', 'EXTERNAL_ADVISOR')) { continue }
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
        ProjectId = if ($projectMatch.Success) { Remove-RoleMapCodeTicks $projectMatch.Groups[1].Value } else { '' }
        BootstrapState = if ($bootstrapMatch.Success) { $bootstrapMatch.Groups[1].Value } else { '' }
        OuterTaskId = if ($outerMatch.Success) { Remove-RoleMapCodeTicks $outerMatch.Groups[1].Value } else { '' }
        Rows = $rows.ToArray()
    }
}
