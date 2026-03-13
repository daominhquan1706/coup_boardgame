---
name: generate-flame-component
description: "**CODE GEN SKILL** — Generate a reusable Flame component with lifecycle, movement, and collision hooks. USE FOR: creating player, enemy, projectile, pickup, or obstacle components. Triggers on: 'create flame component', 'generate player component', 'flame enemy', 'flame projectile'. DO NOT USE FOR: full game scaffolding; pure Flutter widget screens."
argument-hint: "Component type + behavior, e.g. 'projectile fast linear'"
---

# Generate Flame Component

Generate one production-ready Flame component with clear responsibilities and extension points.

## Workflow

### Step 1 - Confirm Component Contract
- Component role: player, enemy, projectile, item, obstacle
- Coordinate type: world-space or screen-space
- Collision type: passive, active, or none
- Update model: fixed-speed, acceleration, or state-machine

### Step 2 - Pick Base Class
- Use `SpriteComponent` when single-sprite visual is enough
- Use `PositionComponent` when rendering is custom
- Mix in `CollisionCallbacks` when participating in collisions

### Step 3 - Generate Component
Must include:
- Constructor with required dependencies (position, size, speed, assets)
- `onLoad` for sprite/children initialization
- `update(double dt)` with deterministic math
- Optional `onCollisionStart` / `onCollisionEnd` when collision enabled

### Step 4 - Add Safety and Extensibility
- Avoid allocations inside `update` when possible
- Clamp velocity and position as needed
- Keep side effects explicit (emit event/callback instead of direct global mutation)

### Step 5 - Usage Snippet
Provide a small usage example showing how to spawn/add the component into the game world.

## Decision Points
- If animation frames are required, switch to `SpriteAnimationComponent`.
- If behavior grows past ~120 lines, split logic into helper methods or mini systems.
- If component owns gameplay state transitions, document the states explicitly.

## Quality Checklist
- [ ] Correct Flame base class chosen
- [ ] `dt` used consistently for frame-rate independent movement
- [ ] Collision hitbox matches visual intent
- [ ] No heavy allocation in `update`
- [ ] Constructor API is clear and minimal
