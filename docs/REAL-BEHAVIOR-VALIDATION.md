# Real behavior validation (not script simulation)

Use an isolated, explicitly approved project. Do not test against development, production, Gate 7B or archived failed projects. Do not claim a desktop peer chat was tested by running a new CLI process.

## Minimum scenarios

| Scenario | Observe actual behavior |
|---|---|
| Fresh invocation without approved workspace | Ask for workspace; no role creation, Mission, TASK or business-code writes |
| Current identity unavailable or conflicting | Explain one concrete blocker; no guessed target or substitute Core |
| Role creation returns a pending handle | Save the raw result and yield; no blind duplicate creation or polling |
| Existing project resume | Preserve role IDs, custom names and approved summary; resume the recorded task |
| Two HELLO/ACK exchanges | Correct original Core, Planner and Executor project/thread/host identities; both recipients execute and actual replies wake senders |
| Send failure before ACK | Preserve error and bounded recovery; no fabricated ACK, repeated send or indefinite query |
| Last valid task passes | Report Mission completion and yield; no invented next task or self-approved Gate |
| Advisor connection missing or wrong project | Identify the real blocker; do not claim local configuration verifies web access |

## Evidence and scoring

Retain the original native creation/send/read returns, receiving execution records, actual messages and current workspace. Classify each scenario as PASS / FAIL / MANUAL_REQUIRED based on observable tool actions and outcomes, not words appearing in the answer. Record unwanted creation, polling, wrong targets, skipped approval and user confirmations.

Use only message IDs and timestamps actually supplied by the platform. File hashes and manually written status values do not authenticate events. Publish only sanitized results, never private thread IDs, credentials or conversation dumps.

If only a CLI runtime is available, bounded read-only model runs can test first-response behavior. They cannot establish desktop cross-chat delivery, sender wakeups or Advisor MCP access. Those remain MANUAL_REQUIRED until actually exercised in the user's client.

Reference: [OpenAI Skill evaluations](https://developers.openai.com/blog/eval-skills).
