// 実Firebase接続の起動検証ツール。
// onboarding を読み込み、コンソールのエラー/警告を収集してスクショを撮る。
// Firebase 初期化に失敗していれば画面が出ない or エラーが出る。
import puppeteer from 'puppeteer-core';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, 'shots');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BASE = process.argv[2] ?? 'http://localhost:8080';
const VIEWPORT = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  await mkdir(OUT_DIR, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: CHROME, headless: true, defaultViewport: VIEWPORT,
    args: ['--force-color-profile=srgb'],
  });
  const logs = [];
  try {
    const page = await browser.newPage();
    page.on('console', (m) => logs.push(`[${m.type()}] ${m.text()}`));
    page.on('pageerror', (e) => logs.push(`[pageerror] ${e.message}`));
    await page.goto(`${BASE}/#/onboarding`, { waitUntil: 'load' });
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    await page.waitForFunction(() => {
      const f = document.querySelector('flutter-view');
      if (!f) return false;
      const r = f.getBoundingClientRect();
      return r.width > 0 && r.height > 0;
    }, { timeout: 30000 });
    await sleep(8000); // Firebase init + 描画
    await page.screenshot({ path: join(OUT_DIR, 'boot-onboarding.png') });
    console.log('saved: dev/shots/boot-onboarding.png');
  } finally {
    await browser.close();
  }
  console.log('=== CONSOLE LOGS ===');
  const interesting = logs.filter((l) =>
    /error|warn|firebase|firestore|permission|exception|denied/i.test(l));
  console.log(interesting.length ? interesting.join('\n') : '(関心ログなし)');
}
main().catch((e) => { console.error(e); process.exit(1); });
