const { chromium } = require('playwright');

(async () => {
  const base = process.env.HTTP_BASE || process.env.PUBLIC_URL || 'https://workspaces.adeptengr.com';
  const outDir = process.env.OUT_DIR || '/out';
  const errors = [];

  const browser = await chromium.launch({
    channel: undefined,
    executablePath: '/ms-playwright/chromium-1148/chrome-linux/chrome',
    args: ['--no-sandbox'],
  });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));

  await page.goto(base + '/#/login', { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(3000);

  const title = await page.title();
  if (!title.includes('Adept Engineering Solutions')) errors.push('title=' + JSON.stringify(title));

  if (!(await page.$('link[href*="/branding/adept.css"]'))) errors.push('missing adept.css');
  if (!(await page.$('script[src*="/branding/adept.js"]'))) errors.push('missing adept.js');

  await page.waitForSelector('.login-card-top, [class*="login-card-top"]', { timeout: 30000 }).catch(() => {
    errors.push('login form did not render (stuck on spinner)');
  });

  const bodyText = (await page.textContent('body')) || '';
  const companyEl = await page.$('.adept-company-name');
  if (!companyEl) errors.push('company name element missing');
  else {
    const companyText = await companyEl.textContent();
    if (!companyText || !companyText.includes('Adept Engineering Solutions')) {
      errors.push('company name text wrong: ' + JSON.stringify(companyText));
    }
  }

  if (!bodyText.includes('Secure virtual workspaces for teams')) errors.push('tagline not in DOM');
  if (bodyText.includes('Container Streaming Platform')) errors.push('default tagline visible');
  if (/Powered by Kasm Workspaces/i.test(bodyText)) errors.push('powered-by visible');

  const loginHeading = await page.textContent('h1');
  if (!loginHeading || !/login/i.test(loginHeading)) errors.push('h1=' + JSON.stringify(loginHeading));

  if (!(await page.$('img[src*="logo"]'))) errors.push('logo img missing');

  const splashBg = await page.evaluate(() => {
    const panels = Array.from(document.querySelectorAll('.login_box, [class*="login_box"]'));
    for (const panel of panels) {
      const bg = getComputedStyle(panel).backgroundImage || '';
      if (bg && bg !== 'none') return bg;
    }
    return 'none';
  });
  const hasAdeptSplash =
    splashBg.includes('login-splash') ||
    splashBg.includes('branding') ||
    bodyText.includes('Secure virtual workspaces for teams');
  if (!hasAdeptSplash) errors.push('splash/branding not detected; bg=' + splashBg.slice(0, 120));

  const ls = await page.evaluate(() => ({
    login_caption: localStorage.getItem('login_caption'),
    login_splash_background: localStorage.getItem('login_splash_background'),
  }));
  if (ls.login_caption !== 'Secure virtual workspaces for teams') {
    errors.push('localStorage caption=' + JSON.stringify(ls.login_caption));
  }

  await page.screenshot({ path: outDir + '/login.png', fullPage: true });
  await browser.close();

  if (errors.length) {
    console.error('BROWSER FAIL');
    errors.forEach((e) => console.error(' -', e));
    process.exit(1);
  }
  console.log('BROWSER PASS');
})();
