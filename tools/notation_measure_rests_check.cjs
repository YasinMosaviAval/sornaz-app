const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),web=process.argv.includes('--web-assets')?path.resolve(root,'../../../web/sornaz/assets/notation'):null;
const {chromium}=require(path.resolve(root,'../../../web/sornaz/storage/notation-browser-check/package'));
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 const page=await browser.newPage();await page.route('http://notation.test/**',r=>{const name=new URL(r.request().url()).pathname,file=web&&name.startsWith('/assets/notation/')?path.resolve(web,name.slice(17)):path.resolve(root,'.'+name);return (file.startsWith(root+path.sep)||(web&&file.startsWith(web+path.sep)))&&fs.existsSync(file)?r.fulfill({path:file}):r.fulfill({status:404,body:''});});
 for(const width of [1280,390]){await page.setViewportSize({width,height:900});await page.goto('http://notation.test/test/notation_measure_rests_test.html');assert.equal(await page.locator('body').getAttribute('data-result'),'PASS');await page.screenshot({path:path.resolve(root,'.dart_tool/measure-rests-'+(web?'web':'app')+'-'+width+'.png'),fullPage:true});console.log('Rests, exact voices, compact repeats and print layout: '+width+' passed');}
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
