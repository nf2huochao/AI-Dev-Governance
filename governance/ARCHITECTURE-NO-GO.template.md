# Architecture NO-GO

Record routes and working methods that are proven not to be acceptable.

## NO-GO record format

```text
NO-GO-ID: {{NO_GO_ID}}
Rejected Route: {{REJECTED_ROUTE}}
Evidence: {{EVIDENCE}}
Failure Reason: {{FAILURE_REASON}}
Affected Scope: {{AFFECTED_SCOPE}}
Allowed Alternative: {{ALLOWED_ALTERNATIVE}}
New Evidence Required to Reconsider: {{NEW_EVIDENCE_REQUIRED}}
Status: CLOSED
Date: {{DATE}}
```

## Protection rules

- A rejected route cannot be retried by changing only the TASK-ID or wording.
- A Mock/Fixture pass cannot be presented as a real integration pass.
- A second implementation or temporary bypass cannot be accumulated just to make tests pass.
- Reconsideration requires new evidence and Core Architect governance; Human Governor approval is required when the frozen architecture changes.
