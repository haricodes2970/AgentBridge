# Cross-agent dogfood report — TEMPLATE

## Date
_2026-11-06_

## Agents used
- Arm 1 agent: _Agent A (e.g. Cline)_
- Arm 2 agent: _Agent B (e.g. OpenCode)_
- Project: /tmp/agentbridge-dogfood
- Control project: /tmp/agentbridge-dogfood-control

## Prerequisite status
- Two agents installed: yes / no
- bridges active: yes / no

## Stale bridge check (status.sh before Arm 1)
```
_<output>_
```

## Arm 1 metrics — with AgentBridge
- First action: _
- Files read before first edit: _ (# baseline: 7)
- Tool calls before first useful action: _ (# baseline: ~9)
- Correctly identified bug in lib/tax-calculator.js? _ (yes / no)
- Asked questions? _ What the bridge failed to answer: _

## Arm 2 metrics — control (no bridge)
- First action: _
- Files read before first edit: _ (# baseline: 7)
- Tool calls before first useful action: _ (# baseline: ~9)
- Correctly located bug in lib/tax-calculator.js? _ (yes / no)
- Asked questions? _ What was missing: _

## Delta
- Files read: _ (# from 7 to #)
- Tool calls: _ (# from ~9 to #)
- Conclusion: AgentBridge _ (reduced / did not reduce)

## Rough edges
- _list anything unexpected here_ (e.g. agent ignored instructions, stale files,
  missing info the bridge did not have)

## Conclusion
_One paragraph honest summary: did AgentBridge reduce cold-start cost, and for
what kind of project was it most valuable?_
