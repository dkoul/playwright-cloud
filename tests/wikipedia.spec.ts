import { test, expect } from '@playwright/test';

const QUERY = 'Playwright';

test('wikipedia search shows article results', async ({ page }) => {
  await page.goto('https://www.wikipedia.org/');

  await page.locator('input#searchInput').fill(QUERY);
  await page.locator('input#searchInput').press('Enter');

  // Expect the first heading to contain the query or navigate to a result page
  const heading = page.locator('#firstHeading');
  await expect(heading).toBeVisible();
  await expect(heading).toContainText(/playwright/i);
}); 