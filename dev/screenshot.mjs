// Flutter Web ビルドのスクリーンショットを撮るツール。
//
// 前提: `flutter build web` 済みの build/web を任意の静的サーバ（既定 http://localhost:8080）で配信しておくこと。
// 使い方: node dev/screenshot.mjs [baseUrl]
//   例) node dev/screenshot.mjs http://localhost:8080
//
// go_router はハッシュURL戦略のため、各画面へは <base>/#/<path> で遷移する。
// 出力先: dev/shots/<name>.png

import puppeteer from 'puppeteer-core';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, 'shots');

const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BASE = process.argv[2] ?? 'http://localhost:8080';

// 撮影対象の画面（go_router のパス）
const SCREENS = [
  { name: 'tasks', route: '/tasks' },
  { name: 'mytasks', route: '/mytasks' },
  { name: 'stats', route: '/stats' },
  { name: 'character', route: '/character' },
  { name: 'settings', route: '/settings' },
];

const VIEWPORT = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Flutter（CanvasKit）の初回描画完了を待つ。
async function waitForFlutter(page, firstLoad) {
  await page.waitForSelector('flutter-view', { timeout: 30000 });
  // flutter-view が実サイズを持つまで待つ
  await page.waitForFunction(() => {
    const f = document.querySelector('flutter-view');
    if (!f) return false;
    const r = f.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  }, { timeout: 30000 });
  // 初回はエンジン初期化＋フォントフォールバック取得に時間がかかる
  await sleep(firstLoad ? 7000 : 1500);
}

async function main() {
  await mkdir(OUT_DIR, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: true,
    defaultViewport: VIEWPORT,
    args: ['--force-color-profile=srgb'],
  });
  try {
    const page = await browser.newPage();
    let first = true;
    for (const s of SCREENS) {
      const url = `${BASE}/#${s.route}`;
      await page.goto(url, { waitUntil: 'load' });
      await waitForFlutter(page, first);
      first = false;
      const path = join(OUT_DIR, `${s.name}.png`);
      await page.screenshot({ path });
      console.log(`saved: ${path}`);
    }
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
