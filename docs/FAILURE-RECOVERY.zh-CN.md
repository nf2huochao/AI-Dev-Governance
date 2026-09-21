# 首次初始化失败恢复

## 路径或项目不正确

停止初始化，重新确认项目路径。路径存在不等于项目绑定成功；不要清空非空目录，也不要把两个项目的治理文件混在一起。

## 摘要未批准

保持 `Approval Status: DRAFT`，回到 ChatGPT 规划对话补充问题。只有用户亲自改为 `Approval Status: APPROVED` 后，才运行正式初始化。

## 初始化中断

重新运行相同的 `init-governance.ps1` 参数。脚本会跳过已有治理文件，不覆盖原批准摘要、角色 Prompt 或用户已有资料。先检查 `.ai-governance/PROJECT-INDEX.md` 和 `START-HERE.md`，再继续未完成检查。

## 角色对话重复或身份不清

不要创建第五个角色，也不要让一个对话模拟多个角色。当前最初 Codex 对话固定为唯一 `CORE_ARCHITECT`，生命周期始终是 `CURRENT_CONTEXT / REUSE_CURRENT`；恢复时不要求 Core Architect creation event，也不得重新创建。对 Mission Planner 和 Build Executor 必须把现有 `ROLE-MAP.md` 传给 `guard-role-creation.ps1`：已有绑定返回 `REUSE_EXISTING_THREAD`，只对返回 `ROLE_CREATION_ALLOWED` 的缺失角色执行 `ENSURE`。无法取得当前 threadId 时记录 `CURRENT_THREAD_ID_UNAVAILABLE / BINDING_BLOCKED / CAPABILITY GAP`，不得创建替代 Core Architect。重复 ROLE_ID、重复 THREAD_ID 或目标不确定时停止创建，进入冲突处理。

## 基础通信失败

先运行 `check-role-bindings.ps1`，确认通信目标是已验证的 `THREAD_ID`，不是显示名、TASK_ID、EXECUTION_ID 或 OUTER_TASK_ID。然后只检查两组 `BOOTSTRAP_HELLO → BOOTSTRAP_ACK`；没有真实收发、送达或唤醒证据时保持 `MANUAL_REQUIRED` / `CAPABILITY GAP`，不得派发 Mission、TASK、重复发送或轮询掩盖失败。`check-bootstrap.ps1` 只验证记录结构，不把脚本 PASS 当成平台通信 PASS。

## MCP 错误或不可用

停止独立审查声明，运行目标检查。错误项目是 `MCP_TARGET_MISMATCH`，无平台能力是 `MCP_CAPABILITY_GAP`。不要粘贴凭证，不要用轮询或伪造日志替代 MCP。

## 对话中断后恢复

读取角色 Prompt、项目启动摘要、项目索引、当前 Phase/Mission、`RELAY_STATE.md`、最新事件、最新 Commit 和未决决定。治理文件帮助恢复上下文，但不能伪造缺失的真实消息或 Handoff。
