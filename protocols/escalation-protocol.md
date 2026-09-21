# 升级协议 / Escalation Protocol

## 1. Purpose

本协议规定异常如何收缩、记录、升级和恢复，防止用盲试、范围扩大或第二套实现掩盖真实问题。

## 2. Escalation levels

| Level | Meaning | First owner | Route |
|---|---|---|---|
| Technical Blocked | 当前技术条件不足，但方向仍清楚 | Build Executor / Mission Planner | 收缩 → 补证据或依赖 → 重新验证 |
| REWORK repeated | 同一根因多次修复仍失败 | Mission Planner | ESCALATE → Core Architect |
| Architecture Conflict | TASK 与正式架构、NO-GO 或 SPEC 冲突 | Mission Planner | BLOCKED → Core Architect |
| Independent Audit Needed | 内部角色都 PASS，但证据不足或互相冲突 | Core Architect | External Advisor 独立审查 |
| Human-only | 生产、真实凭据、不可逆、付费、正式发布或冻结架构变更 | Core Architect | Human Decision Queue |

## 3. Required escalation record

```text
ESCALATE
Escalation ID:
Source Task/Mission:
Current State:
Claim:
Evidence:
Counter Evidence:
Root Cause (if known):
Why current role cannot decide:
Blocked Scope:
Unaffected Work:
Requested Decision or Review:
Recommended Option:
Risk if Deferred:
```

## 4. Routing rules

- 执造者发现无法安全继续：先向司策令提交 BLOCKED，不直接找外参师派任务。
- 司策令发现连续失败、架构冲突或无法验收：向天枢核 ESCALATE。
- 天枢核发现需要真实工程独立证据：请求外参师审查。
- 外参师完成 Advisory 后交给 Human Governor 和/或天枢核，不进入普通接力。
- 涉及 Human-only 决策：写入项目 `.ai-governance/DECISIONS.md`，并标明阻断与不受影响工作。

## 5. Recovery rules

收到升级结果后，原任务只能执行明确的恢复路径：

- `RESUME`：依赖已满足，按原 Scope 继续；
- `REWORK`：只做记录中明确的最小修正；
- `REPLAN`：由天枢核重新定义 Mission/TASK；
- `CLOSE`：证明路线不应继续，写入 NO-GO 或 Closed Decision；
- `WAIT-HUMAN`：等待授权，不盲试；不依赖该决定的其他任务可以继续。

不得把升级结果默认为 PASS，也不得用新 TASK-ID 隐藏旧问题。

## 6. Human-only boundary

以下事项不能由任何 AI 自动批准：

- 生产环境变更；
- 使用真实密码、Token、Secret 或真实用户数据；
- 不可逆删除；
- 外部付费；
- 正式 Release 或公网部署；
- 改变冻结的 V0.1 架构或非目标边界；
- 重大产品承诺或账号权限变更。
