const { chromium } = require('@playwright/test');

const baseURL = 'http://localhost:7357';

async function enableFlutterSemantics(page) {
  const placeholder = page.locator('flt-semantics-placeholder').first();
  if (await placeholder.count()) {
    try {
      await placeholder.click({ force: true, timeout: 2000 });
    } catch {
      await page.evaluate(() => {
        const node = document.querySelector('flt-semantics-placeholder');
        if (node instanceof HTMLElement) {
          node.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
          node.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true }));
          node.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
        }
      });
    }
    await page.waitForTimeout(100);
  }
}

async function waitForTaggedButton(page, tag, timeoutMs = 60000) {
  const button = page.getByRole('button', { name: new RegExp(tag, 'i') }).first();
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    await enableFlutterSemantics(page);
    if (await button.count()) return button;
    await page.waitForTimeout(250);
  }
  return button;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1080 },
    baseURL,
  });
  const page = await context.newPage();

  // Navigate to home
  await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(3000);

  // Click "Create Room"
  const createRoomBtn = await waitForTaggedButton(page, 'e2e-home-create-room-button', 30000);
  await createRoomBtn.click();
  await page.waitForTimeout(3000);

  // Add a bot
  const addBotBtn = await waitForTaggedButton(page, 'e2e-lobby-add-bot', 15000);
  await addBotBtn.click();
  await page.waitForTimeout(2000);

  // Start game
  const startBtn = await waitForTaggedButton(page, 'e2e-lobby-start-game', 15000);
  await startBtn.click();
  await page.waitForTimeout(8000);

  // Click Rules tab
  const rulesBtn = page.getByRole('button', { name: /^Rules$/i }).first();
  await rulesBtn.waitFor({ state: 'visible', timeout: 15000 });
  await rulesBtn.click();
  await page.waitForTimeout(2000);

  // Take screenshot
  await page.screenshot({
    path: 'playwright/artifacts/rules-screenshot.png',
    fullPage: true,
  });

  console.log('Screenshot saved to playwright/artifacts/rules-screenshot.png');
  await browser.close();
})();
