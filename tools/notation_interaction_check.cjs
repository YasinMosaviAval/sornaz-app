const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const webAssets = process.argv.includes('--web-assets') ? path.resolve(root, '../../../web/sornaz/assets/notation') : null;
const {chromium} = require(process.env.PLAYWRIGHT_CORE_PATH || path.resolve(root, '../../../web/sornaz/storage/notation-browser-check/package'));
(async () => {
  const browser = await chromium.launch({channel: 'msedge', headless: true});
  try {
    const page = await browser.newPage({viewport: {width: 390, height: 844}, hasTouch: true});
    await page.route('http://notation.test/**', route => {
      const pathname = new URL(route.request().url()).pathname;
      const file = webAssets && pathname.startsWith('/assets/notation/') ? path.resolve(webAssets, pathname.slice('/assets/notation/'.length)) : path.resolve(root, '.' + pathname);
      return (file.startsWith(root + path.sep) || (webAssets && file.startsWith(webAssets + path.sep))) && fs.existsSync(file)
        ? route.fulfill({path: file}) : route.fulfill({status: 404, body: ''});
    });
    for (const file of ['notation_measure_rests_test', 'notation_duration_dialog_test', 'notation_vertical_spacing_test', 'notation_native_piano_test', 'notation_quarter_keyboard_test', 'notation_tempo_dots_test', 'notation_compact_form_test', 'notation_iranian_signatures_test', 'notation_iranian_choices_test', 'notation_interaction_revision_test', 'notation_symbol_controls_test', 'notation_rest_picker_test', 'notation_timing_test', 'notation_toolbar_test', 'notation_grand_staff_ui_test']) {
      for (const locale of ['fa', 'en']) {
        await page.goto(`http://notation.test/test/${file}.html?locale=${locale}`);
        await page.waitForFunction(() => document.body.dataset.result !== 'pending', {}, {timeout: 20000});
        const result = await page.locator('body').getAttribute('data-result');
        assert.ok(['PASS', 'passed'].includes(result), `${file} ${locale}: ${result}`);
        console.log(`${file} ${locale}: passed`);
      }
    }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
