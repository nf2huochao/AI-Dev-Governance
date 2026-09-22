[**English**](README.en.md) | [简体中文](README.md)

# AI Dev Governance / AI 开发治理局

> **In one sentence**
>
> An open-source AI development governance Skill for **ChatGPT Plus + Codex** users. It organizes long-term software development around four collaborating roles—External Advisor, Core Architect, Mission Planner, and Build Executor—so the work remains supervisable, correctable, and transferable.
>
> In plain language: **the External Advisor checks direction from outside the delivery chain, the Core Architect keeps the whole project on course, the Mission Planner breaks work down and reviews it, and the Build Executor focuses on coding and testing**. Each role owns one responsibility, preventing a single AI from planning, implementing, reviewing itself, and declaring success. The result is development that is less likely to drift, miss defects, or break down halfway through.

> **Core Principle**
>
> **No AI supervises itself.**

> **Current status: V0.1 Public Beta**

<p align="center">
  <img src="docs/images/four-roles-banner.png" alt="Panoramic view of the four-role AI Dev Governance team" width="100%">
</p>

## Four Roles, One Governed System

In Chinese thought, governance has never meant merely issuing orders.

A system that can operate over the long term needs **a center that holds direction, a function that plans, a function that executes, and an independent observer outside the delivery chain who can advise and challenge it**.

Direction must have an owner, and execution must be reviewed. The planner should not replace the implementer, and the implementer should not declare its own work correct. Each position carries a distinct responsibility: the roles cooperate, while preserving the boundaries that make supervision meaningful.

> **Every role has its place, every task has an owner, every authority has a boundary, and every result must be verified.**

AI Dev Governance draws on this view of ordered responsibility to establish four independent roles that relay work to one another in AI software development:

- **External Advisor / 外参师**
- **Core Architect / 天枢核**
- **Mission Planner / 司策令**
- **Build Executor / 执造者**

These names are not replicas of historical offices, nor are they intended merely to create an antique aesthetic. They draw on Chinese-language ideas of **observing from outside, holding direction at the center, planning and coordinating work, and personally turning plans into working results**, then map those ideas onto four modern software-development responsibilities.

> **Four roles form one system: coordinated but not conflated, mutually checking without obstructing one another.**

---

## External Advisor / 外参师

<p align="center">
  <img src="docs/images/roles/external-advisor.png" alt="External Advisor: observing from outside and reviewing independently" width="92%">
</p>

### Observe from outside; advise without taking over

Important judgments sometimes require an observer who is not embedded in the execution chain.

The External Advisor therefore remains outside the routine development relay. It does not receive ordinary TASKs, write business code on behalf of the development roles, or approve work merely to make the project appear successful. It discusses project goals, rules, and major changes with the user; independently examines code, Git history, tests, and evidence at key stages; and supplies a second perspective when internal roles disagree, encounter anomalies, or drift from the intended direction.

Its responsibilities include:

- Discussing the project's overall goals and plan
- Preparing the Project Startup Summary
- Conducting independent engineering reviews
- Analyzing major anomalies
- Advising on architecture and direction
- Independently reviewing critical Gates
- Reading authorized, real engineering evidence through MCP

> **See the system from outside it; contribute judgment without replacing execution.**

---

## Core Architect / 天枢核

<p align="center">
  <img src="docs/images/roles/core-architect.png" alt="Core Architect: holding the overall project direction" width="92%">
</p>

### Hold the center and set direction without doing every task

“Tianshu” is the pivot star of the Big Dipper. Here, the name expresses one clear idea: **a long-running project needs a stable center of direction**.

The Core Architect continuously maintains the overall goal, current phase, and architectural boundaries, preventing the project from gradually drifting across dozens of TASKs, hundreds of messages, and many rounds of revision.

Its responsibilities include:

- Maintaining the project's overall direction
- Issuing Missions
- Managing Phases and Gates
- Maintaining architectural boundaries
- Recording major decisions and forbidden routes
- Handling drift, blockers, and escalations
- Establishing and verifying the development team during Bootstrap

The Core Architect governs development, but does not perform routine business-code implementation.

> **The center sets direction; it does not replace every craftsperson.**

---

## Mission Planner / 司策令

<p align="center">
  <img src="docs/images/roles/mission-planner.png" alt="Mission Planner: decomposing work and reviewing it independently" width="92%">
</p>

### Establish the plan and sequence before execution

Complex projects rarely fail simply because nobody can write code. More often, they fail because tasks are too large, boundaries are unclear, sequencing is confused, and acceptance criteria are vague.

The Mission Planner turns the Core Architect's Mission into TASKs that can genuinely be executed and reviewed. Its responsibilities include:

- Decomposing Missions
- Writing TASK Contracts
- Managing task order and dependencies
- Dispatching work to the Build Executor
- Receiving Handoffs
- Performing independent Reviews
- Deciding PASS / REWORK / BLOCKED
- Dispatching the next TASK after a PASS

It is neither the highest-level direction setter nor the code implementer. It turns strategy into order and goals into executable steps.

> **Set the plan first, then make the instruction clear; every action has its proper sequence.**

---

## Build Executor / 执造者

<p align="center">
  <img src="docs/images/roles/build-executor.png" alt="Build Executor: implementing code and tests" width="92%">
</p>

### Enter the work and turn plans into working systems

Plans that never become real code, real tests, and real running software remain paper arrangements.

The Build Executor is responsible for:

- Reading the code and necessary context
- Modifying business files
- Implementing features
- Running tests and debugging failures
- Fixing defects
- Creating Git commits
- Producing structured Handoffs

In V0.1, the Build Executor is the **only role authorized to write formal business code**. The role that changes the code must provide execution evidence; the role that reviews the result should not also be the role being reviewed. The Build Executor may report what it completed, but it cannot grant itself the final PASS.

> **Plans may be discussed by many, but implementation must have an accountable owner; achievement and responsibility must both be traceable.**

---

# How the Four Roles Form a Development Governance System

The four roles are not four parallel chatbots. Together, they form a bounded development order:

```text
                    User / Human Governor
                            │
                  Final goals and major authority
                            │
              ┌─────────────┴─────────────┐
              │                           │
       External Advisor              Core Architect
       Observe · Review · Advise      Direction · Phase · Mission · Gate
                                          │
                                          ▼
                                    Mission Planner
                                  Decompose · Dispatch · Review
                                          │
                                          ▼
                                    Build Executor
                                 Code · Test · Fix · Handoff
                                          │
                                          └──────► Back to Mission Planner for review
```

The routine development chain is:

```text
Core Architect
  ↓ Mission
Mission Planner
  ↓ TASK
Build Executor
  ↓ ACK / WORKING / HANDOFF
Mission Planner
  ↓ Review
PASS → Next TASK
REWORK → Targeted correction
BLOCKED → Escalation
```

The External Advisor remains independent and does not enter the ordinary TASK pipeline. The user always retains authority over goals, major changes, high-risk operations, and publication.

## Governance Is Not About Making AI Slower

Good governance does not require every action to wait for approval. Instead:

> **Let routine authorized work proceed automatically, and return only genuinely important decisions to the human.**

V0.1 uses an event-driven relay:

```text
SEND → YIELD → WAKE → ACT
```

After sending work, a role yields control. A real message or scheduling event wakes the next role, instead of one role continuously polling another conversation. Routine, safe, authorized development continues; the user is consulted again only when direction changes, a major blocker appears, a high-risk operation is required, or an authorization boundary is reached.

---

# Why AI Dev Governance

Many AI-development failures are not caused by an AI being unable to write code. They happen because:

- A single AI tends to confirm itself and gradually drift
- Work moves away from the original objective over time
- Long-running development lacks stable handoffs and creates repeated rework
- Users cannot clearly see the current phase, decision basis, or genuine blockers
- Ordinary users struggle to sustain long-term development within limited budgets

AI Dev Governance does not simply add more agents. It adds a **governance structure**: roles have explicit responsibilities, dispatch, execution, reporting, and review form a real chain, supervision remains separate from implementation, and the user retains final authority.

---

# Features

## 1. Team-First Bootstrap

Establish the team and verify communication before planning the project and beginning formal development:

- The original Codex conversation is directly bound as the only **Core Architect**
- Only two new Codex conversations are created: **Mission Planner** and **Build Executor**
- Two minimal, real HELLO / ACK communication checks happen first
- A second Core Architect is never created

## 2. Event-Driven Relay

The relay follows `SEND → YIELD → WAKE → ACT`:

- No continuous polling
- A sent message is not treated as completed work
- An ACK is not treated as a Handoff
- The workflow advances only when a real event has occurred

## 3. Single Writer

Only the Build Executor modifies formal business code, reducing competing edits, overwritten work, unclear responsibility, and self-review.

## 4. Mission / TASK / Handoff / Review

The complete relay includes:

```text
Mission → TASK Contract → ACK → WORKING → HANDOFF
        → Review → PASS / REWORK / BLOCKED / ESCALATE
```

## 5. Phase / Gate

Phases and Gates govern long-running project progress, architectural decisions, acceptance boundaries, high-risk escalation, blockers, and recovery.

## 6. Independent External Advisor Review

Through an authorized MCP connection, the External Advisor can read real engineering evidence for critical-stage reviews, anomaly analysis, direction checks, and independent examination of major issues. MCP is not used as a communication bus between development roles.

---

# Installation

> Current version: **V0.1 Public Beta · v0.1.0-beta.1**

## Ask Codex to install it for you (recommended)

Copy the complete sentence below into Codex:

```text
Install the AI Dev Governance v0.1.0-beta.1 Skill from https://github.com/nf2huochao/AI-Dev-Governance. If a Skill with the same name already exists, do not overwrite it; tell me first. When installation is complete, tell me whether Codex needs to be restarted.
```

## Manual installation with PowerShell

Run the following in Windows PowerShell:

```powershell
$src = Join-Path $env:TEMP ("ai-dev-governance-" + [guid]::NewGuid())
git clone --depth 1 --branch v0.1.0-beta.1 https://github.com/nf2huochao/AI-Dev-Governance.git $src
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $src "scripts\install-local-skill.ps1")
```

The installer uses the current Windows user's Codex Skill directory. If a target with the same name already exists, it stops instead of silently overwriting the old version.

After installation, restart Codex. In a new Codex project or conversation, send:

```text
Use ai-dev-governance to help me start a project.
```

If the workspace-confirmation guide does not appear, consult the [Chinese First-Use Guide](docs/FIRST-USE-ONBOARDING.zh-CN.md) and report the problem through [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues).

---

# How It Works

1. The user creates a new project and conversation in Codex, then confirms an isolated workspace.
2. The original Codex conversation immediately becomes the only `CORE_ARCHITECT`.
3. The Skill creates only two new Codex conversations: `MISSION_PLANNER` and `BUILD_EXECUTOR`.
4. The team completes two real `BOOTSTRAP_HELLO → BOOTSTRAP_ACK` checks.
5. After communication succeeds, the user creates a new External Advisor conversation in ChatGPT.
6. The External Advisor helps define the project's goals, scope, plan, and acceptance criteria, then produces the Project Startup Summary.
7. The user reviews and approves the summary, then copies it once into the original Codex Core Architect conversation.
8. The Core Architect creates the project records, index, development rules, Phase baseline, decisions, and NO-GO routes.
9. The user configures External Advisor MCP and verifies that it points to the correct workspace.
10. Formal `Mission → TASK → HANDOFF → Review` development begins.

For detailed instructions, see the [Chinese First-Use Guide](docs/FIRST-USE-ONBOARDING.zh-CN.md).

---

# Privacy & Boundaries

- The user always remains the final authority
- The External Advisor does not join the routine business-code execution chain
- One AI should not both execute work and review itself
- Platform capability gaps must be recorded honestly
- Polling must not be disguised as event-driven operation
- Template or script tests must not be presented as proof of real multi-conversation communication
- Display names must not replace real role identities
- A successful send must not be presented as proof of receipt, execution, or return delivery

Before submitting an Issue, log, or screenshot, remove API keys, access tokens, cookies, sessions, customer data, private code, business data, keys, credentials, and unredacted logs.

---

# Platform Support

## Current focus

- ChatGPT Plus
- Codex
- Local Windows development environments
- Git
- MCP for independent External Advisor review

## Not prioritized in V0.1

- Dedicated Claude Code compatibility
- Multiple concurrent Executors
- Governance MCP
- Dashboard
- Database-backed governance center
- Automatic production release
- Large-scale agent swarms

---

# Public Beta Status

Verified by local deterministic regression tests:

- Isolated Windows package copy, duplicate-install protection, and package integrity
- Team-First Bootstrap
- Direct binding of the original conversation as the only Core Architect
- Creation of exactly one Mission Planner and one Build Executor
- Structural checks for HELLO / ACK identity, order, and evidence references
- No-polling and Event-Driven Relay rules
- Single Writer, Project Startup Summary, and governance initialization mechanisms

Still being validated with real users:

- Compatibility across different ChatGPT Plus and Codex environments
- Actual Codex discovery, real HELLO / ACK delivery, execution, and wake-up across three independent conversations
- The first-time External Advisor setup experience
- Real MCP connection experience
- The complete `Mission → TASK → HANDOFF → Review` cycle
- Long-running project recovery
- Sustained development stability across different project types

Public Beta does not mean Stable, and it does not authorize unattended production operations.

---

# Roadmap

V0.1 is not focused on adding more agents. Its priority is making the foundational governance chain reliable:

- First-time installation and onboarding for new users
- Compatibility across project types
- MCP review experience
- Error recovery and interruption recovery
- Lower token consumption
- Clearer user-visible status
- Better public-beta feedback mechanisms
- More accessible Chinese and English documentation

---

# Documentation & Feedback

- [Chinese First-Use Guide](docs/FIRST-USE-ONBOARDING.zh-CN.md)
- [Project Planning Prompt](docs/PROJECT-PLANNING-PROMPT.zh-CN.md)
- [External Advisor MCP Guide](docs/MCP-EXTERNAL-ADVISOR-SETUP.zh-CN.md)
- [Failure Recovery Guide](docs/FAILURE-RECOVERY.zh-CN.md)
- [GitHub Issues](https://github.com/nf2huochao/AI-Dev-Governance/issues)

This project is licensed under the [Apache License 2.0](LICENSE).

---

# Invitation to Test and Contribute

AI Dev Governance does not claim to be a perfect system. It is an open-source AI development governance framework being continuously tested and corrected in real user environments.

If you are a ChatGPT Plus or Codex user, a non-professional programmer, an independent developer, or someone who wants to use AI for long-running real software development, you are welcome to join the Public Beta. Tell us what feels too complex, what is not automated enough, which rules do not work, and which platform boundaries need to be explained more clearly.

Your feedback will help build an AI development governance system that is **more accessible to ordinary users, more transparent, more supervisable, and more sustainable**.

## Closing

> May AI become not only more capable,
>
> but also more orderly.
>
> May development become not only faster,
>
> but also more trustworthy.

**AI Dev Governance / AI 开发治理局**

You are welcome to test it, improve it, and build with us.
