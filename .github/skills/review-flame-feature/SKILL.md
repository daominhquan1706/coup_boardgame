---
name: review-flame-feature
description: "**REVIEW SKILL** — Review a Flame game feature for bugs, performance risks, and gameplay regressions. USE FOR: pre-merge review and stabilization of Flame modules. Triggers on: 'review flame feature', 'audit flame game', 'check flame performance', 'flame bug review'. DO NOT USE FOR: creating new feature scaffolds from scratch."
argument-hint: "Path to feature and target platform"
---

# Review Flame Feature

Perform a focused technical review of a Flame module before merge or release.

## Workflow

### Step 1 - Scope the Review
- Identify entry files (`*_game.dart`, page/widget host, overlays)
- Identify core components and systems (player, enemy, spawn, scoring)
- Confirm target platform constraints (web/mobile)

### Step 2 - Correctness Review
Check for:
- Incorrect `dt` usage causing frame-dependent behavior
- Missing/incorrect collision hitboxes
- State transitions that can deadlock (paused/gameOver/restart)
- Resource loading race conditions in `onLoad`

### Step 3 - Performance Review
Check for:
- Per-frame object allocations in `update`/`render`
- Excessive component churn without pooling
- Unbounded timers/spawners
- Heavy overlay rebuild frequency

### Step 4 - Resilience Review
Check for:
- Null/late initialization hazards
- Asset path mismatch and missing fallback behavior
- Restart leaks (old components/timers still alive)
- Input handlers active in invalid states

### Step 5 - Testing and Validation
- Run analyzer on affected files
- Run or add at least one focused test for critical system logic
- Manual smoke test: start, play, lose, restart, pause/resume

## Output Format
Report findings first, ordered by severity:
1. Critical
2. Major
3. Minor

Each finding should include:
- File path
- What breaks and why
- Minimal fix direction

## Quality Checklist
- [ ] Findings are actionable and reproducible
- [ ] At least one runtime/perf risk assessed
- [ ] Includes testing gaps and residual risks
