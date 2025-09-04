import { test, expect } from '@playwright/test';

const QUERY = 'OpenShift Playwright';

test('google search shows results', async ({ page }) => {
  await page.goto('https://www.google.com/ncr');

  // Accept consent if dialog appears
  const acceptBtn = page.locator('button:has-text("I agree"), button:has-text("Accept all"), div[role="none"] >> text=Accept all');
  if (await acceptBtn.first().isVisible().catch(() => false)) {
    await acceptBtn.first().click({ timeout: 5000 }).catch(() => {});
  }

  await page.getByRole('combobox', { name: /search/i }).fill(QUERY);
  await page.getByRole('combobox', { name: /search/i }).press('Enter');

  // If Google rate-limits ("sorry" page), skip gracefully
  await page.waitForLoadState('domcontentloaded');
  if (page.url().includes('/sorry/')) {
    test.skip(true, 'Google rate-limited this cluster IP (sorry page). Skipping test.');
  }

  // Validate there is at least one result
  const results = page.locator('#search a h3');
  await expect(results.first()).toBeVisible();

  // Softly check title contains query
  await expect.soft(page).toHaveTitle(new RegExp(QUERY, 'i'));
}); 