# AI 开发治理局 / AI Dev Governance

这是一个面向 ChatGPT Plus + Codex 用户的 AI 开发治理 Skill，帮助用户建立外参师、天枢核、司策令、执造者四角色开发团队，并通过真实多对话接力进行长期软件开发。

> **V0.1 Public Beta**：当前正在进行真实陌生用户首次使用验证，不是 Stable 版本。

> **No AI supervises itself. / AI 无法自我监督。**

本版本适用于愿意亲自确认工作区、项目摘要、独立角色对话和审查权限的 ChatGPT Plus + Codex 用户。它不会自动替用户创建业务项目，也不会替用户授予生产权限。

## 适合谁

- ChatGPT Plus 和 Codex 用户；
- 不具备专业编程背景，但希望用 AI 开发软件的用户；
- 希望 AI 能持续开发，同时不接受单个 AI 自我监督的个人或小团队。

## 能解决什么

- `TEAM_FIRST_BOOTSTRAP`：先建立团队并验证通信，再制定项目计划和建立治理资料；
- 用 Core Architect、Mission Planner、Build Executor 和 External Advisor 分离职责；
- 让 Build Executor 写业务代码，Mission Planner 做验收；
- 记录 TASK Contract、Handoff、Review、Evidence 和恢复信息；
- 用事件驱动接力：`SEND → YIELD → WAKE → ACT`，禁止空转轮询；
- 在无法证明真实项目绑定、通信或 MCP 目标时明确标记 `MANUAL_REQUIRED` / `CAPABILITY GAP`。

## 已验证能力

- Windows 本地 Skill 安装、Codex 自动发现与调用；
- 原始 Codex 对话直接成为唯一 Core Architect；
- 只新增一个 Mission Planner 和一个 Build Executor；
- Team-First Bootstrap 和两组真实 `HELLO/ACK` 基础通信；
- `No polling`、`SEND → YIELD → WAKE → ACT` 和 Single Writer；
- 项目启动摘要及治理初始化规则。

## 正在外部验证

`EXTERNAL_VALIDATION_IN_PROGRESS`

- 不同 ChatGPT Plus 用户及 Windows/Codex 环境兼容性；
- ChatGPT External Advisor 的首次建立和实际 MCP 连接；
- 完整 `Mission → TASK → HANDOFF → Review` 接力；
- 长期项目运行、恢复和跨环境迁移。

## 安装

在 Windows PowerShell 中执行下面两行。安装脚本会从公开仓库下载当前 Beta，并拒绝覆盖已有同名目录：

```powershell
$tmp = Join-Path $env:TEMP 'ai-dev-governance-v0.1.0-beta.1'
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
git clone --depth 1 --branch v0.1.0-beta.1 https://github.com/nf2huochao/AI-Dev-Governance.git $tmp
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tmp 'scripts/install-local-skill.ps1')
```

安装完成后重新打开 Codex，在新对话中调用 `ai-dev-governance`。如果目标目录已存在，脚本会停止而不覆盖；请先备份旧版本，或使用 `-TargetPath` 指定新的隔离目录。

## 首次使用

按 [中文首次使用指南](docs/FIRST-USE-ONBOARDING.zh-CN.md) 操作。首次调用时应该先看到工作区确认引导，并把当前 Codex 对话确定为唯一 Core Architect，而不是直接生成业务代码。

流程是：

1. 确认独立项目工作区；
2. 当前原始 Codex 对话直接绑定为唯一 Core Architect；只新增 Mission Planner 和 Build Executor 两个 Codex 对话，绝不新建第二个 Core Architect；
3. 记录真实 `PROJECT_ID` / `ROLE_ID` / `THREAD_ID` / `COMMUNICATION_TARGET_HANDLE`，完成两组 `BOOTSTRAP_HELLO → BOOTSTRAP_ACK`；
4. 通信通过后，在 ChatGPT 建立 External Advisor 对话并生成《项目启动摘要》；
5. 用户亲自审查并批准摘要，再复制回最初的 Codex 对话；
6. 建立项目资料、索引、开发规程和四角色名称映射；
7. 按 [External Advisor MCP 指南](docs/MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md) 检查独立审查目标；
8. 所有真实证据齐全后，才启动首个 Mission。

用户不需要自行编写四角色 Prompt 或修改治理协议，但必须亲自完成平台要求的对话创建、授权和确认。Routine relay messages 不需要用户手工复制；平台不支持真实回唤时，必须停在能力缺口状态，不能伪装成功。

## 四角色边界

```text
Human Governor
      ↓
External Advisor ←→ 独立审查，不参加普通接力
      ↓ Advisory
Core Architect
      ↓ Mission
Mission Planner ⇄ Build Executor
```

Build Executor 是唯一正式业务代码写入者；Mission Planner 不写业务代码并负责 Review；Core Architect 管理 Phase、Gate 和架构偏离；External Advisor 只做独立审查。MCP 不作为 Agent 通信总线。

## 常用校验

在项目根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\validate-governance.ps1 -ProjectPath .
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-relay.ps1 -ProjectPath .
```

这些脚本只检查确定性结构，不替代角色判断、架构判断、真实对话证据或 Human Governor 授权。

正式事件日志从空文件开始；握手示例位于 `examples/RELAY_EVENTS.bootstrap.example.jsonl`，不得当作真实运行日志。首个 Mission 前还必须完成 `check-startup-readiness.ps1`，保留真实 Codex 原始材料和 MCP 验证材料；当前没有原生证据认证接口时保持 `MANUAL_REQUIRED`，不接受人工填写的 PASS/VERIFIED 字段。

## 版本与反馈

当前版本：`v0.1.0-beta.1`（V0.1 PUBLIC BETA）。本版本尚未完成所有陌生用户环境的验收，欢迎通过 [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues) 反馈安装、识别、工作区初始化、项目摘要、角色通信和 MCP 问题。

提交日志或截图前，请删除 API Key、Token、Cookie、客户资料、私人项目代码、绝对路径和其他敏感信息。

## 目录

- `SKILL.md`：Skill 入口和完整使用边界；
- `roles/`：四个固定角色的正式 Prompt；
- `governance/`：项目治理文件模板；
- `protocols/`：接力、Review、升级、治理和独立审查协议；
- `scripts/`：初始化、安装和确定性校验脚本；
- `docs/`：首次使用、规划、MCP 和恢复指南；
- `examples/`：最小示例项目；
- `tests/`：可重复的结构与协议验证。

## 许可证

本项目采用 [Apache License 2.0](LICENSE)。
