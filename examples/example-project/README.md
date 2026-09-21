# Example Project

这是一个不包含业务代码的最小示例项目，用于演示初始化路径。它只验证治理结构，不代表真实独立 Codex 对话、真实消息通信或 MCP 已经建立。

首次使用时，先从 Skill 仓库的 `docs/FIRST-USE-ONBOARDING.zh-CN.md` 开始，确认工作区并取得用户批准的《项目启动摘要》。

在示例项目目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\init-governance.ps1 -ProjectPath .
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\validate-governance.ps1 -ProjectPath .
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\check-relay.ps1 -ProjectPath .
```

批准摘要后的正式初始化示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\init-governance.ps1 -ProjectPath . -ApprovedSummaryPath .\PROJECT-STARTUP-SUMMARY.md -ProjectName "Example Project" -ProjectShortName "example"
```

示例只验证治理结构，不代表真实业务闭环、真实多对话接力或 MCP 已经完成；这些必须由平台和用户按启动检查实际确认。
