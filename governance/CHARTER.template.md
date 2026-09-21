# Governance Charter

## Project

- Name: `{{PROJECT_NAME}}`
- Goal: `{{PROJECT_GOAL}}`
- Human Governor: `{{HUMAN_GOVERNOR}}`
- Product baseline: `{{SPEC_PATH_OR_VERSION}}`

## Core principles

- No AI supervises itself.
- Single Writer: only Build Executor writes formal business code.
- Normal work stays inside Mission Planner ↔ Build Executor relay.
- MCP is only for External Advisor independent audit.
- Human Governor keeps final product, authorization, production, deletion, credential and major architecture decisions.

## Fixed roles

| Role | Purpose | May write business code? |
|---|---|---|
| External Advisor | Independent audit and complex root-cause analysis | No |
| Core Architect | Phase, Gate, Mission and architecture governance | No |
| Mission Planner | Task planning, dispatch and review | No |
| Build Executor | Implementation, tests, commit and handoff | Yes, only within TASK Scope |

## Permission boundaries

- Role prompts are stored in `roles/` and must be loaded in independent conversations.
- Governance files persist context but do not replace real relay dialogue.
- The Executor cannot modify this Charter, Phase/Gate, formal Decisions or NO-GO rules.
- No role may approve production, real-data, credential, irreversible, payment or release actions without the required authorization.

## Non-goals

Record project-specific V0.1 non-goals here without weakening the product baseline:

- `{{NON_GOAL_1}}`
- `{{NON_GOAL_2}}`
- `{{NON_GOAL_3}}`
