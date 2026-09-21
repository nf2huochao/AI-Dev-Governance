# Project Development Rules

## Requirement authority

- The original `.ai-governance/PROJECT-STARTUP-SUMMARY.md` is the approved product baseline.
- Every Mission and TASK must serve the approved goal and first-version scope.
- A material scope or goal change requires new Human Governor approval.

## Role boundaries

- Core Architect governs Phase, Gate, Mission, architecture and deviation; it does not write business code.
- Mission Planner creates, dispatches and reviews TASKs; it does not write business code or self-approve.
- Build Executor is the only formal business-code writer and submits Handoff, not PASS.
- External Advisor independently audits evidence and does not participate in ordinary TASK dispatch.
- No AI supervises itself.

## Relay and safety

- The original Codex conversation is the only `CORE_ARCHITECT`; `BOOTSTRAP` is a temporary state, not a role.
- Core Architect uses `CURRENT_CONTEXT / REUSE_CURRENT`; only Mission Planner and Build Executor may pass the deterministic create-thread guard. `EXPECTED_NEW_CODEX_THREADS = 2`.
- Create exactly one `MISSION_PLANNER` and one `BUILD_EXECUTOR`; duplicate or uncertain creation stops the route for conflict review.
- Verify `PROJECT_ID`, `ROLE_ID`, `THREAD_ID` and the native communication target handle before messaging. These are separate fields; `TASK_ID`, `EXECUTION_ID` and `OUTER_TASK_ID` are never message targets.
- The formal `RELAY_EVENTS.jsonl` starts empty. Record only real platform events, with a real `EXECUTION_ID`; examples are not runtime history.
- Complete both `BOOTSTRAP_HELLO → BOOTSTRAP_ACK` checks before planning, Mission or business-code changes.
- Run `check-startup-readiness.ps1` and preserve the original platform/MCP records before publishing the first Mission. The checker must not authenticate hand-written JSON, `VERIFIED_BY_PLATFORM`, message IDs or send-tool success; when no native evidence verifier exists, remain `MANUAL_REQUIRED`.
- Normal relay uses `SEND → YIELD → WAKE → ACT`.
- No polling. Work on events.
- Governance files and logs do not replace real messages, Handoffs, tests, Commit evidence or platform wake evidence.
- Production, real data, credentials, irreversible actions, payment, public release and frozen architecture changes require Human Governor authorization.
