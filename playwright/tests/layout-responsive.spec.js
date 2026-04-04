const { test, expect, devices } = require('@playwright/test');
const {
  addBotsInLobby,
  createRoomAndWaitLobby,
  openHome,
  startGameFromLobby,
  waitForActionTurn,
  waitForGameScreen,
  waitForTaggedSemanticNode,
} = require('./helpers/coup-e2e-helpers');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function buttonByExactName(page, label) {
  return page.getByRole('button', { name: new RegExp(`^${escapeRegex(label)}$`, 'i') }).first();
}

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

async function buttonCenter(page, label) {
  const button = buttonByExactName(page, label);
  await expect(button).toBeVisible({ timeout: 15_000 });
  const box = await button.boundingBox();
  expect(box, `Missing bounding box for "${label}"`).toBeTruthy();
  return {
    x: box.x + box.width / 2,
    y: box.y + box.height / 2,
  };
}

async function expectButtonsWithinViewport(page, labels) {
  const viewport = page.viewportSize();
  expect(viewport).toBeTruthy();

  const rowMarkers = new Set();
  for (const label of labels) {
    const button = buttonByExactName(page, label);
    await expect(button).toBeVisible({ timeout: 30_000 });
    const box = await button.boundingBox();
    expect(box, `Missing bounding box for button: ${label}`).toBeTruthy();

    expect(box.x, `Button ${label} is overflowing on the left`).toBeGreaterThanOrEqual(0);
    expect(
      box.x + box.width,
      `Button ${label} is overflowing on the right`,
    ).toBeLessThanOrEqual(viewport.width + 2);

    rowMarkers.add(Math.round(box.y / 8));
  }

  return rowMarkers.size;
}

test.describe('GameStart responsive layout', () => {
  test('desktop: uses rail nav and wide layout with clear tab content', async ({ page }, testInfo) => {
    test.setTimeout(180_000);

    await launchGame(page);

    await expect(buttonByExactName(page, 'Game')).toBeVisible({ timeout: 10_000 });
    await expect(buttonByExactName(page, 'History')).toBeVisible({ timeout: 10_000 });
    await expect(buttonByExactName(page, 'Rules')).toBeVisible({ timeout: 10_000 });
    await expect(buttonByExactName(page, 'Settings')).toBeVisible({ timeout: 10_000 });

    const gameCenter = await buttonCenter(page, 'Game');
    const historyCenter = await buttonCenter(page, 'History');
    expect(Math.abs(gameCenter.x - historyCenter.x)).toBeLessThan(40);
    expect(Math.abs(gameCenter.y - historyCenter.y)).toBeGreaterThan(50);

    await buttonByExactName(page, 'History').click();
    await expect(page.getByText(/^History$/i).first()).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText(/events/i).first()).toBeVisible({ timeout: 10_000 });

    await buttonByExactName(page, 'Rules').click();
    await expect(page.getByText(/^COUP Rules$/i).first()).toBeVisible({ timeout: 10_000 });

    await buttonByExactName(page, 'Settings').click();
    await expect(page.getByText(/^Game Settings$/i).first()).toBeVisible({ timeout: 10_000 });

    await buttonByExactName(page, 'Game').click();
    await waitForActionTurn(page, 60_000);
    await expect(buttonByExactName(page, 'Foreign Aid')).toBeVisible({ timeout: 15_000 });
    await expect(buttonByExactName(page, 'Aid')).toHaveCount(0);

    await page.screenshot({
      path: testInfo.outputPath('desktop-gamestart-layout.png'),
      fullPage: true,
    });
  });

  test('mobile: uses bottom nav and compact action grid without overflow', async ({ browser }, testInfo) => {
    test.setTimeout(220_000);

    const context = await browser.newContext({
      ...devices['iPhone 13'],
      locale: 'en-US',
    });
    const page = await context.newPage();

    try {
      await launchGame(page);

      await expect(buttonByExactName(page, 'Game')).toBeVisible({ timeout: 10_000 });
      await expect(buttonByExactName(page, 'History')).toBeVisible({ timeout: 10_000 });
      await expect(buttonByExactName(page, 'Rules')).toBeVisible({ timeout: 10_000 });
      await expect(buttonByExactName(page, 'Settings')).toBeVisible({ timeout: 10_000 });

      const gameCenter = await buttonCenter(page, 'Game');
      const historyCenter = await buttonCenter(page, 'History');
      const viewport = page.viewportSize();
      expect(viewport).toBeTruthy();
      expect(Math.abs(gameCenter.y - historyCenter.y)).toBeLessThan(30);
      expect(Math.abs(gameCenter.x - historyCenter.x)).toBeGreaterThan(45);
      expect(gameCenter.y).toBeGreaterThan(viewport.height * 0.75);
      expect(historyCenter.y).toBeGreaterThan(viewport.height * 0.75);

      await expect(page.getByText(/^ROOM /i).first()).toBeVisible({ timeout: 10_000 });
      await expect(
        page.getByText(/ACTION|CHALLENGE|BLOCK|RESOLVING|FINISHED/i).first(),
      ).toBeVisible({ timeout: 10_000 });

      await buttonByExactName(page, 'Game').click();
      await waitForActionTurn(page, 60_000);

      const compactActionLabels = ['Income', 'Aid', 'Tax', 'Steal', 'Swap', 'Assassin', 'Coup'];
      const actionRows = await expectButtonsWithinViewport(page, compactActionLabels);
      expect(actionRows).toBeGreaterThan(1);

      await buttonByExactName(page, 'History').click();
      await expect(page.getByText(/^History$/i).first()).toBeVisible({ timeout: 10_000 });
      await expect(page.getByText(/events/i).first()).toBeVisible({ timeout: 10_000 });

      await buttonByExactName(page, 'Rules').click();
      await expect(page.getByText(/^COUP Rules$/i).first()).toBeVisible({ timeout: 10_000 });

      await buttonByExactName(page, 'Settings').click();
      await expect(page.getByText(/^Game Settings$/i).first()).toBeVisible({ timeout: 10_000 });

      await buttonByExactName(page, 'Game').click();
      await page.screenshot({
        path: testInfo.outputPath('mobile-gamestart-layout.png'),
        fullPage: true,
      });
    } finally {
      await context.close().catch(() => {});
    }
  });
});
