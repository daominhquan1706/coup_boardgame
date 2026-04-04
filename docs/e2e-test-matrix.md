# E2E Test Matrix

This matrix tracks end-to-end coverage for the Coup web flow.

## P0 (required in CI)

| ID | Flow | Priority | Status | Target Spec |
|---|---|---|---|---|
| P0-01 | Host creates room, adds bot, starts game, reaches game screen | P0 | Covered | `playwright/tests/app-flow.spec.js` |
| P0-02 | Join room success path from Home to Lobby | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-03 | Join room failure: room not found | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-04 | Join room failure: room full | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-05 | Join room failure: game already started | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-06 | Host cannot start game until at least 2 players and all non-bot players ready | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-07 | Core game action smoke (income, coup, assassin) | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |
| P0-08 | End game from game screen | P0 | Planned | `playwright/tests/p0-core.todo.spec.js` |

## P1 (core gameplay branches)

| ID | Flow | Priority | Status |
|---|---|---|---|
| P1-01 | Challenge action success branch | P1 | Planned |
| P1-02 | Challenge action fail branch | P1 | Planned |
| P1-03 | Block foreign aid with duke | P1 | Planned |
| P1-04 | Block assassinate with contessa | P1 | Planned |
| P1-05 | Block steal with captain or ambassador | P1 | Planned |
| P1-06 | Challenge block success branch | P1 | Planned |
| P1-07 | Challenge block fail branch | P1 | Planned |
| P1-08 | Turn rotation and finish condition | P1 | Planned |
| P1-09 | Bot auto decisions in action and response phases | P1 | Planned |
| P1-10 | Auto-action toggle and countdown behavior | P1 | Planned |

## P2 (UX and operational flows)

| ID | Flow | Priority | Status |
|---|---|---|---|
| P2-01 | Splash fallback still routes to Home on auth bootstrap failure | P2 | Planned |
| P2-02 | Language switch from Home | P2 | Planned |
| P2-03 | Language switch from Game settings tab | P2 | Planned |
| P2-04 | Player display name update from Lobby | P2 | Planned |
| P2-05 | Host kicks player in Lobby | P2 | Planned |
| P2-06 | History tab renders and copy logs works | P2 | Planned |
| P2-07 | Rules tab and settings metadata render | P2 | Planned |

## Notes

- Keep P0 green in CI before adding P1/P2 branches.
- Prefer deterministic server setup for local visual debugging (`flutter build web` + static HTTP server).
