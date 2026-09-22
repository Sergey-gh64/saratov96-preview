import puppeteer from 'puppeteer-core';
import fs from 'node:fs';
import crypto from 'node:crypto';

const baseUrl = process.env.S96_BASE_URL || 'http://127.0.0.1:4173/';
const outDir = process.env.S96_QA_DIR || 'browser-qa';
fs.mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({
  executablePath: '/usr/bin/google-chrome',
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-dev-shm-usage',
    '--enable-unsafe-swiftshader',
    '--ignore-gpu-blocklist',
  ],
});

const failures = [];
const diagnostics = [];

function check(condition, message) {
  if (!condition) failures.push(message);
}

function digest(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

async function waitForBoot(page) {
  await page.waitForFunction(() => {
    const status = document.getElementById('status');
    return !status || !document.body.contains(status);
  }, { timeout: 90000 });
  await new Promise(resolve => setTimeout(resolve, 700));
}

async function capture(page, name) {
  return await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: true });
}

try {
  const page = await browser.newPage();
  await page.setViewport({
    width: 390,
    height: 844,
    deviceScaleFactor: 1,
    isMobile: true,
    hasTouch: true,
  });

  page.on('pageerror', error => failures.push(`pageerror: ${error.message}`));
  page.on('requestfailed', request => {
    failures.push(`requestfailed: ${request.url()} ${request.failure()?.errorText || ''}`);
  });
  page.on('console', message => diagnostics.push(`console ${message.type()}: ${message.text()}`));

  await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 90000 });
  await waitForBoot(page);

  const shell = await page.evaluate(() => {
    const canvas = document.getElementById('canvas');
    const rect = canvas?.getBoundingClientRect();
    const marker = document.querySelector('meta[name="s96-build"]')?.getAttribute('content') || null;
    return {
      marker,
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      scrollWidth: document.documentElement.scrollWidth,
      scrollHeight: document.documentElement.scrollHeight,
      canvasWidth: canvas?.width || null,
      canvasHeight: canvas?.height || null,
      canvasClientWidth: rect?.width || null,
      canvasClientHeight: rect?.height || null,
      overflow: getComputedStyle(document.body).overflow,
      touchAction: canvas ? getComputedStyle(canvas).touchAction : null,
    };
  });
  fs.writeFileSync(`${outDir}/shell.json`, JSON.stringify(shell, null, 2));

  check(!!shell.marker, 'build marker is visible in HTML');
  check(shell.innerWidth === 390, 'mobile viewport width is 390 CSS px');
  check(shell.scrollWidth <= shell.innerWidth + 1, 'page has no horizontal scroll');
  check(shell.scrollHeight <= shell.innerHeight + 1, 'page has no vertical scroll');
  check(shell.overflow === 'hidden', 'body overflow is hidden');
  check(shell.touchAction === 'none', 'canvas disables browser touch gestures');
  check((shell.canvasClientWidth || 0) > 300, 'canvas occupies mobile viewport width');
  check((shell.canvasClientHeight || 0) > 600, 'canvas occupies mobile viewport height');

  const selectPng = await capture(page, 'level-select');

  await page.touchscreen.tap(195, 292);
  await new Promise(resolve => setTimeout(resolve, 800));
  const level1Png = await capture(page, 'level1');
  check(digest(level1Png) !== digest(selectPng), 'touch on Level 1 changes rendered scene');

  const beforeMove = level1Png;
  await page.touchscreen.tap(145, 655);
  await new Promise(resolve => setTimeout(resolve, 500));
  const afterMove = await capture(page, 'level1-after-touch-move');
  check(digest(afterMove) !== digest(beforeMove), 'touch on reachable Level 1 node changes world state');

  await page.reload({ waitUntil: 'domcontentloaded', timeout: 90000 });
  await waitForBoot(page);
  const selectAgain = await capture(page, 'level-select-reload');
  await page.touchscreen.tap(195, 412);
  await new Promise(resolve => setTimeout(resolve, 800));
  const level2Png = await capture(page, 'level2');
  check(digest(level2Png) !== digest(selectAgain), 'touch on Level 2 changes rendered scene');

  fs.writeFileSync(`${outDir}/browser.log`, diagnostics.join('\n'));

  if (failures.length) {
    for (const failure of failures) console.error(`S96_BROWSER_FAIL: ${failure}`);
    process.exitCode = 1;
  } else {
    console.log('S96_BROWSER_OK=1');
  }
} finally {
  await browser.close();
}
