# External Advisor MCP 连接与核验

MCP 在 V0.1 中只用于 External Advisor 的独立工程证据审查，不是三个 Codex 角色的日常通信总线。

## 用户需要亲自确认

1. 在 Codex/ChatGPT 中找到当前项目的连接入口。
2. 选择与项目工作区一致的本地项目，不要凭项目名称猜测。
3. 完成平台要求的连接或授权操作；不要把凭证复制到聊天、Markdown 或 Git。
4. 让平台显示或提供当前连接的项目路径。
5. 将实际显示路径与预期工作区比较。

## 本地目标检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-mcp-target.ps1 `
  -ExpectedProjectPath <expected-project-path> `
  -ObservedProjectPath <path-reported-by-platform>
```

结果含义：

- `MCP_TARGET_MATCH: PASS`：只证明两条已观察路径一致，不代表整个独立审查已经完成。
- `MCP_TARGET_MISMATCH`：连接指向错误项目，停止审查并修正目标。
- `MCP_CAPABILITY_GAP`：没有可核实的目标路径或连接能力，不能声称 MCP 可用。

## 外参师能读取什么

在授权范围内读取项目代码、测试、Git 状态、Commit、Diff、治理文件和证据；独立核对 Claim 与 Counter Evidence。External Advisor 不参加普通 TASK 派发、不写业务代码、不替代用户授权。

## 常见失败

- 路径存在但 Codex 当前项目未切换：回到 Codex 项目选择界面确认。
- MCP 指向另一个项目：显示 `MCP_TARGET_MISMATCH`，不要通过修改日志掩盖。
- 平台没有连接或无法回报目标：显示 `MCP_CAPABILITY_GAP`，由 Human Governor 决定是否继续人工审查。
