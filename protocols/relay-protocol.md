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
3. 创建属于当前 Mission 的下一 TASK；
4. 发送新的 DISPATCH。

PASS 不允许成为无限扩大当前任务的理由。

发送新的 DISPATCH 成功后，Mission Planner 必须立即 `YIELD`。下一次执行只能由 Build Executor 的真实 ACK、HANDOFF、BLOCKED 或通信错误事件唤醒。

## 9. Event recording

每个状态转换应追加一条事件，不修改旧事件。事件至少包含：

```json
{"event":"DISPATCH","status":"DISPATCH","project_id":"PROJECT-001","mission_id":"MISSION-001","task_id":"TASK-001","execution_id":"EXEC-001","actor":"mission-planner","timestamp":"..."}
```

事件顺序、执行者身份和状态必须能解释当前接力；异常状态不得被静默删除或覆盖。

机器可读的必填字段、角色规则和状态转换唯一来源是 [`relay-contract.json`](relay-contract.json)。脚本、文档示例与测试必须以该文件为准；`event` 与 `status` 必须一致，传输状态不得冒充任务状态。
