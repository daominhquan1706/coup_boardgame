# Firestore Schema – Coup Multiplayer

This document defines the Firestore data structure used by the Coup multiplayer game.  
Firestore acts as the **single source of truth** for all game state.

---

# 1. Top Level Collections

```
games/
```

Each document represents a game room.

```
games/{gameId}
```

---

# 2. Game Document

Document path:

```
games/{gameId}
```

Fields:

| field | type | description |
|---|---|---|
| status | string | waiting, playing, finished |
| hostId | string | player id of room creator |
| createdAt | timestamp | room creation time |
| startedAt | timestamp | game start time |
| currentTurnPlayerId | string | player whose turn it is |
| phase | string | waiting, action, challenge, block, resolve |
| deck | array<string> | remaining cards in deck |
| winnerId | string | player id of winner |
| playerOrder | array<string> | order of turns |

Example:

```json
{
  "status": "playing",
  "hostId": "player_1",
  "phase": "action",
  "currentTurnPlayerId": "player_2",
  "playerOrder": ["player_1","player_2","player_3"],
  "deck": ["duke","captain","assassin"],
  "createdAt": "timestamp"
}
```

---

# 3. Players Subcollection

Path:

```
games/{gameId}/players/{playerId}
```

Fields:

| field | type | description |
|---|---|---|
| name | string | display name |
| isBot | boolean | true if bot |
| coins | number | player coins |
| influences | array<string> | hidden cards |
| revealedInfluences | array<string> | revealed cards |
| alive | boolean | player active status |
| joinedAt | timestamp | time joined |

Example:

```json
{
  "name": "Player1",
  "isBot": false,
  "coins": 2,
  "influences": ["duke","captain"],
  "revealedInfluences": [],
  "alive": true
}
```

---

# 4. Actions Subcollection

Stores action history and realtime events.

Path:

```
games/{gameId}/actions/{actionId}
```

Fields:

| field | type | description |
|---|---|---|
| type | string | income, foreign_aid, coup, tax, assassinate, steal, exchange |
| playerId | string | acting player |
| targetId | string | target player if applicable |
| status | string | pending, challenged, blocked, resolved |
| claimedCard | string | card claimed for action |
| createdAt | timestamp | action time |
| resolvedAt | timestamp | resolution time |

Example:

```json
{
  "type": "steal",
  "playerId": "player_2",
  "targetId": "player_3",
  "claimedCard": "captain",
  "status": "pending",
  "createdAt": "timestamp"
}
```

---

# 5. Challenges Subcollection

Tracks challenge attempts.

Path:

```
games/{gameId}/challenges/{challengeId}
```

Fields:

| field | type | description |
|---|---|---|
| actionId | string | related action |
| challengerId | string | player who challenges |
| result | string | success, fail |
| resolvedAt | timestamp | time resolved |

Example:

```json
{
  "actionId": "action_1",
  "challengerId": "player_3",
  "result": "fail"
}
```

---

# 6. Blocks Subcollection

Tracks block attempts.

Path:

```
games/{gameId}/blocks/{blockId}
```

Fields:

| field | type | description |
|---|---|---|
| actionId | string | action being blocked |
| blockerId | string | player who blocks |
| claimedCard | string | card used to block |
| status | string | pending, resolved |
| createdAt | timestamp | time |

Example:

```json
{
  "actionId": "action_1",
  "blockerId": "player_4",
  "claimedCard": "contessa",
  "status": "pending"
}
```

---

# 7. Waiting Room Data

While the game is waiting to start:

Game document fields:

| field | type | description |
|---|---|---|
| status | string | waiting |
| hostId | string | room host |
| playersCount | number | number of players |

Host can:

- add bots
- start game

Bots appear as player documents with:

```
isBot = true
```

---

# 8. Realtime Subscriptions

Client should listen to:

```
games/{gameId}
games/{gameId}/players
games/{gameId}/actions
games/{gameId}/blocks
games/{gameId}/challenges
```

These listeners drive the UI state.

---

# 9. Transaction Requirements

The following operations must use Firestore transactions:

- resolving challenge
- resolving block
- coin transfer
- losing influence
- turn rotation

Purpose:

```
prevent race conditions
```

---

# 10. Security Principles

Firestore rules should enforce:

1. Only host can start game
2. Only current turn player can initiate action
3. Players can only modify their own player document
4. Game state transitions must follow phase rules

Example concept:

```
request.auth.uid == playerId
```

---

# 11. Indexing Recommendations

Recommended composite indexes:

| collection | fields |
|---|---|
| actions | gameId + createdAt |
| players | gameId + alive |
| blocks | actionId |
| challenges | actionId |

---

# 12. Future Extensions

Possible future schema extensions:

- spectator mode
- chat messages
- reconnect support
- ranked matchmaking
- analytics events