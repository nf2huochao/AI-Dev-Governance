# V0.1.3 Reliability Implementation Plan

> Execute inline using executing-plans. The user has approved the preceding audit and requested fixes and a GitHub release; do not restart product design or create governance roles.

**Goal:** Fix the confirmed relay defects and improve startup, recovery and version visibility without changing the four-role model.
**Architecture:** Extend existing scripts and ROLE-MAP metadata. Version new formal events, retain legacy histories as unverified structural records, and never authenticate platform facts from files.
**Tech Stack:** Windows PowerShell 5.1 / PowerShell 7, Markdown, Git and GitHub CLI.

## Constraints

- Original development tree, foreign-trade projects, Gate 7B and archived chats remain untouched.
- No fifth role, new transport, paid API, polling, false ACK or automatic Gate approval.
- New release is v0.1.3 Public Beta. Existing tags and history are preserved.

## Work

- [x] Add `tests/phase-9-v013-reliability.ps1`: execute real scripts on isolated synthetic fixtures, verify pre-ACK blocking, identity/project mismatch, missing evidence, linked handoff/review, and retained legacy logs. Run against baseline and retain failing output.
- [x] Extend `protocols/relay-contract.json` and `scripts/check-relay.ps1`: DISPATCH → BLOCKED needs a real error reference; schema 2 associates threads with ROLE-MAP and requires local evidence links. Report declared/linked counts separately; never report them as authenticated completion.
- [x] Add read-only `scripts/get-current-context.ps1` returning a candidate from the actual environment, not a verified identity. The bootstrap workflow must cross-check native thread metadata and target contract once.
- [x] Add policy version/hash metadata to existing ROLE-MAP and `scripts/check-policy-version.ps1`; init preserves old metadata, status reports differences without modifying files. Include scripts in runtime whitelist.
- [x] Update Bootstrap preflight, Mission completion branch, concise Chinese/English quick start, recovery/version instructions and actual behavior-test plan.
- [x] Run `tests/run-tests.ps1` with both shells; exercise bounded real CLI behavior if available, clearly distinguishing it from desktop multi-chat/MCP. Unavailable platform tests remain MANUAL_REQUIRED.
- [ ] Update package version, bilingual release notes/changelog/README installation commands. Review diff for private data, commit, push a non-forced branch, merge reviewed PR, tag and create prerelease.
- [ ] Download v0.1.3 from GitHub into a new isolation directory and execute the actual installer; verify runtime files and installation receipt. Do not overwrite global installations.

## Verification commands

```powershell
pwsh -NoProfile -File tests/run-tests.ps1 -Filter phase-9-v013-reliability.ps1
pwsh -NoProfile -File tests/run-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-tests.ps1
git diff --check
```

## Completion conditions

All deterministic regressions pass; new runtime package installs from the actual remote tag; native communication is not falsely claimed. GitHub commit, tag and release must be verified before reporting publication.

This checklist records source-preparation status. Publication and subsequent remote-install evidence are recorded in the GitHub release handoff, not retroactively asserted before they occur.
