import { defineConfig, devices } from '@playwright/test';

const wsEndpoint = process.env.PW_TEST_CONNECT_WS_ENDPOINT || process.env.PW_WS_ENDPOINT;

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  expect: { timeout: 10_000 },
  use: {
    // Connect to remote Playwright server if provided
    connectOptions: wsEndpoint ? { wsEndpoint } : undefined,
    // Base settings
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
}); 