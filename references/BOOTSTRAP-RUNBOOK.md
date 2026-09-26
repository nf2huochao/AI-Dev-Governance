# Bootstrap 执行规程（给 Codex，不是普通用户操作清单）

## 1. 先核实工作区与调用场景

只在用户请求建立/继续 AI 开发治理团队时应用。开发本 Skill 不触发团队初始化。
已有 .ai-governance/ROLE-MAP.md 时，先运行 get-onboarding-status.ps1 -ProjectPath <已确认目录> -AsJson。
读取角色表、当前阶段、最新接力状态及必要证据；不要把每次 Skill 调用都解释为新 Core。
状态工具只读；may_start_mission=false 不是故障，表示它无权认证平台事实。
缺少身份或文件冲突先查明来源；不要覆盖记录、删除历史或重新创建团队来“恢复”。
状态为 RESUME_PROJECT / RESUME_RELAY 时，先核对既有真实批准和当前任务，再从对应步骤恢复；不重新规划或索取同一摘要。
VERIFY_STARTUP 表示获批摘要已保存，应补查已有通信、MCP 与启动证据。所有这些状态都只是本地记录提示，不会自动授权开发。
已有治理内容但 ROLE-MAP 缺失，或已有注册表但 RELAY_EVENTS 缺失时，初始化会停止；从 Git、备份或可核实原始记录恢复缺失文件，不创建新身份或空历史。

首次启动：用 check-workspace.ps1 只读检查用户指定目录，核实平台项目绑定与同一目录相符。
目录不存在时只提出创建该目录；非空目录说明已有内容并确认用途。绝不清空，也不把 Skill 源码/安装目录当用户项目。
用户一次确认工作区与角色名即可；没有更名偏好时使用项目简称+四角色默认名。
普通初始化的批准不包含生产、费用、凭据、发布等额外权限。

## 2. 能力预检与唯一原始 Core

在创建任何角色前，核查本次平台可用的创建、消息和可靠当前对话身份能力。
BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT：CORE_ARCHITECT_SOURCE = CURRENT ORIGINAL CONVERSATION。
BINDING_MODE = CURRENT_CONTEXT；CREATION_MODE = REUSE_CURRENT；BOOTSTRAP_STATE = ACTIVE。
EXPECTED_NEW_CODEX_THREADS = 2；Bootstrap 不是第五角色，不能创建第二个 Core Architect。

本次已知原生契约（使用时仍核对工具说明）：

| 操作 | 可用字段与限制 |
|---|---|
| list_projects | projectId、路径、isGitRepository；选择与已确认工作区一致的项目 |
| create_thread | 就绪返回 threadId、hostId；设置中可能只有 clientThreadId，它不能传给要求 threadId 的工具 |
| send_message_to_thread | 目标参数 threadId，可选 hostId；这是已验证契约下目标句柄与 threadId 相同的依据，而不是字符串猜测 |
| read_thread | 读取指定 threadId 的实际内容；可一次性核实有疑问的记录，不作为等待循环 |
| 当前调用者身份 | 当前工具集没有专用“返回调用者 threadId”的接口；不得从标题、最近时间、活跃状态或同一路径猜测 |

当前身份如由宿主可信上下文提供，保存原始来源引用并核对路由。否则保持
CURRENT_THREAD_ID_UNAVAILABLE / BINDING_BLOCKED / CAPABILITY GAP，解释缺口和可行的人工平台核实动作。
不能要求用户猜线程号，也不能创建替代 Core 来绕过缺失回传地址。

PROJECT_ID、ROLE_ID、THREAD_ID、COMMUNICATION_TARGET_HANDLE、TASK_ID、EXECUTION_ID、OUTER_TASK_ID 分开保存。
hostId 属于平台路由元数据，随原始工具记录保存；多主机发送时必须使用已验证的实际 hostId。
不要把 clientThreadId、外层任务、执行编号或显示名变成地址。
若身份无法可靠取得，停止创建下游角色；不要先建立团队再发现不能回传。

## 3. 骨架与两个角色

由 Codex 执行（用真实已确认值，不让用户填写占位符）：

    & <skill-root>/scripts/init-governance.ps1 -ProjectPath <workspace> -BootstrapOnly -ProjectName <name> -ProjectShortName <short>
    & <skill-root>/scripts/guard-role-creation.ps1 -RoleMapPath <workspace>/.ai-governance/ROLE-MAP.md -RoleId MISSION_PLANNER

初始化只创建缺失骨架；自动生成 PROJECT_ID，恢复时复用已有身份、名称与原摘要。
正式事件日志从空文件开始，示例 examples/RELAY_EVENTS.bootstrap.example.jsonl 绝不导入正式日志。
guard 输出 ROLE_CREATION_ALLOWED 才允许原生创建；CORE_ARCHITECT_CREATION_FORBIDDEN 必须复用当前对话；
ROLE_ALREADY_BOUND / REUSE_EXISTING_THREAD 必须复用对应线程。

明确让两个角色使用同一用户确认工作区的 local 环境，避免工具的默认 Git worktree 创建另一个工程。
创建前在现有角色表记录创建中状态；不增加第二份注册表。
用户已请求团队创建时，在平台权限允许范围内顺序创建；无需每一步再自然语言询问。
创建返回不确定，保留原始返回/设置阶段句柄与角色绑定的证据引用，等待真实平台完成事件。
可在用户再次请求恢复时核实一次状态；禁止持续轮询或第二次盲目创建。
只在确认真实 threadId 后更新 BOUND，追加真实 ROLE_THREAD_CREATED。
恢复使用 guard 确认，已绑定的不再创建；重复身份进入冲突处理。
对新增的唯一角色发送所属 roles/ 规则和对应项目上下文，不广播/重建全团队。
创建工具可能立即启动新对话。创建提示明确告知：当前只加载角色和上下文，未收到真实 HELLO 时结束本轮；不要提前 ACK 或给尚未绑定的另一角色发消息。
Core 确认两个角色均已绑定后才发送第一个 HELLO，使 Planner 能读取已登记的 Executor 目标。

## 4. 基础通信

绑定检查 check-role-bindings.ps1 只是结构检查。由平台原始记录逐个核实工作区、PROJECT_ID、真实 threadId 与消息目标。
同一握手使用一个独立 execution_id：

1. CORE_ARCHITECT → MISSION_PLANNER：BOOTSTRAP_HELLO。
2. Planner 真正收到、核对身份和工作区，回传 BOOTSTRAP_ACK。Core 被真实回传唤醒。
3. Planner → BUILD_EXECUTOR：BOOTSTRAP_HELLO。
4. Executor 真正收到并核对后回传 BOOTSTRAP_ACK。Planner 被真实回传唤醒，再通知 Core 测试结果。

只有收发实际发生才追加对应事件和原始工具/执行/消息引用。不虚构平台没有的 message ID 或时间戳。
需要核实收发两端执行与回传，而不是只有发送返回。只记录真实证据，不在正式工程运行模拟测试。
四条 HELLO/ACK 是一次握手，不是整个历史只有四条。创建和协调通知也保留，不伪装为握手事件。

    & <skill-root>/scripts/check-bootstrap.ps1 -EventsPath <events> -RoleMapPath <map> -ExecutionId <id>

初始模式 Initial 要求该次两个真实创建记录；Recovery 使用 RECOVERY_HELLO/RECOVERY_ACK，可零新增，
但必须追溯现有角色的历史创建证据，不能靠删历史通过。
每次 SEND → YIELD → WAKE → ACT；发送失败保留错误，只做一次定向恢复，结果不确定时不重复发送。
区分角色绑定错误、路由错误、送达失败和自动唤醒缺口。记录 BLOCKED，给用户一个明确恢复动作。
基础通信未通过前，不派正式 Mission、TASK，不写业务代码，不引导用户提前完成繁琐规划。

## 5. 规划、摘要与 MCP

通信经原始证据核实后，才转 ChatGPT External Advisor 项目规划。
读取 docs/PROJECT-PLANNING-PROMPT.zh-CN.md，带入已确认的工作区、角色名称和已有目标，
直接给用户完整可复制文字；用户不需要寻找模板。
ChatGPT 生成 PROJECT STARTUP SUMMARY 初稿 DRAFT，用户批准后为 APPROVED。
用户一次复制完整获批摘要回原 Core；由 Codex 保存原文并执行：

    & <skill-root>/scripts/init-governance.ps1 -ProjectPath <workspace> -ApprovedSummaryPath <saved-approved-summary>

核对实际用户批准，不因文件写 APPROVED 就假定批准发生。恢复时复用相同摘要，变更须明确批准。
已有日志不清空，资料存在不等于开发就绪。
按 docs/MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md 指导用户完成平台需要的授权；
用实际只读连接读取目标项目的 ROLE-MAP 项目标识及一份允许公开给外参师的工程文件。
check-mcp-target.ps1 比对两个输入路径只是辅助，不能证明真实连接、权限或读取成功。
当前账号没有相应入口/连接能力时如实 MANUAL_REQUIRED，不声称所有 Plus 账户都支持。
连接失败不索要凭据，不重开发 MCP，不降级为同一 AI 自我审查。

## 6. 首个 Mission 的执行闸门

由实际启动对话检查以下全部条件，不得仅按脚本退出码判断：

- 唯一原始 Core、唯一 Planner、唯一 Executor、实际项目和目标身份一致，无未解决冲突；
- 本次两组真实 HELLO/ACK 的原始平台收发、执行和唤醒证据可核实；
- 用户真实批准的摘要已保存，正式索引与规程已建立；
- 外参师实际 MCP 指向正确项目且允许的文件能读取；
- 无未解决阻断，用户的启动批准可在真实对话中定位。

    & <skill-root>/scripts/check-startup-readiness.ps1 -RoleMapPath <map> -EventsPath <events> -ExecutionId <id> -PlatformEvidencePath <raw-records> -McpEvidencePath <actual-read-records> -ApprovedSummaryPath <summary> -AsJson

恢复时增加 -Mode Recovery。
脚本 status=MANUAL_REQUIRED、may_start_mission=false 是有意的认证边界，不是“再填一个 PASS”即可解决。
不用 -AsJson 时以非零退出阻止旧自动调用者误放行；JSON 模式仅让调用者获得结构结果。
可选旧 HumanAuthorizationPath 只校验内容一致性，授权文件和哈希不是用户真实批准的证明。
不要求用户计算哈希或填写 JSON；有权限访问原始记录的流程完成核验，并定位已有实际批准；
证据不可访问时继续 MANUAL_REQUIRED，不自行宣称平台通过或首次使用验收完成。
完成真实核验后才 BOOTSTRAP_STATE = COMPLETE，发布首个 Mission；后续按既有接力规则运行。
