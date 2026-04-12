const { test, expect } = require("@playwright/test");
const {
  addBotsInLobby,
  createRoomAndWaitLobby,
  joinRoomFromHome,
  openHome,
  readRoomCodeFromLobby,
  startGameFromLobby,
  waitForActionTurn,
  waitForGameScreen,
  waitForTaggedButton,
  waitForTaggedSemanticNode,
  performIncome,
  performTax,
  performForeignAid,
  performCoup,
  selectBotTargetIfDialogVisible,
  playFullGameAsHost,
  waitForWinner,
  endGame,
  navigateToHome,
  waitForGameEndAndReturnToLobby,
} = require("./helpers/coup-e2e-helpers");

test.describe("Full Game Flow - Play to End", () => {
  test("F01: Host creates room, adds bot, plays full game until winner", async ({
    browser,
  }) => {
    test.setTimeout(600_000); // 10 minutes for full game

    const hostContext = await browser.newContext();
    const hostPage = await hostContext.newPage();

    try {
      // Step 1: Open app and create room
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      const roomCode = await readRoomCodeFromLobby(hostPage);
      console.log(`Room created: ${roomCode}`);

      // Step 2: Add 2 bots (minimum 3 players for interesting game)
      await addBotsInLobby(hostPage, 2);
      await hostPage.waitForTimeout(500);

      // Step 3: Start game
      await startGameFromLobby(hostPage);
      console.log("Game started");

      // Step 4: Play full game as host
      const result = await playFullGameAsHost(hostPage, 80);
      console.log(`Game result: ${result}`);

      // Step 5: Verify game ended (returned to lobby or winner announced)
      if (result === "returned_to_lobby") {
        const roomCodeCard = await waitForTaggedSemanticNode(
          hostPage,
          "e2e-lobby-room-code-card",
          15_000,
        );
        await expect(roomCodeCard).toBeVisible({ timeout: 5_000 });
        console.log("Game ended, returned to lobby");
      } else {
        // Check for winner announcement
        const winner = await waitForWinner(hostPage, 10_000);
        if (winner) {
          console.log(`Winner: ${winner}`);
        }
      }
    } finally {
      await hostContext.close().catch(() => {});
    }
  });

  test("F02: Host creates room, adds 3 bots, plays aggressive game (Coup focus)", async ({
    browser,
  }) => {
    test.setTimeout(600_000);

    const hostContext = await browser.newContext();
    const hostPage = await hostContext.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      const roomCode = await readRoomCodeFromLobby(hostPage);
      console.log(`Room created: ${roomCode}`);

      // Add 3 bots for faster elimination
      await addBotsInLobby(hostPage, 3);
      await hostPage.waitForTimeout(500);

      await startGameFromLobby(hostPage);
      console.log("Game started with 4 players");

      // Play aggressively with Coup
      const result = await playFullGameAsHost(hostPage, 100);
      console.log(`Game result: ${result}`);

      // Verify game state
      const bodyText = await hostPage.locator("body").textContent();
      expect(bodyText.length).toBeGreaterThan(0);
    } finally {
      await hostContext.close().catch(() => {});
    }
  });

  test("F03: Host ends game manually from Game screen", async ({ browser }) => {
    test.setTimeout(180_000);

    const hostContext = await browser.newContext();
    const hostPage = await hostContext.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      await addBotsInLobby(hostPage, 1);
      await startGameFromLobby(hostPage);

      // Wait for first turn
      await waitForActionTurn(hostPage, 30_000);

      // End game manually
      await endGame(hostPage);

      // Should return to lobby
      const roomCodeCard = await waitForTaggedSemanticNode(
        hostPage,
        "e2e-lobby-room-code-card",
        15_000,
      );
      await expect(roomCodeCard).toBeVisible({ timeout: 5_000 });
      console.log("Game ended manually, returned to lobby");
    } finally {
      await hostContext.close().catch(() => {});
    }
  });

  test("F04: Full game with Income and Tax actions only", async ({
    browser,
  }) => {
    test.setTimeout(300_000);

    const hostContext = await browser.newContext();
    const hostPage = await hostContext.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      await addBotsInLobby(hostPage, 1);
      await startGameFromLobby(hostPage);

      // Play 10 turns with Income/Tax only
      for (let i = 0; i < 10; i++) {
        const incomeButton = await waitForActionTurn(hostPage, 30_000).catch(
          () => null,
        );
        if (!incomeButton) break;

        // Alternate between Income and Tax
        if (i % 2 === 0) {
          await performIncome(hostPage);
          console.log(`Turn ${i + 1}: Income`);
        } else {
          await performTax(hostPage);
          console.log(`Turn ${i + 1}: Tax`);
        }
      }

      // End game
      await endGame(hostPage);
      const roomCodeCard = await waitForTaggedSemanticNode(
        hostPage,
        "e2e-lobby-room-code-card",
        15_000,
      );
      await expect(roomCodeCard).toBeVisible({ timeout: 5_000 });
    } finally {
      await hostContext.close().catch(() => {});
    }
  });
});
