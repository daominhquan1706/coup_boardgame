const { test, expect, chromium } = require('@playwright/test');

test('screenshot rules page from existing Chrome', async ({}, testInfo) => {
  test.setTimeout(60_000);

  // Try to connect to existing Chrome instance
  let browser;
  try {
    browser = await chromium.connectOverCDP('http://localhost:9222');
    console.log('Connected to existing Chrome instance');
  } catch (e) {
    console.log('Could not connect to existing Chrome, launching new one');
    browser = await chromium.launch({
      headless: false,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--remote-debugging-port=9222'],
    });
  }
  
  const contexts = browser.contexts();
  const context = contexts[0] || await browser.newContext();
  const pages = context.pages();
  const page = pages[0] || await context.newPage();

  // Navigate to the game
  await page.goto('http://localhost:57230/', {
    waitUntil: 'domcontentloaded',
    timeout: 30000,
  });

  // Wait for Flutter to render
  await page.waitForTimeout(5000);

  // Take screenshot of current page
  await page.screenshot({
    path: testInfo.outputPath('current-page.png'),
    fullPage: true,
  });

  console.log('Screenshot saved to:', testInfo.outputPath('current-page.png'));
  
  // Don't close browser if connected to existing instance
  if (!contexts[0]) {
    await browser.close();
  }
});
