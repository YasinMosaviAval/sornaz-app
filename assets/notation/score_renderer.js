/* Responsive screen engraving and independent A4 pagination. No network fonts. */
(function(root){
'use strict';
const VF=Vex.Flow,M=NotationModel;
VF.setMusicFont('Bravura','Gonville','Custom');
function accidentalParts(value){return value==='bk'?['b','k']:value==='#o'?['#','o']:[value];}
// Resolve display signs in staff time order without changing stored pitches.
function measureAccidentals(sheet,index,staff){
 const bar=sheet.score.measures[index],key=M.effectiveKey(sheet,index),signature=M.iranianSignature?.(sheet.metadata.scale_type,key),keyValue=signature?Object.fromEntries(signature.degrees.map(d=>[d.letter,d.alter])):key,carry={},result=new Map();
 const signs={0:'n',1:'#','-1':'b',2:'##','-2':'bb',0.5:'o','-0.5':'k',1.5:'#o','-1.5':'bk'};
 const previous=new Map(),seen=new Set();
 for(let i=0;i<index;i++){
  const oldKey=M.effectiveKey(sheet,i),oldValue=M.iranianSignature?.(sheet.metadata.scale_type,oldKey)?.alterations||oldKey,oldCarry={},oldBar=sheet.score.measures[i];
  for(const {n}of oldBar.notes.map((n,j)=>({n,j,at:M.positionOf(oldBar,j)})).filter(({n})=>!n.rest&&M.staffOf(n)===staff).sort((a,b)=>a.at-b.at||a.j-b.j))for(const tone of [...(n.graces||[]),n,...(n.pitches||[])])previous.set(tone.pitch,M.frequency(tone.pitch,tone.accidental||'',oldValue,oldCarry));
 }
 const resolve=tone=>{const pitch=tone.pitch,before=M.frequency(pitch,'',keyValue,carry),after=M.frequency(pitch,tone.accidental||'',keyValue,carry),changed=Math.abs(after-before)>.00001,signaturePitch=M.frequency(pitch,'',keyValue),returnToSignature=!seen.has(pitch)&&previous.has(pitch)&&Math.abs(after-signaturePitch)<.00001&&Math.abs(previous.get(pitch)-signaturePitch)>.00001;seen.add(pitch);if(!changed&&!returnToSignature&&!tone.cautionary&&!tone.showAccidental)return '';const alter=Math.round(24*Math.log2(after/M.frequency(pitch,'','C')))/2;return signs[alter]||tone.accidental||'';};
 bar.notes.map((n,i)=>({...n,index:i,at:M.positionOf(bar,i)})).filter(n=>!n.rest&&M.staffOf(n)===staff).sort((a,b)=>a.at-b.at||a.index-b.index).forEach(n=>{const graces=(n.graces||[]).map(resolve),tones=[n,...(n.pitches||[])].map(resolve);result.set(n.index,{graces,tones});});
 return result;
}
class IranianKeySignature extends VF.KeySignature {
 constructor(signature,clef,previous=null){super('C');const cancelled=(previous?.accidentals||[]).filter(item=>!signature.alterations[item.letter]).map(item=>({...item,accidental:'n'}));this.signature={...signature,accidentals:[...cancelled,...signature.accidentals]};this.clefOverride=clef;}
 format(){
  const stave=this.checkStave(),clef=this.clefOverride||stave.getClef();this.width=0;this.glyphs=[];this.xPositions=[0];this.accList=[];
  const lower=[2,.5,2.5,1,3,1.5,3.5].map(line=>({line})),upper=[0,1.5,-.5,1,2.5,.5,2].map(line=>({line}));
  this.convertAccLines(clef,'b',lower);this.convertAccLines(clef,'#',upper);
  for(const item of this.signature.accidentals){const line=(item.alter<0?lower:upper)[(item.alter<0?'BEADGCF':'FCGDAEB').indexOf(item.letter)].line;for(const type of accidentalParts(item.accidental))this.accList.push({type,line});}
  for(let i=0;i<this.accList.length;i++)this.convertToGlyph(this.accList[i],this.accList[i+1]);this.formatted=true;
 }
}
function signatureReserve(sheet){return Math.max(0,...sheet.score.measures.map((_,i)=>(M.iranianSignature?.(sheet.metadata.scale_type,M.effectiveKey(sheet,i))?.accidentals||[]).reduce((sum,a)=>sum+(a.accidental==='bk'||a.accidental==='#o'?28:16),0)-35));}
class SmallStaveNote extends VF.StaveNote {getStaveNoteScale(){return .7;}}
const escape=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const gapDurations=Object.keys(M.durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:M.units({duration,dots})}))).sort((a,b)=>b.value-a.value);
function spacingNotes(length){const notes=[];while(length>0){const part=gapDurations.find(item=>item.value<=length);if(!part)break;notes.push(new VF.GhostNote({duration:part.duration,dots:part.dots}));length-=part.value;}return notes;}
// Render-only rests never enter the score, undo history, export or playback.
function completedVoice(source,sheet,index,staff,voice){
 const end=M.barUnits(sheet,index),pattern=M.beamPattern(sheet,index),boundaries=[];let boundary=0;
 if(pattern)for(const part of pattern.parts){boundary+=part*M.wholeUnits/pattern.denominator;boundaries.push(boundary);}
 const ratios=[...new Map(source.filter(n=>n.tuplet).map(n=>[n.tuplet.actual+':'+n.tuplet.normal,n.tuplet])).values()];
 const choices=gapDurations.filter(n=>!(n.duration==='h'&&n.dots)).flatMap(n=>[n,...ratios.map(tuplet=>({...n,tuplet,value:n.value*tuplet.normal/tuplet.actual})).filter(item=>Number.isInteger(item.value))]).sort((a,b)=>b.value-a.value||Number(!!a.tuplet)-Number(!!b.tuplet));
 const result=[];let cursor=0;
 const memo=new Map([[0,true]]),values=[...new Set(choices.map(n=>n.value))],minimum=Math.min(...values),gcd=(a,b)=>b?gcd(b,a%b):a,quantum=values.reduce(gcd);
 const reachable=length=>{if(length<0||length%quantum||length>0&&length<minimum)return false;if(memo.has(length))return memo.get(length);const valid=values.some(value=>value<=length&&reachable(length-value));memo.set(length,valid);return valid;};
 const fill=until=>{while(cursor<until){const limit=Math.min(until,boundaries.find(b=>b>cursor)||until),remaining=reachable(limit-cursor)?limit-cursor:until-cursor,valid=choices.filter(n=>n.value<=remaining&&reachable(remaining-n.value));const choice=valid.find(n=>cursor%n.value===0||pattern&&n.value===remaining)||valid[0];if(!choice)break;const note={pitch:'B4',duration:choice.duration,dots:choice.dots,rest:true,index:-1,synthetic:true,staff,voice,at:cursor};if(choice.tuplet)note.tuplet=choice.tuplet;result.push(note);cursor+=choice.value;}};
 for(const note of source){fill(Math.min(note.at,end));result.push(note);cursor=Math.max(cursor,note.at+M.units(note));}fill(end);return result;
}
function renderingBeamPattern(sheet,index){
 const m=M.effectiveTempoUnit(sheet,index);if(!M.durations[m.tempo_note])return M.beamPattern(sheet,index);
 const beat=M.units({duration:m.tempo_note,dots:Number(m.tempo_dots)||0}),length=M.barUnits(sheet,index),parts=[];for(let at=0;at<length;at+=beat)parts.push(Math.min(beat,length-at));return {parts,denominator:M.wholeUnits};
}
// Choose stems before formatting so noteheads attach on the correct side.
function notationBeam(notes){
 const lines=notes.map(note=>note.getKeyProps()[0].line),up=notes.filter(note=>note.getStemDirection()===VF.Stem.UP).length;
 const above=Math.max(0,Math.max(...lines)+3.5-5),below=Math.max(0,1-(Math.min(...lines)-3.5));
 const direction=up*2===notes.length?(above<=below?VF.Stem.UP:VF.Stem.DOWN):up*2>notes.length?VF.Stem.UP:VF.Stem.DOWN;
 notes.forEach(note=>note.setStemDirection(direction));const beam=new VF.Beam(notes);
 beam.calculateSlope=function(){
  const first=this.notes[0],last=this.notes.at(-1),x=first.getStemX(),head=note=>direction===VF.Stem.UP?Math.min(...note.getYs()):Math.max(...note.getYs()),span=last.getStemX()-x;
  this.slope=span?Math.max(-.25,Math.min(.25,(head(last)-head(first))/span/2)):0;
  const required=this.notes.map(note=>{const minimum=Math.max(VF.Stem.HEIGHT,(note.getStave()?.getSpacingBetweenLines()||10)*3.5)+VF.Stem.WIDTH/2;return head(note)-direction*minimum-this.slope*(note.getStemX()-x);});
  const target=direction===VF.Stem.UP?Math.min(...required):Math.max(...required);this.y_shift=target-first.getStemExtents().topY;
 };
 return beam;
}
// Beam groups choose a common stem direction, including pitches across the middle line.
function rhythmicBeams(notes,positions,sheet,index){
 const pattern=renderingBeamPattern(sheet,index);if(!pattern)return VF.Beam.generateBeams(notes,{maintain_stem_directions:false});
 const bounds=[];let end=0;for(const part of pattern.parts){end+=part*M.wholeUnits/pattern.denominator;bounds.push(end);}
 const beams=[];let run=[],previousEnd=-1,previousGroup=-1;const flush=()=>{if(run.length>1)beams.push(notationBeam(run));run=[];};
 for(const note of notes){const entry=positions.get(note),group=bounds.findIndex(boundary=>entry.at<boundary);if(!entry.flagged||group<0||entry.at+entry.units>bounds[group]){flush();previousGroup=-1;continue;}if(group!==previousGroup||entry.at!==previousEnd)flush();run.push(note);previousEnd=entry.at+entry.units;previousGroup=group;}flush();return beams;
}
function measureRepeatAt(bars,index){if(bars[index]?.repeat?.measure)return {start:index,count:bars[index].repeat.measure};if(bars[index-1]?.repeat?.measure===2)return {start:index-1,count:2};return null;}
const repeatGlyphSize=38,repeatPadding=26,repeatWidths={1:new VF.Glyph('repeat1Bar',repeatGlyphSize).getMetrics().width+repeatPadding*2,2:new VF.Glyph('repeat2Bars',repeatGlyphSize).getMetrics().width+repeatPadding*2};
function centeredGlyph(ctx,svg,code,x,y,className,attributes={},hang=false){
 ctx.save();ctx.setFillStyle('#111');ctx.setStrokeStyle('#111');ctx.openGroup(className);new VF.Glyph(code,repeatGlyphSize).render(ctx,0,0);ctx.closeGroup();ctx.restore();
 const group=[...svg.querySelectorAll('[class*="'+className+'"]')].at(-1),box=group.getBBox();group.classList.add(className);group.setAttribute('transform','translate('+(x-box.x-box.width/2)+' '+(y-box.y-(hang?0:box.height/2))+')');for(const[k,v]of Object.entries(attributes))group.setAttribute(k,String(v));return group;
}
function previewNote(ctx,stave,n,x){
 const pitch=ottava(n.pitch).pitch,v=new VF.StaveNote({clef:stave.getClef(),keys:[pitch[0].toLowerCase()+'/'+pitch.slice(1)],duration:n.duration,dots:n.dots||0,auto_stem:true});
 for(let d=0;d<(n.dots||0);d++)VF.Dot.buildAndAttach([v],{all:true});if(n.accidental)for(const part of accidentalParts(n.accidental))v.addModifier(new VF.Accidental(part),0);
 v.setStyle({fillStyle:'#d5d5d5',strokeStyle:'#d5d5d5'});v.setStave(stave);const voice=new VF.Voice({num_beats:4,beat_value:4}).setStrict(false).addTickables([v]);new VF.Formatter().joinVoices([voice]).format([voice],40);const tick=v.getTickContext();tick.setX(tick.getX()+x-v.getAbsoluteX());ctx.openGroup('notation-preview-note');v.setContext(ctx).draw();ctx.closeGroup();v.getSVGElement?.()?.closest('[class*="notation-preview-note"]')?.classList.add('notation-preview-note');
}
// Reserve horizontal space for modifiers before grouping measures into rows.
const estimate=(bar,repeatCount=bar.repeat?.measure||0,sheet=null,index=0)=>{
 if(repeatCount)return repeatWidths[repeatCount]/repeatCount;
 const lanes=[1,2].map(staff=>{const saved=bar.notes.map((n,i)=>({...n,at:M.positionOf(bar,i)})).filter(n=>M.staffOf(n)===staff),extra=sheet?[...new Set(saved.map(M.voiceOf))].reduce((sum,voice)=>sum+completedVoice(saved.filter(n=>M.voiceOf(n)===voice).sort((a,b)=>a.at-b.at),sheet,index,staff,voice).filter(n=>n.synthetic).length*24,0):0;return saved.reduce((width,n)=>width+38+(n.accidental?18:0)+(n.cautionary?10:0)+(n.pitches||[]).filter(tone=>tone.accidental).length*12+(n.graces?.length||0)*13+(n.chordSymbol?30:0),extra);});
 const prefix=((bar.time||bar.timeSymbol)&&(!sheet||index===0||M.effectiveTime(sheet,index)!==M.effectiveTime(sheet,index-1))?32:0)+(bar.key?35:0)+(bar.clefs?38:0)+(bar.repeat?.start?18:0);
 return Math.max(150,Math.max(...lanes)+100+prefix+(bar.clefChanges?.length||0)*24);
};
function ottava(pitch,rest=false){
 if(rest)return {pitch,label:''};
 const octave=Number(pitch.slice(1)),letter=pitch[0];
 const low=octave<2||(octave===2&&'CDEFG'.includes(letter));
 const shift=low?(octave<2?2:1):octave>=7?(octave===8?-2:-1):0;
 return {pitch:letter+(octave+shift),label:shift?(Math.abs(shift)===2?'16':'8')+(shift>0?'vb':'va'):'',below:shift>0};
}
function groups(measures,width,printing,reserve=0,sheet=null){
 const result=[],density=Math.max(0,...measures.flatMap(b=>[1,2].map(staff=>M.lane(b,staff).length))),count=printing?(density>12?5:density>6?6:8):4;
 let row=[],used=70+reserve;
 for(let index=0;index<measures.length;){const countBars=measures[index].repeat?.measure===2&&index+1<measures.length?2:1,unit=measures.slice(index,index+countBars),cost=unit.reduce((sum,bar,offset)=>sum+estimate(bar,measureRepeatAt(measures,index+offset)?.count||0,sheet,index+offset),0);
  if(row.length&&(printing?row.length+countBars>count:row.length+countBars>16||row.filter((b,offset)=>!measureRepeatAt(measures,index-row.length+offset)).length+unit.filter((b,offset)=>!measureRepeatAt(measures,index+offset)).length>4||used+cost>width)){result.push(row);row=[];used=70+reserve;}
  if(!row.length)used=measureRepeatAt(measures,index)?2*(70+reserve):70+reserve;
  row.push(...unit);used+=cost;index+=countBars;
 }if(row.length)result.push(row);return result;
}
function renderRow(target,bars,start,options){
 const m=options.metadata,layout=M.staves(m),grand=layout.length===2,width=Math.max(options.width,bars.reduce((v,b,i)=>v+estimate(b,measureRepeatAt(options.sheet.score.measures,start+i)?.count||0,options.sheet,start+i),(70+signatureReserve(options.sheet))*(measureRepeatAt(options.sheet.score.measures,start)?2:1))),staffStep=options.printing?150:(options.staffStep||95),height=grand?staffStep+150:120;
 const renderer=new VF.Renderer(target,VF.Renderer.Backends.SVG);renderer.resize(width,height);
 const ctx=renderer.getContext(),engraved=[],octaveNotes=[];
 const svg=target.querySelector('svg');svg.setAttribute('viewBox',`0 0 ${width} ${height}`);svg.setAttribute('width','100%');svg.setAttribute('height',String(options.printing?(grand?215:86):height*options.pixels/width));
 svg.style.display='block';svg.style.maxWidth='100%';if(!options.printing)svg.style.width='100%';svg.dataset.baseHeight=String(height);svg.dataset.legacyHeight=String(grand?300:120);svg.dataset.screenScale=String(options.pixels/width);svg.dataset.staffStep=String(staffStep);
 const leftInset=options.leftInset??(grand?30:4),repeatInfo=bars.map((_,i)=>measureRepeatAt(options.sheet.score.measures,start+i)),widths=options.measureWidths?.slice()||repeatInfo.map(info=>info?repeatWidths[info.count]/info.count:0);
 const firstRepeat=repeatInfo[0];if(firstRepeat&&!options.measureWidths){const prefix=2*(70+signatureReserve(options.sheet));for(let i=0;i<Math.min(firstRepeat.count,widths.length);i++)widths[i]+=prefix/firstRepeat.count;}
 const flexible=widths.filter(w=>!w).length,remaining=width-leftInset-4-widths.reduce((a,b)=>a+b,0);for(let i=0;i<widths.length;i++)if(!widths[i])widths[i]=remaining/flexible;
 let barX=leftInset;
 bars.forEach((bar,col)=>{
  const index=start+col,x=barX,barWidth=widths[col],repeatRegion=repeatInfo[col],barTime=M.effectiveTime(options.sheet,index),barKey=M.effectiveKey(options.sheet,index),clefs=layout.map((_,lane)=>M.effectiveClef(options.sheet,index,lane+1)),staves=layout.map((entry,lane)=>new VF.Stave(x,6+lane*staffStep,barWidth)),multiRest=M.multiRestAt(options.sheet.score.measures,index),selectedHint=!options.printing&&options.sheet.editable&&options.measureSelected&&index===options.activeBar&&index>0,tempoTargets=[];
  if(!options.printing&&index===options.activeBar){ctx.save();ctx.setFillStyle(options.accent+'14');ctx.openGroup('notation-active-background');staves.forEach(stave=>ctx.fillRect(x,stave.getY()+15,barWidth,94));ctx.closeGroup();ctx.restore();}
  staves.forEach((stave,lane)=>{
   // Keep the clef context even when its repeated visual modifier is omitted.
   stave.clef=clefs[lane].split('_')[0];
   const changedClef=index===0||clefs[lane]!==M.clefAt(options.sheet,index-1,lane+1,Infinity);
   if(col===0||bar.clefs?.[lane+1]||bar.time||bar.timeSymbol||bar.key||selectedHint){if(col===0||bar.clefs?.[lane+1]&&(!options.continuousSignatures||changedClef))stave.addClef(clefs[lane].split('_')[0],undefined,clefs[lane].split('_')[1]);if(options.continuousSignatures?(index===0||!M.sameKeySignature(options.sheet,barKey,M.effectiveKey(options.sheet,index-1))):(col===0||bar.key)){const signature=M.iranianSignature?.(m.scale_type,barKey);if(signature)stave.addModifier(new IranianKeySignature(signature,clefs[lane].split('_')[0],index>0?M.iranianSignature(m.scale_type,M.effectiveKey(options.sheet,index-1)):null));else stave.addKeySignature(barKey,index>0?M.effectiveKey(options.sheet,index-1):undefined);}if(index===0||barTime!==M.effectiveTime(options.sheet,index-1)||selectedHint){stave.addTimeSignature(bar.timeSymbol==='common'?'C':bar.timeSymbol==='cut'?'C|':barTime);if(selectedHint&&barTime===M.effectiveTime(options.sheet,index-1))stave.getModifiers().find(mod=>mod.getCategory()==='TimeSignature')?.setStyle({fillStyle:'#c4c4c4',strokeStyle:'#c4c4c4'});}
   }
   if(lane===0&&(bar.displayNumber||index>0)){ctx.save();ctx.setFillStyle('#666');ctx.setFont('Arial',5.5);ctx.fillText(String(bar.displayNumber||index+1),x+9,35);ctx.restore();}
   if(bar.repeat?.start)stave.setBegBarType(VF.Barline.type.REPEAT_BEGIN);
   if(multiRest&&index<multiRest.end)stave.setEndBarType(VF.Barline.type.NONE);
   else if(bar.repeat?.end)stave.setEndBarType(VF.Barline.type.REPEAT_END);
   else if(bar.barline==='double')stave.setEndBarType(VF.Barline.type.DOUBLE);
   else if(bar.barline==='final'||index===options.lastWritten)stave.setEndBarType(VF.Barline.type.END);
   else if(bar.barline==='hidden')stave.setEndBarType(VF.Barline.type.NONE);
   ctx.openGroup('notation-staff-'+(lane+1));stave.setContext(ctx).draw();ctx.closeGroup();
  });
  barX+=barWidth;
  const noteStart=Math.max(...staves.map(stave=>stave.getNoteStartX()))+12;
  staves.forEach(stave=>stave.setNoteStartX(noteStart));
  if(grand){
   for(const type of [VF.StaveConnector.type.SINGLE_LEFT,...(col===0?[VF.StaveConnector.type.BRACE]:[]),VF.StaveConnector.type.SINGLE_RIGHT])
    new VF.StaveConnector(staves[0],staves[1]).setType(type).setContext(ctx).draw();
  }
  const addLabel=(label,y,size=12)=>{const element=document.createElementNS('http://www.w3.org/2000/svg','text');for(const[key,value]of Object.entries({x:x+barWidth/2,y,'text-anchor':'middle','font-family':'NotationTheme, Arial','font-size':size,fill:'#111'}))element.setAttribute(key,value);element.textContent=label;svg.append(element);};
  if(multiRest){staves.forEach(stave=>{const y=stave.getYForLine(2),left=index===multiRest.start?x+Math.min(25,barWidth/5):x,right=index===multiRest.end?x+barWidth-Math.min(25,barWidth/5):x+barWidth;const path=document.createElementNS('http://www.w3.org/2000/svg','path');path.setAttribute('d',`M${left} ${y}H${right}${index===multiRest.start?`M${left} ${y-7}V${y+7}`:''}${index===multiRest.end?`M${right} ${y-7}V${y+7}`:''}`);path.setAttribute('fill','none');path.setAttribute('stroke','#111');path.setAttribute('stroke-width','4');path.setAttribute('class','notation-multi-rest');svg.append(path);});if(index===multiRest.start)addLabel(String(multiRest.count),staves[0].getYForLine(0)-8,12);}
  const repeat=bar.repeat||{};
  if(repeat.endings?.length){
   const ending=repeat.endings.join(','),previous=options.sheet.score.measures[index-1]?.repeat?.endings?.join(','),next=options.sheet.score.measures[index+1]?.repeat?.endings?.join(','),y=staves[0].getY()-8;
   const left=x+(previous===ending&&col>0?0:14),right=x+barWidth-(next===ending&&col<bars.length-1?0:10),line=document.createElementNS('http://www.w3.org/2000/svg','path');
   line.setAttribute('d',`M${left} ${y+7}V${y}H${right}${next===ending?'':`V${y+7}`}`);line.setAttribute('fill','none');line.setAttribute('stroke','#111');line.setAttribute('stroke-width','1');svg.append(line);
   if(previous!==ending||col===0)addLabel(ending+'.',y-2,10);
  }
  if(repeat.marker)addLabel(({segno:'Segno',coda:'Coda',toCoda:'To Coda',fine:'Fine'})[repeat.marker],staves[0].getY()-18,10);
  if(repeat.jump)addLabel(({dc:'D.C.',ds:'D.S.',dcAlFine:'D.C. al Fine',dsAlFine:'D.S. al Fine',dcAlCoda:'D.C. al Coda',dsAlCoda:'D.S. al Coda'})[repeat.jump],staves[0].getY()-30,10);
  if(repeatRegion&&repeatRegion.start===index){
   const center=repeatRegion.count===1?x+barWidth/2:x+barWidth;
   staves.forEach((stave,lane)=>centeredGlyph(ctx,svg,repeatRegion.count===1?'repeat1Bar':'repeat2Bars',center,stave.getYForLine(2),'notation-measure-repeat',{'data-bar':index,'data-staff':lane+1,'data-repeat-count':repeatRegion.count,'data-center-x':center,'data-center-y':stave.getYForLine(2)}));
   if(repeatRegion.count===2){const label=document.createElementNS('http://www.w3.org/2000/svg','text');for(const[k,v]of Object.entries({x:center,y:staves[0].getYForLine(0)-9,'text-anchor':'middle','font-family':'NotationTheme, Arial','font-size':12,fill:'#111','class':'notation-repeat-count'}))label.setAttribute(k,String(v));label.textContent='2';svg.append(label);}
  }
  if(bar.rehearsal)addLabel(bar.rehearsal,staves[0].getY()-53,12);
  if(bar.text)addLabel(bar.text,staves[0].getY()-66,10);
  const currentUnit=M.effectiveTempoUnit(options.sheet,index),previousUnit=M.effectiveTempoUnit(options.sheet,index-1),unitChanged=currentUnit.tempo_note!==previousUnit.tempo_note||currentUnit.tempo_dots!==previousUnit.tempo_dots,segment=M.tempoSegment(options.sheet,index),previousBpm=index?M.tempoSegment(options.sheet,index-1).final:Number(m.bpm),tempoChanged=!!bar.tempo&&(segment.initial!==previousBpm||segment.final!==segment.initial);
  if((unitChanged||tempoChanged||selectedHint)&&!(index===0&&(!bar.tempo||bar.tempo.mode==='instant'))){
   const ns='http://www.w3.org/2000/svg',label=document.createElementNS(ns,'g'),scale=options.pixels/width,reference=target.closest('.shell')?.querySelector('.score-title .metronome-mark'),font=reference?parseFloat(getComputedStyle(reference).fontSize):10,fontSize=font/scale;let offset=0;
   for(const[key,value]of Object.entries({'font-family':'NotationTheme, Arial','font-size':fontSize,fill:'#111','class':'notation-tempo-change','data-bar':index,'data-staff-top':staves[0].getYForLine(0),'data-note-start':noteStart}))label.setAttribute(key,String(value));svg.append(label);
   const unit=M.effectiveTempoUnit(options.sheet,index),bpm=bar.tempo?.mode==='aTempo'?m.bpm:bar.tempo?.bpm||M.tempoSegment(options.sheet,index).initial,part=(text,field,faint)=>{const span=document.createElementNS(ns,'text');span.textContent=text;span.setAttribute('x',String(offset));span.setAttribute('y','0');span.setAttribute('fill',faint?'#c4c4c4':'#111');span.setAttribute('class','notation-measure-'+field);label.append(span);offset+=span.getBBox().width;if(field)tempoTargets.push({span,field});};
   if(!bar.tempo||bar.tempo.mode==='instant'||selectedHint){const holder=document.createElement('div');holder.innerHTML=root.NotationSymbols.note(unit.tempo_note);const icon=holder.firstElementChild,w=(reference?.querySelector('.note-glyph')?.getBoundingClientRect().width||14)/scale,h=(reference?.querySelector('.note-glyph')?.getBoundingClientRect().height||19)/scale,group=document.createElementNS(ns,'g');group.setAttribute('class','notation-measure-tempo_unit');group.setAttribute('color',selectedHint&&!bar.tempo_unit?'#c4c4c4':'#111');group.setAttribute('fill',selectedHint&&!bar.tempo_unit?'#c4c4c4':'#111');icon.setAttribute('width',String(w));icon.setAttribute('height',String(h));icon.setAttribute('y',String(-h/2-fontSize/3));icon.style.width=w+'px';icon.style.height=h+'px';group.append(icon);label.append(group);offset=w;if(unit.tempo_dots){const head=new DOMPoint(0,0).matrixTransform(icon.querySelector('text').getScreenCTM()).matrixTransform(group.getScreenCTM().inverse());for(let dot=0;dot<unit.tempo_dots;dot++){const circle=document.createElementNS(ns,'circle');circle.setAttribute('class','notation-tempo-dot');circle.setAttribute('cx',String(w-4/scale+dot*fontSize*.32));circle.setAttribute('cy',String(head.y));circle.setAttribute('r',String(fontSize*.09));circle.setAttribute('fill',selectedHint&&!bar.tempo_unit?'#c4c4c4':'#111');group.append(circle);}offset=Math.max(offset,w-4/scale+(unit.tempo_dots-1)*fontSize*.32+fontSize*.09);}tempoTargets.push({span:group,field:'tempo_unit'});offset+=4/scale;part('= '+bpm,'tempoBpm',selectedHint&&!bar.tempo);}else{part(({ritardando:'rit. \u2192 ',accelerando:'accel. \u2192 ',aTempo:'a tempo'})[bar.tempo.mode],'',false);if(bar.tempo.mode!=='aTempo')part(String(bpm),'tempoBpm',false);}
   label.setAttribute('transform','translate('+noteStart+' '+(staves[0].getYForLine(0)-14/scale-label.getBBox().y-label.getBBox().height)+')');
  }
  const previewTargets=[],generatedRests=[],fingerings=[],engravedNotes=Array(bar.notes.length),voices=[],beams=[],tuplets=[],crossGroups=new Map(),crossCounts=new Map(),manualGroups=new Map(),manualCounts=new Map();
  bar.notes.forEach(note=>{if(note.crossBeam&&!note.rest&&M.staffOf(note)<=layout.length)crossCounts.set(note.crossBeam,(crossCounts.get(note.crossBeam)||0)+1);});
  bar.notes.forEach(note=>{if(note.beamGroup&&!note.rest&&M.staffOf(note)<=layout.length)manualCounts.set(note.beamGroup,(manualCounts.get(note.beamGroup)||0)+1);});
  staves.forEach((stave,lane)=>{
   if(multiRest||repeatRegion)return;
   const staff=lane+1,all=bar.notes.map((n,i)=>({...n,index:i,at:M.positionOf(bar,i)})).filter(n=>M.staffOf(n)===staff),voiceIds=[...new Set(all.map(M.voiceOf))];
   if(!all.length)centeredGlyph(ctx,svg,'restWhole',(stave.getNoteStartX()+stave.getNoteEndX())/2,stave.getYForLine(1),'notation-measure-rest',{'data-bar':index,'data-staff':staff,'data-units':M.barUnits(options.sheet,index)},true);
   const displayAccidentals=measureAccidentals(options.sheet,index,staff);
   const ghost=!options.printing&&index===options.ghostBar&&options.ghost&&M.staffOf(options.ghost)===staff?options.ghost:null;
   if(ghost&&!voiceIds.length)previewTargets.push({stave,n:ghost,x:stave.getNoteStartX()+12});
   for(const voiceId of voiceIds){
   const stored=all.filter(n=>M.voiceOf(n)===voiceId).sort((a,b)=>a.at-b.at||a.index-b.index),source=completedVoice(stored,options.sheet,index,staff,voiceId);
   const notes=[],actual=[],noteTimes=new Map();let cursor=0,tupletGroup=[],tupletRatio='';
   const finishTuplet=()=>{if(tupletGroup.length){const[actualCount,normalCount]=tupletRatio.split(':').map(Number);tuplets.push(new VF.Tuplet(tupletGroup,{num_notes:actualCount,notes_occupied:normalCount}));tupletGroup=[];tupletRatio='';}};
   source.forEach(n=>{
    if(n.at>cursor)notes.push(...spacingNotes(n.at-cursor));
    const tones=[{pitch:n.pitch,accidental:n.accidental},...(n.pitches||[])],display=ottava(n.pitch,n.rest);
    const noteClef=M.clefAt(options.sheet,index,staff,n.at),restKey=({treble:'b/4',bass:'d/3',alto:'c/4',tenor:'a/3',soprano:'g/4','mezzo-soprano':'e/4','baritone-f':'f/3'})[noteClef.split('_')[0]]||'b/4';
    const keys=n.rest?[restKey]:tones.map(tone=>{const shifted=ottava(tone.pitch);return shifted.pitch[0].toLowerCase()+'/'+shifted.pitch.slice(1);});
    const NoteClass=n.noteSize&&!n.rest?SmallStaveNote:VF.StaveNote;
    const v=new NoteClass({clef:noteClef.split('_')[0],keys,duration:n.duration+(n.rest?'r':''),dots:n.dots||0,auto_stem:true});
    if(n.graces?.length){const graceNotes=n.graces.map((grace,graceIndex)=>{const p=ottava(grace.pitch).pitch,small=new VF.GraceNote({clef:noteClef.split('_')[0],keys:[p[0].toLowerCase()+'/'+p.slice(1)],duration:grace.duration||'8',slash:grace.kind==='acciaccatura'});if(displayAccidentals.get(n.index)?.graces[graceIndex])for(const value of accidentalParts(displayAccidentals.get(n.index).graces[graceIndex]))small.addModifier(new VF.Accidental(value),0);return small;});v.addModifier(new VF.GraceNoteGroup(graceNotes,true).beamNotes(),0);}
    octaveNotes.push({note:v,staff,...display});
    if(!n.rest)v.setStemDirection(v.getKeyProps()[0].line<=3?VF.Stem.UP:VF.Stem.DOWN);
    if(!n.rest)tones.forEach((tone,i)=>{if(displayAccidentals.get(n.index)?.tones[i])for(const value of accidentalParts(displayAccidentals.get(n.index).tones[i])){const accidental=new VF.Accidental(value);if((i===0?n.cautionary:tone.cautionary)&&accidental.setAsCautionary)accidental.setAsCautionary();v.addModifier(accidental,i);}});
    for(let d=0;d<(n.dots||0);d++)VF.Dot.buildAndAttach([v],{all:true});
    const art={staccato:'a.',tenuto:'a-',accent:'a>',marcato:'a^',staccatissimo:'av'};
    if(art[n.articulation])v.addModifier(new VF.Articulation(art[n.articulation]).setPosition(VF.Modifier.Position.ABOVE),0);
    if(['fermata','breath','caesura'].includes(n.articulation))v.addModifier(new VF.Annotation(({fermata:'𝄐',breath:',',caesura:'//'})[n.articulation]).setFont('Arial',15).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
    if(n.ornament){const ornament={trill:'tr',mordent:'mordent',invertedMordent:'mordent_inverted',turn:'turn',invertedTurn:'turn_inverted'}[n.ornament];if(ornament){const symbol=new VF.Ornament(ornament);if(n.ornamentUpperAccidental)symbol.setUpperAccidental(n.ornamentUpperAccidental);if(n.ornamentLowerAccidental)symbol.setLowerAccidental(n.ornamentLowerAccidental);v.addModifier(symbol,0);}}
    if(n.tremolo)v.addModifier(new VF.Tremolo(n.tremolo),0);
    if(n.harmonic?.kind==='natural')v.addModifier(new VF.Annotation('○').setFont('NotationTheme',16).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
    if(n.arpeggio&&n.pitches?.length)v.addModifier(new VF.Stroke(n.arpeggio==='down'?VF.Stroke.Type.ROLL_DOWN:VF.Stroke.Type.ROLL_UP),0);
    if(!n.rest&&[n,...(n.pitches||[])].some(tone=>tone.finger))fingerings.push({note:v,n,stave,staff});
    if(n.bow)v.addModifier(new VF.Annotation(n.bow==='up'?'∨':'⊓').setFont('Arial',13).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
    if(n.dynamic)v.addModifier(new VF.Annotation(n.dynamic).setFont('Times',12,'italic').setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);
    if(n.lyric)v.addModifier(new VF.Annotation(n.lyric).setFont('NotationTheme',11).setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);
    if(n.chordSymbol)v.addModifier(new VF.Annotation(n.chordSymbol).setFont('NotationTheme',11).setVerticalJustification(VF.Annotation.VerticalJustify.TOP),0);
    if(n.pedal){const label={sustainDown:'Ped.',sustainUp:'✱',sostenutoDown:'Sost.',sostenutoUp:'✱',unaCorda:'una corda',treCorde:'tre corde'}[n.pedal];if(label)v.addModifier(new VF.Annotation(label).setFont('Times',11,'italic').setVerticalJustification(VF.Annotation.VerticalJustify.BOTTOM),0);}
    noteTimes.set(v,{at:n.at,units:M.units(n),flagged:!n.rest&&M.durations[n.duration]<=8});
    if(n.synthetic)generatedRests.push({note:v,n});
    if(ghost&&M.voiceOf(ghost)===voiceId&&n.synthetic&&!previewTargets.some(item=>item.stave===stave))previewTargets.push({stave,n:ghost,anchor:v});
    const color=options.printing?'#111':n.ghost?'#d5d5d5':options.selectedNotes?.has(index+':'+n.index)||index===options.activeBar&&n.index===options.activeNote?options.accent:'#111';
    v.setStyle({fillStyle:color,strokeStyle:color});if(n.index>=0)engravedNotes[n.index]=v;notes.push(v);if(!n.ghost){if(n.crossBeam&&crossCounts.get(n.crossBeam)>1){const group=crossGroups.get(n.crossBeam)||[];group.push({note:v,at:n.at});crossGroups.set(n.crossBeam,group);}else if(n.beamGroup&&manualCounts.get(n.beamGroup)>1){const group=manualGroups.get(n.beamGroup)||[];group.push({note:v,at:n.at});manualGroups.set(n.beamGroup,group);}else actual.push(v);}cursor=n.at+M.units(n);
    const ratio=n.tuplet?`${n.tuplet.actual}:${n.tuplet.normal}`:'';
    if(ratio!==tupletRatio)finishTuplet();
    if(ratio){tupletRatio=ratio;tupletGroup.push(v);if(tupletGroup.length===n.tuplet.actual)finishTuplet();}
   });
   finishTuplet();
   if(notes.length){const[beats,beatValue]=barTime.split('/').map(Number),voice=new VF.Voice({num_beats:beats,beat_value:beatValue}).setStrict(false);voice.addTickables(notes);voices.push({voice,stave});beams.push(...rhythmicBeams(actual,noteTimes,options.sheet,index));}
   }
  });
  // Attach manual beams before formatting/drawing so their notes suppress standalone flags.
  for(const group of crossGroups.values())if(group.length>1)beams.push(new VF.Beam(group.sort((a,b)=>a.at-b.at).map(item=>item.note)));
  for(const group of manualGroups.values())if(group.length>1)beams.push(notationBeam(group.sort((a,b)=>a.at-b.at).map(item=>item.note)));
  if(voices.length){const formatter=new VF.Formatter();staves.forEach(stave=>{const same=voices.filter(v=>v.stave===stave).map(v=>v.voice);if(same.length)formatter.joinVoices(same);});formatter.format(voices.map(v=>v.voice),Math.max(20,staves[0].getNoteEndX()-noteStart-12));voices.forEach(({voice,stave})=>{ctx.openGroup('notation-staff-'+(staves.indexOf(stave)+1));voice.draw(ctx,stave);ctx.closeGroup();});beams.forEach(beam=>beam.setContext(ctx).draw());tuplets.forEach(tuplet=>tuplet.setContext(ctx).draw());}
  // Place fingering after beam drawing, when the final stem endpoints are known.
  for(const {note,n,stave,staff}of fingerings){
   const top=stave.getYForLine(0),spacing=stave.getYForLine(1)-top,gap=4*width/options.pixels,stemTop=note.hasStem()?Math.min(note.getStemExtents().topY,note.getStemExtents().baseY):top;
   const bottom=note.getStemDirection()===VF.Stem.UP&&stemTop<top?stemTop-gap:top-spacing,center=(note.getNoteHeadBeginX()+note.getNoteHeadEndX())/2,group=note.getSVGElement?.()||svg;
   const tones=[n,...(n.pitches||[])].map((tone,index)=>({tone,index})).filter(({tone})=>tone.finger);
   tones.forEach(({tone,index},lane)=>{const text=document.createElementNS('http://www.w3.org/2000/svg','text');for(const[key,value]of Object.entries({x:center,y:0,'text-anchor':'middle','font-family':'NotationTheme, Arial','font-size':12,fill:options.printing?'#111':note.getStyle()?.fillStyle||'#111','class':'notation-fingering','data-bar':start+bars.indexOf(bar),'data-note':n.index,'data-tone':index,'data-spacing-staff':staff}))text.setAttribute(key,String(value));text.textContent=tone.finger;group.append(text);const box=text.getBBox();text.setAttribute('y',String(bottom-lane*14-box.y-box.height));});
  }
  for(const [i,note]of engravedNotes.entries()){const group=note?.getSVGElement?.()||note&&svg.querySelector('#vf-'+note.getAttribute('id'));if(group){group.dataset.playbackBar=String(index);group.dataset.playbackNote=String(i);}}
  for(const {note,n} of generatedRests){const group=note.getSVGElement?.()||svg.querySelector('#vf-'+note.getAttribute('id'));if(group){group.classList.add('notation-auto-rest');for(const[k,value]of Object.entries({'data-bar':index,'data-staff':n.staff,'data-voice':n.voice,'data-at':n.at,'data-units':M.units(n),'data-duration':n.duration,'data-dots':n.dots||0}))group.setAttribute(k,String(value));}}
  for(const item of previewTargets)previewNote(ctx,item.stave,item.n,item.x||item.anchor.getAbsoluteX()+14);
  for(const event of bar.clefChanges||[]){const stave=staves[event.staff-1];if(!stave)continue;const anchors=bar.notes.map((note,i)=>({note,at:M.positionOf(bar,i),box:engravedNotes[i]?.getBoundingBox()})).filter(item=>M.staffOf(item.note)===event.staff&&item.box).sort((a,b)=>a.at-b.at),after=anchors.find(item=>item.at>=event.at),before=[...anchors].reverse().find(item=>item.at<event.at),position=after?after.box.getX()-22:before?before.box.getX()+before.box.getW()+18:stave.getNoteStartX()+20,markerX=Math.max(stave.getNoteStartX()+2,Math.min(x+barWidth-24,position)),marker=new VF.ClefNote(event.clef.split('_')[0],'small',event.clef.split('_')[1]);marker.setStave(stave).setContext(ctx);marker.getAbsoluteX=()=>markerX;ctx.openGroup('notation-timed-clef');marker.draw();ctx.closeGroup();}
  engraved.push({notes:engravedNotes,ctx,row:target,svg});
  if(!options.printing){
   const hit=(attributes)=>{const rect=document.createElementNS('http://www.w3.org/2000/svg','rect');for(const[k,v]of Object.entries({fill:'transparent',stroke:'none','class':'note-hit',...attributes}))rect.setAttribute(k,String(v));svg.append(rect);};
   staves.forEach((stave,lane)=>hit({x,y:stave.getY()+10,width:barWidth,height:grand?Math.min(100,staffStep-12):100,'data-bar':index,'data-staff':lane+1}));
   engravedNotes.forEach((note,i)=>{const box=note?.getBoundingBox();if(box)hit({x:box.getX()-4,y:box.getY()-6,width:Math.max(22,box.getW()+8),height:Math.max(38,box.getH()+12),'data-bar':index,'data-staff':M.staffOf(bar.notes[i]),'data-note':i,'data-note-selected':options.selectedNotes?.has(index+':'+i)?'true':'false'});});
   if(options.sheet.editable&&!options.continuousSignatures)for(const {span,field} of tempoTargets){const box=span.getBBox();hit({x:box.x-3,y:box.y-4,width:Math.max(12,box.width+6),height:box.height+8,'class':'notation-signature-hit','data-tempo-hit':index,'data-signature-field':field,'data-bar':index,'data-staff':1,role:'button',tabindex:0,'aria-haspopup':'dialog','aria-expanded':'false'});}
   if(options.sheet.editable&&!options.continuousSignatures)staves.forEach((stave,lane)=>{for(const modifier of stave.getModifiers()){const category=modifier.getCategory();if(!['Clef','KeySignature','TimeSignature'].includes(category))continue;hit({x:modifier.getX()-2,y:stave.getYForLine(0)-24,width:Math.max(10,modifier.getWidth()+4),height:88,'class':'notation-signature-hit','data-signature-field':category==='Clef'?'clef'+(lane+1):category==='TimeSignature'?'time':'key','data-signature-value':category==='Clef'?clefs[lane]:category==='TimeSignature'?barTime:barKey,'data-bar':index,'data-staff':lane+1,role:'button',tabindex:0,'aria-haspopup':'listbox','aria-expanded':'false'});}});

  }
 });
 // Brackets continue over adjacent notes and bars, with a fresh label on each row.
 const add=(tag,attrs,text)=>{const el=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const[k,v]of Object.entries(attrs))el.setAttribute(k,String(v));if(text)el.textContent=text;svg.append(el);};
 let run=[];
 const bracket=()=>{if(!run.length)return;const first=run[0],boxes=run.map(n=>n.note.getBoundingBox()).filter(Boolean);if(!boxes.length){run=[];return;}
  const x=boxes[0].getX(),end=Math.min(width-4,boxes.at(-1).getX()+boxes.at(-1).getW()+10),y=first.below?Math.max(...boxes.map(b=>b.getY()+b.getH()))+14:Math.min(...boxes.map(b=>b.getY()))-14;
  add('text',{x,y,'font-size':10,'font-family':'Arial',fill:'#111','class':'ottava-label','data-spacing-staff':first.staff},first.label);
  const lineStart=Math.min(x+28,end-2);add('path',{d:'M'+lineStart+' '+(y-3)+'H'+end+'v'+(first.below?-5:5),fill:'none',stroke:'#111','stroke-width':.8,'stroke-dasharray':'3 2','class':'ottava-line','data-spacing-staff':first.staff});run=[];
 };
 for(const entry of octaveNotes){if(!entry.label||run.length&&(run[0].label!==entry.label||run[0].staff!==entry.staff))bracket();if(entry.label)run.push(entry);}bracket();
 const bounds=svg.getBBox(),top=Math.min(0,bounds.y-5),bottom=Math.max(height,bounds.y+bounds.height+5),total=bottom-top;
 svg.setAttribute('viewBox',`0 ${top} ${width} ${total}`);if(!options.printing)svg.setAttribute('height',String(total*options.pixels/width));
 if(grand&&!options.printing&&!options.spacingResolved){
  const ink=staff=>[...svg.querySelectorAll('[class*="notation-staff-'+staff+'"],[data-spacing-staff="'+staff+'"]')].map(node=>node.getBBox()).filter(b=>b.width&&b.height);
  const upper=ink(1),lower=ink(2),extra=bars.some(bar=>bar.notes.some(n=>M.staffOf(n)===1&&(n.pedal||n.octaveShift)))?24:0;
  if(upper.length&&lower.length){const overlap=Math.max(...upper.map(b=>b.y+b.height))+extra+10-Math.min(...lower.map(b=>b.y));if(overlap>0){target.replaceChildren();return renderRow(target,bars,start,{...options,staffStep:staffStep+Math.ceil(overlap),spacingResolved:true});}}
 }
 return engraved;
}
function ties(sheet,engraved){
 const previous=new Map();let barStart=0;
 sheet.score.measures.forEach((bar,b)=>{
  bar.notes.map((note,i)=>({note,i,at:M.positionOf(bar,i)})).sort((a,b)=>a.at-b.at||a.i-b.i).forEach(({note,i,at})=>{
   const staff=M.staffOf(note),voice=M.voiceOf(note),start=barStart+at,end=start+M.units(note),current={v:engraved[b]?.notes[i],ctx:engraved[b]?.ctx,row:engraved[b]?.row};
   if(note.rest){for(const key of previous.keys())if(key.startsWith(staff+':'+voice+':'))previous.delete(key);return;}
   [{pitch:note.pitch,tiePrevious:note.tiePrevious,tieNext:note.tieNext},...(note.pitches||[]).map(tone=>({pitch:tone.pitch,tiePrevious:tone.tiePrevious??note.tiePrevious,tieNext:tone.tieNext??note.tieNext}))].forEach((tone,index)=>{
    const key=staff+':'+voice+':'+tone.pitch,last=previous.get(key);
    if(tone.tiePrevious&&last?.tieNext&&last.end===start&&last.v&&current.v){
     const drawTie=(first,final,firstIndex,lastIndex,ctx)=>new VF.StaveTie({first_note:first,last_note:final,first_indices:[firstIndex],last_indices:[lastIndex]}).setContext(ctx).draw();
     if(last.row===current.row)drawTie(last.v,current.v,last.index,index,current.ctx);
     else{drawTie(last.v,null,last.index,index,last.ctx);drawTie(null,current.v,last.index,index,current.ctx);}
    }
    previous.set(key,{...current,index,end,tieNext:!!tone.tieNext});
   });
  });
  barStart+=M.barUnits(sheet,b);
 });
}
function slurs(sheet,engraved){
 const starts=new Map();
 const arc=(svg,x1,y1,x2,y2)=>{const path=document.createElementNS('http://www.w3.org/2000/svg','path'),bend=Math.max(14,Math.abs(x2-x1)*.12);path.setAttribute('d',`M${x1} ${y1} Q${(x1+x2)/2} ${Math.min(y1,y2)-bend} ${x2} ${y2}`);path.setAttribute('fill','none');path.setAttribute('stroke','#111');path.setAttribute('stroke-width','1.2');path.setAttribute('class','notation-slur');svg.append(path);};
 sheet.score.measures.forEach((bar,b)=>bar.notes.map((note,i)=>({note,i,at:M.positionOf(bar,i)})).sort((a,c)=>a.at-c.at||a.i-c.i).forEach(({note,i})=>{
  const key=M.staffOf(note)+':'+M.voiceOf(note),current=engraved[b],box=current?.notes[i]?.getBoundingBox();if(!box)return;
  const x=box.getX()+box.getW()/2,y=box.getY()-8,earlier=starts.get(key);
  if(note.slurEnd&&earlier){if(earlier.svg===current.svg)arc(current.svg,earlier.x,earlier.y,x,y);else{const leftWidth=Number(earlier.svg.viewBox.baseVal.width),rightWidth=Number(current.svg.viewBox.baseVal.width);arc(earlier.svg,earlier.x,earlier.y,leftWidth-8,earlier.y);arc(current.svg,8,y,x,y);}starts.delete(key);}
  if(note.slurStart)starts.set(key,{svg:current.svg,x,y});
 }));
}
function pedalLines(sheet,engraved){
 const active=new Map(),markers=[];let start=0;
 sheet.score.measures.forEach((bar,b)=>{bar.notes.forEach((note,i)=>{if(note.pedal&&engraved[b]?.notes[i])markers.push({time:start+M.positionOf(bar,i),kind:note.pedal,view:engraved[b],box:engraved[b].notes[i].getBoundingBox()});});start+=M.barUnits(sheet,b);});
 markers.sort((a,b)=>a.time-b.time);
 const path=(view,x1,x2,y,begin,end)=>{if(x2<=x1)return;const element=document.createElementNS('http://www.w3.org/2000/svg','path');element.setAttribute('d',`M${x1} ${y+(begin?0:-4)}${begin?'v-4':''}H${x2}${end?'v4':''}`);element.setAttribute('fill','none');element.setAttribute('stroke','#111');element.setAttribute('stroke-width','1');element.setAttribute('class','notation-pedal-line');view.svg.append(element);};
 const close=(first,last)=>{if(first.view.svg===last.view.svg){const y=Math.max(first.box.getY()+first.box.getH(),last.box.getY()+last.box.getH())+28;path(first.view,first.box.getX(),last.box.getX(),y,true,true);return;}let begin=engraved.indexOf(first.view),finish=engraved.indexOf(last.view);for(let i=begin;i<=finish;i++){const view=engraved[i],width=Number(view.svg.viewBox.baseVal.width),y=(i===begin?first.box.getY()+first.box.getH():i===finish?last.box.getY()+last.box.getH():view.notes.find(Boolean)?.getBoundingBox()?.getY()+80||90)+28;path(view,i===begin?first.box.getX():8,i===finish?last.box.getX():width-8,y,i===begin,i===finish);}};
 for(const marker of markers){const key=marker.kind.startsWith('sostenuto')?'sostenuto':marker.kind.startsWith('sustain')?'sustain':null;if(!key)continue;if(marker.kind.endsWith('Down'))active.set(key,marker);else if(active.has(key)){close(active.get(key),marker);active.delete(key);}}
 for(const marker of active.values()){const view=engraved.at(-1);if(view){const width=Number(view.svg.viewBox.baseVal.width),last={view,box:{getX:()=>width-8,getY:()=>marker.box.getY(),getH:()=>marker.box.getH()}};close(marker,last);}}
}
function hairpins(sheet,engraved){
 const active=new Map();
 const line=(view,x1,x2,y,type)=>{if(x2<=x1)return;const spread=6,path=document.createElementNS('http://www.w3.org/2000/svg','path');path.setAttribute('d',type==='crescendo'?`M${x1} ${y}L${x2} ${y-spread}M${x1} ${y}L${x2} ${y+spread}`:`M${x1} ${y-spread}L${x2} ${y}M${x1} ${y+spread}L${x2} ${y}`);path.setAttribute('fill','none');path.setAttribute('stroke','#111');path.setAttribute('stroke-width','1');path.setAttribute('class','notation-hairpin');view.svg.append(path);};
 sheet.score.measures.forEach((bar,b)=>bar.notes.map((note,i)=>({note,i,at:M.positionOf(bar,i)})).sort((a,c)=>a.at-c.at||a.i-c.i).forEach(({note,i})=>{
  if(!note.hairpin)return;const view=engraved[b],box=view?.notes[i]?.getBoundingBox();if(!box)return;const key=M.staffOf(note)+':'+M.voiceOf(note),x=box.getX()+box.getW()/2,y=box.getY()+box.getH()+24;
  if(note.hairpin==='stop'){const start=active.get(key);if(!start)return;const first=engraved.indexOf(start.view),last=engraved.indexOf(view);for(let at=first;at<=last;at++){const segment=engraved[at],w=Number(segment.svg.viewBox.baseVal.width);line(segment,at===first?start.x:8,at===last?x:w-8,at===first?start.y:y,start.type);}active.delete(key);}
  else active.set(key,{view,x,y,type:note.hairpin});
 }));
}
function octaveLines(sheet,engraved){
 const active=new Map();const segment=(view,x1,x2,y,label,first,last)=>{if(x2<=x1)return;const svg=view.svg,text=document.createElementNS('http://www.w3.org/2000/svg','text'),path=document.createElementNS('http://www.w3.org/2000/svg','path');if(first){text.setAttribute('x',String(x1));text.setAttribute('y',String(y-3));text.setAttribute('font-size','11');text.setAttribute('font-family','NotationTheme, Arial');text.textContent=label;svg.append(text);}path.setAttribute('d',`M${x1+(first?25:0)} ${y}H${x2}${last?'v5':''}`);path.setAttribute('fill','none');path.setAttribute('stroke','#111');path.setAttribute('stroke-width','1');path.setAttribute('stroke-dasharray','4 3');path.setAttribute('class','notation-octave-line');svg.append(path);};
 sheet.score.measures.forEach((bar,b)=>bar.notes.map((note,i)=>({note,i,at:M.positionOf(bar,i)})).sort((a,c)=>a.at-c.at||a.i-c.i).forEach(({note,i})=>{if(!note.octaveShift)return;const view=engraved[b],box=view?.notes[i]?.getBoundingBox();if(!box)return;const key=M.staffOf(note)+':'+M.voiceOf(note),x=box.getX()+box.getW()/2;
  if(note.octaveShift==='stop'){const start=active.get(key);if(!start)return;const first=engraved.indexOf(start.view),last=engraved.indexOf(view);for(let at=first;at<=last;at++){const item=engraved[at],width=Number(item.svg.viewBox.baseVal.width);segment(item,at===first?start.x:8,at===last?x:width-8,start.y,start.label,at===first,at===last);}active.delete(key);}
  else active.set(key,{view,x,y:note.octaveShift.endsWith('vb')?box.getY()+box.getH()+34:box.getY()-23,label:note.octaveShift});
 }));
}
function slides(sheet,engraved){
 const entries=sheet.score.measures.flatMap((bar,b)=>bar.notes.map((note,i)=>({note,b,i,at:M.positionOf(bar,i)}))).sort((a,c)=>a.b-c.b||a.at-c.at||a.i-c.i);
 const segment=(view,x1,y1,x2,y2,kind)=>{if(x2<=x1)return;const svg=view.svg,path=document.createElementNS('http://www.w3.org/2000/svg','path'),steps=kind==='glissando'?Math.max(6,Math.round((x2-x1)/8)):1;let d=`M${x1} ${y1}`;for(let n=1;n<=steps;n++){const ratio=n/steps;d+=`L${x1+(x2-x1)*ratio} ${y1+(y2-y1)*ratio+(n===steps?0:kind==='glissando'?(n%2?3:-3):0)}`;}path.setAttribute('d',d);path.setAttribute('fill','none');path.setAttribute('stroke','#111');path.setAttribute('stroke-width','1');path.setAttribute('class','notation-slide');svg.append(path);};
 for(let n=0;n<entries.length;n++){const first=entries[n];if(!first.note.slide)continue;const last=entries.slice(n+1).find(item=>M.staffOf(item.note)===M.staffOf(first.note)&&M.voiceOf(item.note)===M.voiceOf(first.note)&&!item.note.rest);if(!last)continue;const a=engraved[first.b],z=engraved[last.b],from=a?.notes[first.i]?.getBoundingBox(),to=z?.notes[last.i]?.getBoundingBox();if(!from||!to)continue;const x1=from.getX()+from.getW(),y1=from.getY()+from.getH()/2,x2=to.getX(),y2=to.getY()+to.getH()/2;if(a.svg===z.svg)segment(a,x1,y1,x2,y2,first.note.slide);else{const start=engraved.indexOf(a),end=engraved.indexOf(z);for(let b=start;b<=end;b++){const view=engraved[b],width=Number(view.svg.viewBox.baseVal.width);segment(view,b===start?x1:8,b===start?y1:y2,b===end?x2:width-8,b===end?y2:y1,first.note.slide);}}}
}
function fitDecorations(engraved,printing){for(const svg of new Set(engraved.map(item=>item.svg))){
 if(!svg)continue;const previous=svg.viewBox.baseVal;
 if(printing){const bounds=svg.getBBox(),top=Math.min(previous.y,bounds.y-5),bottom=Math.max(previous.y+previous.height,bounds.y+bounds.height+5),height=bottom-top;if(height>previous.height+.1)svg.setAttribute('viewBox',`0 ${top} ${previous.width} ${height}`);continue;}
 // Selection backgrounds and generous hit targets must not reserve blank space.
 const targets=[...svg.querySelectorAll('.note-hit,.notation-signature-hit,[class*="notation-active-background"]')],display=targets.map(n=>n.style.display);let bounds;
 try{targets.forEach(n=>n.style.display='none');bounds=svg.getBBox();}finally{targets.forEach((n,i)=>n.style.display=display[i]);}
 const base=Number(svg.dataset.baseHeight),scale=Number(svg.dataset.screenScale),letterbox=Number(svg.dataset.legacyHeight)*(1/scale-1),frameTop=-letterbox/2,frameBottom=base+letterbox/2,inkBottom=bounds.y+bounds.height,topBlank=Math.max(0,bounds.y-frameTop),bottomBlank=Math.max(0,frameBottom-inkBottom);
 const top=Math.min(bounds.y-5,frameTop+topBlank/2),bottom=Math.max(inkBottom+5,frameBottom-bottomBlank/2),height=bottom-top;
 svg.dataset.originalBlank=String(topBlank+bottomBlank);svg.dataset.compactBlank=String(bounds.y-top+bottom-inkBottom);
 svg.setAttribute('viewBox',`0 ${top} ${previous.width} ${height}`);svg.setAttribute('height',String(height*scale));svg.style.height=height*scale+'px';
}}

function alignMeasureTempos(element){
 const reference=element.closest('.shell')?.querySelector('.score-title .metronome-mark'),first=element.querySelector('svg');if(!reference||!first)return;const matrix=first.getScreenCTM();if(!matrix)return;const gap=Math.max(0,matrix.f+46*matrix.d-reference.getBoundingClientRect().bottom)/3;
 for(const label of element.querySelectorAll('.notation-tempo-change')){const svg=label.ownerSVGElement,scale=svg.getScreenCTM()?.d;if(!scale)continue;const box=label.getBBox(),x=Number(label.dataset.noteStart),y=Number(label.dataset.staffTop)-gap/scale-box.y-box.height;label.setAttribute('transform','translate('+x+' '+y+')');for(const hit of svg.querySelectorAll('[data-tempo-hit="'+label.dataset.bar+'"]')){hit.setAttribute('transform','translate('+x+' '+y+')');}}
}
function fitMeasureTempos(element){
 for(let pass=0;pass<10;pass++){alignMeasureTempos(element);let changed=false;for(const svg of element.querySelectorAll('.staff-row>svg')){const marks=[...svg.querySelectorAll('.notation-tempo-change')];if(!marks.length)continue;const frame=svg.viewBox.baseVal,min=Math.min(...marks.map(mark=>mark.getBBox().y+(mark.transform.baseVal.consolidate()?.matrix.f||0)))-6;if(min<frame.y-.1){const scale=svg.getScreenCTM()?.d||.68,height=frame.height+frame.y-min;svg.setAttribute('viewBox',[frame.x,min,frame.width,height].join(' '));svg.setAttribute('height',String(height*scale));svg.style.height=height*scale+'px';changed=true;}}if(!changed)break;}
}
function draw(element,sheet,options={}){
 element.replaceChildren();const pixels=Math.max(280,element.clientWidth),width=pixels/.68,measures=sheet.score.measures,engraved=[];
 let index=0;for(const bars of groups(measures,width,false,signatureReserve(sheet),sheet)){
  const row=document.createElement('div');row.className='staff-row';element.append(row);
  engraved.push(...renderRow(row,bars,index,{...options,sheet,metadata:sheet.metadata,width,pixels}));index+=bars.length;
 }ties(sheet,engraved);slurs(sheet,engraved);pedalLines(sheet,engraved);hairpins(sheet,engraved);octaveLines(sheet,engraved);slides(sheet,engraved);fitDecorations(engraved,false);fitMeasureTempos(element);const firstSvg=element.querySelector('svg');document.fonts?.ready.then(()=>{if(element.querySelector('svg')===firstSvg)fitMeasureTempos(element);});
}
// One horizontal system per instrument; all systems share physical bar widths.
function drawEnsemble(element,parts,options={}){
 const scrollLeft=element.scrollLeft;element.replaceChildren();element.classList.add('notation-ensemble');
 const count=Math.max(...parts.map(part=>Math.max(1,M.trimmedMeasures(part).length))),prefix=Math.max(...parts.map(signatureReserve))*2+170;
 const measureWidths=Array.from({length:count},(_,index)=>Math.max(210,...parts.map(part=>part.score.measures[index]?estimate(part.score.measures[index],0,part,index):210))+(index===0?prefix:0));
 const width=measureWidths.reduce((a,b)=>a+b,0)+38,pixels=width*.68;
 for(const[partIndex,part]of parts.entries()){
  const sheet=M.clone(part),written=M.trimmedMeasures(sheet);sheet.score.measures=Array.from({length:count},(_,index)=>written[index]||{notes:[],preserve:true});
  const lane=document.createElement('section');lane.className='notation-ensemble-part';lane.dataset.part=partIndex;lane.style.width=pixels+'px';
  const label=document.createElement('div');label.className='notation-ensemble-label';label.textContent=options.instrumentName?options.instrumentName(sheet.metadata,partIndex):sheet.metadata.instrument+' '+(partIndex+1);lane.append(label);
  const row=document.createElement('div');row.className='staff-row';lane.append(row);element.append(lane);
  const active=options.activeNotes?.[partIndex],engraved=renderRow(row,sheet.score.measures,0,{...options,sheet,metadata:sheet.metadata,width,pixels,measureWidths,continuousSignatures:true,leftInset:30,lastWritten:written.length-1,activeBar:active?.bar??-1,activeNote:active?.note??-1,selectedNotes:new Set()});
  ties(sheet,engraved);slurs(sheet,engraved);pedalLines(sheet,engraved);hairpins(sheet,engraved);octaveLines(sheet,engraved);slides(sheet,engraved);fitDecorations(engraved,false);
 }
 element.scrollLeft=scrollLeft;
}
// Recolor existing engraving without blocking the audio clock with score layout.
function updatePlayback(element,events,accent){
 for(const entry of element._playbackPaint||[]){entry.node.style.fill=entry.fill;entry.node.style.stroke=entry.stroke;}element._playbackPaint=[];
 element.querySelectorAll('[data-sounding]').forEach(node=>node.removeAttribute('data-sounding'));element.querySelectorAll('.playback-bar').forEach(node=>node.remove());
 const seen=new Set(),bars=new Set();for(const event of events){const scope=element.classList.contains('notation-ensemble')?element.querySelector('[data-part="'+event.part+'"]'):element;if(!scope)continue;const key=event.part+':'+event.bar+':'+event.note;if(seen.has(key))continue;seen.add(key);
 const group=scope.querySelector('[data-playback-bar="'+event.bar+'"][data-playback-note="'+event.note+'"]')||scope.querySelector('.notation-measure-repeat[data-bar="'+event.bar+'"]');if(group){group.dataset.sounding='true';for(const node of [group,...group.querySelectorAll('path,rect,ellipse,circle,line,polygon,text')]){const style=getComputedStyle(node);element._playbackPaint.push({node,fill:node.style.fill,stroke:node.style.stroke});if(!['none','transparent','rgba(0, 0, 0, 0)'].includes(style.fill))node.style.fill=accent;if(style.stroke!=='none')node.style.stroke=accent;}}
 const hit=scope.querySelector('.note-hit[data-bar="'+event.bar+'"][data-note="'+event.note+'"]');if(hit)hit.dataset.sounding='true';const barKey=event.part+':'+event.bar;if(bars.has(barKey))continue;bars.add(barKey);
 for(const hit of scope.querySelectorAll('.note-hit[data-bar="'+event.bar+'"]:not([data-note])')){const rect=document.createElementNS('http://www.w3.org/2000/svg','rect');for(const key of ['x','y','width','height'])rect.setAttribute(key,hit.getAttribute(key));rect.setAttribute('fill',accent+'14');rect.setAttribute('class','playback-bar notation-active-background');rect.setAttribute('pointer-events','none');hit.ownerSVGElement.insertBefore(rect,hit.ownerSVGElement.firstChild);}
 }
}
function metronomeUnit(metadata,symbols={}){const notes={w:'\u{1D15D}',h:'\u{1D15E}',q:'\u2669','8':'\u266A','16':'\u{1D161}','32':'\u{1D162}','64':'\u{1D163}','128':'\u{1D164}','256':'\u{1D165}'};return (symbols[metadata.tempo_note]||notes[metadata.tempo_note]||metadata.tempo_note)+'\u00b7'.repeat(Math.max(0,Math.min(2,Number(metadata.tempo_dots)||0)));}
function printDocument(sheet,locale='en',symbols={}){
 if(sheet.score.sections?.length||sheet.score.subsections?.length)return printDocument(M.joinSections(sheet),locale,symbols);
 if(sheet.score.parts?.length){const documents=M.parts(sheet).map((part,printPartIndex)=>printDocument({...part,printPart:true,printPartIndex},locale,symbols)),body=documents.map(html=>new DOMParser().parseFromString(html,'text/html').body.innerHTML).join(''),combined=new DOMParser().parseFromString(body,'text/html');combined.querySelectorAll('.print-page-number').forEach((node,i)=>node.textContent=String(i+1));return documents[0].replace(/<body>[\s\S]*<\/body>/,()=>'<body>'+combined.body.innerHTML+'</body>');}
 const trimmed=M.trimmedMeasures(sheet),measures=trimmed.length?trimmed:[sheet.score.measures[0]||{notes:[]}],rows=groups(measures,1000,true,signatureReserve(sheet),sheet),pages=[],engraved=[];let index=0;
 const printInstrument=symbols.instrumentName?symbols.instrumentName(sheet.metadata,sheet.printPartIndex):sheet.metadata.instrument+' '+((sheet.printPartIndex||0)+1);
 const host=document.createElement('div');host.style.cssText='position:absolute;left:-10000px;top:0;visibility:hidden';document.body.append(host);
 try{
 for(let cursor=0;cursor<rows.length;){
  const page=document.createElement('section');page.className='print-page';const first=pages.length===0,m={...sheet.metadata,...M.effectiveTempoUnit(sheet,0),bpm:M.tempoSegment(sheet,0).initial};
  host.append(page);
  if(first)page.innerHTML=`<header><h1>${escape(m.title)}</h1>${m.subtitle?`<p class="subtitle">${escape(m.subtitle)}</p>`:''}<div class="score-meta"><div class="credits">${m.lyricist?`<p>${locale==='fa'?'ترانه‌سرا':'Lyricist'}: ${escape(m.lyricist)}</p>`:''}${m.composer?`<p>${locale==='fa'?'آهنگساز':'Composer'}: ${escape(m.composer)}</p>`:''}${m.arranger?`<p>${locale==='fa'?'تنظیم‌کننده':'Arranger'}: ${escape(m.arranger)}</p>`:''}</div><div class="tempo">${sheet.printPart?'<span class="part-instrument">'+escape(printInstrument)+'</span>':''}<span>${escape(m.tempo_text)}</span><span>${root.NotationSymbols.beat(m.tempo_note,m.tempo_dots)} = ${m.bpm}</span></div></div></header>`;
  if(!first&&sheet.printPart)page.innerHTML='<div class="print-part-heading">'+escape(printInstrument)+'</div>';
 const pageNumber=document.createElement('div');pageNumber.className='print-page-number';pageNumber.textContent=String(pages.length+1);page.prepend(pageNumber);
 const grand=M.staves(m).length===2,count=grand?(first?4:5):(first?10:12);
  for(const bars of rows.slice(cursor,cursor+count)){
   const row=document.createElement('div');row.className='print-staff';row.style.height=(grand?53:23)+'mm';page.append(row);
   engraved.push(...renderRow(row,bars,index,{sheet,metadata:m,width:1000,pixels:730,printing:true,continuousSignatures:true,lastWritten:measures.length-1}));index+=bars.length;
  }cursor+=count;pages.push(page);
 }ties({...sheet,score:{measures}},engraved);slurs({...sheet,score:{measures}},engraved);pedalLines({...sheet,score:{measures}},engraved);hairpins({...sheet,score:{measures}},engraved);octaveLines({...sheet,score:{measures}},engraved);slides({...sheet,score:{measures}},engraved);fitDecorations(engraved,true);
 return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><style>@font-face{font-family:Sornaz;src:url('../fonts/iran_sansx_fa/regular.ttf')}@font-face{font-family:Bravura;src:url('fonts/Bravura.otf')}.bravura-symbol{font-family:Bravura!important}@page{size:A4;margin:0}*{box-sizing:border-box}body{margin:0;background:white;color:black;font:12px Sornaz,Arial,sans-serif}.print-page{position:relative;width:210mm;height:297mm;padding:8mm;break-after:page;overflow:hidden}.print-page-number{position:absolute;top:2mm;left:8mm;direction:ltr;text-align:left;font-size:10px;line-height:1}.print-page:last-child{break-after:auto}.print-page header{height:auto;margin-bottom:0}.print-page header+.print-staff{margin-top:-4mm}.print-part-heading{position:absolute;top:2mm;left:8mm;right:8mm;text-align:center;font-size:12px}h1{text-align:center;font-size:20px;margin:0 0 4px}.subtitle{text-align:center;margin:0}.score-meta{display:flex;direction:rtl;justify-content:space-between;align-items:flex-end;gap:12px}.credits{text-align:right;direction:${locale==='fa'?'rtl':'ltr'}}.credits p{margin:2px 0}.part-instrument{flex-basis:100%;text-align:center}.tempo{display:flex;flex-wrap:wrap;gap:12px;direction:ltr;align-items:center}.print-staff{height:${M.staves(sheet.metadata).length===2?53:23}mm}.print-page:not(:first-child){padding-top:9mm}svg{width:100%;height:100%}</style></head><body>${pages.map(p=>p.outerHTML).join('')}</body></html>`;
 }finally{host.remove();}
}
root.NotationRenderer={updatePlayback,draw,drawEnsemble,printDocument,groups,ottava,beamPattern:renderingBeamPattern,measureAccidentals};
})(globalThis);
