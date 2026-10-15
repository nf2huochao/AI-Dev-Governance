# AI Dev Governance v0.1.4 — Public Beta

本次更新针对真实使用中暴露的接力、恢复和验收问题，保持四角色职责及权限边界不变。

## 改进内容

- 接力记录先校验再追加：独占写锁、历史哈希检查、重复事件去重；冲突、非法状态及损坏历史拒绝写入，不覆盖旧证据。
- 恢复时保留当前任务，识别已有开发、外审例外和日志错误，不因初始化标记重建团队。
- 新增原生工具调用记录离线检查，识别发送后的主动等待或查询；明确 ACK 后继续执行、HANDOFF 后让出回合。
- 验收区分代码实现、隔离测试、真实接通和用户验收，避免局部测试通过被误称为产品完成。
- 巡检覆盖天枢核自己尚未完成的阶段推进职责。
- 安装器支持只读检查同名安装、版本及入口哈希，不自动覆盖或删除旧版。
- 更新中英文安装入口与中文恢复说明。

## 验证与限制

PowerShell 7.6.5、Windows PowerShell 5.1 完整回归各 20/20 通过，新增可靠性场景各 12/12 通过。历史原生调用记录离线检查可以识别发送后轮询；这不代表新版本真实多对话行为已通过。

真实独立角色通信、自动唤醒、Codex 自动发现、实际 MCP 连接及陌生用户验收仍需实测。离线检查不认证平台证据真实性，也不能拦截未来的原生工具调用。现有项目的损坏历史不会自动修复；人工例外不会自动解除启动限制。

## 安装与升级

将下面一句话复制给 Codex：

> 请从 https://github.com/nf2huochao/AI-Dev-Governance 的 v0.1.4 安装 ai-dev-governance；先检查同名安装，有则说明安全备份更新方案，不要覆盖。已有团队只读比较规则差异，不重建角色、不改历史。

重新安装不会自动迁移运行中项目的规则。请在当前任务结束后，核对项目定制、备份并经授权更新。

This public beta improves validated relay appends, task-preserving recovery, offline no-polling checks, acceptance evidence levels, Core-owned pending work and read-only duplicate installation inspection. Real multi-chat, wakeup, discovery and MCP validation remain required. Existing teams and historical evidence are not automatically migrated or rewritten.
