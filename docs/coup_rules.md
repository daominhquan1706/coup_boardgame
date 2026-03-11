# Coup – Game Rules Specification

This document defines the rules and gameplay logic for the Coup multiplayer game.  
It is intended to guide implementation for Flutter clients and Firestore backend logic.

---

# 1. Game Overview

Coup is a multiplayer bluffing and deduction game.

Players use hidden influence cards to perform actions, challenge other players, and eliminate opponents.  
The last remaining player with at least one unrevealed influence wins the game.

---

# 2. Player Limits

| Rule | Value |
|---|---|
| Minimum players | 2 |
| Maximum players | 6 |
| Starting coins | 2 |
| Starting influence | 2 cards |

Bots may be added by the host during the waiting room phase.

---

# 3. Influence Cards

Deck contains the following cards:

| Card | Count | Ability |
|---|---|---|
| Duke | 3 | Take Tax (3 coins), block Foreign Aid |
| Assassin | 3 | Assassinate a player |
| Captain | 3 | Steal coins |
| Ambassador | 3 | Exchange cards |
| Contessa | 3 | Block assassination |

Total deck size: **15 cards**

Each player receives **2 hidden cards** at the start.

---

# 4. Game Setup

Game initialization process:

1. Create and shuffle deck.
2. Each player receives 2 influence cards.
3. Each player starts with 2 coins.
4. Determine the first player randomly.
5. Game phase begins with **action phase**.

---

# 5. Game Objective

Eliminate all other players by forcing them to reveal both influence cards.

A player is eliminated when:

```
revealedInfluenceCount >= 2
```

---

# 6. Turn Structure

Each turn follows this sequence:

```
Turn Start
→ Player selects action
→ Challenge phase
→ Block phase (if applicable)
→ Resolve action
→ Next player turn
```

Only the **current turn player** may initiate an action.

---

# 7. Available Actions

## 7.1 Income

Effect:

```
+1 coin
```

Properties:

| property | value |
|---|---|
| Challengeable | No |
| Blockable | No |

---

## 7.2 Foreign Aid

Effect:

```
+2 coins
```

Properties:

| property | value |
|---|---|
| Challengeable | No |
| Blockable | Yes (Duke) |

---

## 7.3 Coup

Effect:

```
Target player loses one influence
```

Cost:

```
7 coins
```

Properties:

| property | value |
|---|---|
| Challengeable | No |
| Blockable | No |

Rule:

If a player has **10 or more coins**, they **must perform Coup**.

---

## 7.4 Tax (Duke)

Effect:

```
+3 coins
```

Properties:

| property | value |
|---|---|
| Required card | Duke |
| Challengeable | Yes |
| Blockable | No |

---

## 7.5 Assassinate (Assassin)

Effect:

```
Target player loses one influence
```

Cost:

```
3 coins
```

Properties:

| property | value |
|---|---|
| Required card | Assassin |
| Challengeable | Yes |
| Blockable | Yes (Contessa) |

---

## 7.6 Steal (Captain)

Effect:

```
Take up to 2 coins from target player
```

Properties:

| property | value |
|---|---|
| Required card | Captain |
| Challengeable | Yes |
| Blockable | Yes (Captain or Ambassador) |

---

## 7.7 Exchange (Ambassador)

Effect:

```
Draw 2 cards from deck
Choose 2 cards to keep
Return the rest to the deck
Shuffle deck
```

Properties:

| property | value |
|---|---|
| Required card | Ambassador |
| Challengeable | Yes |
| Blockable | No |

---

# 8. Challenge Rules

Any player may challenge a claim.

Challenge process:

```
Player declares action
→ Opponent challenges
→ Acting player reveals card
```

Result:

### If claim is true

```
Challenger loses one influence
Acting player returns revealed card to deck
Draws a new card
Deck reshuffled
```

### If claim is false

```
Acting player loses one influence
Action fails
```

---

# 9. Block Rules

Some actions may be blocked.

| Action | Blocked By |
|---|---|
| Foreign Aid | Duke |
| Assassinate | Contessa |
| Steal | Captain or Ambassador |

Block can also be challenged.

Challenge resolution follows the same rule as action challenges.

---

# 10. Losing Influence

When a player loses influence:

1. Player selects one of their hidden cards
2. Card is revealed publicly
3. Card becomes inactive

If both cards are revealed:

```
player.alive = false
```

---

# 11. Turn Rotation

After resolving the action:

```
Next player = next alive player clockwise
```

Skip eliminated players.

---

# 12. Win Condition

Game ends when:

```
alivePlayers == 1
```

Winner is the remaining player with unrevealed influence.

---

# 13. Waiting Room Rules

Before game start:

Host can:

- start the game
- add bot players
- remove bot players

Players can:

- join room
- leave room

Game can start when:

```
playerCount >= 2
```

---

# 14. Bot Behaviour (Basic)

Bots follow simple logic:

Priority example:

```
if coins >= 7 → coup
else if coins < 3 → income
else random strategic action
```

Bots may:

- challenge randomly
- block if possible

---

# 15. Game State Phases

Possible phases:

```
waiting
action
challenge
block
resolve
finished
```

Transitions must follow the game state machine.

---

# 16. Visibility Rules

Players can see:

| Data | Visibility |
|---|---|
| own cards | visible |
| opponent cards | hidden |
| revealed cards | visible |
| coins | visible |

---

# 17. Realtime Requirements

Client should listen to:

```
game state
player list
action history
```

All updates should propagate in realtime to all players.

---

# 18. Anti-Cheat Principle

Client must not control game state.

Rules:

- only server transactions update coins
- influence changes must be validated
- turn order enforced by backend

Firestore should be the **single source of truth**.