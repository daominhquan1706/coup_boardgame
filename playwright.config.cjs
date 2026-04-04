const { defineConfig, devices } = require('@playwright/test');

const port = Number(process.env.PORT || 7357);
const baseURL =
  process.env.PLAYWRIGHT_BASE_URL || `http://127.0.0.1:${port}`;
const flutterRunner = process.env.PLAYWRIGHT_FLUTTER_BIN || 'fvm flutter';

module.exports = defineConfig({
  testDir: './playwright/tests',
  fullyParallel: false,
  workers: 1,
  timeout: 60 * 1000,
  expect: {
    timeout: 15 * 1000,
  },
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL,
    locale: 'en-US',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    viewport: { width: 1440, height: 1080 },
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
  ],
  webServer: process.env.PLAYWRIGHT_BASE_URL
      ? undefined
      : {
          command: [
            `${flutterRunner} run`,
            '-d web-server',
            '--web-hostname 127.0.0.1',
            `--web-port ${port}`,
            '--dart-define=ENABLE_E2E_TAGS=true',
          ].join(' '),
          url: baseURL,
          reuseExistingServer: !process.env.CI,
          timeout: 4 * 60 * 1000,
          stdout: 'pipe',
          stderr: 'pipe',
        },
});
