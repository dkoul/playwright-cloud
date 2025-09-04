import { test, expect } from '@playwright/test';

const ARTICLE_URL = 'https://medium.com/@begunova/fine-tune-browser-context-automation-with-webdriver-bidi-7c38b49b2588';

test('read medium article about webdriver bidi', async ({ page }) => {
  await page.goto(ARTICLE_URL);

  // Wait for basic DOM load
  await page.waitForLoadState('domcontentloaded');

  // Get the article title
  const title = await page.locator('h1').first().textContent();
  console.log('Article Title:', title);

  // Extract all visible text content from the article area
  const articleBody = page.locator('article, .postArticle-content, [data-testid="storyContent"]').first();
  const allText = await articleBody.textContent();
  
  if (allText) {
    console.log('\n=== ARTICLE CONTENT ===\n');
    // Split into paragraphs and clean up
    const paragraphs = allText.split('\n').filter(p => p.trim().length > 20);
    paragraphs.forEach((paragraph, index) => {
      console.log(`${index + 1}. ${paragraph.trim()}\n`);
    });
  }

  // Try to get individual paragraphs as fallback
  const paragraphElements = page.locator('p').filter({ hasText: /webdriver|bidi|browser|automation/i });
  const paragraphCount = await paragraphElements.count();
  
  if (paragraphCount > 0) {
    console.log('\n=== KEY PARAGRAPHS ===\n');
    for (let i = 0; i < Math.min(paragraphCount, 5); i++) {
      const text = await paragraphElements.nth(i).textContent();
      if (text && text.length > 30) {
        console.log(`${i + 1}. ${text.trim()}\n`);
      }
    }
  }

  // Basic assertions
  expect(title).toBeTruthy();
  expect(title).toContain('WebDriver BiDi');
}); 