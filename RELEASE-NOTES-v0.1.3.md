# AI Dev Governance v0.1.3 — Public Beta

## 中文更新说明

- 修复任务已派发但 ACK 前通信受阻时无法记录 BLOCKED；必须保存错误证据，不补造 ACK。
- 新项目启用接力 schema 2，核对项目、角色线程、真实通信目标和 Contract / Handoff / Review 的本地证据关联；可选 Commit 必须在仓库存在。
- 分开声明完成数、本地证据关联数与平台真实性。旧历史保留并明确标注证据缺口，不再仅凭 PASS 日志统计真实完成。
- 增加当前对话身份候选读取；仍须一次原生记录对照，环境变量不能自行认证。
- 建团队前检查通信、回唤和外参师 MCP 入口；不把本地配置或 Plus 订阅当作通用可用证明。
- Mission 目标满足后上报完成并让出执行权，不为继续而制造下一 TASK；完成报告不能通过 Gate。
- 项目在既有角色表记录规则版本与哈希；恢复只读检查更新/定制差异，更新不覆盖角色或历史。
- 中英文 README 前置快速入口、环境说明，安装指令更新到 v0.1.3。

## English

- Allow evidence-backed BLOCKED before ACK; never fabricate receipt or retry indefinitely.
- Schema 2 links formal relay events to project/role threads, registered targets and task artifacts; optional commits must resolve in the repository.
- Separate declared outcomes, locally linked evidence and platform authenticity. Preserve legacy history and report its evidence gaps.
- Read the current environment's candidate thread ID, requiring one native metadata cross-check before binding.
- Preflight messaging, wakeups and Advisor connection availability before team creation. A Plus subscription or local MCP configuration alone proves neither.
- Finish the Mission and yield when its objectives are met; do not manufacture tasks or self-approve Gates.
- Record policy provenance in the existing registry and compare versions/customizations read-only.
- Add early quick-start links and current installation commands to both READMEs.

## Validation boundary

Windows PowerShell 5.1 and PowerShell 7.6.5 each passed all 19 regression files. New reliability scenarios passed 13/13, recovery 8/8, and user journey 11/11. Skill metadata and diff checks also passed. See [the validation record](https://github.com/nf2huochao/AI-Dev-Governance/blob/v0.1.3/docs/V0.1.3-VALIDATION.md).

Windows PowerShell 5.1 和 PowerShell 7.6.5 的完整回归各 19/19 通过；新增可靠性场景 13/13、恢复 8/8、用户路径 11/11 通过。隔离 CLI 实测因环境政策无法读取目标 Skill，未计为调用成功。

This is BETA_NOT_STABLE. Deterministic script regressions and remote package installation do not prove native desktop multi-chat communication, wakeups, MCP access or unfamiliar-user acceptance. Real-platform results are reported separately; untested capabilities remain MANUAL_REQUIRED. Four-role responsibilities, Single Writer and the Advisor-only MCP boundary are unchanged.
