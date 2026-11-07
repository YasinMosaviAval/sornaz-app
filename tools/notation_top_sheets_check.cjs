const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),web=process.argv.includes('--web-assets')?path.resolve(root,'../../../web/sornaz/assets/notation'):null;
const {chromium}=require(path.resolve(root,'../../../web/sornaz/storage/notation-browser-check/package'));
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 const page=await browser.newPage({hasTouch:true});const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route('http://notation.test/**',r=>{const name=new URL(r.request().url()).pathname,file=web&&name.startsWith('/assets/notation/')?path.resolve(web,name.slice(17)):path.resolve(root,'.'+name);return (file.startsWith(root+path.sep)||(web&&file.startsWith(web+path.sep)))&&fs.existsSync(file)?r.fulfill({path:file}):r.fulfill({status:404,body:''});});
 for(const locale of ['fa','en'])for(const width of [390,1280]){
  await page.setViewportSize({width,height:844});await page.goto('http://notation.test/test/notation_quarter_keyboard_test.html?locale='+locale);
  await page.waitForFunction(()=>document.body.dataset.result!=='pending');assert.equal(await page.locator('body').getAttribute('data-result'),'PASS');
  await page.evaluate(()=>Notation.configure({nativeToolbar:false}));await page.locator('[data-tool-sheet=voices]').click();await page.locator('.notation-tool-sheet:modal').waitFor();await page.locator('[data-action=voice][data-voice="2"]').click();assert.equal(await page.locator('[data-action=voice][data-voice="2"]').getAttribute('aria-pressed'),'true');await page.locator('[data-action=close-tool-sheet]').click();await page.waitForFunction(()=>document.querySelector('[data-tool-sheet=voices]')===document.activeElement);
  await page.locator('[data-tool-sheet=measure]').click();await page.locator('[data-control-key=time].notation-symbol-picker').click();await page.locator('[data-notation-option=manual]').click();await page.locator('[data-control-key=timeTop].notation-symbol-picker').click();await page.locator('[data-notation-option="19"]').click();assert.equal(await page.locator('[data-measure-choice=timeTop]').inputValue(),'19');assert.equal(await page.locator('[data-control-key=timeTop].notation-symbol-picker svg text').textContent(),'19');await page.keyboard.press('Escape');assert.equal(await page.locator('.notation-tool-sheet').count(),0);
  await page.evaluate(()=>Notation.command('metadata'));await page.locator('[data-control-key=scale_type].notation-symbol-picker').click();await page.locator('[data-notation-option=iran_shur]').click();
  await page.locator('.beat-picker summary').click();
  assert.ok(await page.locator('.beat-options button').evaluateAll(buttons=>buttons.every(button=>{const glyph=button.querySelector('svg').getBoundingClientRect(),dots=button.querySelector('.beat-dots').getBoundingClientRect(),box=button.getBoundingClientRect();return Math.abs(glyph.width-12)<.1&&Math.abs(glyph.height-17)<.1&&Math.abs((Math.min(glyph.left,dots.left)+Math.max(glyph.right,dots.right))/2-(box.left+box.right)/2)<1;})),'Beat glyphs and dots are half size and centered');
  await page.locator('.beat-picker summary').click();await page.locator('#metadata button.primary').click();await page.locator('.quarter-piano').waitFor();
  const layout=await page.locator('.score-title h2').evaluate(n=>{const r=n.getBoundingClientRect(),s=n.querySelector('.state').getBoundingClientRect();return {size:getComputedStyle(n).fontSize,center:(r.left+r.right)/2,status:(s.left+s.right)/2,viewport:innerWidth};});assert.equal(layout.size,'16px');assert.ok(Math.abs(layout.center-layout.status)<1,'Status is centered beneath title');
  await page.screenshot({path:path.resolve(root,'.dart_tool/notation-sheets-'+(web?'web-':'app-')+locale+'-'+width+'.png')});
  await page.locator('[data-tool-sheet=measure]').click();await page.screenshot({path:path.resolve(root,'.dart_tool/notation-measure-sheet-'+(web?'web-':'app-')+locale+'-'+width+'.png')});await page.locator('[data-action=close-tool-sheet]').click();
  console.log('Top sheets, real picks, automatic Iranian piano, centered half-size beats: '+locale+'/'+width+' passed');
 }
 assert.deepEqual(errors,[]);
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
