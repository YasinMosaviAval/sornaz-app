/* Responsive screen engraving and independent A4 pagination. No network fonts. */
(function(root){
'use strict';
const VF=Vex.Flow,M=NotationModel;
const escape=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const gapDurations=Object.keys(M.durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:M.units({duration,dots})}))).sort((a,b)=>b.value-a.value);
function spacingNotes(length){const notes=[];while(length>0){const part=gapDurations.find(item=>item.value<=length);if(!part)break;notes.push(new VF.GhostNote({duration:part.duration,dots:part.dots}));length-=part.value;}return notes;}
// Reserve at least 12 logical pixels around each note/group and stave edge.
const estimate=bar=>Math.max(110,Math.max(...[1,2].map(staff=>M.lane(bar,staff).length))*34+82);
function ottava(pitch,rest=false){
 if(rest)return {pitch,label:''};
 const octave=Number(pitch.slice(1)),letter=pitch[0];
 const low=octave<2||(octave===2&&'CDEFG'.includes(letter));
 const shift=low?(octave<2?2:1):octave>=7?(octave===8?-2:-1):0;
 return {pitch:letter+(octave+shift),label:shift?(Math.abs(shift)===2?'16':'8')+(shift>0?'vb':'va'):'',below:shift>0};
}
function groups(measures,width,printing){
 const result=[];
 if(printing){
  const density=Math.max(0,...measures.flatMap(b=>[1,2].map(staff=>M.lane(b,staff).length)));
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
 const m=options.metadata,layout=M.staves(m),grand=layout.length===2,width=Math.max(options.width,bars.reduce((v,b)=>v+estimate(b),70)),height=grand?300:120;
 const renderer=new VF.Renderer(target,VF.Renderer.Backends.SVG);renderer.resize(width,height);
 const ctx=renderer.getContext(),engraved=[],octaveNotes=[];
 const svg=target.querySelector('svg');svg.setAttribute('viewBox',`0 0 ${width} ${height}`);svg.setAttribute('width','100%');svg.setAttribute('height',String(options.printing?(grand?215:86):height*options.pixels/width));
 svg.style.display='block';svg.style.maxWidth='100%';
 const leftInset=grand?30:4,barWidth=(width-leftInset-4)/bars.length;
 bars.forEach((bar,col)=>{
  const index=start+col,x=leftInset+col*barWidth,barTime=M.effectiveTime(options.sheet,index),staves=layout.map((entry,lane)=>new VF.Stave(x,6+lane*150,barWidth));
  if(!options.printing&&index===options.activeBar){ctx.save();ctx.setFillStyle(options.accent+'14');staves.forEach(stave=>ctx.fillRect(x,stave.getY()+15,barWidth,94));ctx.restore();}
  staves.forEach((stave,lane)=>{
   if(col===0){stave.addClef(layout[lane].clef);stave.addKeySignature(m.key);if(index===0||bar.time||bar.timeSymbol)stave.addTimeSignature(bar.timeSymbol==='common'?'C':bar.timeSymbol==='cut'?'C|':barTime);
    else if(lane===0){ctx.save();ctx.setFillStyle('#666');ctx.setFont('Arial',5.5);ctx.fillText(String(index+1),x+9,35);ctx.restore();}}
   if(bar.repeat?.start)stave.setBegBarType(VF.Barline.type.REPEAT_BEGIN);
   if(bar.repeat?.end)stave.setEndBarType(VF.Barline.type.REPEAT_END);
   else if(bar.barline==='double')stave.setEndBarType(VF.Barline.type.DOUBLE);
   else if(bar.barline==='final'||index===options.lastWritten)stave.setEndBarType(VF.Barline.type.END);
   else if(bar.barline==='hidden')stave.setEndBarType(VF.Barline.type.NONE);
   stave.setContext(ctx).draw();
  });
  const noteStart=Math.max(...staves.map(stave=>stave.getNoteStartX()))+12;
  staves.forEach(stave=>stave.setNoteStartX(noteStart));
  if(grand){
   for(const type of [VF.StaveConnector.type.SINGLE_LEFT,...(col===0?[VF.StaveConnector.type.BRACE]:[]),VF.StaveConnector.type.SINGLE_RIGHT])
    new VF.StaveConnector(staves[0],staves[1]).setType(type).setContext(ctx).draw();
  }
  const addLabel=(label,y,size=12)=>{const element=document.createElementNS('http://www.w3.org/2000/svg','text');for(const[key,value]of Object.entries({x:x+barWidth/2,y,'text-anchor':'middle','font-family':'NotationTheme, Arial','font-size':size,fill:'#111'}))element.setAttribute(key,value);element.textContent=label;svg.append(element);};
  const repeat=bar.repeat||{};
  if(repeat.endings?.length){
   const ending=repeat.endings.join(','),previous=options.sheet.score.measures[index-1]?.repeat?.endings?.join(','),next=options.sheet.score.measures[index+1]?.repeat?.endings?.join(','),y=staves[0].getY()-8;
   const left=x+(previous===ending&&col>0?0:14),right=x+barWidth-(next===ending&&col<bars.length-1?0:10),line=document.createElementNS('http://www.w3.org/2000/svg','path');
   line.setAttribute('d',`M${left} ${y+7}V${y}H${right}${next===ending?'':`V${y+7}`}`);line.setAttribute('fill','none');line.setAttribute('stroke','#111');line.setAttribute('stroke-width','1');svg.append(line);
   if(previous!==ending||col===0)addLabel(ending+'.',y-2,10);
  }
  if(repeat.marker)addLabel(({segno:'Segno',coda:'Coda',toCoda:'To Coda',fine:'Fine'})[repeat.marker],staves[0].getY()-18,10);
  if(repeat.jump)addLabel(({dc:'D.C.',ds:'D.S.',dcAlFine:'D.C. al Fine',dsAlFine:'D.S. al Fine',dcAlCoda:'D.C. al Coda',dsAlCoda:'D.S. al Coda'})[repeat.jump],staves[0].getY()-30,10);
  if(repeat.measure)addLabel(repeat.measure===1?'%':'% %',staves[0].getY()+58,24);
  const engravedNotes=Array(bar.notes.length),voices=[],beams=[],tuplets=[];
  staves.forEach((stave,lane)=>{
   const staff=lane+1,all=bar.notes.map((n,i)=>({...n,index:i,at:M.positionOf(bar,i)})).filter(n=>M.staffOf(n)===staff),voiceIds=[...new Set(all.map(M.voiceOf))];
   if(!voiceIds.length&&options.ghost&&M.staffOf(options.ghost)===staff)voiceIds.push(M.voiceOf(options.ghost));
   for(const voiceId of voiceIds){
   const source=all.filter(n=>M.voiceOf(n)===voiceId).sort((a,b)=>a.at-b.at||a.index-b.index);
   if(!options.printing&&index===options.ghostBar&&options.ghost&&M.staffOf(options.ghost)===staff&&M.voiceOf(options.ghost)===voiceId)source.push({...options.ghost,index:-1,at:source.length?source.at(-1).at+M.units(source.at(-1)):0,ghost:true,rest:false});
   const notes=[],actual=[];let cursor=0,tupletGroup=[],tupletRatio='';
   const finishTuplet=()=>{if(tupletGroup.length){const[actualCount,normalCount]=tupletRatio.split(':').map(Number);tuplets.push(new VF.Tuplet(tupletGroup,{num_notes:actualCount,notes_occupied:normalCount}));tupletGroup=[];tupletRatio='';}};
   source.forEach(n=>{
    if(n.at>cursor)notes.push(...spacingNotes(n.at-cursor));
    const tones=[{pitch:n.pitch,accidental:n.accidental},...(n.pitches||[])],display=ottava(n.pitch,n.rest);
    const keys=n.rest?['b/4']:tones.map(tone=>{const shifted=ottava(tone.pitch);return shifted.pitch[0].toLowerCase()+'/'+shifted.pitch.slice(1);});
    const v=new VF.StaveNote({clef:layout[lane].clef,keys,duration:n.duration+(n.rest?'r':''),dots:n.dots||0,auto_stem:true});
    octaveNotes.push({note:v,...display});
    if(!n.rest)v.setStemDirection(v.getKeyProps()[0].line<=3?VF.Stem.UP:VF.Stem.DOWN);
    if(!n.rest)tones.forEach((tone,i)=>{if(tone.accidental)v.addModifier(new VF.Accidental(tone.accidental),i);});
    for(let d=0;d<(n.dots||0);d++)VF.Dot.buildAndAttach([v],{all:true});
    const art={staccato:'a.',tenuto:'a-',accent:'a>',marcato:'a^',staccatissimo:'av'};
    if(n.articulation)v.addModifier(new VF.Articulation(art[n.articulation]).setPosition(VF.Modifier.Position.ABOVE),0);
    if(n.ornament)v.addModifier(new VF.Ornament(n.ornament==='trill'?'tr':n.ornament),0);
    if(n.finger)v.addModifier(new VF.FretHandFinger(n.finger).setPosition(VF.Modifier.Position.ABOVE),0);
    if(n.bow)v.addModifier(new VF.Annotation(n.bow==='up'?'∨':'⊓').setFont('Arial',13).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
    if(n.dynamic)v.addModifier(new VF.Annotation(n.dynamic).setFont('Times',12,'italic').setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);
    const color=options.printing?'#111':n.ghost?'#d5d5d5':options.selectedNotes?.has(index+':'+n.index)||index===options.activeBar&&n.index===options.activeNote?options.accent:'#111';
    v.setStyle({fillStyle:color,strokeStyle:color});if(n.index>=0)engravedNotes[n.index]=v;notes.push(v);if(!n.ghost)actual.push(v);cursor=n.at+M.units(n);
    const ratio=n.tuplet?`${n.tuplet.actual}:${n.tuplet.normal}`:'';
    if(ratio!==tupletRatio)finishTuplet();
    if(ratio){tupletRatio=ratio;tupletGroup.push(v);if(tupletGroup.length===n.tuplet.actual)finishTuplet();}
   });
   finishTuplet();
   if(notes.length){const[beats,beatValue]=barTime.split('/').map(Number),voice=new VF.Voice({num_beats:beats,beat_value:beatValue}).setStrict(false);voice.addTickables(notes);voices.push({voice,stave});beams.push(...VF.Beam.generateBeams(actual,{maintain_stem_directions:true}));}
   }
  });
  if(voices.length){const formatter=new VF.Formatter();staves.forEach(stave=>{const same=voices.filter(v=>v.stave===stave).map(v=>v.voice);if(same.length)formatter.joinVoices(same);});formatter.format(voices.map(v=>v.voice),Math.max(20,staves[0].getNoteEndX()-noteStart-12));voices.forEach(({voice,stave})=>voice.draw(ctx,stave));beams.forEach(beam=>beam.setContext(ctx).draw());tuplets.forEach(tuplet=>tuplet.setContext(ctx).draw());}
  engraved.push({notes:engravedNotes,ctx,row:target});
  if(!options.printing){
   const hit=(attributes)=>{const rect=document.createElementNS('http://www.w3.org/2000/svg','rect');for(const[k,v]of Object.entries({fill:'transparent',stroke:'none','class':'note-hit',...attributes}))rect.setAttribute(k,String(v));svg.append(rect);};
   staves.forEach((stave,lane)=>hit({x,y:stave.getY()+10,width:barWidth,height:100,'data-bar':index,'data-staff':lane+1}));
   engravedNotes.forEach((note,i)=>{const box=note?.getBoundingBox();if(box)hit({x:box.getX()-4,y:box.getY()-6,width:Math.max(22,box.getW()+8),height:Math.max(38,box.getH()+12),'data-bar':index,'data-staff':M.staffOf(bar.notes[i]),'data-note':i});});
  }
 });
 // Brackets continue over adjacent notes and bars, with a fresh label on each row.
 const add=(tag,attrs,text)=>{const el=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const[k,v]of Object.entries(attrs))el.setAttribute(k,String(v));if(text)el.textContent=text;svg.append(el);};
 let run=[];
 const bracket=()=>{if(!run.length)return;const first=run[0],boxes=run.map(n=>n.note.getBoundingBox()).filter(Boolean);if(!boxes.length){run=[];return;}
  const x=boxes[0].getX(),end=Math.min(width-4,boxes.at(-1).getX()+boxes.at(-1).getW()+10),y=first.below?Math.max(...boxes.map(b=>b.getY()+b.getH()))+14:Math.min(...boxes.map(b=>b.getY()))-14;
  add('text',{x,y,'font-size':10,'font-family':'Arial',fill:'#111','class':'ottava-label'},first.label);
  const lineStart=Math.min(x+28,end-2);add('path',{d:'M'+lineStart+' '+(y-3)+'H'+end+'v'+(first.below?-5:5),fill:'none',stroke:'#111','stroke-width':.8,'stroke-dasharray':'3 2','class':'ottava-line'});run=[];
 };
 for(const entry of octaveNotes){if(!entry.label||run.length&&run[0].label!==entry.label)bracket();if(entry.label)run.push(entry);}bracket();
 const bounds=svg.getBBox(),top=Math.min(0,bounds.y-5),bottom=Math.max(height,bounds.y+bounds.height+5),total=bottom-top;
 svg.setAttribute('viewBox',`0 ${top} ${width} ${total}`);if(!options.printing)svg.setAttribute('height',String(total*options.pixels/width));
 return engraved;
}
function ties(measures,engraved){
 let previous;
 measures.forEach((bar,b)=>bar.notes.forEach((note,i)=>{
  const current={note,v:engraved[b].notes[i],ctx:engraved[b].ctx,row:engraved[b].row};
  if(note.tiePrevious&&previous?.note.tieNext&&M.staffOf(note)===M.staffOf(previous.note)&&note.pitch===previous.note.pitch&&!note.rest){
   const tie=(first,last,ctx)=>new VF.StaveTie({first_note:first,last_note:last,first_indices:[0],last_indices:[0]}).setContext(ctx).draw();
   if(previous.row===current.row)tie(previous.v,current.v,current.ctx);else{tie(previous.v,null,previous.ctx);tie(null,current.v,current.ctx);}
  }previous=current;
 }));
}
function draw(element,sheet,options={}){
 element.replaceChildren();const pixels=Math.max(280,element.clientWidth),width=pixels/.68,measures=sheet.score.measures,engraved=[];
 let index=0;for(const bars of groups(measures,width,false)){
  const row=document.createElement('div');row.className='staff-row';element.append(row);
  engraved.push(...renderRow(row,bars,index,{...options,sheet,metadata:sheet.metadata,width,pixels}));index+=bars.length;
 }ties(measures,engraved);
}
function printDocument(sheet,locale='en',symbols={}){
 const measures=M.trimmedMeasures(sheet),rows=groups(measures,1000,true),pages=[],engraved=[];let index=0;
 const host=document.createElement('div');host.style.cssText='position:absolute;left:-10000px;top:0;visibility:hidden';document.body.append(host);
 try{
 for(let cursor=0;cursor<rows.length;){
  const page=document.createElement('section');page.className='print-page';const first=pages.length===0,m=sheet.metadata;
  host.append(page);
  if(first)page.innerHTML=`<header><h1>${escape(m.title)}</h1>${m.subtitle?`<p class="subtitle">${escape(m.subtitle)}</p>`:''}<div class="score-meta"><div class="credits">${m.lyricist?`<p>${locale==='fa'?'ترانه‌سرا':'Lyricist'}: ${escape(m.lyricist)}</p>`:''}${m.composer?`<p>${locale==='fa'?'آهنگساز':'Composer'}: ${escape(m.composer)}</p>`:''}${m.arranger?`<p>${locale==='fa'?'تنظیم‌کننده':'Arranger'}: ${escape(m.arranger)}</p>`:''}</div><div class="tempo"><span>${escape(m.tempo_text)}</span><span>${escape(symbols[m.tempo_note]||m.tempo_note)} = ${m.bpm}</span></div></div></header>`;
  const grand=M.staves(m).length===2,count=grand?(first?4:5):(first?10:12);
  for(const bars of rows.slice(cursor,cursor+count)){
   const row=document.createElement('div');row.className='print-staff';page.append(row);
   engraved.push(...renderRow(row,bars,index,{sheet,metadata:m,width:1000,pixels:730,printing:true,lastWritten:measures.length-1}));index+=bars.length;
  }cursor+=count;pages.push(page);
 }ties(measures,engraved);
 return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><style>@font-face{font-family:Sornaz;src:url('../fonts/iran_sansx_fa/regular.ttf')}@page{size:A4;margin:0}*{box-sizing:border-box}body{margin:0;background:white;color:black;font:12px Sornaz,Arial,sans-serif}.print-page{width:210mm;height:297mm;padding:8mm;break-after:page;overflow:hidden}.print-page:last-child{break-after:auto}.print-page header{height:40mm}h1{text-align:center;font-size:20px;margin:0 0 4px}.subtitle{text-align:center;margin:0}.score-meta{display:flex;direction:rtl;justify-content:space-between;align-items:center;gap:12px}.credits{text-align:right;direction:${locale==='fa'?'rtl':'ltr'}}.credits p{margin:2px 0}.tempo{display:flex;gap:12px;direction:ltr;align-items:center}.print-staff{height:${M.staves(sheet.metadata).length===2?53:23}mm}.print-page:not(:first-child){padding-top:9mm}svg{width:100%;height:100%}</style></head><body>${pages.map(p=>p.outerHTML).join('')}</body></html>`;
 }finally{host.remove();}
}
root.NotationRenderer={draw,printDocument,groups,ottava};
})(globalThis);
