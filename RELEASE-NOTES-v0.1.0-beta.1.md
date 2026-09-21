# AI Dev Governance V0.1.0-beta.1

这是 AI 开发治理局 V0.1 的公开测试版。

> `BETA_NOT_STABLE`：这是 Public Beta，不是 Stable 版本，仍需不同用户和环境继续验证。

## 本版内容

- 首次使用工作区确认与项目启动摘要流程；
- Core Architect、Mission Planner、Build Executor、External Advisor 四角色边界；
- `SEND → YIELD → WAKE → ACT` 事件驱动接力和禁止轮询规则；
- 项目治理模板、初始化脚本、接力检查和恢复流程；
- Windows 当前用户隔离安装脚本；
- 中文首次使用、MCP 审查目标和失败恢复指南；
- GitHub Issues 反馈模板。

## 已验证能力

- `REAL_BOOTSTRAP_HELLO_ACK=PASS`；
- 原始 Codex 对话为唯一 Core Architect；
- 实际只新增 Mission Planner 和 Build Executor 两个 Codex 对话；
- 两组真实 HELLO/ACK 通信成功；
- 本轮真实验证未发生主动轮询，未发现平台能力缺口。

## 测试状态

结构、脚本和协议已有本地回归验证，Team-First Bootstrap 已完成一次隔离真实多对话验证。不同 Plus 用户环境、External Advisor 首次建立、实际 MCP 连接、完整开发接力和长期恢复仍需测试用户继续核验。

## 安装

请从 [README.md](README.md) 的安装章节开始，并在新 Codex 对话中调用 `ai-dev-governance`。

## 反馈

请使用 [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues)，提交前务必脱敏。
