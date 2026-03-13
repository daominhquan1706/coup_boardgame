---
name: create-flame-feature
description: "**FEATURE SCAFFOLD SKILL** — Scaffold a new Flame game feature in Flutter. USE FOR: creating a playable module with FlameGame, world, player, HUD overlay, and route wiring. Triggers on: 'create flame feature', 'scaffold flame game', 'new flame module', 'flame feature'. DO NOT USE FOR: tuning one existing component only; non-Flame Flutter screens."
argument-hint: "Feature name and game type, e.g. 'arena_battle top-down'"
---

# Create Flame Feature

Create a complete baseline Flame feature that is runnable, extendable, and aligned with project structure.

## Workflow

### Step 1 - Confirm Inputs
- `{feature_name}` in snake_case
- Game style: top-down, platformer, endless-runner, or puzzle
- Primary platform target: mobile, web, or both
- Confirm if this feature should live in `lib/app/modules/` (default in this workspace)

### Step 2 - Resolve Paths
Default path:

```text
lib/app/modules/{feature_name}/
```

Create these files (adapt names if project conventions differ):
- `{feature_name}_game.dart`
- `components/player_component.dart`
- `components/enemy_component.dart`
- `world/{feature_name}_world.dart`
- `overlays/{feature_name}_hud.dart`
- `{feature_name}_page.dart`

### Step 3 - Generate Baseline Game Architecture
Required composition:
- `class {FeatureName}Game extends FlameGame with HasCollisionDetection`
- A world object responsible for spawning entities and map boundaries
- A player component with movement + hitbox
- At least one enemy/NPC component
- An HUD overlay (score, HP, state)

### Step 4 - Wire UI Integration
- Create a Flutter page using `GameWidget(game: ...)`
- Register overlays in `overlayBuilderMap`
- Provide start/pause/restart control hooks
- Keep overlay widgets stateless where possible, state sourced from game notifiers

### Step 5 - Add Assets Contract
- Define required assets and expected paths in comments near loading code
- Use `images.load` or `Sprite.load` from predictable directories
- Fail fast with clear logs if critical assets are missing

### Step 6 - Validate
Run checks:
- `fvm flutter analyze` on created files
- `fvm flutter test` if tests are added
- Ensure game reaches first playable frame without exceptions

## Decision Points
- If game logic is tiny and no camera/world needed, use a single `FlameGame` file plus one overlay.
- If map/camera or many entities are expected, split into `world/`, `components/`, and `systems/` immediately.
- If web is a target, avoid heavy per-frame allocations and test on Chrome early.

## Quality Checklist
- [ ] First frame renders with no runtime errors
- [ ] Player can perform at least one meaningful action
- [ ] Hitbox/collision present for interactive entities
- [ ] HUD updates from live game state
- [ ] Code split avoids giant monolithic game class
- [ ] Analyzer passes for generated files
