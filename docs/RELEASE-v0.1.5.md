# AI Dev Governance v0.1.5 — Public Beta

本次针对真实使用中发现的接力空转查询与外参师连接错项目问题做小范围修复，四角色职责和治理边界不变。

- 离线检查已有原生对话时，可以一次审查导出范围内的全部消息发送边界，定位发送后的查询或等待，减少人工逐条指定发送记录的工作。
- 外参师连接请求自动带入当前项目登记的精确 ID 与路径；若当前目录与登记不符，直接拒绝生成。外参师须实际读取角色记录和阶段文件并返回原始工具引用，错误项目立即报告。
- 20 分钟巡检先看治理文件与最近事件；证据足够时不再例行查询所有角色，存在具体缺口时才做一次定向查询。
- 中英文安装说明和首次使用指南已更新至 v0.1.5。

Windows PowerShell 5.1 和 PowerShell 7.6.5 的完整回归各 20/20 通过，新增接力与外参师场景在可靠性套件中各 14/14 通过；隔离安装包的 51 个运行文件已逐个核对哈希。脚本验证只能证明本地检查逻辑。真实独立多对话的发送后行为、平台回唤、外参师实际 MCP 连接、Codex 自动发现和陌生用户首次使用仍需单独实测。已经运行的项目不会因 GitHub 发布自动切换规则；请在任务边界只读比对项目定制，备份并经授权后迁移。

安装时可将这句话复制给 Codex：

> 请从 https://github.com/nf2huochao/AI-Dev-Governance 的 v0.1.5 安装 ai-dev-governance。先检查同名安装及来源，不要直接覆盖；已有项目先只读比对规则，不重建角色或改写历史。

This public beta adds a whole-thread offline send/yield audit, a project-specific External Advisor connection request, and lighter evidence-first watchdog checks. It does not authenticate platform records or automatically migrate running teams. Real multi-chat and MCP behavior still require direct verification.
