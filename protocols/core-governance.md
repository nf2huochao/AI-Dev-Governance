# 天枢核治理体系 / Core Governance

## 1. Purpose

本协议定义通用的 Phase、Gate、Mission、Deviation Gate、Decision Protection、Architecture NO-GO 和 Closed Issue Protection。

治理层回答：

> 当前团队是否在正确的阶段、围绕正确的 Mission、沿着仍被允许的路线推进？

治理层不替代司策令与执造者的日常接力，也不把治理判断伪装成真实代码证据。

## 2. Governance hierarchy

```text
Human Governor
    ↓ target / decision / authorization
Core Architect
    ↓ Phase / Gate / Mission / architecture governance
Mission Planner ⇄ Build Executor
    ↓ task relay / implementation / review
External Advisor
    ↗ independent evidence audit when requested
```

Human Governor 是最高权力来源；天枢核是 AI 组织中的治理控制中心；司策令与执造者运行普通接力；外参师只做独立审查。

## 3. Phase

`Phase` 是一组有明确目标、入口条件、出口条件和 Gate 的阶段。

每个 Phase 至少记录：

```text
Phase ID:
Phase Goal:
Entry Criteria:
Exit Criteria:
Current Gate:
Current Mission:
```

未通过当前 Gate 前，不得进入依赖该 Gate 的下一 Phase。技术阻断可以在同一 Phase 内收缩和修复；Human-only 阻断可以跳过受影响分支，但不能伪造 Gate PASS。

## 4. Gate

`Gate` 是对阶段出口的正式审查，不是“文件已经存在”的形式检查。Gate Review 至少检查：

- 交付物是否存在且边界符合 SPEC；
- 核心行为是否有可重复证据；
- 角色权限是否未越界；
- 是否存在未处理的 Deviation、NO-GO 或 Closed Issue 违规；
- 是否还有阻断当前出口的风险。

结果只有：

```text
PASS     允许进入下一阶段
PARTIAL  创建最小修正 TASK 后重新审查
BLOCKED  记录技术或 Human-only 阻断，不伪造通过
```

## 5. Mission

`Mission` 是当前 Phase 内由天枢核交给司策令的主任务。Mission 必须包含 Goal、Why now、Scope、Out of Scope、Target Gate、Completion Standard 和 Escalation Conditions。

Mission 不等于一个代码 TASK。司策令可以在 Mission 内拆分多个 TASK，但不能改变 Mission 的目标、边界或完成标准。

## 6. Deviation Gate

Deviation Gate 检查“当前正在做的事”是否仍然服务当前 Mission，而不是只检查接力状态是否正常。

每次巡检至少回答：

```text
Current Phase:
Current Gate:
Current Mission:
Current Task:
Does Task directly advance Mission? YES | NO | UNCLEAR
Is work inside Scope? YES | NO | UNCLEAR
Is a closed decision being reopened? YES | NO | UNCLEAR
Is a NO-GO route being retried? YES | NO | UNCLEAR
```

若 TASK 的状态机完整、测试也通过，但 `Does Task directly advance Mission?` 为 NO，则治理结果必须是 `PAUSE CURRENT ROUTE`，不能因为接力顺畅就 PASS。

## 7. Decision Protection

正式 Decision 必须有唯一 ID、内容、状态、原因、证据和替代关系。状态至少包括：`PROPOSED`、`ACCEPTED`、`SUPERSEDED`、`CLOSED`。

保护规则：

- `ACCEPTED` 决定不能被普通 TASK 悄悄覆盖；
- `SUPERSEDED` 必须指向替代它的新 Decision；
- `CLOSED` 问题无新证据不得重新打开；
- 改变正式 Decision 必须由天枢核治理，并在需要时升级 Human Governor；
- 执造者不能修改正式 Decision。

## 8. Architecture NO-GO

`ARCHITECTURE-NO-GO` 记录已证明不能继续的技术路线或工作方式。每条记录必须包含：路线、证据、失败原因、影响范围、替代路径和重新考虑所需的新证据。

以下行为不得作为默认恢复方案：

- 为了通过测试不断叠加第二套实现；
- 用 Mock/Fixture 代替真实闭环并宣称完成；
- 用新 TASK-ID 重新做已否决路线；
- 在没有新证据时反复打开已关闭问题。

## 9. Closed Issue Protection

重新打开 CLOSED 问题前必须提出：

```text
Closed Issue ID:
New Evidence:
Why Previous Decision No Longer Holds:
Affected Mission:
Risk of Reopening:
Required Approval:
```

没有新证据时，司策令和执造者必须拒绝重开，并升级给天枢核；天枢核不得用“进度需要”替代新证据。

## 9.1 Self-review protection

正常接力必须保持“实现者”和“验收者”分离；任何 `PASS` 都需要由负责 Review 的角色依据 TASK Contract 和证据作出，不能由实现者自我授予。

## 10. Governance result and recovery

发现偏离时：

```text
PAUSE CURRENT ROUTE
→ record evidence
→ identify root cause
→ shrink or replan the task
→ re-run the relevant Deviation Gate
→ RESUME only after governance condition is clear
```

正常巡检保持静默；发现偏离才打断当前路线。治理发现不直接写业务代码。
