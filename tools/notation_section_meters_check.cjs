const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {chromium}=require(path.resolve(__dirname,'../../../../web/sornaz/storage/notation-browser-check/package'));
const native=!process.argv.includes('--web-assets');
const assets=native?path.resolve(__dirname,'../assets/notation'):path.resolve(__dirname,'../../../../web/sornaz/assets/notation');
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true});try{
 for(const locale of ['fa','en'])for(const width of [390,1280]){
  const page=await browser.newPage({viewport:{width,height:900}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.addInitScript(({locale,native,dark})=>{
   window.NOTATION_BOOT={locale,userId:7,embedded:true,nativePiano:native,nativeToolbar:native,durationMode:2,dark,showHelp:false};
   window.SornazNotation={postMessage(raw){const d=JSON.parse(raw);if(d.action==='route'){window.lastRoute=d;window.piano=d.piano;return;}queueMicrotask(()=>{
    let data=true;if(d.action==='list')data={items:window.savedSheet?[{...window.savedSheet,title:window.savedSheet.metadata.title}]:[],has_more:false};
    if(d.action==='instruments')data=[{id:42,fa:'تار',en:'Tar'}];
    if(d.action==='save'){window.savedPayload=d.payload;data=window.savedSheet={...d.payload,id:91,version:1,editable:true};}
    if(d.action==='get')data=window.savedSheet;
    if(d.action==='export')window.exported=JSON.parse(d.content);
    window.Notation.receive(d.id,data,null);
   });}};
  },{locale,native,dark:width===1280});
  await page.route('http://notation.test/**',route=>{const pathname=new URL(route.request().url()).pathname,file=path.resolve(assets,'.'+(pathname==='/'?'/index.html':pathname));return file.startsWith(assets+path.sep)&&fs.existsSync(file)?route.fulfill({path:file}):route.fulfill({status:404,body:''});});
  await page.goto('http://notation.test/');await page.locator('[data-action=new]').click();
  const chooseMeter=async value=>{
   assert.equal(await page.locator('#metadata [name=time] option[value=""]').count(),0,'metadata must not offer an inherit/no-change value');
   await page.locator('#metadata .notation-symbol-picker[data-control-key=time]').click();
   assert.equal(await page.locator('.notation-form-options[data-control-key=time] [data-notation-option=""]').count(),0,'visible picker must omit no-change');
   await page.locator('.notation-form-options[data-control-key=time] [data-notation-option="'+value+'"]').click();
  };
  const submit=async()=>{await page.locator('#metadata button[type=submit]').click();await page.locator('#score svg').first().waitFor();};
  const enter=async(pitch,seconds)=>{
   if(native)await page.evaluate(pitch=>{Notation.pianoPointer({phase:'down',pitch,accidental:''});Notation.pianoPointer({phase:'up',pitch,accidental:''});},pitch);
   else await page.locator('.white[data-pitch='+pitch+']').evaluate(n=>n.click());
   if(seconds!==undefined){await page.locator('[data-duration-seconds]').fill(String(seconds));await page.locator('.free-duration-picker button[type=submit]').click();}
   else await page.locator('.note-duration-picker [data-duration=q][data-dots="0"]').click();
  };
  await page.locator('[name=title]').fill('Mixed piece');await page.locator('[name=instrument]').selectOption('42');await page.locator('[name=scale_type]').selectOption('major');
  await chooseMeter('4/4');await page.locator('[name=tempo_unit]').selectOption('q:0');await page.locator('[name=bpm]').fill('100');await submit();await enter('C4');
  await page.evaluate(()=>Notation.command('add-subsection'));await page.evaluate(()=>Notation.command('metadata'));await page.locator('#metadata').waitFor();
  await chooseMeter('free');await submit();
  await page.evaluate(()=>Notation.command('undo'));assert.equal(await page.locator('.editor-footer [data-action=edit-seconds]').count(),0);
  await page.evaluate(()=>Notation.command('redo'));assert.equal(await page.locator('.editor-footer [data-action=edit-seconds]').count(),1);
  await enter('D4',.25);
  await page.evaluate(()=>Notation.command('add-section'));await page.evaluate(()=>Notation.command('metadata'));await page.locator('#metadata').waitFor();
  await chooseMeter('3/4');await submit();await enter('E4');
  await page.evaluate(()=>Notation.command('save'));await page.locator('dialog [data-action=yes]').click();await page.waitForFunction(()=>!!window.savedPayload);
  const saved=await page.evaluate(()=>window.savedPayload);
  assert.equal(saved.metadata.time,'4/4');assert.equal(saved.score.time,undefined,'redundant root meter must be omitted');assert.equal(saved.score.subsections[0].time,'free');assert.equal(saved.score.sections[0].time,'3/4');
  assert.equal(saved.score.subsections[0].measures[0].notes[0].durationSeconds,.25);assert.equal(saved.notation_section_meters,true);
  await page.locator('[data-action=structure-breadcrumb][data-depth="1"]').click();
  assert.equal(await page.locator('#score .note-hit[data-note]').count(),3,'full piece must draw all mixed sections');
  const result=await page.evaluate(()=>{
   const source=NotationModel.clone(window.savedPayload),joined=NotationModel.joinSections(source),times=[],original=Vex.Flow.Stave.prototype.addTimeSignature;
   Vex.Flow.Stave.prototype.addTimeSignature=function(value,...args){times.push(value);return original.call(this,value,...args);};
   let printed;try{printed=NotationRenderer.printDocument(source,document.documentElement.lang);}finally{Vex.Flow.Stave.prototype.addTimeSignature=original;}
   const ensemble=NotationModel.clone(source);ensemble.score.parts=[{metadata:{...source.metadata,instrument:'Violin'},score:{time:'3/4',measures:[{notes:[{pitch:'G4',duration:'q',rest:false}]}]}}];
   const host=document.createElement('div');host.style.width='800px';document.body.append(host);let labels;
   try{NotationRenderer.drawEnsemble(host,NotationModel.parts(ensemble),{});labels=[...host.querySelectorAll('.notation-ensemble-label')].map(n=>n.textContent);NotationRenderer.updatePlayback(host,NotationModel.ensembleTimeline(ensemble).events,'#0065ff');}finally{host.remove();}
   return {duration:NotationModel.ensembleTimeline(source).duration,times,labels,seconds:printed.includes('0.25 s'),invalid:printed.includes('NaN'),meters:joined.score.measures.map((_,i)=>NotationModel.effectiveTime(joined,i))};
  });
  assert.deepEqual(result.meters,['4/4','free','3/4']);assert.ok(Math.abs(result.duration-4.45)<1e-10);assert.deepEqual(result.times,['4/4','3/4']);assert.equal(result.seconds,true);assert.equal(result.invalid,false);
  assert.deepEqual(result.labels,['42 1','Violin 2']);
  await page.evaluate(()=>Notation.command('back'));await page.locator('[data-action=open][data-id="91"]').click();await page.locator('#score svg').first().waitFor();
  await page.evaluate(()=>Notation.command('export'));await page.waitForFunction(()=>!!window.exported);
  assert.equal(await page.evaluate(()=>window.exported.score.subsections[0].time),'free');assert.equal(await page.evaluate(()=>window.exported.score.sections[0].time),'3/4');
  assert.deepEqual(errors,[]);await page.close();console.log(`${native?'App':'Web'} mixed meters ${locale}/${width}: real pickers, 4/4 + free + 3/4, save/reopen, full playback and PDF passed.`);
 }
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
