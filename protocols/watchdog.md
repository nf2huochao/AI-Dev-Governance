# 治理巡检 / Watchdog

## 1. Purpose

Watchdog 是天枢核执行的轻量治理巡检，用于发现接力断链、方向偏离、重复失败、架构漂移和错误恢复。

它不代替开发、不代替 Review、不代替 External Advisor 的独立审查，也不要求正常状态下频繁发消息。

Watchdog 遵循 **No polling. Work on events.** 它只在真实的 20 分钟触发、明确治理事件或恢复请求到达时执行，不通过连续查询等待任何角色完成。

## 2. Twenty-minute inspection

从开发开始后，每 20 分钟执行一次轻量检查。每次只检查：

1. 当前 Phase 是什么？
2. 当前 Gate 是什么？
3. 当前 Mission 是什么？
4. 当前 TASK 是否直接推进当前 Gate？
5. 是否出现范围扩大？
6. 是否进入 V0.1 非目标？
7. 是否重复修同一根因？
8. 是否重新打开已关闭问题？
9. 是否出现第二套实现或临时旁路？
10. 是否有人越过角色边界？
11. 是否出现“自己实现、自己验收”？
12. 是否 PASS 后继续无边界扩张？
13. 是否已经 BLOCKED 但仍不断盲试？
14. 当前仓库是否可解释、可恢复？

正常时：保持静默，继续开发。

正常巡检只执行一轮轻量检查，记录 `WATCHDOG: CLEAR` 后立即结束本轮；不得使用 `sleep`、循环读取线程状态或持续等待恢复结果。

## 3. Evidence required

巡检只使用当前可追溯证据：

- 当前治理文件；
- 当前 Mission 和 TASK Contract；
- Relay Events；
- 代码改动和 Commit；
- 测试和执行结果；
- 已记录的 Decision、NO-GO 和 Closed Issue。

“大家都同意”“状态看起来正常”不是方向正确的证据。

## 4. Healthy relay, wrong work detection

Watchdog 必须将以下两件事分开判断：

```text
Relay Health:      DISPATCH → ACK → WORKING → HANDOFF → REVIEW → PASS
Mission Alignment: 当前 TASK 是否实际推进当前 Mission
```

即使 Relay Health 为 PASS，只要 Mission Alignment 为 NO 或 UNCLEAR，就必须标记 Deviation，不得把接力顺畅当作治理通过。

## 5. Response protocol

### Normal

```text
WATCHDOG: CLEAR
Reason:
Next Check:
```

保持静默，不向普通接力插入新任务。

### Deviation

```text
WATCHDOG: DEVIATION
Current Phase:
Current Gate:
Current Mission:
Current Task:
Evidence:
Deviation:
Required Action: PAUSE CURRENT ROUTE
Unaffected Work:
```

然后：

1. 暂停当前偏离路线；
2. 让司策令收缩或重排 TASK；
3. 必要时请求外参师独立审查；
4. 重新执行 Deviation Gate；
5. 条件清楚后才 RESUME。

如果需要恢复，Watchdog 只发送一次定向恢复消息；发送后立即 `YIELD`。接收方的真实回传或下一次合法调度事件负责 `WAKE` 后续处理。平台没有真实回唤能力时，记录 `CAPABILITY GAP` 并 `BLOCKED`，不得用轮询替代。

## 6. Anti-loop rules

- 同一根因连续两次修复失败，停止盲试并 ESCALATE。
- 已 BLOCKED 的任务没有新输入时保持等待，不重复执行相同动作。
- 已 PASS 的任务不能继续无边界扩张。
- 已 CLOSED 的问题没有新证据不能重开。
- NO-GO 路线不能通过换名称或换 TASK-ID 重新进入。
