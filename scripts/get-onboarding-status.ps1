[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ProjectPath, [switch]$AsJson)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$result = [ordered]@{stage='CONFIRM_WORKSPACE'; structure='NOT_CHECKED'; may_start_mission=$false; next_action='请确认要使用的独立项目文件夹。'; diagnostic=$null}
try {
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
        $result.stage='WORKSPACE_MISSING'; $result.next_action='项目目录不存在。请确认位置，由 Codex 在获得确认后创建。'
    } else {
        $project=(Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd('\','/')
        $g=Join-Path $project '.ai-governance'; $map=Join-Path $g 'ROLE-MAP.md'
        if (Test-Path -LiteralPath $g -PathType Container) {
            $result.stage='REPAIR_RECORDS'; $result.next_action='治理记录不完整，请让 Codex 检查并恢复已有记录，不要重新创建团队。'
            $registry=Read-RoleMap $map
            $result['recorded_bootstrap_state']=$registry.BootstrapState
            if (-not $registry.ProjectPath -or [IO.Path]::GetFullPath($registry.ProjectPath).TrimEnd('\','/') -ne $project) { throw 'WORKSPACE_IDENTITY_CONFLICT' }
            $core=@($registry.Rows | Where-Object RoleId -eq 'CORE_ARCHITECT')
            if ($core.Count -ne 1) { throw 'CORE_BINDING_MISSING' }
            if ($core[0].BindingStatus -ne 'BOUND') {
                $result.stage='BIND_CURRENT_CONTEXT'; $result.next_action='请回到最初的 Codex 天枢核对话，由它核实自身通信身份；不要新建替代天枢核。'
            } else {
                $team=@($registry.Rows | Where-Object RoleId -in @('MISSION_PLANNER','BUILD_EXECUTOR'))
                if ($team.Count -ne 2) { throw 'TEAM_RECORDS_MISSING' }
                if (@($team | Where-Object BindingStatus -ne 'BOUND').Count) {
                    $result.stage='CREATE_TEAM'; $result.next_action='由 Codex 核实两个角色的现有创建结果，只建立确实缺失的角色。'
                } else {
                    $null=& (Join-Path $PSScriptRoot 'check-role-bindings.ps1') -RoleMapPath $map
                    $result.stage='VERIFY_COMMUNICATION'; $result.next_action='由 Codex 核实真实收发与回唤记录；发送成功不等于通信测试成功。'
                    $eventsPath=Join-Path $g 'RELAY_EVENTS.jsonl'
                    $events=@(Get-Content -LiteralPath $eventsPath -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
                    $latest=@($events | Where-Object event -in @('BOOTSTRAP_HELLO','BOOTSTRAP_ACK','RECOVERY_HELLO','RECOVERY_ACK'))
                    if ($latest.Count) {
                        $last=$latest[-1]; $mode=if($last.event -like 'RECOVERY_*'){'Recovery'}else{'Initial'}
                        $null=& (Join-Path $PSScriptRoot 'check-bootstrap.ps1') -EventsPath $eventsPath -RoleMapPath $map -ExecutionId $last.execution_id -Mode $mode
                        # Local records can suggest the next review, but cannot authenticate communication.
                        $result.stage='HUMAN_REVIEW_REQUIRED'
                        $result.next_action='本地通信记录格式完整，仍需核对原始平台记录。确认真实通信后再进入 ChatGPT 规划、批准摘要和 MCP 核验；文件不能自动放行开发。'
                        $summary=Join-Path $g 'PROJECT-STARTUP-SUMMARY.md'
                        $result['summary_saved']=(Test-Path -LiteralPath $summary -PathType Leaf)
                        $approved=$false
                        if ($result.summary_saved) {
                            $text=[IO.File]::ReadAllText($summary, [Text.Encoding]::UTF8)
                            $approved=($text -match '(?im)^\s*Approval Status\s*:\s*APPROVED\s*$' -or $text -match '(?im)^\s*用户审查与批准状态\s*[:：]\s*APPROVED\s*$')
                            $result.stage='APPROVE_SUMMARY'
                            $result.next_action='已有项目摘要，请核对是否已在真实对话中批准；已有批准则复用，不重新规划。'
                            if ($approved) {
                                $result.stage='VERIFY_STARTUP'
                                $result.next_action='已保存标为获批的摘要。由 Codex 定位已有真实批准、通信及 MCP 证据，补齐缺项；不要重新要求规划或复制同一摘要。'
                            }
                        }
                        if ($registry.BootstrapState -eq 'COMPLETE') {
                            $result.stage='REPAIR_RECORDS'
                            if (-not $approved) { throw 'COMPLETED_STARTUP_SUMMARY_MISSING_OR_UNAPPROVED' }
                            foreach ($file in @('PROJECT-INDEX.md','DEVELOPMENT-RULES.md','CURRENT_MISSION.md','RELAY_STATE.md')) {
                                $path=Join-Path $g $file
                                if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or [string]::IsNullOrWhiteSpace([IO.File]::ReadAllText($path))) { throw "COMPLETED_STARTUP_RECORD_MISSING: $file" }
                            }
                            $null=& (Join-Path $PSScriptRoot 'check-relay.ps1') -ProjectPath $project
                            $contract=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '../protocols/relay-contract.json')) | ConvertFrom-Json
                            $formal=@($events | Where-Object { $_.event -notin $contract.control_events })
                            $result.stage='RESUME_PROJECT'
                            $result.next_action='项目记录显示初始化已完成。核对已有真实授权与当前 Mission 后继续，不重建团队或重复规划；本地 COMPLETE 不证明平台核验通过。'
                            if ($formal.Count) {
                                $current=$formal[-1]
                                $result.stage='RESUME_RELAY'
                                $result['current_mission']=$current.mission_id
                                $result['current_task']=$current.task_id
                                $result['relay_status']=$current.status
                                $result.next_action="项目已有接力记录：$($current.task_id) / $($current.status)。由对应角色读取任务、交接与真实对话证据，从当前步骤恢复；不重走初始化、不自动重发任务。"
                            }
                        }
                        $result.structure='VALID'
                    }
                }
            }
        }
    }
} catch {
    $result.structure='INVALID'
    $result.diagnostic=$_.Exception.Message
    if ($result.stage -ne 'VERIFY_COMMUNICATION') {
        $result.stage='REPAIR_RECORDS'; $result.next_action='请让 Codex 核查缺失资料、身份或工作区冲突，恢复并保留原记录，不要重新创建团队。'
    }
}
if ($AsJson) { $result | ConvertTo-Json -Depth 3 } else {
    Write-Output $result.next_action
    Write-Output "Stage: $($result.stage); local state only; may_start_mission=false"
    if ($result.diagnostic) { Write-Output "Diagnostic: $($result.diagnostic)" }
}
