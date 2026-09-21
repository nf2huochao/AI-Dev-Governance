# AI 开发治理局 / AI Dev Governance
## V0.1 产品规格与开发计划

**版本：V0.1**
**定位：ChatGPT + Codex 场景下的 AI 开发治理 Skill**
**目标用户：有真实开发需求、预算有限、开发经验有限、主要依靠 AI 编程的个人用户与小团队**
**核心原则：No AI supervises itself. / AI 无法自我监督。**

---

# 1. 产品定位

AI 开发治理局（AI Dev Governance）不是一个新的编程 Agent Framework，也不是一个多 Agent Swarm。

它是一套面向 ChatGPT + Codex 的 **AI 开发治理 Skill**，用于帮助普通用户建立一个长期、可监督、可接力、可纠偏的 AI 开发组织。

它重点解决的不是：

> “怎样让 AI 写代码？”

而是：

> “怎样让多个 AI 角色持续开发几十、几百个任务以后，仍然知道自己为什么在做、做到哪里、是否跑偏、是否重复旧问题、是否需要升级给用户处理。”

---

# 2. V0.1 核心用户

V0.1 主要服务以下用户：

- ChatGPT Plus + Codex 用户；
- 预算有限，无法长期使用最贵模型的用户；
- 主要依赖 Luna High 等低成本模型持续开发的用户；
- AI 编程新手；
- 非专业程序员；
- 独立开发者；
- 一人公司；
- 小团队；
- 有真实产品开发需求，但缺少完整工程团队的人。

V0.1 不以大型专业研发团队为主要目标用户。

---

# 3. 产品核心目标

V0.1 要实现：

1. 用户能够在 10 分钟内建立四角色 AI 开发组织；
2. 四个角色职责稳定、互不越权；
3. 司策令与执造者可以形成持续开发接力；
4. 天枢核可以主动发现断链、跑偏、重复开发和架构漂移；
5. 外参师可以通过 MCP 独立读取真实工程证据；
6. AI 不允许自我验收；
7. 已关闭的问题和被否决的技术路线不会被轻易重新打开；
8. 普通用户不需要理解全部代码细节，也能知道：
   - 当前阶段；
   - 当前任务；
   - 谁在工作；
   - 有没有阻断；
   - 有没有跑偏；
   - 下一步是什么；
9. 大多数日常工作可以由低成本模型承担；
10. 对话丢失后，可以依靠治理规则和治理文件恢复。

---

# 4. V0.1 支持范围

## 4.1 首发平台

V0.1 **仅支持**：

```text
ChatGPT + Codex
```

V0.1 不做 Claude Code 兼容。

V0.1 也不承诺支持：

- Gemini CLI；
- OpenCode；
- 其他 Agent Framework；
- 其他 IDE Agent。

---

# 5. 核心原则

## 5.1 核心原则 1

> **No AI supervises itself.**
> **AI 无法自我监督。**

工程解释：

> **任何 AI 都不能成为自己工作结果的最终裁判。**

例如：

- 执造者不能验收自己的代码；
- 司策令不能把自己的规划判断当作最终事实；
- 天枢核不能成为整个治理系统唯一的真理来源；
- 外参师不能取代 Human Governor 做最终授权。

---

## 5.2 核心原则 2：Single Writer

> **同一项目、同一时间，只允许执造者作为正式业务代码写入者。**

外参师、天枢核、司策令均不直接写业务代码。

---

## 5.3 核心原则 3：低成本模型负责吞吐，强模型负责稀缺判断

日常工作：

- 司策令；
- 执造者；
- 天枢核轻量巡检；
- 普通验收；

应尽量由低成本模型承担。

只有以下场景升级到外参师：

- 复杂 Root Cause；
- 重大架构争议；
- 长期 BLOCKED；
- 连续 REWORK；
- 高风险 Gate；
- 用户怀疑整个 AI 团队走偏；
- 天枢核自身无法判断；
- 需要独立工程证据审查。

---

## 5.4 核心原则 4：正常工作留在接力链内部

> **Execution stays inside the relay.**

正常开发不频繁向上汇报。

司策令与执造者形成主要开发闭环：

```text
司策令
↓
执造者
↓
司策令
↓
执造者
```

只有异常、阶段完成、授权需求等才逐级上升。

---

## 5.5 核心原则 5：外参师只做独立审查

> **The advisor observes the system, but does not run it.**

外参师：

- 可以独立调查；
- 可以用 MCP 读取真实证据；
- 可以提出架构纠偏；
- 可以帮助用户制定规则；
- 可以分析复杂异常。

外参师不能：

- 直接给执造者派任务；
- 绕过天枢核建立第二条指挥链；
- 日常替代司策令；
- 参与普通接力；
- 直接修改业务代码。

---

# 6. V0.1 组织结构

```text
用户 / Human Governor
目标 / 决策 / 授权
        │
        ├──────────────────────────────┐
        │                              │
        ▼                              ▼
外参师 / External Advisor          天枢核 / Core Architect
独立审查 / 异常分析               阶段 / Gate / 架构治理
MCP读取真实工程证据               主任务 / 20分钟巡检
        │                              │
        └──── Advisory ───────────────►│
                                       │
                                       ▼
                              司策令 / Mission Planner
                              拆任务 / 派发 / 验收
                                       │
                                       ▼
                              执造者 / Build Executor
                              代码 / 测试 / Commit
                                       │
                                       └── Handoff ──► 司策令
```

---

# 7. 四个固定角色

V0.1 固定四个角色，并要求分别创建独立新对话。

---

## 7.1 外参师 / External Advisor

### 定位

MCP 开发总顾问。

### 主要职责

- 与用户讨论项目；
- 协助需求分析；
- 协助制定治理规则；
- 独立审查；
- 复杂异常分析；
- Root Cause Analysis；
- 重大架构审查；
- 重大 Gate 审查；
- 通过 MCP 读取真实工程证据；
- 验证其他 AI 的结论是否成立。

### MCP 边界

**V0.1 中 MCP 仅用于外参师。**

MCP 不作为 Agent 通信总线。

外参师可通过 MCP 读取：

- Workspace；
- Git status；
- Commit；
- Diff；
- Tests；
- 代码；
- 文件；
- 执行结果；
- 真实工程证据。

### 禁止事项

- 不直接给司策令派日常任务；
- 不直接给执造者派任务；
- 不直接修改业务代码；
- 不替代天枢核运行开发组织；
- 不替代 Human Governor 做最终授权。

---

## 7.2 天枢核 / Core Architect

### 定位

最高治理与架构控制中心。

### 主要职责

- 管理当前 Phase；
- 管理当前 Gate；
- 发布主任务 Mission；
- 架构治理；
- 检查开发是否偏离主线；
- 检查是否重复打开已关闭问题；
- 检查是否重新采用被否决路线；
- 20 分钟巡检；
- 发现接力断链；
- 发现阶段变化；
- 判断是否继续、纠偏、暂停或等待用户授权。

### 天枢核管理的是

```text
Mission
Phase
Gate
Architecture
Deviation
Escalation
```

而不是每一个代码 Task。

### 禁止事项

- 不写业务代码；
- 不替代司策令拆日常 Task；
- 不直接长期管理执造者；
- 不进入普通 Debug 循环；
- 不重复执行执造者已经做过的工作。

---

## 7.3 司策令 / Mission Planner

### 定位

任务规划、派发、验收中枢。

### 主要职责

```text
接收 Mission
↓
拆分最小可验收 TASK
↓
派发给执造者
↓
等待 Handoff
↓
验收
↓
PASS / REWORK / BLOCKED / ESCALATE
↓
继续派下一 TASK
```

### 正常开发闭环

```text
司策令
DISPATCH
↓
执造者
ACK → WORKING → COMMIT → HANDOFF
↓
司策令
REVIEW
↓
PASS → 下一 TASK
```

### 什么时候向天枢核汇报

只在：

- 当前 Mission 完成；
- 真实 BLOCKED；
- 连续失败；
- 架构冲突；
- 无法判断；
- 需要用户授权；
- 需要阶段调整。

### 禁止事项

- 不直接写业务代码；
- 不修改执造者 Evidence；
- 不擅自修改 Phase/Gate；
- 不通过扩大范围解决单个任务；
- 不自己代替执造者完成任务。

---

## 7.4 执造者 / Build Executor

### 定位

唯一正式代码写入者。

### 标准工作流程

```text
ACK
↓
读取最少必要上下文
↓
确认任务边界
↓
最小修改
↓
测试
↓
Debug
↓
必要回归
↓
Commit
↓
Evidence
↓
Handoff
```

### 主要职责

- 代码实现；
- 测试；
- Debug；
- 构建；
- Commit；
- Handoff；
- 真实技术证据。

### 禁止事项

- 不自己修改任务验收标准；
- 不修改 Phase/Gate；
- 不修改正式架构 Decision；
- 不修改 NO-GO；
- 不给自己 PASS；
- 不擅自扩大任务范围；
- 遇到架构矛盾必须 BLOCKED 或 ESCALATE。

---

# 8. Human Governor

Human Governor 是整个系统最高权力来源。

用户保留：

- 最终产品目标；
- 重大方向改变；
- 重大风险授权；
- 生产环境授权；
- 删除和不可逆操作授权；
- 重大架构争议裁决；
- 关键产品判断。

Human Governor 不需要参与每一个普通 Task。

---

# 9. MCP 使用规则

V0.1 中：

> **MCP 只用于外参师进行独立审查和异常分析。**

MCP 不用于：

- 天枢核 ↔ 司策令通信；
- 司策令 ↔ 执造者通信；
- 普通 Task 派发；
- 普通 Handoff；
- 自动事件总线。

外参师使用 MCP 的核心目的：

> **Independent Evidence Verification**

即：

```text
其他 AI 的说法
↓
提出可验证 Claim
↓
MCP 读取真实工程证据
↓
寻找 Counter Evidence
↓
独立判断
```

---

# 10. 接力协议

## 10.0 事件驱动接力

V0.1 的普通接力遵循：

```text
SEND → YIELD → WAKE → ACT
```

即：角色发送消息并确认发送成功后，立即结束当前执行回合；接收方在真实消息或平台调度事件到达时唤醒并继续处理。**No polling. Work on events. / 禁止空转轮询，依靠事件驱动。**

发送成功不等于接收方已完成，ACK 不等于 Handoff，日志或治理文件不等于真实回传。任何角色不得主动轮询其他角色线程、反复读取聊天记录、使用 `sleep` 持续等待或无限重试。

消息发送失败时必须记录真实错误，只进行一次定向恢复；恢复失败则记录 `BLOCKED`/`ESCALATE`。如果平台不支持发送方结束当前回合后的真实回唤，必须记录 `CAPABILITY GAP` 并阻断受影响路线，不得以轮询伪装事件驱动。

## 10.1 标准状态机

```text
DISPATCH
↓
ACK
↓
WORKING
↓
HANDOFF
↓
REVIEW
↓
PASS
```

异常状态：

```text
REWORK
BLOCKED
ESCALATE
```

---

## 10.2 PASS

表示当前 TASK 满足验收条件。

司策令应立即：

```text
PASS
↓
生成下一 TASK
↓
继续派发
```

普通成功不向天枢核反复汇报。

---

## 10.3 REWORK

表示：

- 当前实现有明确缺陷；
- 根因明确；
- 仍属于当前 Task；
- 可通过一次针对性修正完成。

禁止：

```text
REWORK
↓
扩大范围
↓
重做整个系统
```

连续 REWORK 应升级。

---

## 10.4 BLOCKED

表示：

- 缺真实前置条件；
- 外部环境不满足；
- 架构矛盾；
- 无法继续；
- 需要更高层判断。

BLOCKED 不能通过“继续试”代替。

---

## 10.5 ESCALATE

用于：

- 连续 REWORK；
- 重大架构冲突；
- 天枢核需要独立审查；
- 用户需要授权；
- 怀疑整个开发路径错误。

---

# 11. TASK Contract

每个 TASK 至少包含：

```text
TASK-ID

Goal
目标

Why now
为什么现在做

Scope
允许修改范围

Out of Scope
禁止修改范围

Dependencies
依赖

Acceptance Criteria
验收条件

Tests
必须测试

Evidence
完成证据

Counter Evidence
什么情况说明其实没有完成

Risk Level
风险等级
```

---

# 12. 风险等级

## R0

文档、文案、小 UI。

验收：

- 基础检查。

---

## R1

普通局部代码。

验收：

- 定向测试；
- 司策令验收。

---

## R2

跨模块、集成、端到端。

验收：

- 定向测试；
- 必要回归；
- E2E；
- 司策令正式验收。

---

## R3

身份、权限、数据写回、架构、生产高风险操作。

验收：

- 司策令；
- 天枢核 Gate；
- 必要时外参师独立审查；
- 必要时 Human Governor 授权。

---

# 13. 天枢核 20 分钟巡检

20 分钟巡检负责：

1. 接力是否断链；
2. 当前任务是否服务当前 Mission；
3. 是否偏离当前 Phase/Gate；
4. 是否重新打开已关闭问题；
5. 是否重新采用已否决架构；
6. 是否出现临时旁路或第二套实现；
7. 是否连续围绕同一根因反复修复；
8. 是否当前 Task 已 PASS 仍继续扩张；
9. 是否存在长期 BLOCKED；
10. 是否已经满足进入下一 Gate 的条件。

正常情况下：

> 保持静默。

发现真实问题：

```text
PAUSE CURRENT ROUTE
↓
指出证据
↓
要求司策令收缩或重排
↓
恢复正常接力
```

---

# 14. 治理文件

V0.1 治理目录保持精简：

```text
.ai-governance/
├── CHARTER.md
├── CURRENT_PHASE.md
├── CURRENT_MISSION.md
├── RELAY_STATE.md
├── RELAY_EVENTS.jsonl
├── DECISIONS.md
└── ARCHITECTURE-NO-GO.md
```

这些文件用于：

- 持久治理；
- 恢复上下文；
- 天枢核巡检；
- 记录重大决策；
- 记录禁止路线；
- 记录当前阶段；
- 记录当前主任务；
- 记录接力状态。

这些文件 **不代替司策令与执造者的真实接力对话**。

---

# 15. CHARTER.md

记录项目治理宪章：

- 项目目标；
- Human Governor；
- 四角色；
- 权限边界；
- Single Writer；
- 核心原则；
- MCP 边界；
- 重大禁令。

---

# 16. CURRENT_PHASE.md

回答：

> 项目目前处于哪个阶段？

至少包含：

```text
Phase ID
Phase Goal
Current Gate
Entry Criteria
Exit Criteria
Current Mission
```

---

# 17. CURRENT_MISSION.md

回答：

> 天枢核当前要求司策令推进什么主任务？

至少包含：

```text
Mission ID
Goal
Why now
Scope
Out of Scope
Target Gate
Completion Standard
Escalation Conditions
```

---

# 18. RELAY_STATE.md

回答：

> 当前接力进行到哪里？

至少包含：

```text
Current Mission
Current Task
Current Owner
Current Status
Last Handoff
Next Expected Action
Last Updated
```

---

# 19. RELAY_EVENTS.jsonl

Append-only。正式初始化时必须是空文件；`governance/RELAY_EVENTS.template.jsonl` 只负责生成空日志，握手字段示例另存于 `examples/RELAY_EVENTS.bootstrap.example.jsonl`。旧事件不得修改，Bootstrap 检查必须按本次 `EXECUTION_ID` 选择事件，不得要求整个历史日志只有四条。

记录：

```text
DISPATCH
ACK
WORKING
HANDOFF
REVIEW
PASS
REWORK
BLOCKED
ESCALATE
PAUSE
RESUME
```

旧事件不得修改。

---

# 20. DECISIONS.md

记录正式架构和治理决定。

示例：

```text
DEC-001

Decision:
Only Build Executor may write business code.

Status:
ACCEPTED

Why:
Prevent self-review and conflicting writes.
```

状态至少包括：

```text
PROPOSED
ACCEPTED
SUPERSEDED
CLOSED
```

---

# 21. ARCHITECTURE-NO-GO.md

记录：

> 已经证明不能再走的技术路线和开发方式。

例如通用规则：

```text
已 CLOSED 的问题无新证据不得重新打开。

已 REJECTED 的架构不得换 TASK-ID 重做。

Mock / Fixture 通过不能直接宣称真实闭环完成。

PASS 后不得无限扩大 Task。

同一根因连续失败必须升级。

不得为了让测试通过持续增加第二套实现或临时旁路。
```

---

# 22. V0.1 明确非目标

V0.1 不做：

- Claude Code 兼容；
- 多 Executor 并发；
- 多 Agent Swarm；
- Web Dashboard；
- 自动部署；
- 自动 Merge；
- 自建 IDE；
- 模型路由；
- Token 计费系统；
- 企业级权限系统；
- SQLite；
- Governance MCP；
- Agent 消息总线；
- 大量自动 Agent；
- 无人值守开发。

---

# 23. 开发阶段

---

## Phase 0 — 产品规范冻结

### 目标

冻结 V0.1 产品设计。

### 交付物

```text
SPEC-V0.1.md
```

### Gate 0

必须满足：

- 产品目标明确；
- 用户明确；
- 四角色明确；
- 权限明确；
- MCP 边界明确；
- 接力模型明确；
- 治理文件明确；
- 非目标明确；
- 无重大架构歧义。

通过 Gate 0 前不得进入后续开发。

---

## Phase 1 — 四角色 Prompt

### 目标

形成四个正式初始化 Prompt。

### 交付物

```text
roles/
├── external-advisor.md
├── core-architect.md
├── mission-planner.md
└── build-executor.md
```

### Gate 1

四个角色必须：

- 明确知道自己是谁；
- 明确知道可以做什么；
- 明确知道不能做什么；
- 明确知道什么时候上报；
- 明确知道什么时候静默；
- 不发生角色混淆。

---

## Phase 2 — 接力协议

### 目标

建立司策令 ↔ 执造者稳定闭环。

### 交付物

```text
protocols/relay-protocol.md
```

至少覆盖：

```text
DISPATCH
ACK
WORKING
HANDOFF
REVIEW
PASS
REWORK
BLOCKED
ESCALATE
```

### Gate 2

至少模拟 20 次连续接力。

验收：

- 不断链；
- 不串角色；
- 不出现执造者自我验收；
- PASS 后能继续派发；
- BLOCKED 能正确上升。

---

## Phase 3 — 天枢核治理与巡检

### 目标

建立：

- Phase；
- Gate；
- Mission；
- 20 分钟巡检；
- Deviation Gate；
- NO-GO；
- Closed issue protection。

### 交付物

```text
protocols/core-governance.md
protocols/watchdog.md
```

### Gate 3

天枢核必须能够发现：

> 接力完全正常，但所有人正在做错误的事情。

---

## Phase 4 — 外参师 MCP 独立审查协议

### 目标

建立真正独立于执行链的工程审查。

### 交付物

```text
protocols/external-advisor-audit.md
```

### 审查步骤

```text
收集内部 Claim
↓
定义待验证问题
↓
MCP读取真实工程证据
↓
验证 / 反证
↓
Root Cause
↓
Advisory
↓
交给 Human / 天枢核
```

### Gate 4

必须模拟：

> 天枢核、司策令、执造者全部认为 PASS，但外参师通过真实工程证据发现实际并未完成。

---

## Phase 5 — 治理文件

### 目标

建立可持久化治理目录。

### 交付物

```text
governance/
├── CHARTER.template.md
├── CURRENT_PHASE.template.md
├── CURRENT_MISSION.template.md
├── RELAY_STATE.template.md
├── RELAY_EVENTS.template.jsonl
├── DECISIONS.template.md
└── ARCHITECTURE-NO-GO.template.md
```

### Gate 5

关闭四个角色原对话。

重新创建四个新对话。

仅依靠：

- 角色 Prompt；
- 治理文件；
- 当前项目状态；

能够恢复开发。

---

## Phase 6 — Skill 封装

### 目标

完成真正的 V0.1 Skill。

### 交付物

```text
SKILL.md
README.md
LICENSE
scripts/
examples/
```

Skill 应支持：

```text
初始化治理
↓
生成治理文件
↓
指导用户创建四个独立对话
↓
生成四个角色初始化 Prompt
↓
建立第一个 Phase
↓
建立第一个 Mission
↓
启动司策令 ↔ 执造者接力
```

### Gate 6

陌生用户能够按照 README 在 10 分钟内完成初始化。

---

## Phase 7 — 伍通项目 Dogfood

### 目标

在真实复杂项目验证。

### 最低要求

至少运行：

```text
50 个真实 TASK
```

### 收集指标

```text
TASK 总数
一次 PASS 率
REWORK 率
BLOCKED 率
ESCALATE 次数
接力断链次数
天枢核主动发现偏离次数
外参师独立发现问题次数
CLOSED 问题重开次数
人工干预次数
平均 TASK 时长
```

### Gate 7

至少满足：

- Executor 越权改治理规则 = 0；
- 外参师直接参与普通接力 = 0；
- 连续 REWORK 未升级 = 0；
- 接力断链显著降低；
- 重复问题显著降低。

---

## Phase 8 — 第二项目验证

### 目标

证明不是伍通专用提示词。

选择完全不同项目，例如：

- 小型 SaaS；
- 浏览器工具；
- Python 应用；
- 管理后台；
- 个人应用。

### 限制

不允许修改四角色核心治理模型。

只允许填写项目特定信息。

### Gate 8

第二项目可以稳定运行。

---

## Phase 9 — GitHub V0.1

### 目标

正式开源。

### README 第一屏必须说明

#### 面向谁

> 有真实开发需求，但预算和工程经验有限的人。

#### 解决什么

> 防止 AI 长期开发中的断链、跑偏、重复、错误自验和架构漂移。

#### 怎么工作

```text
Human Governor
↓
External Advisor
↓
Core Architect
↓
Mission Planner
⇄
Build Executor
```

并突出：

> **No AI supervises itself.**

---

# 24. 首次使用与项目初始化补充

V0.1 的首次使用从调用 Skill 的第一刻起，就把当前原始 Codex 对话绑定为唯一 `CORE_ARCHITECT`，并进入临时 `BOOTSTRAP_STATE = ACTIVE`。Bootstrap 是状态，不是角色；不存在 `SETUP_ASSISTANT → CORE_ARCHITECT` 的角色转换。当前对话使用 `CURRENT_CONTEXT / REUSE_CURRENT`，只读检查工作区后仅为 `MISSION_PLANNER` 和 `BUILD_EXECUTOR` 创建两个新 Codex 对话。

正式初始化必须保留批准摘要原文，并生成项目索引、开发规程和显示名映射；显示名不能替代固定内部身份。司策令和执造者必须是两个真实独立的 Codex 对话，不能由当前对话模拟，也不能复用其他项目线程。Core Architect 不得出现 `ROLE_THREAD_CREATED` 事件；Bootstrap 必须断言 `EXPECTED_NEW_CODEX_THREADS = 2`。`THREAD_ID`、实际通信目标句柄、`TASK_ID`、`EXECUTION_ID` 和 `OUTER_TASK_ID` 必须分开记录，不能凭字段名称互相替代。真实通信和 External Advisor MCP 目标必须由平台证据确认；无法确认时记录 `MANUAL_REQUIRED` 或 `CAPABILITY GAP`。

未通过的启动检查不得显示为成功，天枢核不能在摘要批准、工作区确认、独立通信和 MCP 能力均未就绪前发布首个 Mission。结构化治理文件不得冒充平台原始证据；如果平台没有可认证的原始线程、消息和执行记录接口，启动状态必须是 `MANUAL_REQUIRED`。初始化脚本必须幂等并跳过已有文件，不覆盖批准摘要、角色规则或用户资料。

## 24.1 用户资料和初始化交付物

Skill 提供以下项目级资料模板和检查工具：

- `PROJECT-STARTUP-SUMMARY.template.md`：用户审查和批准的需求基线；
- `PROJECT-INDEX.template.md`：项目资料权威来源索引；
- `DEVELOPMENT-RULES.template.md`：项目开发规程；
- `ROLE-MAP.template.md`：显示名与固定内部身份映射；
- `check-workspace.ps1`：只读工作区检查；
- `check-mcp-target.ps1`：根据平台报告路径检查 MCP 目标，不伪造连接；
- `init-governance.ps1 -ApprovedSummaryPath ...`：批准后幂等生成项目资料。

# 25. V0.1 最终仓库建议结构

```text
ai-dev-governance/
│
├── SKILL.md
├── README.md
├── LICENSE
├── SPEC-V0.1.md
│
├── roles/
│   ├── external-advisor.md
│   ├── core-architect.md
│   ├── mission-planner.md
│   └── build-executor.md
│
├── governance/
│   ├── CHARTER.template.md
│   ├── CURRENT_PHASE.template.md
│   ├── CURRENT_MISSION.template.md
│   ├── PROJECT-STARTUP-SUMMARY.template.md
│   ├── PROJECT-INDEX.template.md
│   ├── DEVELOPMENT-RULES.template.md
│   ├── ROLE-MAP.template.md
│   ├── RELAY_STATE.template.md
│   ├── RELAY_EVENTS.template.jsonl
│   ├── DECISIONS.template.md
│   └── ARCHITECTURE-NO-GO.template.md
│
├── protocols/
│   ├── relay-protocol.md
│   ├── escalation-protocol.md
│   ├── review-protocol.md
│   ├── core-governance.md
│   ├── watchdog.md
│   └── external-advisor-audit.md
│
├── scripts/
│   ├── init-governance.*
│   ├── check-workspace.*
│   ├── check-mcp-target.*
│   ├── validate-governance.*
│   └── check-relay.*
│
├── examples/
│   └── example-project/

└── docs/
    ├── FIRST-USE-ONBOARDING.zh-CN.md
    ├── PROJECT-PLANNING-PROMPT.zh-CN.md
    ├── MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md
    └── FAILURE-RECOVERY.zh-CN.md
```

---

# 26. V0.1 最终验收标准

V0.1 发布前必须满足：

- [ ] 10 分钟内能建立四角色开发组织；
- [ ] 四个角色边界稳定；
- [ ] 司策令与执造者可以持续接力；
- [ ] 正常开发不需要用户频繁搬运消息；
- [ ] 天枢核能主动发现断链和偏离；
- [ ] 外参师可以通过 MCP 独立验证真实工程证据；
- [ ] AI 不允许自我验收；
- [ ] 对话丢失后项目可以恢复；
- [ ] Luna High 等低成本模型可以承担绝大多数日常开发；
- [ ] 第二个不同项目无需修改核心体系即可运行。

达到以上条件：

> **AI 开发治理局 V0.1 完成。**

---

# 27. 给 Codex 的启动执行指令

下面内容作为第一次交给 Codex 的执行指令。

```text
你现在开始开发开源项目：

AI 开发治理局
AI Dev Governance

当前唯一产品基线是：

SPEC-V0.1.md

这份规格已经冻结了 V0.1 的核心产品方向。

你不得擅自扩大产品范围，不得主动增加未列出的 Agent、Dashboard、数据库、Governance MCP、并行执行、Claude Code 兼容、自动部署、自动 Merge 或其他 V0.1 非目标能力。

第一步只执行 Phase 0。

Phase 0 目标：

1. 完整读取 SPEC-V0.1.md；
2. 建立项目仓库基础目录；
3. 建立：
   - SPEC-V0.1.md
   - README.md 基础占位
   - LICENSE（经批准的许可证文本）
   - roles/
   - governance/
   - protocols/
   - scripts/
   - examples/
4. 检查当前仓库结构是否与规格一致；
5. 输出 Gate 0 验收结果。

Gate 0 通过前：

- 不编写四角色正式 Prompt；
- 不开发自动化脚本；
- 不开发 MCP；
- 不进入 Phase 1；
- 不主动扩展需求。

完成后提交：

PHASE-0-HANDOFF

必须包含：

- 创建了哪些文件；
- 仓库结构；
- 是否存在与 SPEC 冲突的地方；
- Gate 0 是否 PASS；
- 下一步建议。

如果发现规格内部存在真实矛盾：

不要自行改规格。

返回 BLOCKED，并明确指出冲突位置和建议，由 Human Governor 决定。
```

---

# 28. V0.1 北极星

AI 开发治理局最终不是为了：

> 让 AI 完全替代程序员。

也不是：

> 建一个更复杂的多 Agent 框架。

它的核心目标是：

> **让预算有限、工程能力有限的普通人，也有能力管理一支长期、可控、可审查、可纠偏的 AI 开发团队。**

并始终坚持：

> **No AI supervises itself.**
> **AI 无法自我监督。**
