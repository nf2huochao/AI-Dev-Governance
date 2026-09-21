# Decisions

## Decision record format

```text
DECISION-ID: {{DECISION_ID}}
Decision: {{DECISION}}
Status: PROPOSED | ACCEPTED | SUPERSEDED | CLOSED
Why: {{WHY}}
Evidence: {{EVIDENCE}}
Supersedes: {{SUPERSEDED_DECISION_ID_OR_NONE}}
Approved by: {{APPROVER}}
Date: {{DATE}}
```

## Protection rules

- Accepted decisions cannot be silently overridden by a TASK.
- Superseded decisions must identify the replacement.
- Closed issues cannot be reopened without new evidence and governance review.
- Build Executor cannot modify formal decisions.
