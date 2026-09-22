# AI 开发治理局 V0.1 首次使用与项目初始化

这份流程面向没有专业软件工程知识的普通 ChatGPT Plus + Codex 用户。它先确认工作区、建立三角色团队并验证通信，再制定项目计划和启动开发。

## 0. 你需要知道的边界

- 你只需要提供项目目标、工作区和批准；不需要先理解 Git Worktree、JSONL、线程 ID 或 MCP 内部实现。
- 看到路径存在，不等于当前 Codex 已经绑定该项目。路径检查和 Codex 项目绑定是两件事。
- 治理文件用于保存上下文，不能替代真实角色对话、真实消息、真实 Handoff、测试或 Commit。
- 正常接力使用 `SEND → YIELD → WAKE → ACT`；不需要用户持续复制普通 TASK、ACK、WORKING 或 HANDOFF。
- Routine relay messages do not require user copy/paste.
- `REAL MULTI-CHAT EXECUTION` 和 `SINGLE-CHAT ROLE SIMULATION` 必须区分。没有真实线程通信证据时显示 `MANUAL_REQUIRED`，不得显示成功。

## 0.1 本地 Skill 安装

从 GitHub 下载公开测试版后，在 PowerShell 中执行：

```powershell
$tmp = Join-Path $env:TEMP 'ai-dev-governance-v0.1.0-beta.1'
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
git clone --depth 1 --branch v0.1.0-beta.1 https://github.com/nf2huochao/AI-Dev-Governance.git $tmp
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tmp 'scripts/install-local-skill.ps1')
```

脚本默认安装到当前 Windows 用户目录下的 `.agents\skills\ai-dev-governance`，使用稳定名称；同时检查 `.agents\skills` 与兼容目录 `.codex\skills` 中是否已有同名 Skill。发现重复时会停止，不会覆盖。复制先进入临时目录，通过完整性检查后才一次性落盘。

安装后重新打开 Codex，在新对话中调用 `ai-dev-governance`。如果没有出现，不要开始项目初始化，先检查当前用户的 `.agents\skills\ai-dev-governance\SKILL.md`；旧版 Codex 若使用 `.codex\skills`，请通过 `-TargetPath` 明确选择，并避免留下同名双份安装。

## 1. 第一次调用：唯一 CORE_ARCHITECT / BOOTSTRAP

在 Codex 新建项目和对话，调用 Skill。这个最初 Codex 对话从调用开始就是本项目唯一的 `CORE_ARCHITECT`，`BOOTSTRAP` 只是它的临时初始化状态，不是第五个角色。首次回复应先确认工作区，然后说明：不会创建第二个天枢核。The onboarding must not create a second Core Architect.

> 当前这个 Codex 对话将作为本项目的天枢核。接下来我只需要为你建立司策令和执造者两个 Codex 对话。

内部固定执行 `BIND_CURRENT_CONTEXT_AS_CORE_ARCHITECT`，并写入 `BOOTSTRAP_STATE = ACTIVE`。验收标记为 `CORE_ARCHITECT_SOURCE = CURRENT ORIGINAL CONVERSATION`，`EXPECTED_NEW_CODEX_THREADS = 2`。通过后只把状态改为 `BOOTSTRAP_STATE = COMPLETE`，不发生角色转换。用户自定义显示名只改变界面名称，不改变 `CURRENT_CONTEXT / REUSE_CURRENT`。

用户只需确认工作区、一次性角色名称、批准项目启动摘要和平台权限；建立角色或发送普通 Bootstrap 消息不应逐项重复询问。平台原生逐次确认不能被绕过。

> 欢迎使用 AI 开发治理局。我会一步步帮助你建立项目和 AI 开发团队。首先，请告诉我你希望把新软件放在哪个文件夹中。

用户提供路径后，运行只读检查。路径确认只证明当前环境能读取目录，不证明 Codex 项目已经绑定。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-workspace.ps1 -ProjectPath <project-path>
```

检查结果只说明当前环境能否读取该路径、目录是否为空、是否有 Git 标记；它不会声称 Codex 项目已经绑定。非空目录、已有 Git 仓库或其他项目混用时，先让用户确认，不能清空或覆盖。

## 2. 建立三角色团队并做基础通信

用户确认工作区后，接受默认名称或一次性提供自定义名称。运行一次 Bootstrap 初始化：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\init-governance.ps1 `
  -ProjectPath <project-path> `
  -BootstrapOnly `
  -ProjectId "项目唯一标识" `
  -ProjectName "项目名称" `
  -ProjectShortName "项目简写"
```

这一步只建立 `.ai-governance/` 骨架、角色 Prompt 和 `ROLE-MAP.md`，不建立 Mission、不创建 TASK、不修改业务代码。当前对话直接绑定为唯一 Core Architect；只建立一个新的 Mission Planner 对话和一个新的 Build Executor 对话。每次准备调用 `create_thread` 前必须用 `ROLE-MAP.md` 运行 `guard-role-creation.ps1`；只有输出 `ROLE_CREATION_ALLOWED` 才能创建，`ROLE_ALREADY_BOUND` 必须复用现有线程。创建结果不确定时先核实 `THREAD_ID`，不要盲目重试；发现重复角色时停止并进入冲突处理。

当前 Codex 原生线程接口的能力边界必须按实际返回处理：创建任务准备完成时使用返回的 `threadId` 和 `hostId`；创建尚在准备时返回的 `clientThreadId` 只是设置阶段标识，不能传给消息接口。原生发送接口要求 `threadId`，`hostId` 是可选路由信息；发送工具返回成功只证明请求已提交，不证明接收、执行或唤醒。当前 Skill 不把 `clientThreadId`、`TASK_ID` 或 `OUTER_TASK_ID` 当作通信目标，也不会用持续轮询弥补缺失的送达/唤醒证据。

当前 Codex 工具没有“取得调用者当前 threadId”的专用接口；`list_threads` 只能枚举任务，不能用标题、最近时间、工作目录或 active 状态确定哪一个就是调用者。如果平台不能可靠提供当前原始对话的 `threadId`，ROLE-MAP 必须记录 `CURRENT_THREAD_ID_UNAVAILABLE / BINDING_BLOCKED / CAPABILITY GAP`。原始对话仍是唯一 Core Architect；不得创建替代 Core Architect。若这使 Planner 无法回传，应停止 Bootstrap 等待平台能力或 Human Governor。

把真实的 `PROJECT_ID`、三个内部 `ROLE_ID`、`BINDING_MODE` 和 `CREATION_MODE` 填入 `.ai-governance/ROLE-MAP.md`。Mission Planner 与 Build Executor 必须使用原生创建返回的真实 `threadId` 并标记 `BOUND`；Core Architect 使用 `CURRENT_CONTEXT / REUSE_CURRENT`，只有能够可靠取得当前线程身份时才填写其 `THREAD_ID`，否则保留 `BINDING_BLOCKED`。然后运行结构检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-role-bindings.ps1 `
  -RoleMapPath <project-path>\.ai-governance\ROLE-MAP.md
```

`THREAD_ID` 和 `COMMUNICATION_TARGET_HANDLE` 必须分开记录。通信地址只能使用原生消息工具实际要求且已核实的通信目标句柄；不得把显示名、`PROJECT_ID`、`TASK_ID`、`EXECUTION_ID` 或 `OUTER_TASK_ID` 当作通信目标。结构检查通过不等于平台身份、送达或唤醒已验证。

先执行两组最小通信验证，不派发业务任务：

1. 唯一 Core Architect 向 Mission Planner 发送 `BOOTSTRAP_HELLO`，等待对方真实收到并回传 `BOOTSTRAP_ACK`；
2. Mission Planner 向 Build Executor 发送 `BOOTSTRAP_HELLO`，等待对方真实收到并回传 `BOOTSTRAP_ACK`。

将真实平台证据按 `RELAY_EVENTS.jsonl` 格式记录，再运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-bootstrap.ps1 `
  -EventsPath <project-path>\.ai-governance\RELAY_EVENTS.jsonl `
  -RoleMapPath <project-path>\.ai-governance\ROLE-MAP.md `
  -ExecutionId <本次真实握手执行标识>
```

脚本只检查选定 `EXECUTION_ID` 的身份、目标、顺序和平台证据引用，不能替代平台证明消息已送达或目标已唤醒。历史事件会被保留，不要求整个日志只有四条。基础通信失败时，必须停在 `MANUAL_REQUIRED` / `CAPABILITY GAP`，不得派发正式 Mission、TASK 或重复发送掩盖失败。

Communication gate: only after bootstrap passes may project planning and the first Mission begin.

## 3. 通信通过后，在 ChatGPT 新建 External Advisor 对话

通信验证通过后，才建立新的 ChatGPT External Advisor 对话。把 [PROJECT-PLANNING-PROMPT.zh-CN.md](PROJECT-PLANNING-PROMPT.zh-CN.md) 复制进去。External Advisor 先讨论目标、用户、场景、第一版范围、排除项、计划和验收标准，再生成《项目启动摘要》初稿。

初稿必须标记 `DRAFT`。用户亲自审查并批准后，才把 `Approval Status` 改为 `APPROVED`，然后把完整原文复制回最初的 Codex 对话。未经批准的摘要不能成为开发依据。

## 4. 批准后：由最初 Codex 天枢核建立项目资料

将批准摘要保存为一个文件，例如 `PROJECT-STARTUP-SUMMARY.md`，然后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\init-governance.ps1 `
  -ProjectPath <project-path> `
  -ApprovedSummaryPath <approved-summary-path> `
  -ProjectName "项目名称" `
  -ProjectShortName "项目简写"
```

脚本会保留原摘要原文，并在 `.ai-governance/` 创建项目索引、开发规程和角色显示名映射。已有文件只跳过，不覆盖。正式 `RELAY_EVENTS.jsonl` 会保持为空，直到真实平台事件发生；可选参数可自定义四个显示名，但内部身份始终固定为 `EXTERNAL_ADVISOR`、`CORE_ARCHITECT`、`MISSION_PLANNER`、`BUILD_EXECUTOR`。没有平台证据时输出 `Startup readiness: MANUAL_REQUIRED`，不会把项目标记为可开发。

## 5. 配置 External Advisor MCP

原 ChatGPT 项目规划对话承担 External Advisor。按照 [MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md](MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md) 检查连接目标和读取能力，不要在聊天或 Git 中粘贴 API Key、Cookie、Token 或其他凭证。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-mcp-target.ps1 `
  -ExpectedProjectPath <project-path> `
  -ObservedProjectPath <platform-reported-project-path>
```

没有平台返回的目标路径时，结果必须是 `MCP_CAPABILITY_GAP`；目标不一致时必须是 `MCP_TARGET_MISMATCH`。两种情况都不能显示 MCP 已验证。

## 6. 启动检查

只有以下项目全部有真实证据，天枢核才能发布首个 Mission：

- 最初 Codex 对话已确认是唯一 `CORE_ARCHITECT`，没有第二个天枢核；
- `ROLE-MAP.md` 中 Core Architect 明确绑定当前原始对话；Mission Planner 和 Build Executor 各只有一个原生创建返回的真实 `THREAD_ID` 并标记为 `BOUND`。若当前 Core Architect 的 threadId 不可取得，则保持 `BINDING_BLOCKED / CAPABILITY GAP`，不得创建替代对话；
- 三个角色各有一个由原生消息工具契约核实的 `COMMUNICATION_TARGET_HANDLE`，且不把 `THREAD_ID`、`OUTER_TASK_ID` 或显示名混作目标；
- 两组 `BOOTSTRAP_HELLO → BOOTSTRAP_ACK` 均有真实收发和唤醒证据；
- 用户批准摘要已保存且未被改写；
- 工作区路径已确认，Codex 项目绑定已由平台实际确认；
- 项目索引和开发规程已建立；
- 四个显示名与固定内部身份映射已确认；
- 三个独立 Codex 对话真实建立，基础通信已验证；
- External Advisor MCP 已指向正确项目并可读取允许的工程证据；
- 未通过项目显示为 `DRAFT`、`MANUAL_REQUIRED`、`CAPABILITY GAP` 或 `BLOCKED`，不能伪装成 PASS。

执行最终前置检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-root>\scripts\check-startup-readiness.ps1 `
  -RoleMapPath <project-path>\.ai-governance\ROLE-MAP.md `
  -EventsPath <project-path>\.ai-governance\RELAY_EVENTS.jsonl `
  -ExecutionId <本次真实握手执行标识> `
  -PlatformEvidencePath <Codex 原生平台证据 JSON> `
  -McpEvidencePath <MCP 验证证据文件> `
  -ApprovedSummaryPath <project-path>\.ai-governance\PROJECT-STARTUP-SUMMARY.md
```

当前 Skill 没有 Codex 原生线程/消息/执行记录的认证接口，因此没有 Human Governor 授权回执时，`check-startup-readiness.ps1` 返回 `MANUAL_REQUIRED`。人工填写的 `VERIFIED_BY_PLATFORM`、发送工具成功返回或自填消息 ID 都不能替代独立核验。Human Governor 审查原始工具返回、目标线程、接收方回传和 MCP 目标后，可基于 `governance/STARTUP-AUTHORIZATION.template.json` 生成授权回执；脚本会把它与当前项目、执行、角色表、批准摘要和证据 SHA-256 绑定。任何内容变化都会令旧授权失效；结果仍标记 `HUMAN_VERIFIED / platform_attestation=false`。

失败恢复见 [FAILURE-RECOVERY.zh-CN.md](FAILURE-RECOVERY.zh-CN.md)。
