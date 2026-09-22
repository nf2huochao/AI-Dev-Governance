[CmdletBinding()]
param([string]$TestDirectory = '', [string]$Filter = 'phase-*.ps1')
$ErrorActionPreference = 'Stop'
if (-not $TestDirectory) { $TestDirectory = $PSScriptRoot }
$shell = (Get-Process -Id $PID).Path
$files = @(Get-ChildItem -LiteralPath $TestDirectory -Filter $Filter -File | Sort-Object Name)
if ($files.Count -eq 0) { throw 'NO_TESTS_FOUND' }
$failed = New-Object 'System.Collections.Generic.List[string]'
foreach ($test in $files) {
    # Each test gets its own process: a nested exit 0 cannot skip the remaining suite.
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $shell -NoProfile -ExecutionPolicy Bypass -File $test.FullName; $code = $LASTEXITCODE }
    finally { $ErrorActionPreference = $oldPreference }
    if ($code -ne 0) { $failed.Add($test.Name) }
}
Write-Output "Test files: $($files.Count); passed: $($files.Count - $failed.Count); failed: $($failed.Count); shell: $($PSVersionTable.PSVersion)"
if ($failed.Count) { throw "FAILED: $($failed -join ', ')" }
