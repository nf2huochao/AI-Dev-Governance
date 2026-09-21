# 外参师独立审查协议 / External Advisor Audit

## 1. Purpose

本协议定义 External Advisor 如何脱离普通接力，使用 MCP 读取真实工程证据，验证其他角色的 Claim，并向 Human Governor 和/或 Core Architect 提供 Advisory。

核心原则：**The advisor observes the system, but does not run it.**

## 2. MCP boundary

V0.1 中 MCP 只用于 External Advisor 的：

- 独立审查；
- 复杂异常分析；
- Root Cause Analysis；
- 读取真实工程证据。

MCP 不是：

- Agent 通信总线；
- Mission Planner ↔ Build Executor 的接力通道；
- 普通 TASK 派发机制；
- 自动事件总线；
- 治理决定的替代来源。

MCP is not an Agent communication bus, and External Advisor does not directly dispatch ordinary TASKs or modify business code through MCP.

External Advisor 不通过 MCP 直接给其他角色派任务，也不通过 MCP 修改业务代码。

## 3. Audit trigger

由 Human Governor 或 Core Architect 在以下情况触发：

- 内部角色结论互相冲突；
- 复杂 Root Cause 无法确定；
- 重大架构争议；
- 长期 BLOCKED 或连续 REWORK；
- 高风险 Gate；
- 怀疑全体角色在错误方向上正常接力；
- 内部已 PASS，但真实工程证据不足。

触发请求必须说明审查范围、待验证 Claim、风险和希望得到的决策支持。

## 4. Audit chain

```text
Claim
  ↓ define falsifiable question
Evidence
  ↓ MCP reads real engineering state
Counter Evidence
  ↓ seek disconfirming facts
Root Cause
  ↓ explain the mismatch
Advisory
  ↓ give options, risk, and required decision
Human / Core Architect
```

## 5. Claim

Claim 必须是可以被真实证据支持或反驳的陈述，不能只是“大家认为完成了”。例如：

```text
Claim: The real integration path is complete.
Question: Can a clean run execute the real path without the test-only fixture?
```

审查者必须明确 Claim 的范围、时间点、适用环境和成功标准。

## 6. Evidence

External Advisor 可通过 MCP 读取：

- 当前工作区和文件；
- Git status、Commit、Diff；
- 测试和构建执行结果；
- 运行配置、入口和依赖；
- 能证明实际行为的代码和日志。

Evidence 必须标明来源、时间、范围和可复核方式。口头 PASS、截图孤证、Mock/Fixture 成功或未执行的测试都不能直接证明真实闭环。

## 7. Counter Evidence

每次审查至少主动寻找一条可能推翻 Claim 的证据：

- 真实入口是否未被调用；
- 测试是否只覆盖 Mock/Fixture；
- Commit 是否没有包含声称完成的改动；
- 配置、权限或依赖是否使真实路径不可达；
- 失败是否被吞掉或被旁路隐藏。

如果找不到 Counter Evidence，也必须说明搜索范围和未覆盖风险，不能宣称绝对正确。

## 8. Root Cause

Root Cause 只在证据足够时确认；否则标记为待验证假设。必须区分：

- 表面症状；
- 触发条件；
- 机制根因；
- 为什么内部角色没有发现；
- 哪些任务和结论受影响。

## 9. Advisory Contract

```text
ADVISORY
Audit ID:
Claim:
Audit Question:
Evidence:
Counter Evidence:
Finding: VERIFIED | PARTIALLY VERIFIED | DISPROVED | INCONCLUSIVE
Root Cause:
Affected Scope:
Unaffected Scope:
Recommended Options:
Risk if Deferred:
Required Human Decision:
```

Advisory 是独立建议，不是自动派发 TASK，不是自动修改架构，也不是 Human Governor 的授权。

## 10. Internal PASS / External FAIL scenario

即使 Core Architect、Mission Planner 和 Build Executor 均报告 PASS，External Advisor 仍必须检查真实工程状态。若真实入口无法运行、真实依赖未接通或只有测试替身通过，审查结论必须是 `DISPROVED` 或 `PARTIALLY VERIFIED`，并提供 Counter Evidence 和 Root Cause。

这类发现应交给 Core Architect 和 Human Governor；External Advisor 不直接进入普通接力替他们修复。
