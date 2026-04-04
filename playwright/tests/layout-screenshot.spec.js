const fs = require('fs');
const path = require('path');
const { test, expect, devices } = require('@playwright/test');
const {
  addBotsInLobby,
  createRoomAndWaitLobby,
  openHome,
  startGameFromLobby,
  waitForGameScreen,
} = require('./helpers/coup-e2e-helpers');

const screenshotDir = path.join(process.cwd(), 'playwright', 'artifacts', 'screenshots');

async function launchGame(page) {
  try {
    await openHome(page);
  } catch {
    await page.goto('/');
    await openHome(page);
  }
  await createRoomAndWaitLobby(page);
  await addBotsInLobby(page, 1);
  await startGameFromLobby(page);
  await expect(await waitForGameScreen(page, 45_000)).toBeVisible({ timeout: 5_000 });
}

test.describe('GameStart layout screenshots', () => {
  test('capture desktop screenshot', async ({ page }) => {
    test.setTimeout(180_000);
    fs.mkdirSync(screenshotDir, { recursive: true });

    await launchGame(page);
    await page.screenshot({
      path: path.join(screenshotDir, 'gamestart-desktop.png'),
      fullPage: true,
    });
  });

  test('capture mobile screenshot', async ({ browser }) => {
    test.setTimeout(220_000);
    fs.mkdirSync(screenshotDir, { recursive: true });

    const context = await browser.newContext({
      ...devices['iPhone 13'],
      locale: 'en-US',
    });
    const page = await context.newPage();

    try {
      await launchGame(page);
      await page.screenshot({
        path: path.join(screenshotDir, 'gamestart-mobile.png'),
        fullPage: true,
      });
    } finally {
      await context.close().catch(() => {});
    }
  });
});
