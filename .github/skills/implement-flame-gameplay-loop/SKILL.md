---
name: implement-flame-gameplay-loop
description: "**GAMEPLAY SYSTEM SKILL** — Implement core Flame gameplay loop: input, movement, collision resolution, scoring, and game-over flow. USE FOR: turning a prototype scene into a playable loop. Triggers on: 'implement flame gameplay', 'wire input collision', 'add game over', 'flame loop'. DO NOT USE FOR: one-off component generation; non-game Flutter logic."
argument-hint: "Describe target loop, e.g. 'survive waves 60s with score combo'"
---

# Implement Flame Gameplay Loop

Turn existing Flame pieces into a cohesive gameplay loop with predictable state flow.

## Workflow

### Step 1 - Define Loop States
Create explicit states:
- `ready`
- `running`
- `paused`
- `gameOver`

Track state in a single authoritative location (game class or state controller).

### Step 2 - Wire Input Pipeline
- Keyboard/touch/drag should map to intent (move, dash, shoot)
- Input handlers update intent variables, not direct one-off teleports
- Consume input inside `update` for deterministic behavior

### Step 3 - Movement and Spawn Systems
- Apply intent to velocity/acceleration
- Spawn enemies/items on timers with difficulty scaling
- Keep spawn logic isolated from rendering components

### Step 4 - Collision Resolution
- Define collision matrix (who interacts with whom)
- On collision: compute outcomes (damage, destroy, collect, bounce)
- Guard against duplicate handling in same frame

### Step 5 - Score and Progression
- Track score, HP/lives, and optional combo
- Emit UI updates to overlay through notifiers/events
- Apply progression curve (spawn rate, enemy speed, reward multipliers)

### Step 6 - End Conditions and Restart
- Trigger `gameOver` when fail condition is met
- Freeze or gracefully stop active systems
- Provide clean restart path that resets all transient state

### Step 7 - Verify Runtime Behavior
- Manual run on target device(s)
- Validate pause/resume and restart behavior
- Check for orphaned components after restart

## Decision Points
- If latency-sensitive controls are needed, prioritize simple input mapping and lower logic overhead.
- If entities exceed manageable count, consider pooling for projectiles/FX.
- If logic becomes coupled, separate into tiny systems (`spawn_system.dart`, `score_system.dart`).

## Quality Checklist
- [ ] Full cycle ready -> running -> gameOver -> restart works
- [ ] Input remains responsive under load
- [ ] Collision outcomes are deterministic
- [ ] HUD reflects score/HP/state changes instantly
- [ ] Restart leaves no stale timers/components
