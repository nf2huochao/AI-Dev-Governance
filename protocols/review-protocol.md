# 验收协议 / Review Protocol

## 1. Review authority

司策令负责当前 TASK 的正式 Review，但不能把自己的规划判断当成事实，也不能由执造者自我验收。

执造者提供实现和 Evidence；司策令依据 TASK Contract 检查；天枢核负责 Mission、Gate 和架构层治理；外参师在需要时独立读取真实工程证据。

## 2. Review Contract

```text
REVIEW
TASK-ID:
Reviewer: Mission Planner
Acceptance Criteria:
Evidence Checked:
Tests Checked:
Counter Evidence Checked:
Scope Check:
Decision: PASS | REWORK | BLOCKED | ESCALATE
Reason:
Next Action:
```

Review 必须检查实际改动、Commit、测试结果、Counter Evidence、已知限制和是否超出 Scope。

## 3. PASS

只有在以下条件同时成立时才允许 PASS：

- 每条 Acceptance Criteria 都有对应证据；
- 测试结果与结论一致；
- 改动没有越过 Scope 或 Out of Scope；
- 没有用 Mock/Fixture 冒充真实闭环；
- 没有未披露的阻断或高风险限制；
- 当前 TASK 仍服务当前 Mission。

PASS 后司策令必须继续派发下一 TASK，不得让接力在成功后断开。

## 4. REWORK

REWORK 只适用于：缺陷明确、根因明确、仍在当前 TASK Scope 内、可通过一次针对性修正完成。

REWORK 必须写明：

```text
REWORK
TASK-ID:
Defect:
Root Cause:
Required Change:
Out of Scope:
Recheck Criteria:
```

禁止用 REWORK 重新设计整个系统、扩大 Mission 或增加第二套实现。第二次及以上围绕同一根因失败，应 ESCALATE。

## 5. BLOCKED

BLOCKED 表示无法在当前条件下安全继续，例如缺少真实依赖、必要证据、外部环境、权限或存在架构冲突。

BLOCKED 必须写明：

```text
BLOCKED
TASK-ID:
Blocking Condition:
Evidence:
Attempted Actions:
Required Input or Decision:
Unaffected Scope:
```

不能用“继续试”替代 BLOCKED，也不能用假测试结果解除阻断。

## 6. ESCALATE

以下情况应 ESCALATE：

- 连续 REWORK；
- 重大架构冲突；
- 司策令无法判断验收；
- 发现任务实际服务错误 Mission；
- 需要 Human Governor 授权；
- 怀疑多个角色都在错误方向上正常接力。

司策令先升级给天枢核；天枢核判断是否需要外参师独立审查或 Human Governor 决策。

## 7. Self-review prevention

- Build Executor 只能提交 HANDOFF，不能输出正式 PASS。
- Mission Planner 只能验收 Build Executor 的 Handoff，不能把自己写的规划当作实现证据。
- Core Architect 只能做治理和 Gate 判断，不能把自己的判断当作代码事实。
- External Advisor 的 Advisory 也不能替代 Human Governor 的最终授权。
