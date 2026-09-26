# AI Dev Governance v0.1.2 — Public Beta Update

> 公开测试版 / Public beta. Not a stable release. Local checks do not prove real multi-chat delivery, wake-up, MCP access, or authorization across user environments.

## 中文更新说明

- **恢复已有进度：** 已保存摘要时不再要求重新规划或重复复制；初始化完成后显示当前项目及接力状态，提示从当前 TASK 继续。
- **保护项目身份和历史：** 角色表或事件日志缺失时停止初始化并提示恢复原记录，不创建新项目身份或空白日志覆盖历史。
- **检查治理记录：** 通用检查现在核对角色表、工作区归属和四个角色记录是否齐全。
- **修正团队握手顺序：** 加载角色说明不再触发提前 ACK；两个开发角色绑定后才开始握手，收到真实 HELLO 后才回复。
- **补充用户恢复说明：** 明确已启动项目如何继续，以及更新 Skill 后如何在现有角色对话中加载新规则。

## English update

- **Resume saved work:** Reuse an approved summary instead of asking users to re-plan or copy it again. Completed projects now show the current relay state and direct the existing team to resume the active TASK.
- **Protect project identity and history:** Initialization stops when the role registry or relay event log is missing. It asks for restoration of the original records instead of creating a new identity or empty history.
- **Validate governance records:** The general checker now verifies the role registry, workspace ownership, and presence of all four role records.
- **Correct the team handshake:** Loading a role prompt no longer triggers an early ACK. The Core Architect starts the handshake after both development roles are bound, and a role replies only after receiving the real HELLO.
- **Clarify recovery for users:** Guidance now explains how to resume an existing project and load updated role rules into existing conversations.

## Validation boundary

Windows PowerShell 5.1 and PowerShell 7.6.5 full suites each passed 18/18 test files. Recovery regressions passed 8/8; user-journey regressions passed 11/11. These are local deterministic checks. New-user discovery, real multi-chat communication, wake-up, and External Advisor MCP access still require platform testing.

See the [README](https://github.com/nf2huochao/AI-Dev-Governance/blob/v0.1.2/README.md) and [full changelog](https://github.com/nf2huochao/AI-Dev-Governance/blob/v0.1.2/CHANGELOG.md). Before updating, check for an existing Skill and do not overwrite it without confirming a safe backup path.
