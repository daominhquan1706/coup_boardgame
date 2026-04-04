const { test, expect } = require('@playwright/test');
const {
  addBotsInLobby,
  createRoomAndWaitLobby,
  startGameFromLobby,
  waitForGameScreen,
} = require('./helpers/coup-e2e-helpers');

test.describe('Coup app flow', () => {
  test('P0-01 host can create a room, add a bot, and start the game', async ({
    page,
  }) => {
    test.setTimeout(180_000);

    await page.goto('/');
    await createRoomAndWaitLobby(page);
    await addBotsInLobby(page, 1);
    await startGameFromLobby(page);
    await expect(await waitForGameScreen(page, 45_000)).toBeVisible();
  });
});
