import { chromium } from 'playwright';

const baseUrl = process.env.BROKER_BASE_URL || 'http://127.0.0.1:8000';
const browser = await chromium.launch({ headless: true });
const pageErrors = [];

try {
  const context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  page.setDefaultTimeout(20000);
  page.on('pageerror', error => pageErrors.push(error.message));

  const email = 'browser-' + Date.now() + '@example.test';
  await page.goto(baseUrl + '/register', { waitUntil: 'networkidle' });
  await page.locator('input[name="name"]').fill('Browser Smoke Trader');
  await page.locator('input[name="email"]').fill(email);
  await page.locator('input[name="password"]').fill('browser-smoke-password-2026');
  await page.locator('input[name="password_confirmation"]').fill('browser-smoke-password-2026');
  await page.locator('form button[type="submit"]').click();
  await page.waitForURL(url => url.pathname === '/dashboard');
  await page.waitForFunction(() =>
    Boolean(window.API) && Boolean(document.querySelector('#total')?.textContent.trim())
  );

  if (!(await page.locator('#chart').isVisible())) {
    throw new Error('Dashboard chart did not become visible on desktop.');
  }
  if (!(await page.locator('.demobar').innerText()).includes('Demo mode')) {
    throw new Error('The dashboard is missing its demo-only notice.');
  }

  // Exercise the browser adapter's CSRF/session path and demo wallet accounting.
  await page.locator('#mmBtn').click();
  await page.locator('#mmMenu button[data-a="Deposit"]').click();
  await page.locator('#moneyAmt').fill('250');
  await page.locator('#moneyOk').click();
  await page.locator('#money').waitFor({ state: 'hidden' });

  await page.waitForFunction(async () => {
    const response = await fetch('/api/broker/state', { headers: { Accept: 'application/json' } });
    if (!response.ok) return false;
    const state = await response.json();
    const usd = (state.wallets || []).find(wallet => wallet.symbol === 'USD');
    return Number(usd?.balance || 0) >= 249.999;
  });

  await page.locator('#tAsset').selectOption('BTC');
  await page.locator('#tAmt').fill('100');
  await page.locator('#go').click();

  await page.waitForFunction(async () => {
    const response = await fetch('/api/broker/state', { headers: { Accept: 'application/json' } });
    if (!response.ok) return false;
    const state = await response.json();
    const btc = (state.wallets || []).find(wallet => wallet.symbol === 'BTC');
    const usd = (state.wallets || []).find(wallet => wallet.symbol === 'USD');
    return Number(btc?.balance || 0) > 0 && Number(usd?.balance || 0) < 151;
  });

  // Check common phone widths for horizontal overflow after real data is rendered.
  for (const width of [390, 360]) {
    await page.setViewportSize({ width, height: 844 });
    await page.waitForTimeout(250);
    const dimensions = await page.evaluate(() => ({
      viewport: window.innerWidth,
      document: document.documentElement.scrollWidth,
      body: document.body.scrollWidth,
    }));
    if (dimensions.document > dimensions.viewport + 1 || dimensions.body > dimensions.viewport + 1) {
      throw new Error('Horizontal overflow at ' + width + 'px: ' + JSON.stringify(dimensions));
    }
  }

  // Confirm the account menu can end the web session from the dashboard.
  await page.locator('#acctBtn').click();
  await page.locator('#mOut').click();
  await page.waitForURL(url => url.pathname === '/login');

  if (pageErrors.length) {
    throw new Error('Browser JavaScript errors: ' + pageErrors.join(' | '));
  }

  console.log('PASS: desktop dashboard, chart, demo deposit, server-priced BTC buy, 390px/360px layouts, and logout.');
} finally {
  await browser.close();
}
