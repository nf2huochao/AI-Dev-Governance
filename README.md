[English](README.en.md) | **简体中文**

# AI 开发治理局 / AI Dev Governance

> 启动顺序：`TEAM_FIRST_BOOTSTRAP`——先绑定原始天枢核，建立司策令与执造者并验证通信，再规划项目和授权开发。
>
> 验证状态：`EXTERNAL_VALIDATION_IN_PROGRESS`。脚本回归通过不等于所有 Codex 版本上的真实多对话、唤醒和 MCP 均已验证。

> **一句话定义**
>
> 一套面向 **ChatGPT Plus + Codex** 用户的开源 AI 开发治理 Skill，通过“外参师、天枢核、司策令、执造者”四角色协作，让长期软件开发更可监督、可纠偏、可接力。
>
> 大白话说，就是让 **外部顾问（外参师）帮你从局外检查方向，核心架构师（天枢核）把握全局，任务规划师（司策令）拆任务并验收，代码程序员（执造者）专心写代码和测试**；四个角色各管一件事，避免一个 AI 同时规划、执行、检查自己又宣布成功，让开发更不容易跑偏、漏错和半途断掉。

> **核心原则**
>
> **No AI supervises itself.**
>
> **AI 无法自我监督。**

<p align="center">
  <img src="docs/images/four-roles-banner.png" alt="AI 开发治理局四角色协作全景" width="100%">
</p>

## 版本与更新

- [v0.1.1：首次使用、安装和证据边界改进](https://github.com/nf2huochao/AI-Dev-Governance/releases/tag/v0.1.1)（当前公开测试版）。
- [v0.1.0：最初的公开测试版本](https://github.com/nf2huochao/AI-Dev-Governance/releases/tag/v0.1.0)（历史版本；与原 `v0.1.0-beta.1` 使用同一份代码）。

详细差异见[更新记录](CHANGELOG.md)。两个版本均非稳定版；新用户环境中的真实通信、自动发现和 MCP 仍需验证。

## 四职成局 · 各守其位

中国文化对于“治理”的理解，从来不只是发号施令。

真正能够长期运转的体系，讲究的是：**有中枢、有谋划、有执行，也有身处局外的观察与规谏。**

方向不能无人掌舵，执行不能无人验收；谋划者不应亲自代替执行者，执行者也不应自己宣布自己的工作已经正确。不同的位置承担不同的责任，彼此协作，也保持必要的边界。

> **位有所守，事有所归，权有所界，行有所验。**

AI 开发治理局借用这种秩序观，为 AI 软件开发建立四个彼此独立、相互接力的角色：

- **外参师 / External Advisor**
- **天枢核 / Core Architect**
- **司策令 / Mission Planner**
- **执造者 / Build Executor**

这些名称并不是对古代官职的复刻，也不是为了营造古风气氛。它们取意于中国语言中对 **局外观照、中枢定向、筹策调度、躬身成事** 的理解，并将这些含义映射为现代 AI 软件开发中的四种职责。

> **四位一体，各司其职；协同而不混同，制衡而不掣肘。**

---

## 外参师 · External Advisor

<p align="center">
  <img src="docs/images/roles/external-advisor.png" alt="外参师：局外观局，独立审查" width="92%">
</p>

### 局外观局，参而不代

真正重要的判断，有时需要一个不身处执行链条中的观察者。

外参师位于日常开发接力之外。它不领取普通 TASK，不代替开发者编写业务代码，也不为了让项目“看起来顺利”而自行放行。它与用户讨论项目目标、规则和重大变化，在关键阶段独立查看代码、Git、测试与证据，并在内部角色发生争议、异常或方向偏离时提供第二视角。

它负责：

- 项目整体目标与计划讨论
- 项目启动摘要整理
- 独立工程审查
- 重大异常分析
- 架构与方向建议
- 关键 Gate 外部复核
- 通过 MCP 读取被授权的真实工程证据

> **身在局外，方能观局；参与判断，而不代替执行。**

---

## 天枢核 · Core Architect

<p align="center">
  <img src="docs/images/roles/core-architect.png" alt="天枢核：把握全局与项目方向" width="92%">
</p>

### 居中定向，执枢而不躬作

“天枢”是北斗之枢。这里借它表达的是：**长期项目需要一个稳定的方向中心。**

天枢核持续掌握总体目标、当前阶段和架构边界，避免项目在几十个 TASK、数百次消息和多轮修改中逐渐偏离。

它负责：

- 维护项目总体方向
- 发布 Mission
- 管理 Phase 与 Gate
- 维护架构边界
- 记录重大决策与禁止路线
- 处理偏离、阻断和升级
- 在 Bootstrap 阶段建立并核验开发团队

天枢核治理开发，但不承担日常业务代码开发。

> **枢者定其向，不代百工之作。**

---

## 司策令 · Mission Planner

<p align="center">
  <img src="docs/images/roles/mission-planner.png" alt="司策令：拆解任务与独立验收" width="92%">
</p>

### 谋定其序，分而后行

复杂项目往往不是失败在“完全不会写代码”，而是失败在任务过大、边界不清、顺序混乱和验收模糊。

司策令把天枢核发布的 Mission 拆成真正能够执行和验收的 TASK，并负责：

- Mission 拆解
- TASK Contract
- 任务顺序与依赖
- 向执造者派发任务
- 接收 Handoff
- 独立 Review
- PASS / REWORK / BLOCKED 判断
- 通过后继续派发下一 TASK

它既不是最高方向制定者，也不是代码执行者。它把战略变成秩序，把目标变成步骤。

> **先定其策，再明其令；事有先后，行有次第。**

---

## 执造者 · Build Executor

<p align="center">
  <img src="docs/images/roles/build-executor.png" alt="执造者：实现代码与测试" width="92%">
</p>

### 躬身入局，执事成器

所有规划，如果没有变成真实代码、真实测试和真实可运行的软件，都只是纸面上的秩序。

执造者负责：

- 阅读代码与必要上下文
- 修改业务文件
- 编写功能
- 运行测试与调试错误
- 修复缺陷
- 提交 Git Commit
- 形成结构化 Handoff

在 V0.1 中，执造者是 **唯一正式业务代码写入者**。谁修改代码，谁提供执行证据；谁负责验收，就不应该同时成为被验收的人。执造者可以提交结果，却不能自己给自己最终 PASS。

> **谋可以众议，工必有人落实；功有所出，责有所归。**

---

# 四职如何成为一个开发治理系统

四个角色不是四个平行聊天机器人，而是一条有边界的开发秩序：

```text
                    用户 / Human Governor
                            │
                    最终目标与重大授权
                            │
              ┌─────────────┴─────────────┐
              │                           │
       外参师 External Advisor        天枢核 Core Architect
       独立观察 · 审查 · 建议           方向 · Phase · Mission · Gate
                                          │
                                          ▼
                                 司策令 Mission Planner
                                  拆解 · 派发 · Review
                                          │
                                          ▼
                                 执造者 Build Executor
                                 编码 · 测试 · 修复 · Handoff
                                          │
                                          └──────► 回到司策令验收
```

日常开发主链：

```text
天枢核
  ↓ Mission
司策令
  ↓ TASK
执造者
  ↓ ACK / WORKING / HANDOFF
司策令
  ↓ Review
PASS → 下一 TASK
REWORK → 定向返工
BLOCKED → 升级处理
```

外参师保持独立，不进入普通 TASK 流水线；用户始终保留目标、重大变化、高风险操作和发布授权。

## 治理，不是让 AI 变慢

好的治理不是让所有事情都等待确认，而是：

> **让该自动运行的事情自动运行，让真正重要的决定才回到人。**

V0.1 采用事件驱动接力：

```text
SEND → YIELD → WAKE → ACT
```

发送任务后让出执行权，由真实消息或调度事件唤醒下一角色继续工作，而不是持续轮询其他对话。普通、安全、已授权的开发工作持续推进；只有遇到方向变化、重大阻断、高风险操作或授权边界时，才重新寻找用户。

---

# 为什么选择 AI 开发治理局

很多 AI 开发流程的问题，不在于“AI 会不会写代码”，而在于：

- 单个 AI 容易自我确认和自我漂移
- 任务做着做着偏离最初目标
- 多轮开发缺乏稳定交接，返工严重
- 用户看不清当前阶段、决策依据和真实阻断
- 普通用户难以用有限预算支撑长期开发

AI 开发治理局不是简单增加更多 Agent，而是增加 **治理结构**：让不同角色分工明确，让任务派发、执行、回执和验收形成真实链路，让监督与执行分离，让用户始终拥有最终授权。

---

# 特点 / Features

## 1. Team-First Bootstrap

先建立团队并验证通信，再制定项目计划和启动正式开发：

- 当前原始 Codex 对话直接绑定为唯一 **天枢核**
- 只新建 **司策令** 与 **执造者** 两个 Codex 对话
- 先完成两组 HELLO / ACK 最小真实通信验证
- 绝不创建第二个天枢核

## 2. Event-Driven Relay

遵循 `SEND → YIELD → WAKE → ACT`：

- 不持续轮询
- 不把消息发出当成任务完成
- 不把 ACK 当成 Handoff
- 只在真实事件成立时推进下一步

## 3. Single Writer

正式业务代码只由执造者修改，降低多角色抢写、冲突覆盖、责任不清和自我验收。

## 4. Mission / TASK / Handoff / Review

完整接力链包括：

```text
Mission → TASK Contract → ACK → WORKING → HANDOFF
        → Review → PASS / REWORK / BLOCKED / ESCALATE
```

## 5. Phase / Gate

用于长期项目的阶段推进、架构判断、验收边界、高风险升级、阻断与恢复。

## 6. External Advisor 独立审查

外参师通过被授权的 MCP 连接读取真实工程证据，用于关键节点复核、异常分析、项目方向检查和重大问题独立审查。MCP 不作为角色之间的通信总线。

---

# 安装方式 / Installation

> 当前公开测试版：`v0.1.1`。旧版 `v0.1.0` 与原 `v0.1.0-beta.1` 指向相同历史代码，不含本次改进。

## 让 Codex 帮你安装（推荐）

把下面这句话完整复制给 Codex：

```text
请从 https://github.com/nf2huochao/AI-Dev-Governance 的 v0.1.1 版本安装 AI Dev Governance Skill；先检查是否已有同名安装，有则先说明安全备份或更新方法，未经我确认不要覆盖。安装后请在新对话检查 Skill 是否被发现。
```

## 使用 PowerShell 手动安装

在 Windows PowerShell 中运行：

```powershell
$src = Join-Path $env:TEMP ("ai-dev-governance-" + [guid]::NewGuid())
git clone --depth 1 --branch v0.1.1 https://github.com/nf2huochao/AI-Dev-Governance.git $src
if ($LASTEXITCODE -ne 0) { throw 'GitHub 下载失败，安装未执行' }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $src "scripts\install-local-skill.ps1")
```

安装脚本使用当前 Windows 用户的 Codex Skill 目录，并在发现同名目标时停止，不会静默覆盖旧版本。

安装完成后重新打开 Codex，在全新的 Codex 项目或对话中发送：

```text
请使用 ai-dev-governance 帮我启动项目。
```

如果没有出现工作区确认引导，请先查看 [中文首次使用指南](docs/FIRST-USE-ONBOARDING.zh-CN.md)，并通过 [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues) 反馈。此次改动见[更新说明](CHANGELOG.md)。

---

# 运作方式 / How It Works

1. 用户在 Codex 新建项目和对话，确认独立工作区。
2. 当前原始 Codex 对话直接成为唯一 `CORE_ARCHITECT`。
3. Skill 只建立 `MISSION_PLANNER` 和 `BUILD_EXECUTOR` 两个新 Codex 对话。
4. 完成两组真实 `BOOTSTRAP_HELLO → BOOTSTRAP_ACK`。
5. 通信通过后，用户在 ChatGPT 新建 External Advisor 对话。
6. 外参师协助制定项目目标、范围、计划和验收标准，生成《项目启动摘要》。
7. 用户审查并批准摘要，将它复制一次交回最初的 Codex 天枢核。
8. 天枢核建立项目资料、资料索引、开发规程、Phase、决策和 NO-GO 基线。
9. 配置并验证 External Advisor MCP 指向正确工作区。
10. 启动 `Mission → TASK → HANDOFF → Review` 正式接力开发。

详细操作见：[首次使用中文指南](docs/FIRST-USE-ONBOARDING.zh-CN.md)。

---

# 隐私与界限 / Privacy & Boundaries

- 用户始终是最终授权者
- 外参师不参与日常业务代码执行链
- 单个 AI 不应既执行又自我审查
- 平台能力缺口必须诚实记录
- 不以轮询伪装事件驱动
- 不以模板测试冒充真实多对话通过
- 不以显示名称代替真实角色身份
- 不以发送成功冒充接收、执行和回传成功

提交 Issue、日志或截图前，请删除：API Key、Access Token、Cookie、Session、客户数据、私人代码、商业数据、密钥、凭证和未脱敏日志。

---

# 平台支持 / Platform Support

## 当前重点支持

- ChatGPT Plus
- Codex
- Windows 本地开发环境
- Git
- MCP（External Advisor 独立审查）

## V0.1 暂不优先支持

- Claude Code 专门兼容
- 多 Executor 并发
- Governance MCP
- Dashboard
- 数据库型治理中枢
- 自动生产发布
- 大规模 Agent Swarm

---

# 当前状态 / Public Beta Status

已通过本地确定性回归验证：

- Windows 隔离安装包复制、重复安装保护与文件完整性
- Team-First Bootstrap
- 原始对话直接绑定唯一 Core Architect
- 只创建一个 Mission Planner 和一个 Build Executor
- HELLO / ACK 身份、顺序和证据引用的结构检查
- No polling 与 Event-Driven Relay 规则
- Single Writer、项目启动摘要和治理资料初始化机制

仍在邀请真实用户验证：

- 不同 ChatGPT Plus / Codex 环境兼容性
- Codex 自动发现、三个独立对话的真实 HELLO / ACK、送达与唤醒
- External Advisor 首次建立体验
- MCP 实际连接体验
- 完整 `Mission → TASK → HANDOFF → Review`
- 长期项目恢复
- 不同类型项目的持续开发稳定性

Public Beta 不代表 Stable，也不代表适合未经人工授权的生产环境操作。

---

# 发展方向 / Roadmap

V0.1 的重点不是堆叠更多 Agent，而是先把基础治理链路做稳定：

- 陌生用户首次安装与上手体验
- 多项目类型兼容性
- MCP 审查体验
- 错误恢复与中断恢复
- 更低 Token 消耗
- 更清晰的用户状态提示
- 更完善的公共测试反馈机制
- 更友好的中英文文档

---

# 文档与反馈

- [首次使用中文指南](docs/FIRST-USE-ONBOARDING.zh-CN.md)
- [项目规划提示词](docs/PROJECT-PLANNING-PROMPT.zh-CN.md)
- [External Advisor MCP 指南](docs/MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md)
- [故障恢复说明](docs/FAILURE-RECOVERY.zh-CN.md)
- [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues)

项目采用 [Apache License 2.0](LICENSE)。

---

# 邀请测试与指正

AI 开发治理局不是一套已经宣称完美的系统，而是一套正在真实用户环境中持续验证和修正的开源 AI 开发治理框架。

如果你是 ChatGPT Plus 或 Codex 用户、非专业程序员、独立开发者，或者希望长期使用 AI 开发真实软件，欢迎参与 Public Beta，并告诉我们：哪里太复杂、哪里不够自动、哪些规则不合理、哪些平台边界没有被清楚标注。

你的反馈会帮助我们建立一套 **更适合普通用户、更透明、更可监督、更可持续的 AI 开发治理系统**。

## 结语

> 愿 AI 不只是更强，
>
> 也更有秩序。
>
> 愿开发不只是更快，
>
> 也更可托付。

**AI 开发治理局 / AI Dev Governance**

欢迎测试、反馈与共建。
