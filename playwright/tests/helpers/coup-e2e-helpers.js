const { expect } = require("@playwright/test");

function byTaggedButton(page, tag) {
  return page.getByRole("button", { name: new RegExp(tag, "i") }).first();
}

function byTaggedTextbox(page, tag) {
  return page.getByRole("textbox", { name: new RegExp(tag, "i") }).first();
}

function byTaggedSemanticNode(page, tag) {
  return page.locator("flt-semantics").filter({ hasText: tag }).last();
}

async function enableFlutterSemantics(page) {
  const placeholder = page.locator("flt-semantics-placeholder").first();
  if (!(await placeholder.count())) return;

  try {
    await placeholder.click({ force: true, timeout: 2_000 });
  } catch {
    await page.evaluate(() => {
      const node = document.querySelector("flt-semantics-placeholder");
      if (node instanceof HTMLElement) {
        node.dispatchEvent(
          new MouseEvent("mousedown", { bubbles: true, cancelable: true }),
        );
        node.dispatchEvent(
          new MouseEvent("mouseup", { bubbles: true, cancelable: true }),
        );
        node.dispatchEvent(
          new MouseEvent("click", { bubbles: true, cancelable: true }),
        );
      }
    });
  }

  await page.waitForTimeout(100);
}

async function waitForTaggedButton(page, tag, timeoutMs = 60_000) {
  const button = byTaggedButton(page, tag);
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    if (await button.count()) return button;
    await page.waitForTimeout(250);
  }

  return button;
}

async function waitForTaggedTextbox(page, tag, timeoutMs = 60_000) {
  const textbox = byTaggedTextbox(page, tag);
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    if (await textbox.count()) return textbox;
    await page.waitForTimeout(250);
  }

  return textbox;
}

async function waitForTaggedSemanticNode(page, tag, timeoutMs = 60_000) {
  const node = byTaggedSemanticNode(page, tag);
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    if (await node.count()) return node;
    await page.waitForTimeout(250);
  }

  return node;
}

async function openHome(page) {
  await page.goto("/");
  const createRoomButton = await waitForTaggedButton(
    page,
    "e2e-home-create-room-button",
    90_000,
  );
  await expect(createRoomButton).toBeVisible({ timeout: 5_000 });
}

async function createRoomAndWaitLobby(page) {
  const createRoomButton = await waitForTaggedButton(
    page,
    "e2e-home-create-room-button",
    90_000,
  );
  await expect(createRoomButton).toBeVisible({ timeout: 5_000 });
  await createRoomButton.click();

  const roomCodeCard = await waitForTaggedSemanticNode(
    page,
    "e2e-lobby-room-code-card",
    45_000,
  );
  await expect(roomCodeCard).toBeVisible({ timeout: 5_000 });
  return roomCodeCard;
}

async function readRoomCodeFromLobby(page) {
  const roomCodeCard = await waitForTaggedSemanticNode(
    page,
    "e2e-lobby-room-code-card",
    45_000,
  );
  const text = (await roomCodeCard.textContent()) || "";
  const match = text.match(/\b\d{4}\b/);
  if (match) return match[0];

  const fallbackText = (await page.locator("body").textContent()) || "";
  const fallbackMatch = fallbackText.match(/\b\d{4}\b/);
  if (fallbackMatch) return fallbackMatch[0];

  throw new Error("Unable to read lobby room code");
}

async function joinRoomFromHome(page, roomCode) {
  await waitForTaggedTextbox(page, "e2e-home-join-room-code-input", 45_000);
  const taggedInputNode = byTaggedSemanticNode(
    page,
    "e2e-home-join-room-code-input",
  );
  const visibleTextbox = page
    .getByRole("textbox", { name: /Enter room code/i })
    .first();
  const domTextbox = page
    .locator(
      'input[data-semantics-role="text-field"][aria-label*="Enter room code"]',
    )
    .first();

  let typed = false;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    await enableFlutterSemantics(page);

    if (await taggedInputNode.count()) {
      await taggedInputNode
        .click({ force: true, timeout: 1_500 })
        .catch(() => {});
    } else if (await visibleTextbox.count()) {
      await visibleTextbox
        .click({ force: true, timeout: 1_000 })
        .catch(() => {});
    }

    await page.keyboard.press("ControlOrMeta+A").catch(() => {});
    await page.keyboard.press("Backspace").catch(() => {});
    await page.keyboard.type(roomCode, { delay: 30 }).catch(() => {});

    const currentValue = await domTextbox.inputValue().catch(() => "");
    if (currentValue === roomCode) {
      typed = true;
      break;
    }

    if (await domTextbox.count()) {
      await domTextbox.fill(roomCode, { timeout: 1_000 }).catch(() => {});
      const retryValue = await domTextbox.inputValue().catch(() => "");
      if (retryValue === roomCode) {
        typed = true;
        break;
      }
    }

    await page.waitForTimeout(250);
  }

  if (!typed) {
    throw new Error(`Unable to type room code "${roomCode}" into join input`);
  }

  const readyJoinButton = await waitForTaggedButton(
    page,
    "e2e-home-join-room-button-ready",
    20_000,
  );
  await expect(readyJoinButton).toBeVisible({ timeout: 5_000 });
  const joinBox = await readyJoinButton.boundingBox();
  if (joinBox) {
    await page.mouse.click(
      joinBox.x + joinBox.width / 2,
      joinBox.y + joinBox.height / 2,
    );
  } else {
    await readyJoinButton.click({ force: true });
  }
  await page.waitForTimeout(300);
}

async function addBotsInLobby(page, count) {
  for (let i = 0; i < count; i += 1) {
    const addBotButton = await waitForTaggedButton(
      page,
      "e2e-lobby-add-bot-button",
      30_000,
    );
    await expect(addBotButton).toBeVisible({ timeout: 5_000 });
    await addBotButton.click();
    await page.waitForTimeout(250);
  }
}

async function startGameFromLobby(page) {
  const startButton = await waitForTaggedButton(
    page,
    "e2e-lobby-start-game-button-ready",
    45_000,
  );
  await expect(startButton).toBeVisible({ timeout: 5_000 });
  await startButton.click();
  await waitForGameScreen(page, 45_000);
}

async function waitForGameScreen(page, timeoutMs = 45_000) {
  await enableFlutterSemantics(page);
  const gameScreen = page.getByRole("group", { name: /e2e-game-screen/i });
  await expect(gameScreen).toBeVisible({ timeout: timeoutMs });
  return gameScreen;
}

async function waitForActionTurn(page, timeoutMs = 60_000) {
  const incomeButton = page.getByRole("button", { name: /^Income$/ }).first();
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    if (await incomeButton.count()) {
      const visible = await incomeButton.isVisible().catch(() => false);
      if (visible) return incomeButton;
    }
    await page.waitForTimeout(300);
  }

  return incomeButton;
}

async function selectBotTargetIfDialogVisible(page) {
  const botButton = page.getByRole("button", { name: /BOT_/ }).first();
  if (await botButton.count()) {
    await botButton.click();
    return true;
  }

  const botText = page.getByText(/BOT_/).first();
  if (await botText.count()) {
    await botText.click();
    return true;
  }

  return false;
}

async function performTargetActionWithIncomeFarm(
  page,
  actionLabel,
  maxTurns = 10,
) {
  const actionRegex = new RegExp(`^${actionLabel}$`, "i");
  const actionButton = page.getByRole("button", { name: actionRegex }).last();

  for (let i = 0; i < maxTurns; i += 1) {
    const incomeButton = await waitForActionTurn(page, 60_000);
    await expect(incomeButton).toBeVisible({ timeout: 5_000 });

    await actionButton.click({ timeout: 2_000 }).catch(() => {});
    await page.waitForTimeout(300);

    if (await selectBotTargetIfDialogVisible(page)) {
      await page.waitForTimeout(400);
      return true;
    }

    await incomeButton.click({ timeout: 2_000 }).catch(() => {});
    await page.waitForTimeout(250);
  }

  return false;
}

/**
 * Wait for the game to end and return to lobby.
 */
async function waitForGameEndAndReturnToLobby(page, timeoutMs = 120_000) {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    const roomCodeCard = page
      .locator("flt-semantics")
      .filter({ hasText: "e2e-lobby-room-code-card" })
      .last();
    if (await roomCodeCard.count()) {
      const visible = await roomCodeCard.isVisible().catch(() => false);
      if (visible) return roomCodeCard;
    }
    await page.waitForTimeout(500);
  }

  throw new Error("Game did not end and return to lobby within timeout");
}

/**
 * Perform Income action (no target needed).
 */
async function performIncome(page) {
  const incomeButton = await waitForActionTurn(page, 60_000);
  await expect(incomeButton).toBeVisible({ timeout: 5_000 });
  await incomeButton.click({ timeout: 2_000 });
  await page.waitForTimeout(300);
}

/**
 * Perform Foreign Aid action (no target needed).
 */
async function performForeignAid(page) {
  const incomeButton = await waitForActionTurn(page, 60_000);
  await expect(incomeButton).toBeVisible({ timeout: 5_000 });

  const foreignAidButton = page
    .getByRole("button", { name: /^Foreign Aid$/ })
    .last();
  await foreignAidButton.click({ timeout: 2_000 }).catch(() => {});
  await page.waitForTimeout(300);
}

/**
 * Perform Tax action (no target needed, claims Duke).
 */
async function performTax(page) {
  const incomeButton = await waitForActionTurn(page, 60_000);
  await expect(incomeButton).toBeVisible({ timeout: 5_000 });

  const taxButton = page.getByRole("button", { name: /^Tax$/ }).last();
  await taxButton.click({ timeout: 2_000 }).catch(() => {});
  await page.waitForTimeout(300);
}

/**
 * Perform Coup action (requires target selection).
 */
async function performCoup(page) {
  const incomeButton = await waitForActionTurn(page, 60_000);
  await expect(incomeButton).toBeVisible({ timeout: 5_000 });

  const coupButton = page.getByRole("button", { name: /^Coup$/ }).last();
  await coupButton.click({ timeout: 2_000 }).catch(() => {});
  await page.waitForTimeout(300);

  if (await selectBotTargetIfDialogVisible(page)) {
    await page.waitForTimeout(400);
    return true;
  }

  return false;
}

/**
 * Wait for winner announcement.
 */
async function waitForWinner(page, timeoutMs = 120_000) {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    const bodyText = await page
      .locator("body")
      .textContent()
      .catch(() => "");
    const winnerMatch = bodyText.match(/(\w+)\s*wins!/);
    if (winnerMatch) {
      return winnerMatch[1];
    }
    await page.waitForTimeout(500);
  }

  return null;
}

/**
 * Navigate back to Home from current screen by clicking COUP logo.
 */
async function navigateToHome(page) {
  const coupLogo = page.getByText("COUP").first();
  if (await coupLogo.count()) {
    await coupLogo.click({ timeout: 2_000 }).catch(() => {});
    await page.waitForTimeout(300);
  } else {
    await page.goto("/home");
    await waitForTaggedButton(page, "e2e-home-create-room-button", 30_000);
  }
}

/**
 * Update display name in Lobby.
 */
async function updateDisplayName(page, newName) {
  const nameInput = page
    .getByRole("textbox", { name: /Enter display name/i })
    .first();
  if (await nameInput.count()) {
    await nameInput.click({ force: true, timeout: 1_500 }).catch(() => {});
    await page.keyboard.press("ControlOrMeta+A").catch(() => {});
    await page.keyboard.press("Backspace").catch(() => {});
    await page.keyboard.type(newName, { delay: 30 }).catch(() => {});
    await page.waitForTimeout(1500); // Wait for debounce
  }
}

/**
 * Toggle ready status in Lobby.
 */
async function toggleReady(page) {
  const readyButton = page
    .getByRole("button", { name: /Ready|Unready/i })
    .first();
  if (await readyButton.count()) {
    await readyButton.click({ timeout: 2_000 });
    await page.waitForTimeout(300);
  }
}

/**
 * Kick a player from Lobby (host only).
 */
async function kickPlayer(page, playerName) {
  const kickButton = page
    .getByRole("button", { name: "Kick" })
    .filter({ hasText: playerName })
    .first();
  if (await kickButton.count()) {
    await kickButton.click({ timeout: 2_000 });
    await page.waitForTimeout(300);
  }
}

/**
 * End game from Game screen (host only).
 */
async function endGame(page) {
  const endGameButton = page.getByRole("button", { name: /End Game/i }).first();
  if (await endGameButton.count()) {
    await endGameButton.click({ timeout: 2_000 });
    await page.waitForTimeout(500);
  }
}

/**
 * Copy room code from Lobby.
 */
async function copyRoomCode(page) {
  const copyButton = page.getByRole("button", { name: /Copy/i }).first();
  if (await copyButton.count()) {
    await copyButton.click({ timeout: 2_000 });
    await page.waitForTimeout(300);
  }
}

/**
 * Wait for a specific toast message to appear.
 */
async function waitForToast(page, messagePattern, timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  const regex = new RegExp(messagePattern, "i");

  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    const bodyText = await page
      .locator("body")
      .textContent()
      .catch(() => "");
    if (regex.test(bodyText)) {
      return true;
    }
    await page.waitForTimeout(250);
  }

  return false;
}

/**
 * Play a full game as host with bots until someone wins.
 * Uses aggressive actions (Coup) to speed up the game.
 */
async function playFullGameAsHost(hostPage, maxTurns = 50) {
  let turnCount = 0;

  while (turnCount < maxTurns) {
    turnCount += 1;

    // Wait for my turn
    const incomeButton = await waitForActionTurn(hostPage, 60_000).catch(
      () => null,
    );
    if (!incomeButton) {
      // Check if game ended
      const roomCodeCard = hostPage
        .locator("flt-semantics")
        .filter({ hasText: "e2e-lobby-room-code-card" })
        .last();
      if (await roomCodeCard.count()) {
        return "returned_to_lobby";
      }
      continue;
    }

    await expect(incomeButton).toBeVisible({ timeout: 5_000 });

    // Try Coup first (most aggressive)
    const coupButton = hostPage.getByRole("button", { name: /^Coup$/ }).last();
    if (await coupButton.isVisible().catch(() => false)) {
      await coupButton.click({ timeout: 2_000 }).catch(() => {});
      await hostPage.waitForTimeout(300);

      if (await selectBotTargetIfDialogVisible(hostPage)) {
        await hostPage.waitForTimeout(500);
        continue;
      }
    }

    // Try Assassinate if have enough coins
    const assassinButton = hostPage
      .getByRole("button", { name: /^Assassinate$/ })
      .last();
    if (await assassinButton.isVisible().catch(() => false)) {
      await assassinButton.click({ timeout: 2_000 }).catch(() => {});
      await hostPage.waitForTimeout(300);

      if (await selectBotTargetIfDialogVisible(hostPage)) {
        await hostPage.waitForTimeout(500);
        continue;
      }
    }

    // Try Steal
    const stealButton = hostPage
      .getByRole("button", { name: /^Steal$/ })
      .last();
    if (await stealButton.isVisible().catch(() => false)) {
      await stealButton.click({ timeout: 2_000 }).catch(() => {});
      await hostPage.waitForTimeout(300);

      if (await selectBotTargetIfDialogVisible(hostPage)) {
        await hostPage.waitForTimeout(500);
        continue;
      }
    }

    // Fallback to Income
    await incomeButton.click({ timeout: 2_000 }).catch(() => {});
    await hostPage.waitForTimeout(300);
  }

  return "max_turns_reached";
}

module.exports = {
  addBotsInLobby,
  byTaggedButton,
  byTaggedSemanticNode,
  byTaggedTextbox,
  copyRoomCode,
  createRoomAndWaitLobby,
  enableFlutterSemantics,
  endGame,
  joinRoomFromHome,
  kickPlayer,
  navigateToHome,
  openHome,
  performCoup,
  performForeignAid,
  performIncome,
  performTargetActionWithIncomeFarm,
  performTax,
  playFullGameAsHost,
  readRoomCodeFromLobby,
  selectBotTargetIfDialogVisible,
  startGameFromLobby,
  toggleReady,
  updateDisplayName,
  waitForActionTurn,
  waitForGameEndAndReturnToLobby,
  waitForGameScreen,
  waitForTaggedButton,
  waitForTaggedSemanticNode,
  waitForTaggedTextbox,
  waitForToast,
  waitForWinner,
};
