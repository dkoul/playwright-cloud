import { test, expect } from '@playwright/test';

const QUERY = 'OpenShift Playwright';

// Uses the HTML (lite) endpoint for stable markup
// Results anchor selector: #links .result__a
// Search box: input[name="q"]

test('duckduckgo html search shows results', async ({ page }) => {
  await page.goto('https://duckduckgo.com/html/');

  await page.locator('input[name="q"]').fill(QUERY);
  await page.locator('input[name="q"]').press('Enter');

  const firstResult = page.locator('#links .result__a').first();
  await expect(firstResult).toBeVisible();

  await expect(page).toHaveURL(/duckduckgo\.com\/html\/\?q=/);
}); 