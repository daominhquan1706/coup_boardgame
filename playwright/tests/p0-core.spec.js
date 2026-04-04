const { test, expect } = require('@playwright/test');
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
} = require('./helpers/coup-e2e-helpers');

test.describe('P0 Core Flows', () => {
  test('P0-02 join room success path from Home to Lobby', async ({ browser }) => {
    test.setTimeout(180_000);

    const host = await browser.newContext();
    const guest = await browser.newContext();
    const hostPage = await host.newPage();
    const guestPage = await guest.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      const roomCode = await readRoomCodeFromLobby(hostPage);

      await openHome(guestPage);
      await joinRoomFromHome(guestPage, roomCode);
      const lobbyCard = await waitForTaggedSemanticNode(
        guestPage,
        'e2e-lobby-room-code-card',
        45_000,
      );
      await expect(lobbyCard).toBeVisible({ timeout: 5_000 });
    } finally {
      await host.close().catch(() => {});
      await guest.close().catch(() => {});
    }
  });

  test('P0-03 join room failure: room not found', async ({ page }) => {
    test.setTimeout(120_000);

    await openHome(page);
    await joinRoomFromHome(page, 'ZZZZ');

    const createRoomButton = await waitForTaggedButton(
      page,
      'e2e-home-create-room-button',
      10_000,
    );
    await expect(createRoomButton).toBeVisible({ timeout: 5_000 });
    await expect(
      page.getByRole('textbox', { name: /Enter room code/i }).first(),
    ).toHaveValue('ZZZZ');
    await expect(
      page.getByRole('button', { name: /e2e-lobby-room-code-card/i }),
    ).toHaveCount(0);
  });

  test('P0-04 join room failure: room full', async ({ browser }) => {
    test.setTimeout(240_000);

    const host = await browser.newContext();
    const guest = await browser.newContext();
    const hostPage = await host.newPage();
    const guestPage = await guest.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      const roomCode = await readRoomCodeFromLobby(hostPage);
      await addBotsInLobby(hostPage, 5);

      await openHome(guestPage);
      await joinRoomFromHome(guestPage, roomCode);

      const createRoomButton = await waitForTaggedButton(
        guestPage,
        'e2e-home-create-room-button',
        15_000,
      );
      await expect(createRoomButton).toBeVisible({ timeout: 5_000 });
      await expect(
        guestPage.getByRole('textbox', { name: /Enter room code/i }).first(),
      ).toHaveValue(roomCode);
      await expect(
        guestPage.getByRole('button', { name: /e2e-lobby-room-code-card/i }),
      ).toHaveCount(0);
    } finally {
      await host.close().catch(() => {});
      await guest.close().catch(() => {});
    }
  });

  test('P0-05 join room failure: game already started', async ({ browser }) => {
    test.setTimeout(240_000);

    const host = await browser.newContext();
    const guest = await browser.newContext();
    const hostPage = await host.newPage();
    const guestPage = await guest.newPage();

    try {
      await openHome(hostPage);
      await createRoomAndWaitLobby(hostPage);
      const roomCode = await readRoomCodeFromLobby(hostPage);
      await addBotsInLobby(hostPage, 1);
      await startGameFromLobby(hostPage);

      await openHome(guestPage);
      await joinRoomFromHome(guestPage, roomCode);

      const createRoomButton = await waitForTaggedButton(
        guestPage,
        'e2e-home-create-room-button',
        15_000,
      );
      await expect(createRoomButton).toBeVisible({ timeout: 5_000 });
      await expect(
        guestPage.getByRole('textbox', { name: /Enter room code/i }).first(),
      ).toHaveValue(roomCode);
      await expect(
        guestPage.getByRole('button', { name: /e2e-lobby-room-code-card/i }),
      ).toHaveCount(0);
    } finally {
      await host.close().catch(() => {});
      await guest.close().catch(() => {});
    }
  });

  test('P0-06 host start rule: disabled with 1 player, ready after adding bot', async ({
    page,
  }) => {
    test.setTimeout(180_000);

    await openHome(page);
    await createRoomAndWaitLobby(page);

    const startDisabled = await waitForTaggedButton(
      page,
      'e2e-lobby-start-game-button-disabled',
      20_000,
    );
    await expect(startDisabled).toBeVisible({ timeout: 5_000 });

    await addBotsInLobby(page, 1);
    const startReady = await waitForTaggedButton(
      page,
      'e2e-lobby-start-game-button-ready',
      20_000,
    );
    await expect(startReady).toBeVisible({ timeout: 5_000 });
  });

  test('P0-07 core game action smoke: action panel renders and income executes', async ({
    page,
  }) => {
    test.setTimeout(180_000);

    await openHome(page);
    await createRoomAndWaitLobby(page);
    await addBotsInLobby(page, 1);
    await startGameFromLobby(page);

    const incomeButton = await waitForActionTurn(page, 60_000);
    await expect(incomeButton).toBeVisible({ timeout: 5_000 });
    await incomeButton.click();
    await expect(await waitForGameScreen(page, 15_000)).toBeVisible({
      timeout: 5_000,
    });
  });

  test('P0-08 end game from game screen returns to lobby', async ({ page }) => {
    test.setTimeout(180_000);

    await openHome(page);
    await createRoomAndWaitLobby(page);
    await addBotsInLobby(page, 1);
    await startGameFromLobby(page);

    const endGameButton = page.getByRole('button', { name: /^END GAME$/ }).first();
    await expect(endGameButton).toBeVisible({ timeout: 30_000 });
    await endGameButton.click();

    const lobbyCard = await waitForTaggedSemanticNode(
      page,
      'e2e-lobby-room-code-card',
      45_000,
    );
    await expect(lobbyCard).toBeVisible({ timeout: 5_000 });
  });
});
