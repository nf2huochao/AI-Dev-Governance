[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ProjectPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'role-map-parser.ps1')
$project=(Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd('\','/')
$map=Read-RoleMap (Join-Path $project '.ai-governance/ROLE-MAP.md')
if([string]::IsNullOrWhiteSpace($map.ProjectPath)){throw 'PROJECT_PATH_MISSING'}
$recorded=$map.ProjectPath.TrimEnd('\','/')
if(-not [string]::Equals($recorded,$project,[StringComparison]::OrdinalIgnoreCase)){
    throw "PROJECT_PATH_CONFLICT: role map '$recorded' differs from actual project '$project'"
}
@"
请在你的 ChatGPT 外参师对话中核对当前工程连接。唯一预期项目：
PROJECT_ID: $($map.ProjectId)
PROJECT_PATH: $project

请实际使用你当前可用的只读工程连接，先读取这个项目的 .ai-governance/ROLE-MAP.md，再读取 .ai-governance/CURRENT_PHASE.md。回报工具实际读取到的 PROJECT_ID、PROJECT_PATH、Phase 和原始工具结果引用；不要仅复述本消息提供的值，也不要打开其他项目文件。
若连接显示旧项目、读取到的身份或路径不符，报告 MCP_TARGET_MISMATCH 并停止该连接的审查。若没有连接或读取失败，报告 MCP_CAPABILITY_GAP 和实际错误。未返回可核对的原始读取结果时保持“未验证”，不要宣布 MCP 已通过。
"@
