/* Responsive screen engraving and independent A4 pagination. No network fonts. */
(function(root){
'use strict';
const VF=Vex.Flow,M=NotationModel;
const escape=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const estimate=bar=>Math.max(90,bar.notes.length*18+55);
function groups(measures,width,printing){
 const result=[];
 if(printing){
  const density=Math.max(0,...measures.map(b=>b.notes.length));
  const count=density>12?5:density>6?6:8;
  for(let i=0;i<measures.length;i+=count)result.push(measures.slice(i,i+count));
 }else{
  let row=[],used=70;
  for(const bar of measures){if(row.length&&(used+estimate(bar)>width||row.length===4)){result.push(row);row=[];used=70;}row.push(bar);used+=estimate(bar);}
  if(row.length)result.push(row);
 }
 return result;
}
function renderRow(target,bars,start,options){
 const m=options.metadata,width=Math.max(options.width,bars.reduce((v,b)=>v+estimate(b),70)),height=120;
 const renderer=new VF.Renderer(target,VF.Renderer.Backends.SVG);renderer.resize(width,height);
 const ctx=renderer.getContext(),engraved=[];
 const svg=target.querySelector('svg');svg.setAttribute('viewBox',`0 0 ${width} ${height}`);svg.setAttribute('width','100%');svg.setAttribute('height',String(options.printing?86:height*options.pixels/width));
 svg.style.display='block';svg.style.maxWidth='100%';
 const barWidth=(width-8)/bars.length;
 bars.forEach((bar,col)=>{
  const index=start+col,x=4+col*barWidth,y=6;
  if(!options.printing&&index===options.activeBar){ctx.save();ctx.setFillStyle(options.accent+'14');ctx.fillRect(x,y+15,barWidth,94);ctx.restore();}
  const stave=new VF.Stave(x,y,barWidth);
  if(col===0){stave.addClef(m.clef);stave.addKeySignature(m.key);if(index===0)stave.addTimeSignature(m.time);
   else{ctx.save();ctx.setFillStyle('#666');ctx.setFont('Arial',5.5);ctx.fillText(String(index+1),x+9,y+29);ctx.restore();}}
  if(index===options.lastWritten)stave.setEndBarType(VF.Barline.type.END);
  stave.setContext(ctx).draw();
  const source=bar.notes.map(n=>({...n}));
  if(!options.printing&&index===options.ghostBar&&options.ghost)source.push({...options.ghost,ghost:true,rest:false});
  const notes=source.map((n,i)=>{
   const v=new VF.StaveNote({clef:m.clef,keys:[n.rest?'b/4':n.pitch[0].toLowerCase()+'/'+n.pitch.slice(1)],duration:n.duration+(n.rest?'r':''),dots:n.dots||0,auto_stem:true});
   if(!n.rest)v.setStemDirection(v.getKeyProps()[0].line<=3?VF.Stem.UP:VF.Stem.DOWN);
   if(n.accidental&&!n.rest)v.addModifier(new VF.Accidental(n.accidental),0);
   for(let d=0;d<(n.dots||0);d++)VF.Dot.buildAndAttach([v],{all:true});
   const art={staccato:'a.',tenuto:'a-',accent:'a>',marcato:'a^',staccatissimo:'av'};
   if(n.articulation)v.addModifier(new VF.Articulation(art[n.articulation]).setPosition(VF.Modifier.Position.ABOVE),0);
   if(n.ornament)v.addModifier(new VF.Ornament(n.ornament==='trill'?'tr':n.ornament),0);
   if(n.finger)v.addModifier(new VF.FretHandFinger(n.finger).setPosition(VF.Modifier.Position.ABOVE),0);
   if(n.bow)v.addModifier(new VF.Annotation(n.bow==='up'?'∨':'⊓').setFont('Arial',13).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
   if(n.dynamic)v.addModifier(new VF.Annotation(n.dynamic).setFont('Times',12,'italic').setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);
   const color=options.printing?'#111':n.ghost?'#d5d5d5':index===options.activeBar&&i===options.activeNote?options.accent:'#111';
   v.setStyle({fillStyle:color,strokeStyle:color});return v;
  });
  if(notes.length){const[beats,beatValue]=m.time.split('/').map(Number),voice=new VF.Voice({num_beats:beats,beat_value:beatValue}).setStrict(false);voice.addTickables(notes);
   const beams=VF.Beam.generateBeams(notes.slice(0,bar.notes.length),{maintain_stem_directions:true});
   new VF.Formatter().joinVoices([voice]).formatToStave([voice],stave);voice.draw(ctx,stave);beams.forEach(b=>b.setContext(ctx).draw());}
  engraved.push({notes:notes.slice(0,bar.notes.length),ctx,row:target});
  if(!options.printing){
   const hit=(attributes)=>{const rect=document.createElementNS('http://www.w3.org/2000/svg','rect');for(const[k,v]of Object.entries({fill:'transparent',stroke:'none','class':'note-hit',...attributes}))rect.setAttribute(k,String(v));svg.append(rect);};
   hit({x,y:y+10,width:barWidth,height:100,'data-bar':index});
   notes.slice(0,bar.notes.length).forEach((note,i)=>{const box=note.getBoundingBox();if(box)hit({x:box.getX()-4,y:box.getY()-6,width:Math.max(22,box.getW()+8),height:Math.max(38,box.getH()+12),'data-bar':index,'data-note':i});});
  }
 });
 return engraved;
}
function ties(measures,engraved){
 let previous;
 measures.forEach((bar,b)=>bar.notes.forEach((note,i)=>{
  const current={note,v:engraved[b].notes[i],ctx:engraved[b].ctx,row:engraved[b].row};
  if(note.tiePrevious&&previous?.note.tieNext&&note.pitch===previous.note.pitch&&!note.rest){
   const tie=(first,last,ctx)=>new VF.StaveTie({first_note:first,last_note:last,first_indices:[0],last_indices:[0]}).setContext(ctx).draw();
   if(previous.row===current.row)tie(previous.v,current.v,current.ctx);else{tie(previous.v,null,previous.ctx);tie(null,current.v,current.ctx);}
  }previous=current;
 }));
}
function draw(element,sheet,options={}){
 element.replaceChildren();const pixels=Math.max(280,element.clientWidth),width=pixels/.68,measures=sheet.score.measures,engraved=[];
 let index=0;for(const bars of groups(measures,width,false)){
  const row=document.createElement('div');row.className='staff-row';element.append(row);
  engraved.push(...renderRow(row,bars,index,{...options,metadata:sheet.metadata,width,pixels}));index+=bars.length;
 }ties(measures,engraved);
}
function printDocument(sheet,locale='en',symbols={}){
 const measures=M.trimmedMeasures(sheet),rows=groups(measures,1000,true),pages=[],engraved=[];let index=0;
 for(let cursor=0;cursor<rows.length;){
  const page=document.createElement('section');page.className='print-page';const first=pages.length===0,m=sheet.metadata;
  if(first)page.innerHTML=`<header><h1>${escape(m.title)}</h1>${m.subtitle?`<p class="subtitle">${escape(m.subtitle)}</p>`:''}<div class="score-meta"><div class="credits">${m.lyricist?`<p>${locale==='fa'?'ترانه‌سرا':'Lyricist'}: ${escape(m.lyricist)}</p>`:''}${m.composer?`<p>${locale==='fa'?'آهنگساز':'Composer'}: ${escape(m.composer)}</p>`:''}${m.arranger?`<p>${locale==='fa'?'تنظیم‌کننده':'Arranger'}: ${escape(m.arranger)}</p>`:''}</div><div class="tempo"><span>${escape(m.tempo_text)}</span><span>${escape(symbols[m.tempo_note]||m.tempo_note)} = ${m.bpm}</span></div></div></header>`;
  const count=first?10:12;
  for(const bars of rows.slice(cursor,cursor+count)){
   const row=document.createElement('div');row.className='print-staff';page.append(row);
   engraved.push(...renderRow(row,bars,index,{metadata:m,width:1000,pixels:730,printing:true,lastWritten:measures.length-1}));index+=bars.length;
  }cursor+=count;pages.push(page);
 }ties(measures,engraved);
 return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><style>@font-face{font-family:Sornaz;src:url('../fonts/iran_sansx_fa/regular.ttf')}@page{size:A4;margin:0}*{box-sizing:border-box}body{margin:0;background:white;color:black;font:12px Sornaz,Arial,sans-serif}.print-page{width:210mm;height:297mm;padding:8mm;break-after:page;overflow:hidden}.print-page:last-child{break-after:auto}.print-page header{height:40mm}h1{text-align:center;font-size:20px;margin:0 0 4px}.subtitle{text-align:center;margin:0}.score-meta{display:flex;direction:rtl;justify-content:space-between;align-items:center;gap:12px}.credits{text-align:right;direction:${locale==='fa'?'rtl':'ltr'}}.credits p{margin:2px 0}.tempo{display:flex;gap:12px;direction:ltr;align-items:center}.print-staff{height:23mm}.print-page:not(:first-child){padding-top:9mm}svg{width:100%;height:100%}</style></head><body>${pages.map(p=>p.outerHTML).join('')}</body></html>`;
}
root.NotationRenderer={draw,printDocument,groups};
})(globalThis);
