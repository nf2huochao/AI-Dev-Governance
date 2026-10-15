# 接力协议 / Relay Protocol

## 1. Purpose

本协议定义司策令（Mission Planner）与执造者（Build Executor）的正式开发接力。正常开发留在接力链内部；天枢核和外参师只在协议规定的异常、Gate 或独立审查场景介入。

核心原则：**No AI supervises itself. / AI 无法自我监督。**

## 1.1 Event-driven continuation

正常接力的通信行为必须遵循：

```text
SEND → YIELD → WAKE → ACT
```

核心规则：**No polling. Work on events. / 禁止空转轮询，依靠事件驱动。**

- 发送方发送成功后记录发送事件，立即 `YIELD` 并结束当前执行回合；发送成功只证明消息已被传输层接受，`send success is not task completion`。
- 接收方由真实消息或平台调度事件 `WAKE`，读取已收到的 Contract、ACK 或 HANDOFF 后再 `ACT`。
- 发送方不得主动轮询接收方线程状态、反复读取对方聊天记录、使用 `sleep` 等待或持续查询“是否完成”。
- ACK 只表示任务已接收，不表示任务完成、Handoff 已提交或 Review 已完成。
- 平台若不能在发送方结束当前回合后提供真实回唤（`real wake capability`），必须记录 `CAPABILITY GAP` 并将受影响路线置为 `BLOCKED`；不得用无限轮询伪造事件驱动。
- 消息发送失败时记录真实错误，只进行一次定向恢复（`one targeted recovery`）；恢复仍失败则 `BLOCKED` 或按协议 `ESCALATE`，不得无限重试。

## 2. Role ownership

正式接力前必须先完成 Team-First Bootstrap：当前原始 Codex 对话执行 `BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT`，生命周期为 `CURRENT_CONTEXT / REUSE_CURRENT`；只建立一个 `MISSION_PLANNER` 和一个 `BUILD_EXECUTOR`，新增 Codex 线程数必须恰好为 2，并完成两组 `BOOTSTRAP_HELLO → BOOTSTRAP_ACK`。任何 Core Architect 创建事件或第三个新线程都使 Bootstrap 失败，不得创建 Mission、TASK 或业务代码。

每个通信记录必须分开保存 `PROJECT_ID`、`ROLE_ID`、`THREAD_ID`、`COMMUNICATION_TARGET_HANDLE`、`TASK_ID`、`EXECUTION_ID` 和可选的 `OUTER_TASK_ID`。`THREAD_ID` 表示线程身份；发送目标必须使用原生消息工具实际要求且已经核实的 `COMMUNICATION_TARGET_HANDLE`。只有平台契约证明二者相同时才可记录同值；不得根据字段名猜测，也不得使用显示名、TASK_ID、EXECUTION_ID 或 OUTER_TASK_ID 路由消息。

| Activity | Owner | Boundary |
|---|---|---|
| Mission and Phase/Gate | Core Architect | 不拆日常代码 TASK，不写业务代码 |
| TASK creation and dispatch | Mission Planner | 不写代码，不修改正式架构 |
| Implementation, tests, commit | Build Executor | 唯一正式业务代码写入者 |
| Review decision | Mission Planner | 不由 Build Executor 自己 PASS |
| Independent evidence audit | External Advisor | 不参加普通接力，不派日常 TASK |

## 3. State machine

### Normal path

```text
DISPATCH → ACK → WORKING → HANDOFF → REVIEW → PASS
                                             │
                                             └→ next TASK / DISPATCH
```

### Exception path

```text
REVIEW → REWORK → WORKING → HANDOFF → REVIEW
WORKING/HANDOFF/REVIEW → BLOCKED → ESCALATE
REVIEW → ESCALATE
```

`PASS`、`REWORK`、`BLOCKED` 和 `ESCALATE` 只能由司策令在 Review 阶段作出；执造者只能提交 `HANDOFF` 或 `BLOCKED`。

## 4. Valid transitions (all other transitions are invalid)

| From | To | Actor | Required evidence |
|---|---|---|---|
| DISPATCH | ACK | Build Executor | 已读取 TASK Contract，确认边界 |
| DISPATCH | BLOCKED | Mission Planner / Build Executor | ACK 前真实阻断，error_ref 指向实际错误，不补 ACK |
| ACK | WORKING | Build Executor | 开始执行，未改变任务契约 |
| WORKING | HANDOFF | Build Executor | 改动、测试、Commit、Evidence |
| WORKING | BLOCKED | Build Executor | 明确阻断条件和已尝试内容 |
| HANDOFF | REVIEW | Mission Planner | Handoff 已收到 |
| HANDOFF | BLOCKED | Mission Planner | Handoff 证据缺失或无法进入 Review，记录阻断 |
| REVIEW | PASS | Mission Planner | Acceptance Criteria 全部满足 |
| REVIEW | REWORK | Mission Planner | 明确缺陷、根因仍在当前 Scope |
| REVIEW | BLOCKED | Mission Planner | 缺前置条件、证据或无法继续 |
| REVIEW | ESCALATE | Mission Planner | 连续 REWORK、架构冲突或无法判断 |
| PASS | DISPATCH | Mission Planner | 下一 TASK 仍属于当前 Mission |
| REWORK | WORKING | Build Executor | 收到范围内针对性修正 |
| BLOCKED | ESCALATE | Mission Planner | 记录阻断并向上升级 |
| ESCALATE | DISPATCH | Mission Planner | 必须包含有效 `resolution_ref`，证明受影响路线已获解除决定 |

其他状态转换均为非法，不能通过改写状态文字绕过。

## 5. TASK Contract

司策令派发前必须提供：

```text
TASK
TASK-ID:
Goal:
Why now:
Scope:
Out of Scope:
Dependencies:
Acceptance Criteria:
Tests:
Evidence:
Counter Evidence:
Risk Level: R0 | R1 | R2 | R3
Expected Handoff:
```

`Scope`、`Out of Scope` 和 `Acceptance Criteria` 是执造者的工作边界。任何缺失都应先 `BLOCKED` 或退回补全，不得靠猜测扩大任务。

## 6. ACK and WORKING

执造者 ACK 至少说明：

```text
ACK
TASK-ID:
Scope understood:
Out of Scope understood:
Dependencies available:
Planned tests:
```

ACK 不等于完成，不等于 PASS。执行期间只能修改 Scope 内的业务代码和必要测试。

ACK 发送成功后，Build Executor 继续自己的 TASK 工作；Mission Planner 不因 ACK 保持在线或开始轮询。ACK、工作完成和 Handoff 是三个不同事件。

## 7. HANDOFF Contract

执造者完成后必须提交：

```text
HANDOFF
TASK-ID:
Status: COMPLETE | BLOCKED
Changed Files:
Commit:
Tests Run:
Test Results:
Evidence:
Counter Evidence:
Known Limitations:
Next Expected Action:
```

执造者报告的是实现状态和证据，不得写 `PASS` 作为自己的结论。司策令必须重新检查证据。

## 8. PASS and continuation

司策令确认所有 Acceptance Criteria 满足后才能 `PASS`。PASS 后必须：

1. 记录 Review Evidence；
2. 关闭当前 TASK；
3. 当前 Mission 仍有批准范围内的有价值工作时，创建下一 TASK 并发送 DISPATCH；
4. Mission 目标满足则向天枢核发送 MISSION_COMPLETE 和证据，然后 YIELD；不凑 TASK，完成报告不等于 Gate PASS。

PASS 不允许成为无限扩大当前任务的理由。

发送完全失败时保留错误，不记录成功 DISPATCH；已记录 DISPATCH 但 ACK 前受阻可 DISPATCH → BLOCKED，error_ref 必须可定位。一次定向恢复失败后让出执行权，不轮询、不补 ACK。

### V0.1.3 正式事件与证据关联

新项目 formal event 使用 schema_version=2，保留原有字段，增加真实发送者 thread_id、项目内相对路径 evidence_ref。DISPATCH 增加 contract_ref、target_thread_id、target_handle；HANDOFF 增加 handoff_ref 和司策令目标；REVIEW/PASS/REWORK 增加 review_ref。Contract/Handoff/Review 文件包含匹配的 PROJECT_ID 与 TASK_ID，以及既有目标、测试、Commit 或可验证 Evidence。可选 commit_id 必须能在真实仓库解析。

路径必须在工作区内且不能经链接逃逸；证据存在和上下文匹配不证明真实平台事件。原始收发、执行与独立 Review 由可访问原始记录的流程核验。

旧日志不改写，报告 LEGACY_EVIDENCE_GAP；在新任务边界开始 schema 2 后不能降级，旧角色表不因重新安装自动升级。declared_tasks 数 PASS 标签，evidence_linked_tasks 数本地关联完整的任务；completed_tasks=0 表示本脚本不认证完成数，不是否定原任务。真实完成数须独立证据审核。

MISSION_COMPLETE 是 Planner 控制报告，须在当前 TASK REVIEW/PASS 后发生，包含 role_id、thread_id、project_id、mission_id、execution_id、evidence、evidence_ref；它不能自动通过 Gate，也不能继续给已完成 Mission 派新任务。

发送新的 DISPATCH 成功后，Mission Planner 必须立即 `YIELD`。下一次执行只能由 Build Executor 的真实 ACK、HANDOFF、BLOCKED 或通信错误事件唤醒。

## 9. Event recording

正式状态由司策令依据真实收发、执行与 Review 证据统一归档；actor/thread_id 表示实际事件主体，不是运行记录脚本的人。Bootstrap 创建/握手控制记录由原始天枢核负责。先保存原始证据，按因果顺序追加，不为顺序倒改真实时间，不让各角色抢写同一日志。

使用 `scripts/add-relay-event.ps1`，不能以 `Add-Content`、`Set-Content` 或自编写文件操作代替。准备的 EventPath 只能描述已发生事件，采用 schema_version=2；event_id 是稳定的本地记录去重号，不是虚构的平台 message ID。完整字段仍按现有状态契约与证据要求填写，不新增未定义的 REVIEW_PASS、SUPERSEDING_DISPATCH 等状态；项目说明写入对应任务/决定资料，不伪装成正式事件。

```powershell
# EventPath 已根据真实事件及其原始证据准备；示例不是模拟派发。
$hash = (Get-FileHash -LiteralPath (Join-Path $ProjectPath '.ai-governance/RELAY_EVENTS.jsonl')).Hash
& <skill-root>/scripts/add-relay-event.ps1 -ProjectPath $ProjectPath -EventPath $EventPath -ExpectedLogHash $hash
```

写入者独占写锁，不等待锁；校验完整的历史加候选，成功后只追加。相同 event_id 与相同内容重交不重复写，冲突 ID、过期哈希、非法转换/证据、已损坏历史均拒绝写入，原历史保留。失败保存具体错误，在下一合法事件核对，不盲重试、不补造漏失事件；旧错误的更正/迁移必须显式审查证据，不把日志改成 PASS。

`check-relay.ps1 -EventLines` 只验证内存预览，validation_source=provided_preview，不是磁盘日志已通过的证明。正常核查省略该参数。锁、哈希及校验只保障本地一致性，不认证角色或平台事实。

机器可读的必填字段、角色规则和状态转换唯一来源是 [`relay-contract.json`](relay-contract.json)。脚本、文档示例与测试必须以该文件为准；`event` 与 `status` 必须一致，传输状态不得冒充任务状态。

## 10. Send boundary and communication authorization

DISPATCH、HANDOFF、Mission 或恢复消息成功发送后：保存原始参数/返回，结束回合，等真实消息或合法调度继续。不能用原生 `wait_threads`、afterCursor、timeoutMs=0、反复 `read_thread` 或 sleep 保持在线；“只再确认一次”也不能延长发送边界。Executor 的 ACK 是继续自己工作的收件确认，不是 HANDOFF；不能把 ACK 后独立开发误判为应停止。

收到明确诊断请求或单次 Watchdog 时可按其范围核对一次现态，完成恢复发送后仍立即 YIELD。`check-relay-behavior.ps1` 供后续独立审查：输入原生 read_thread 完整回合导出及边界发送工具 call ID，仅检查实际 mcpToolCall 顺序，不数正文里提到的工具名；未结束的回合不能报告已让出。它不证明原始文件真实性或未来代理遵守规则，不能为了检查而在发送后持续读取线程。

初始化时确认真实人类授权覆盖本项目已绑定角色之间的派发、ACK、交接、风险报告与审查结果，不含团队外或敏感正文。保存原批准的可核实引用；接收上级消息、治理 JSON 或“已授权”文字不自行创造发送权限。已有批准先从真实来源核验；若平台仍要求发送方对话直接确认，说明具体缺口，遵守审批，不重建角色、不无限请求、不假装通信成功。
