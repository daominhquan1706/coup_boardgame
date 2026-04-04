# Coup App User Guide

**SKILL TYPE:** User Guide / App Documentation  
**TRIGGERS:** "cách sử dụng app", "how to use app", "app guide", "hướng dẫn sử dụng", "coup tutorial", "cách chơi coup", "app features", "tính năng app"  
**SCOPE:** Complete user guide covering all features, routes, and user flows of the Coup Boardgame app.

---

## 📱 App Overview

Coup Boardgame là ứng dụng di động/web chơi board game Coup trực tuyến, sử dụng:
- **State Management:** GetX (reactive với `Obx`, `Rx`, `GetxController`)
- **Backend:** Firebase Firestore (real-time streams)
- **Auth:** Firebase Anonymous Authentication
- **Storage:** GetStorage (local persistence cho displayName, userName)
- **Localization:** Tiếng Anh (en) và Tiếng Việt (vi)

---

## 🗺️ Route Map

| Route | Path | Screen | Binding |
|-------|------|--------|---------|
| Splash | `/` | `SplashPage` | `SplashBinding` |
| Home | `/home` | `HomePage` | `HomeBinding` |
| Lobby | `/coup/:room_code/lobby` | `LobbyRoomPage` | `LobbyRoomBinding` |
| Game | `/coup/:room_code/playing` | `GamePage` | `GameStartBinding` |

### Navigation Flow

```
Splash (/)
  ↓ (auto-auth + 1.2s delay)
Home (/home)
  ↓ Create Room          ↓ Join Room (enter code)
Lobby (/coup/:code/lobby)
  ↓ Host starts game (all ready)
Game (/coup/:code/playing)
  ↓ Game ends / host ends
Lobby (back to waiting)
```

---

## 🔐 1. Authentication (Splash Screen)

**File:** `lib/app/modules/splash/`

### Luồng hoạt động:
1. App mở → `SplashPage` hiển thị logo + loading
2. `SplashController._bootstrap()` tự động:
   - Kiểm tra `FirebaseAuth.instance.currentUser`
   - Nếu chưa có → `signInAnonymously()` (anonymous auth)
   - Delay 1.2s → navigate đến `/home`

### Key code:
```dart
// controller.dart
final auth = FirebaseAuth.instance;
User? user = auth.currentUser;
if (user == null) {
  final credential = await auth.signInAnonymously()
      .timeout(const Duration(seconds: 8));
  user = credential.user;
}
Get.offNamed(AppRoutes.home);
```

### Lưu ý:
- Không có màn login/register riêng — auth tự động anonymous
- User ID được dùng để generate `playerId` (format: `P_<uid-suffix>`)

---

## 🏠 2. Home Screen — Tạo & Join Room

**File:** `lib/app/modules/home/`  
**Controller:** `HomeController`

### 2.1. Chọn ngôn ngữ
- Toggle giữa English / Vietnamese
- `controller.changeLanguage('en')` hoặc `controller.changeLanguage('vi')`
- UI: `Obx(() => Wrap(...))` reactive

### 2.2. Tạo Room (Create Room)

**Cách dùng:**
1. Nhấn nút **"Create Room"** (màu xanh lá)
2. Controller generate random 4-digit code: `generateRoomCode()` → ví dụ `0482`
3. Gọi `FirestoreService.createRoom(roomCode, [playerId], hostDisplayName: defaultDisplayName)`
4. Nếu thành công → navigate đến `/coup/{roomCode}/lobby`

**Key code:**
```dart
// controller.dart
Future<void> onTapCreateRoom() async {
  AppToast.info('msgCreatingRoom'.tr);
  final roomCode = generateRoomCode(); // Random 0000-9999
  final isCreateRoomeSuccess = await Get.find<FirestoreService>().createRoom(
    roomCode,
    [playerId],
    hostDisplayName: defaultDisplayName,
  );
  if (isCreateRoomeSuccess) {
    Get.toNamed(AppRoutes.lobbyRoomPath(roomCode));
  } else {
    AppToast.error('msgFailedCreateRoom'.tr);
  }
}
```

**Firestore operations:**
- Tạo document `games/{roomCode}` với status=`waiting`, hostId=playerId
- Tự động join host vào room với `isReady: true`

### 2.3. Join Room

**Cách dùng:**
1. Nhập **room code** (4 số) vào text field
2. Nhấn **"Join Room"** (màu xanh dương)
3. Controller kiểm tra `FirestoreService.isCanJoinRoom(roomCode, playerId)`:
   - Room tồn tại?
   - Game chưa bắt đầu (status == 'waiting')?
   - Room chưa đầy (< maxPlayersPerRoom)?
   - Tên chưa bị trùng?
4. Nếu pass → navigate đến `/coup/{roomCode}/lobby`

**Key code:**
```dart
// controller.dart
Future<void> onTapJoinRoom() async {
  if (roomCode.value.isEmpty) {
    AppToast.info('msgEnterRoomCode'.tr);
    return;
  }
  final isCanJoinRoom = await Get.find<FirestoreService>()
      .isCanJoinRoom(roomCode.value, playerId);
  if (isCanJoinRoom) {
    Get.toNamed(AppRoutes.lobbyRoomPath(roomCode.value));
  }
}
```

### 2.4. Player ID & Display Name

- **Player ID** (unique): Lưu trong `GetStorage` key `userName`, format `P_<suffix>`
- **Display Name**: Lưu trong `GetStorage` key `displayName`, default `Player_<last4>`
- Người dùng có thể đổi display name trong Lobby

---

## 🎮 3. Lobby Screen — Phòng chờ

**File:** `lib/app/modules/lobby_room/`  
**Controller:** `LobbyRoomController`

### 3.1. Vào Lobby

Khi navigate đến `/coup/:room_code/lobby`:
1. `onReady()` subscribe `getRoomStream(roomCode)` — real-time updates
2. Tự động `joinRoom()` với `CoupPlayerModel` (isReady=false, isBot=false)
3. Nếu `autoReady=1` trong URL params → auto set ready
4. Nếu room state chuyển sang `playing` → auto navigate đến Game screen

### 3.2. UI Components

| Component | Mô tả |
|-----------|-------|
| **Room Code Card** | Hiển thị mã phòng 4 số + nút Copy |
| **My Info Card** | TextField đổi display name + nút Edit Name + Ready/Unready toggle |
| **Players Card** | Danh sách người chơi với avatar, tên, badge Ready/BOT |
| **Host Controls** | Nút Add Bot + Start Game (chỉ host thấy) |

### 3.3. Copy Room Code

```dart
Future<void> copyCode() async {
  await Clipboard.setData(ClipboardData(text: roomCode!));
  AppToast.success('msgRoomCodeCopied'.tr, duration: 900ms);
}
```

### 3.4. Update Display Name

**Cách dùng:**
1. Gõ tên mới vào TextField trong "MY INFO" card
2. Debounce 1 giây → `_syncMyDisplayName()`
3. Hoặc nhấn nút **"Edit Name"** → force sync ngay lập tức
4. Firestore update `displayName` field của player
5. Optimistic UI update + lưu vào GetStorage

**Key code:**
```dart
// controller.dart
void onDisplayNameChanged(String value) {
  _pendingDisplayName.value = value; // Debounce 1s
}

Future<void> updateMyDisplayName() async {
  await _syncMyDisplayName(showSuccessToast: true);
}

Future<void> _syncMyDisplayName({bool showSuccessToast = false}) async {
  final me = mePlayer;
  if (me == null) return;
  final name = displayNameController.text.trim();
  if (name.isEmpty) return;
  final success = await _firestoreService.updatePlayerDisplayName(
      roomCode!, me.name, name);
  if (success) {
    _storage.write(LocalStorageKeys.displayName, name);
    if (showSuccessToast) AppToast.success('msgNameUpdated'.tr);
  }
}
```

### 3.5. Toggle Ready

**Cách dùng:**
- Người chơi (không phải host) nhấn nút **"Ready"** / **"Unready"**
- Host và BOT luôn auto-ready
- `controller.toggleReady()` → `FirestoreService.updatePlayerReady(roomCode, me.name, isReady: !me.isReady)`

### 3.6. Add Bot (Host only)

**Cách dùng:**
1. Host nhấn nút **"Add Bot"** trong Players card header
2. `controller.addAI()` → `FirestoreService.addBot(roomCode)`
3. BOT được tạo với tên `BOT_<timestamp>`, auto-ready, isBot=true

**Key code:**
```dart
Future<void> addAI() async {
  if (!isHost) {
    AppToast.error('msgOnlyHostAddBot'.tr);
    return;
  }
  await _firestoreService.addBot(roomCode!);
}
```

**Firestore:**
```dart
Future<void> addBot(String roomId) async {
  final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
  await joinRoom(roomId, CoupPlayerModel(
    name: 'BOT_$suffix',
    displayName: 'BOT_$suffix',
    isReady: true,
    cards: [],
    isAlive: true,
    coins: 2,
    isBot: true,
  ));
}
```

### 3.7. Kick Player (Host only)

**Cách dùng:**
1. Host nhấn nút **"Kick"** (màu đỏ) bên cạnh tên player
2. `controller.kickPlayer(player.name)` → `FirestoreService.kickPlayer(roomCode, hostId, targetPlayerId)`
3. Player bị xóa khỏi Firestore → stream update → player đó bị redirect về Home

**Key code:**
```dart
Future<void> kickPlayer(String targetPlayerId) async {
  if (!isHost || userName == null) return;
  await _firestoreService.kickPlayer(
    roomCode!,
    hostId: userName!,
    targetPlayerId: targetPlayerId,
  );
}
```

**Client-side detection:**
```dart
// Trong room stream listener
final me = value.players.firstWhereOrNull((p) => p.name == userName);
if (me == null) {
  AppToast.info('msgYouWereKicked'.tr);
  Get.offAllNamed(AppRoutes.home);
  return;
}
```

### 3.8. Start Game (Host only)

**Điều kiện:**
- Ít nhất 2 người chơi
- Tất cả người chơi (không phải BOT) đã Ready
- Chỉ host mới có thể start

**Cách dùng:**
1. Host nhấn nút **"Start Game"** (màu xanh lá)
2. `controller.startGame()` → `FirestoreService.startGame(roomCode)`

**Key code:**
```dart
bool get canStart {
  final players = room.value?.players ?? [];
  if (players.length < 2) return false;
  return players.every((player) => player.isBot ? true : player.isReady);
}

Future<void> startGame() async {
  if (!isHost) { AppToast.error('msgOnlyHostStart'.tr); return; }
  if (!canStart) { AppToast.error('msgAllPlayersReady'.tr); return; }
  await _firestoreService.startGame(roomCode!);
}
```

**Firestore operations khi start:**
1. Clear round artifacts (actions, blocks, challenges)
2. Generate standard deck (15 cards: 3x mỗi role × 5 roles)
3. Shuffle player order
4. Deal 2 cards mỗi player
5. Set coins=2, alive=true cho mỗi player
6. Update room status → `playing`, phase → `action`
7. Set `currentTurnPlayerId` = player đầu tiên

---

## 🃏 4. Game Screen — Chơi game

**File:** `lib/app/modules/game/`  
**Controller:** `GameStartController`

### 4.1. Vào Game

Khi navigate đến `/coup/:room_code/playing`:
1. Nhận `roomCode` và `userName` từ Get.arguments hoặc URL params
2. Subscribe `getRoomStream(roomCode)` — real-time updates
3. Subscribe `getActionHistoryStream(roomCode)` — lịch sử actions
4. Nếu room state → `waiting` (game bị end) → redirect về Lobby

### 4.2. Game UI Layout

```
┌─────────────────────────────────────────┐
│  Top Bar: COUP | Room Code | End Game  │
├──────────┬──────────────────────────────┤
│          │                              │
│  Nav     │   Game Board (Tab chính)     │
│  Rail    │   - Table Arena (bài, coins) │
│  (wide)  │   - Player seats quanh bàn   │
│          │   - Action Panel (nút actions)│
│  Tabs    │                              │
│  (narrow)│   Các tab khác:              │
│  - Game  │   - History (lịch sử actions)│
│  - History│  - Rules (luật chơi)        │
│  - Rules │   - Settings (auto-play)     │
│  - Settings                            │
└──────────┴──────────────────────────────┘
```

### 4.3. Game States & Phases

**GameState:**
- `waiting` → Phòng chờ (chưa start)
- `playing` → Đang chơi
- `finished` → Kết thúc

**GamePhase:**
- `waiting` → Chưa bắt đầu
- `action` → Lượt của người chơi (chọn action)
- `challenge` → Chờ challenge action
- `block` → Chờ block action
- `blockChallenge` → Chờ challenge block
- `resolve` → Resolve action (exchange, reveal)
- `finished` → Game kết thúc

### 4.4. Các Actions trong game

| Action | Coins | Target | Claim Role | Description |
|--------|-------|--------|------------|-------------|
| **Income** | +1 | Không | Không | Lấy 1 coin từ bank |
| **Foreign Aid** | +2 | Không | Không | Lấy 2 coin từ bank (có thể bị block bởi Duke) |
| **Tax** | +3 | Không | Duke | Lấy 3 coin từ bank |
| **Steal** | +2 (từ target) | Có | Captain | Cướp 2 coin từ đối thủ |
| **Assassinate** | -3 | Có | Assassin | Loại 1 influence của đối thủ |
| **Exchange** | 0 | Không | Ambassador | Đổi bài với deck |
| **Coup** | -7 | Có | Không | Loại 1 influence (bắt buộc nếu ≥10 coins) |

### 4.5. Thực hiện Action

**Cách dùng:**
1. Đến lượt bạn (`isMyTurn` = true)
2. Action Panel hiển thị các nút action khả dụng
3. Nhấn action → nếu cần target → dialog chọn đối thủ
4. Action được gửi lên Firestore

**Key code:**
```dart
Future<void> performAction(CoupActionType action) async {
  if (!canAct) { AppToast.info('gameNotYourTurn'.tr); return; }
  
  CoupPlayerModel? targetPlayer;
  if (CoupFunction.isNeedPlayerTarget(action)) {
    targetPlayer = await _buildDialogTargetPlayer();
    if (targetPlayer == null) return;
  }
  
  final actionModel = CoupActionModel(
    source: mePlayer.value!,
    target: targetPlayer,
    actionType: action,
  );
  await _firestoreService.performAction(roomCode, actionModel);
}
```

### 4.6. Challenge

Khi đối thủ claim role (Tax, Steal, Assassinate, Exchange):
- Bạn có thể **Challenge** nếu nghi ngờ họ không có role đó
- Nếu challenge thành công → đối thủ reveal 1 card
- Nếu challenge thất bại → bạn reveal 1 card

```dart
Future<void> challengeAction() async {
  await _firestoreService.respondToChallenge(roomCode, userName, challenge: true);
}

Future<void> passChallenge() async {
  await _firestoreService.respondToChallenge(roomCode, userName, challenge: false);
}
```

### 4.7. Block

Một số actions có thể bị block:
- **Foreign Aid** → block bằng Duke
- **Steal** → block bằng Captain
- **Assassinate** → block bằng Ambassador

```dart
Future<void> blockAction(String claimedCard) async {
  await _firestoreService.respondToBlockOpportunity(
    roomCode, userName, block: true, claimedCard: claimedCard);
}

Future<void> passBlockOpportunity({bool auto = false}) async {
  await _firestoreService.respondToBlockOpportunity(
    roomCode, userName, block: false);
}
```

### 4.8. Exchange (Ambassador)

Khi dùng Ambassador action:
1. Dialog hiển thị bài hiện tại + bài rút từ deck
2. Người chơi chọn giữ lại cards nào
3. Submit selection → Firestore update influences

```dart
Future<List<String>?> _selectInfluencesToKeepForPendingExchange(
  CoupActionModel action,
) async {
  // Hiển thị dialog chọn cards để giữ
  return _showExchangeSelectionDialog(
    candidates: candidates,
    hiddenToKeep: hiddenToKeep,
    initialSelectedIds: defaultSelectedIds,
  );
}
```

### 4.9. Auto-Play Mode

**Settings Tab** có toggle **Auto-Play**:
- Khi bật, auto decision sau 5 giây countdown
- Auto income khi đến lượt
- Auto pass challenge/block
- Hữu ích khi chơi với BOT hoặc casual play

```dart
void setAutoActionEnabled(bool enabled) {
  autoActionEnabled.value = enabled;
  if (!enabled) { _cancelAutoDecision(); return; }
  _scheduleAutoDecision(room);
}
```

### 4.10. End Game

**Host có thể kết thúc game:**
- Nhấn nút **"End Game"** trong Top Bar
- `controller.endGame()` → `FirestoreService.endGame(roomCode)`
- Reset tất cả players về trạng thái waiting
- Redirect về Lobby

### 4.11. BOT Processing

- Chỉ **host client** xử lý BOT actions (tránh race conditions)
- `_processBots(room)` → `FirestoreService.processBots(room.roomId)`
- BOT tự động thực hiện actions khi đến lượt

---

## 📊 5. Data Models

### CoupRoomModel
```dart
class CoupRoomModel {
  String roomId;                    // Mã phòng (4 số)
  List<CoupPlayerModel> players;    // Danh sách người chơi
  GameState roomState;              // waiting | playing | finished
  GamePhase phase;                  // action | challenge | block | ...
  String? hostId;                   // ID của host
  List<CoupCardModel> deck;         // Bài còn lại trong deck
  String? currentTurn;              // ID người đang đến lượt
  String? winnerId;                 // ID người thắng
  List<String> playerOrder;         // Thứ tự người chơi
  CoupActionModel? currentAction;   // Action đang diễn ra
}
```

### CoupPlayerModel
```dart
class CoupPlayerModel {
  String name;              // Unique player ID (P_xxx hoặc BOT_xxx)
  String? displayName;      // Tên hiển thị (do user đặt)
  List<CoupCardModel> cards;  // Influence cards (tối đa 2)
  bool isAlive;             // Còn trong game?
  bool isReady;             // Đã sẵn sàng?
  int coins;                // Số coins hiện tại
  bool isBot;               // Là BOT?
  
  String get shownName => displayName?.trim().isNotEmpty ?? false 
      ? displayName!.trim() : name;
}
```

### GameState & GamePhase
```dart
enum GameState { waiting, playing, finished }
enum GamePhase { waiting, action, challenge, block, blockChallenge, resolve, finished }
```

---

## 🔥 6. Firestore Service — Key Operations

**File:** `lib/app/data/firestore/firestore_service.dart`

| Method | Mô tả |
|--------|-------|
| `createRoom(roomId, players, hostDisplayName)` | Tạo room mới |
| `joinRoom(roomId, player)` | Join room (kiểm tra điều kiện) |
| `isCanJoinRoom(roomId, userName)` | Kiểm tra có thể join không |
| `addBot(roomId)` | Thêm BOT vào room |
| `removeBot(roomId)` | Xóa BOT khỏi room |
| `updatePlayerReady(roomId, playerId, isReady)` | Toggle ready status |
| `updatePlayerDisplayName(roomId, playerId, displayName)` | Đổi tên hiển thị |
| `kickPlayer(roomId, hostId, targetPlayerId)` | Kick player (host only) |
| `startGame(roomId)` | Bắt đầu game |
| `endGame(roomId)` | Kết thúc game |
| `performAction(roomId, actionModel)` | Thực hiện action |
| `respondToChallenge(roomId, playerId, challenge)` | Challenge hoặc pass |
| `respondToBlockOpportunity(roomId, playerId, block, ...)` | Block hoặc pass |
| `respondToBlockChallenge(roomId, playerId, challenge)` | Challenge block |
| `submitExchangeSelection(roomId, playerId, keepInfluences)` | Submit exchange |
| `submitRevealSelection(roomId, playerId, revealedInfluence)` | Submit reveal |
| `getRoomStream(roomId)` | Real-time stream của room |
| `getActionHistoryStream(roomId)` | Real-time stream của history |
| `processBots(roomId)` | Xử lý BOT actions (host only) |

---

## 🌐 7. Localization

**Files:**
- `lib/app/translations/en_us.dart` — English
- `lib/app/translations/vi_vn.dart` — Vietnamese

### Cách đổi ngôn ngữ:
```dart
// HomeController
void changeLanguage(String languageCode) {
  selectedLanguage.value = languageCode;
  Get.updateLocale(Locale(languageCode));
}
```

### Key translations:
| Key | English | Vietnamese |
|-----|---------|------------|
| `homeCreateRoomButton` | Create Room | Tạo phòng |
| `homeJoinRoomButton` | Join Room | Vào phòng |
| `lobbyStartGame` | Start Game | Bắt đầu game |
| `lobbyAddBot` | Add Bot | Thêm bot |
| `lobbyKick` | Kick | Mời ra |
| `lobbyEditName` | Edit Name | Đổi tên |
| `lobbyReady` | Ready | Sẵn sàng |
| `gameEndGame` | End Game | Kết thúc game |

---

## 🧪 8. E2E Testing Tags

App được instrument với E2E tags cho Playwright testing:

| Tag | Location |
|-----|----------|
| `e2e-home-create-room-button` | Home → Create Room button |
| `e2e-home-join-room-code-input` | Home → Room code input |
| `e2e-home-join-room-button-ready` | Home → Join Room (enabled) |
| `e2e-home-join-room-button-disabled` | Home → Join Room (disabled) |
| `e2e-lobby-room-code-card` | Lobby → Room code card |
| `e2e-lobby-add-bot-button` | Lobby → Add Bot button |
| `e2e-lobby-start-game-button-ready` | Lobby → Start Game (enabled) |
| `e2e-lobby-start-game-button-disabled` | Lobby → Start Game (disabled) |
| `e2e-game-screen` | Game screen |
| `e2e-game-nav-rail` | Game navigation rail |

---

## 📁 9. File Structure Reference

```
lib/
├── main.dart                           # App entry point
├── firebase_options.dart               # Firebase config
└── app/
    ├── routes/
    │   ├── app_pages.dart              # Route definitions + GetPage bindings
    │   └── app_routes.dart             # Route path constants
    ├── modules/
    │   ├── splash/                     # Splash screen (auto-auth)
    │   │   ├── binding.dart
    │   │   ├── controller.dart
    │   │   └── page.dart
    │   ├── home/                       # Home screen (create/join room)
    │   │   ├── binding.dart
    │   │   ├── controller.dart
    │   │   └── page.dart
    │   ├── lobby_room/                 # Lobby screen (waiting room)
    │   │   ├── binding.dart
    │   │   ├── controller.dart
    │   │   └── page.dart
    │   └── game/                       # Game screen (playing)
    │       ├── binding.dart
    │       ├── controller.dart
    │       ├── page.dart
    │       └── widgets/                # Game sub-widgets
    │           ├── game_page_top_bar.dart
    │           ├── game_page_table_arena.dart
    │           ├── game_page_action_panel.dart
    │           ├── game_page_history.dart
    │           ├── game_page_rules_settings.dart
    │           ├── game_page_end_screen.dart
    │           ├── game_page_widgets.dart
    │           └── game_page_motion.dart
    ├── data/
    │   ├── firestore/
    │   │   └── firestore_service.dart  # All Firestore operations
    │   ├── model/
    │   │   ├── firestore_model/
    │   │   │   ├── coup_room_model.dart
    │   │   │   ├── coup_player_model.dart
    │   │   │   ├── coup_action_model.dart
    │   │   │   └── coup_card_model.dart
    │   │   └── game_history_entry.dart
    │   ├── api/
    │   │   └── api_error.dart          # Error types
    │   └── provider/
    │       ├── home_provider.dart
    │       ├── lobby_room_provider.dart
    │       └── game_provider.dart
    ├── constants/
    │   └── local_storage_keys.dart     # GetStorage keys
    ├── translations/
    │   ├── app_translations.dart
    │   ├── en_us.dart
    │   └── vi_vn.dart
    └── utils/
        ├── constants.dart              # App constants (maxPlayers, etc.)
        ├── functions/
        │   └── coup_function.dart      # Game logic helpers
        └── widgets/
            ├── app_toast.dart          # Toast notifications
            └── e2e_tag.dart            # E2E testing wrapper
```

---

## 🎯 10. Quick User Flow Summary

### Tạo game mới:
1. Mở app → Splash auto-auth → Home
2. Nhấn **"Create Room"** → Room code được tạo ngẫu nhiên
3. Vào Lobby → Copy room code gửi cho bạn bè
4. (Optional) Nhấn **"Add Bot"** để thêm BOT
5. Chờ người chơi join → Mỗi người nhấn **"Ready"**
6. Host nhấn **"Start Game"** → Vào game

### Join game có sẵn:
1. Mở app → Home
2. Nhập **room code** (4 số) → Nhấn **"Join Room"**
3. Vào Lobby → Đổi tên (optional) → Nhấn **"Ready"**
4. Chờ host start game

### Trong game:
1. Đến lượt → Chọn action (Income, Tax, Steal, ...)
2. Nếu cần target → Dialog chọn đối thủ
3. Đối thủ có thể Challenge hoặc Block
4. Lose influence → Reveal card
5. Mất hết 2 cards → Eliminated
6. Người cuối cùng còn alive → Winner!

### Kết thúc game:
1. Host nhấn **"End Game"** → Về Lobby
2. Hoặc chơi lại từ Lobby
