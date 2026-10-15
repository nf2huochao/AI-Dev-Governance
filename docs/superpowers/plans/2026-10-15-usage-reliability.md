# Usage Reliability Implementation Plan

> Execute inline with executing-plans. The user approved optimizing the preceding six-point design; no new governance team, publication or installation is authorized.

**Goal:** Turn the demonstrated usage failures into safer event recording, accurate recovery and reviewable behavior without changing the four roles.
**Architecture:** Reuse the existing role registry, relay state machine and local evidence boundary. Add a single validated append command and an offline native-action trace check; neither authenticates platform facts. Preserve historical logs and user-approved project exceptions as unverified claims pending original-source review.
**Tech Stack:** PowerShell 5.1/7, Markdown, existing regression runner.

## Constraints

- Only this isolated Skill source branch changes; no running project, global installation, archived conversation, production or remote write.
- No fifth role, transport, polling service, database, automatic Gate or fabricated events.
- Keep public version references at v0.1.3; changes are Unreleased until separately authorized for publication.
- Historical agent failures supply the behavior baseline. Local trace/fixture tests do not establish that a new independent live team complies; that remains MANUAL_REQUIRED.

## Tasks

- [ ] Read the current implementation and tests; reproduce missing append protection, approved-exception recovery and send/wait behavior against isolated fixtures before patching.
- [ ] Add `scripts/add-relay-event.ps1 -ProjectPath -EventPath -ExpectedLogHash`. Lock the log, reject stale hashes and conflicting local event IDs, validate the full prospective history in memory through `check-relay.ps1 -EventLines`, append only after validation, and preserve bytes on failure. Duplicate identical IDs must be idempotent; never repair old logs automatically.
- [ ] Update `get-onboarding-status.ps1` to retain current work when Bootstrap remains ACTIVE or a manual-review exception is recorded. Return REVIEW_PROJECT_EXCEPTION / RECONCILE_ACTIVE_PROJECT / REPAIR_RELAY as appropriate. All outputs retain may_start_mission=false; recorded exception text never grants authority or MCP success.
- [ ] Add `check-relay-behavior.ps1 -TracePath -SendCallId` for actual native read_thread exports: after the specified send boundary, flag active peer queries/waits in that same turn. Do not classify quoted examples as executed actions, claim platform authenticity or run this by polling the sender after every send.
- [ ] Add read-only `install-local-skill.ps1 -InspectOnly` for same-name installations and version/hash visibility; do not move or overwrite installed Skills.
- [ ] Update only relevant role/protocol/template guidance: named no-wait boundaries, original human communication authorization, Core-owned pending work, and separate implementation/isolated/live/user acceptance evidence. Retain all frozen authorities and approvals.
- [ ] Run new `tests/phase-9-usage-reliability.ps1` plus all prior suites under both shells; validate metadata, runtime allowlist install, diff and private-data exclusion. Commit locally and report exact remaining live-test limits.

## Verification

```powershell
pwsh -NoProfile -File tests/run-tests.ps1 -Filter phase-9-usage-reliability.ps1
pwsh -NoProfile -File tests/run-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-tests.ps1
git diff --check
```

## Review of scope

The append writer enforces local structure, not honest platform reporting. The trace checker observes an exported sequence, not future compliance. A project exception must be checked against the actual human decision. Existing invalid history remains invalid and is never rewritten or relabelled PASS. Platform approvals remain in force.

## Verified results

Publication scope update: the Human Governor subsequently authorized completing and publishing v0.1.4 on GitHub. The original no-publication constraint above records the earlier implementation scope; it no longer blocks the separately authorized release. Existing installations and running teams remain untouched.

Implementation tasks above are complete. PowerShell 7.6.5 and Windows PowerShell 5.1 each passed all 20 test files; the new usage-reliability suite passed 12/12 cases in each shell. Metadata validation and git diff whitespace checks passed. An offline historical native-action export correctly produced SEND_YIELD_VIOLATION; it is private test material, excluded from the runtime package and commit.

Fresh independent multi-chat compliance, actual MCP connectivity and user acceptance remain MANUAL_REQUIRED. No existing project, global installation, archived conversation or GitHub release was changed. Runtime package installation is checked in an isolated temporary directory; it does not establish Codex discovery or platform communication.
