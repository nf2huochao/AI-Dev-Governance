# AI 开发治理局 v0.1.1 — 公开测试版更新

> Pre-release：本版不是稳定版。脚本测试通过不等于所有 Codex / ChatGPT Plus 环境中的真实多对话、唤醒或 MCP 都已通过验证。

## 本次更新

- 首次使用先确认工作区与角色名称；恢复时读取已有进度，减少重复创建角色和反复确认。
- 新增只读进度提示和更清楚的普通用户引导，内部模板、线程号与命令由 Codex 处理。
- 安装包使用运行文件清单、同名检查、逐文件校验和版本来源记录，防止覆盖旧版或混入开发文件。
- 修正角色记录解析、复制工作区身份、已完成 TASK 重新派发及测试运行器漏跑测试等问题。
- 结构性启动检查与真实平台证据分开；无法独立核验时明确要求人工验证，不用手填 PASS 冒充真实通信。

Windows PowerShell 5.1 和 PowerShell 7.6.5 的完整回归各 17/17 通过，用户路径确定性回归 11/11 通过。真实新用户首次启动、平台多对话通信和外参师 MCP 仍待进一步实测。

## 安装

请按 [中文 README 安装说明](https://github.com/nf2huochao/AI-Dev-Governance/blob/v0.1.1/README.md#安装方式--installation) 操作，或将其中的一句话复制给 Codex。安装前检查同名 Skill；不要直接覆盖已有安装。

完整版本差异见 [CHANGELOG.md](https://github.com/nf2huochao/AI-Dev-Governance/blob/v0.1.1/CHANGELOG.md)。问题与建议请通过 [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues) 反馈，提交前请脱敏。
