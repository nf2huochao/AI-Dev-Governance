# Relay State

- Current Mission: `{{MISSION_ID}}`
- Current Task: `{{TASK_ID}}`
- Current Owner: `{{CURRENT_OWNER}}`
- Current Status: `{{DISPATCH | ACK | WORKING | HANDOFF | REVIEW | PASS | REWORK | BLOCKED | ESCALATE}}`
- Last Handoff: `{{LAST_HANDOFF}}`
- Next Expected Action: `{{NEXT_EXPECTED_ACTION}}`
- Last Updated: `{{LAST_UPDATED}}`

## Recovery rule

This file is a snapshot, not a replacement for the real relay conversation. On recovery, load the role Prompt, current Mission, current Task Contract, latest events and latest Commit before continuing.
