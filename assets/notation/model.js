/* Shared score model. Legacy durations are in sixty-fourths; event positions use exact whole-note units. */
(function(root){
'use strict';
const durations={w:64,h:32,q:16,'8':8,'16':4,'32':2,'64':1,'128':.5,'256':.25};
// A whole note has 967680 units: exact for double dots and common 3/5/7/9 tuplets.
const wholeUnits=967680,unitPerLegacyTick=wholeUnits/64;
const tuplets={'3:2':true,'5:4':true,'7:4':true,'4:3':true,'6:4':true,'9:8':true};
const keys=['C','G','D','A','E','B','F#','C#','F','Bb','Eb','Ab','Db','Gb','Cb','Am','Em','Bm','F#m','C#m','G#m','D#m','A#m','Dm','Gm','Cm','Fm','Bbm','Ebm','Abm'];
const clone=v=>JSON.parse(JSON.stringify(v));
const ticks=n=>durations[n.duration]*(2-Math.pow(.5,n.dots||0));
const units=n=>{const base=Math.round(ticks(n)*unitPerLegacyTick),t=n.tuplet;if(!t)return base;const key=t.actual+':'+t.normal;if(!tuplets[key])throw Error('Invalid tuplet.');const value=base*t.normal/t.actual;if(!Number.isInteger(value))throw Error('Tuplet duration is not integral.');return value;};
const measureUnits=(meta,bar={})=>{const[a,b]=String(bar.time||meta.time).split('/').map(Number);if(!Number.isInteger(a)||a<1||a>32||![1,2,4,8,16,32,64,128,256].includes(b))throw Error('Invalid time signature.');const full=a*wholeUnits/b;return Number.isInteger(bar.length)?bar.length:full;};
const effectiveTime=(sheet,index)=>{let time=sheet.metadata.time;for(let i=0;i<=index&&i<sheet.score.measures.length;i++)if(sheet.score.measures[i].time)time=sheet.score.measures[i].time;return time;};
const barUnits=(sheet,index)=>measureUnits({...sheet.metadata,time:effectiveTime(sheet,index)},sheet.score.measures[index]||{});
const capacity=(meta,bar={})=>measureUnits(meta,bar)/unitPerLegacyTick;
const staves=m=>Array.isArray(m.staves)&&m.staves.length===2?m.staves.map(s=>({clef:s.clef||'treble'})):[{clef:m.clef||'treble'}];
const staffOf=n=>n.staff===2?2:1;
const voiceOf=n=>Number.isInteger(n.voice)&&n.voice>0?n.voice:1;
const lane=(bar,staff,voice=null)=>bar.notes.filter(n=>staffOf(n)===staff&&(voice===null||voiceOf(n)===voice));
const used=(bar,staff,voice=1)=>lane(bar,staff,voice).reduce((sum,n)=>sum+units(n),0)/unitPerLegacyTick;
function positionOf(bar,noteIndex){const cursors=new Map();for(let i=0;i<=noteIndex;i++){const n=bar.notes[i],key=staffOf(n)+':'+voiceOf(n),at=Number.isInteger(n.at)?n.at:cursors.get(key)||0;cursors.set(key,Math.max(cursors.get(key)||0,at+units(n)));if(i===noteIndex)return at;}return 0;}
function normalizeBar(bar){const cursors=new Map();for(const n of bar.notes){const key=staffOf(n)+':'+voiceOf(n),at=Number.isInteger(n.at)?n.at:cursors.get(key)||0;n.at=at;n.voice=voiceOf(n);cursors.set(key,Math.max(cursors.get(key)||0,at+units(n)));}return bar;}
function fresh(){return {id:0,version:0,editable:true,visibility:'private',metadata:{title:'',subtitle:'',composer:'',arranger:'',lyricist:'',instrument:'Tar',scale_type:'major',key:'C',time:'4/4',tempo_text:'Allegro',tempo_note:'q',tempo_dots:0,bpm:100,clef:'treble'},score:{measures:[{notes:[]}]}};}
function add(sheet,bar,note){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const measure=sheet.score.measures[bar],staff=staffOf(note),voice=voiceOf(note),length=units(note);
 const intervals=lane(measure,staff,voice).map(n=>{const i=measure.notes.indexOf(n),start=positionOf(measure,i);return [start,start+units(n)];});
 const at=Number.isInteger(note.at)?note.at:Math.max(0,...intervals.map(([,end])=>end));
 if(at<0||at+length>barUnits(sheet,bar)||intervals.some(([start,end])=>at<end&&at+length>start))throw Error('This measure is full.');
 measure.notes.push({...clone(note),staff,voice,at});return measure.notes.length-1;
}
function copySelection(sheet,selected){
 const items=[];for(const key of selected){const[bar,index]=key.split(':').map(Number),note=sheet.score.measures[bar]?.notes[index];if(note)items.push({bar,at:positionOf(sheet.score.measures[bar],index),note:clone(note)});}
 if(!items.length)return [];
 const firstBar=Math.min(...items.map(item=>item.bar)),firstStaff=Math.min(...items.map(item=>staffOf(item.note))),firstAt=Math.min(...items.filter(item=>item.bar===firstBar).map(item=>item.at));
 return items.map(item=>({bar:item.bar-firstBar,at:item.at-(item.bar===firstBar?firstAt:0),staff:staffOf(item.note)-firstStaff,note:item.note,offset:item.at-firstAt+Array.from({length:item.bar-firstBar},(_,i)=>barUnits(sheet,firstBar+i)).reduce((sum,length)=>sum+length,0)}));
}
function pasteSelection(sheet,items,targetBar,targetStaff,targetAt=0){
 if(!Array.isArray(items)||!items.length)throw Error('Nothing to paste.');
 const draft=clone(sheet),locations=[];
 for(const item of items){let bar=targetBar+item.bar,at=item.at+targetAt,staff=targetStaff+item.staff;
  if(Number.isInteger(item.offset)){bar=targetBar;at=targetAt+item.offset;}
  if(bar<0||bar>=64||staff<1||staff>staves(sheet.metadata).length||!Number.isInteger(at)||at<0)throw Error('Paste target is outside the score.');
  while(true){
   while(draft.score.measures.length<=bar)draft.score.measures.push({notes:[],preserve:true});
   const length=barUnits(draft,bar);if(at<length)break;
   at-=length;if(++bar>=64)throw Error('Paste target is outside the score.');
  }
  const index=add(draft,bar,{...clone(item.note),staff,at});locations.push(bar+':'+index);
 }
 sheet.score=draft.score;return new Set(locations);
}
// Plan the complete insertion before mutating, including overflow into later bars.
function insert(sheet,bar,note,replaceIndex=null){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const measures=clone(sheet.score.measures),values=Object.keys(durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:units({duration,dots})}))).sort((a,b)=>b.value-a.value);
 const inserted={...clone(note),_inserted:true};delete inserted.tieNext;delete inserted.tiePrevious;
 const staff=staffOf(note),voice=voiceOf(note),initial=measures[bar]?.notes||[];
 let queue=initial.filter(n=>staffOf(n)===staff&&voiceOf(n)===voice),lastBar=bar;
 if(replaceIndex===null)queue.push(inserted);else{const preceding=initial.slice(0,replaceIndex).filter(n=>staffOf(n)===staff&&voiceOf(n)===voice).length;queue.splice(preceding,1,inserted);}
 while(queue.length){
  if(bar>=64)throw Error('At most 64 measures.');
  const output=[],cap=measureUnits({...sheet.metadata,time:effectiveTime({...sheet,score:{measures}},bar)},measures[bar]||{});let cursor=0;
  while(queue.length&&cursor<cap){
   const n=queue.shift(),at=Math.max(cursor,Number.isInteger(n.at)?n.at:cursor),length=units(n),room=cap-at;
   if(room<=0){delete n.at;queue.unshift(n);break;}
   if(length<=room){output.push({...n,at,voice});cursor=at+length;continue;}
   if(n.tuplet)throw Error('Tuplet crosses a measure boundary.');
   const first=[],remaining=[];let left=length,target=room;
   while(left>0){const part=values.find(v=>v.value<=Math.min(target||left,left));if(!part)throw Error('Invalid note duration.');const item={...n,duration:part.duration,dots:part.dots};delete item.at;(target>0?first:remaining).push(item);left-=part.value;if(target>0)target-=part.value;}
   const parts=[...first,...remaining];if(!n.rest)parts.forEach((part,i)=>{part.tiePrevious=i>0||!!n.tiePrevious;part.tieNext=i<parts.length-1||!!n.tieNext;});
   cursor=at;for(const part of first){output.push({...part,at:cursor,voice});cursor+=units(part);}queue.unshift(...remaining);cursor=cap;
  }
  for(const n of output){if(n._inserted)lastBar=bar;delete n._inserted;}
  const other=(measures[bar]?.notes||[]).filter(n=>staffOf(n)!==staff||voiceOf(n)!==voice);
  measures[bar]={...(measures[bar]||{}),notes:staff===1&&voice===1?[...output,...other]:[...other,...output]};bar++;
  if(queue.length)queue.push(...(measures[bar]?.notes||[]).filter(n=>staffOf(n)===staff&&voiceOf(n)===voice));
 }
 sheet.score.measures=measures;return lastBar;
}

function trimmedMeasures(sheet){const measures=clone(sheet.score.measures);while(measures.length&&!measures.at(-1).notes.length&&!measures.at(-1).preserve&&!measures.at(-1).time&&!measures.at(-1).timeSymbol&&!measures.at(-1).length&&!measures.at(-1).barline&&!measures.at(-1).repeat)measures.pop();return measures;}
function asRest(note){const rest={...clone(note),pitch:'B4',rest:true,accidental:'',dynamic:'',articulation:'',bow:'',finger:'',ornament:'',tieNext:false,tiePrevious:false};delete rest.pitches;return rest;}
// Ripple only within the selected measure and staff. Fill the vacated time with rests.
function compactDelete(sheet,selected){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const values=Object.keys(durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:units({duration,dots})}))).sort((a,b)=>b.value-a.value);
 sheet.score.measures.forEach((bar,barIndex)=>{
  const original=bar.notes.map((n,i)=>({n,i})),groups=new Map();
  for(const entry of original){const key=staffOf(entry.n)+':'+voiceOf(entry.n);if(!groups.has(key))groups.set(key,[]);groups.get(key).push(entry);}
  if(!original.some(({i})=>selected.has(barIndex+':'+i)))return;
  const output=[];
  for(const [key,entries] of groups){if(!entries.some(({i})=>selected.has(barIndex+':'+i))){output.push(...entries.map(({n})=>n));continue;}const [staff,voice]=key.split(':').map(Number),ordered=entries.map(entry=>({...entry,at:positionOf(bar,entry.i)})).sort((a,b)=>a.at-b.at||a.i-b.i),end=Math.max(...ordered.map(({n,at})=>at+units(n)));let removed=0;
   for(const {n,i,at} of ordered){if(selected.has(barIndex+':'+i)){removed+=units(n);continue;}output.push({...n,at:at-removed});}
   let remaining=removed,cursor=end-removed;
   while(remaining>0){const part=values.find(v=>v.value<=remaining);if(!part)throw Error('Invalid note duration.');output.push({pitch:'B4',duration:part.duration,dots:part.dots,rest:true,staff,voice,at:cursor,accidental:''});remaining-=part.value;cursor+=part.value;}
  }
  bar.notes=output.sort((a,b)=>staffOf(a)-staffOf(b)||voiceOf(a)-voiceOf(b)||(a.at||0)-(b.at||0));bar.preserve=true;
 });
 return sheet;
}
function prepare(sheet){
 const measures=trimmedMeasures(sheet);
 const full=measures.length&&staves(sheet.metadata).some((_,i)=>used(measures.at(-1),i+1)>=barUnits({...sheet,score:{measures}},measures.length-1)/unitPerLegacyTick);
 if(sheet.editable&&(!measures.length||full)&&measures.length<64)measures.push({notes:[]});
 sheet.score.measures=measures;return sheet;
}
function measureSource(sheet,position){const bars=sheet.score.measures;let source=position;for(let guard=0;guard<bars.length;guard++){if(source<0)throw Error('Measure repeat has no source.');if(bars[source]?.repeat?.measure===1){source--;continue;}if(bars[source]?.repeat?.measure===2||bars[source-1]?.repeat?.measure===2){source-=2;continue;}return source;}throw Error('Measure repeat does not terminate.');}
// Resolve structural repeats before assigning sound timings. The caller can inspect
// sourceBar independently of the physical measure position in the performance.
function performanceOrder(sheet){
 const bars=sheet.score.measures,order=[],startForEnd=new Map(),starts=[];
 const append=(bar,sourceBar)=>{if(barUnits(sheet,bar)!==barUnits(sheet,sourceBar))throw Error('Repeated measures must have the same length.');order.push({bar,sourceBar});};
 bars.forEach((bar,i)=>{if(bar.repeat?.start)starts.push(i);if(bar.repeat?.end){startForEnd.set(i,starts.at(-1)??0);if(starts.length)starts.pop();}});
 const segno=bars.findIndex(bar=>bar.repeat?.marker==='segno'),coda=bars.findIndex(bar=>bar.repeat?.marker==='coda');
 const passes=new Map();let index=0,pass=1,jumpTaken=false,alFine=false,alCoda=false,codaTaken=false,steps=0;
 while(index<bars.length){
  if(++steps>Math.max(128,bars.length*32))throw Error('Repeat structure does not terminate.');
  const bar=bars[index],repeat=bar.repeat||{},endings=repeat.endings;
  if(repeat.start)pass=passes.get(index)||1;
  if(endings&&(!Array.isArray(endings)||!endings.includes(pass))){index++;continue;}
  const stopAtFine=jumpTaken&&alFine&&repeat.marker==='fine';
  const moveToCoda=jumpTaken&&alCoda&&!codaTaken&&repeat.marker==='toCoda';
  const measureRepeat=repeat.measure;
  if(measureRepeat&&bar.notes.length)throw Error('Empty the measure before adding a repeat sign.');
  if(measureRepeat===1){if(index<1)throw Error('One-bar repeat has no source.');append(index,measureSource(sheet,index));}
  else if(measureRepeat===2){if(index<2||index+1>=bars.length)throw Error('Two-bar repeat has no source.');if(bars[index+1].notes.length)throw Error('Empty the measure before adding a repeat sign.');append(index,measureSource(sheet,index));append(index+1,measureSource(sheet,index+1));index++;}
  else append(index,index);
  if(stopAtFine)break;
  if(moveToCoda){if(coda<0)throw Error('Coda marker is missing.');codaTaken=true;index=coda;continue;}
  if(repeat.end){const start=startForEnd.get(index)??0,count=passes.get(start)||1,limit=repeat.end===true?2:repeat.end;if(!Number.isInteger(limit)||limit<2||limit>8)throw Error('Invalid repeat count.');if(count<limit){passes.set(start,count+1);pass=count+1;index=start;continue;}passes.delete(start);}
  if(repeat.jump&&!jumpTaken){
   const destinations={dc:0,ds:segno,dcAlFine:0,dsAlFine:segno,dcAlCoda:0,dsAlCoda:segno};
   if(!Object.hasOwn(destinations,repeat.jump)||destinations[repeat.jump]<0)throw Error('Repeat target is missing.');
   if(repeat.jump.endsWith('AlFine')&&!bars.some(item=>item.repeat?.marker==='fine'))throw Error('Fine marker is missing.');
   if(repeat.jump.endsWith('AlCoda')&&(coda<0||!bars.some(item=>item.repeat?.marker==='toCoda')))throw Error('Coda marker is missing.');
   jumpTaken=true;alFine=repeat.jump.endsWith('AlFine');alCoda=repeat.jump.endsWith('AlCoda');passes.clear();pass=1;index=destinations[repeat.jump];continue;
  }
  index++;
 }
 return order;
}
function timeline(sheet){
 const events=[],meta=sheet.metadata,beatUnits=units({duration:meta.tempo_note,dots:meta.tempo_dots||0}),unit=60/meta.bpm/beatUnits,lastByVoice=new Map();let elapsed=0,previousSource=-1;
 performanceOrder(sheet).forEach(({bar:barIndex,sourceBar})=>{const bar=sheet.score.measures[sourceBar];if(previousSource>=0&&sourceBar!==previousSource+1)lastByVoice.clear();previousSource=sourceBar;
  for(let staff=1;staff<=staves(meta).length;staff++){
   const carry={},notes=bar.notes.map((n,i)=>({n,i,at:positionOf(bar,i)})).filter(({n})=>staffOf(n)===staff).sort((a,b)=>a.at-b.at||voiceOf(a.n)-voiceOf(b.n));
   for(const {n,i} of notes){
    const voice=voiceOf(n),at=positionOf(bar,i),length=units(n)*unit,start=elapsed+at*unit,key=staff+':'+voice,previous=lastByVoice.get(key)||new Map();
    for(const tone of [{pitch:n.pitch,accidental:n.accidental},...(n.pitches||[])]){
     const pitch=typeof tone==='string'?tone:tone.pitch,accidental=typeof tone==='string'?'':tone.accidental;
     const hz=n.rest?0:frequency(pitch,accidental,meta.key,carry);
     const event={bar:barIndex,note:i,staff,voice,start,length,hz,soundLength:length};
     const last=previous.get(pitch);
     if(n.tiePrevious&&last?.source.tieNext&&!n.rest){event.hz=0;last.attack.soundLength+=length;event.attack=last.attack;}else event.attack=event;
     events.push(event);previous.set(pitch,{source:n,attack:event.attack});
    }
    if(n.rest)previous.clear();
    lastByVoice.set(key,previous);
   }
   for(const voice of new Set(notes.map(({n})=>voiceOf(n)))){const voiceNotes=notes.filter(({n})=>voiceOf(n)===voice),last=voiceNotes.at(-1);if(last&&last.at+units(last.n)<barUnits(sheet,sourceBar))lastByVoice.delete(staff+':'+voice);}
  }
  elapsed+=barUnits(sheet,sourceBar)*unit;
 });
 events.sort((a,b)=>a.start-b.start||a.staff-b.staff||a.note-b.note);
 return {events,duration:elapsed};
}
function frequency(pitch,accidental='',key='C',carry={}){
 const letter=pitch[0],octave=Number(pitch.slice(1)),base={C:0,D:2,E:4,F:5,G:7,A:9,B:11};
 const signatures={C:0,G:1,D:2,A:3,E:4,B:5,'F#':6,'C#':7,F:-1,Bb:-2,Eb:-3,Ab:-4,Db:-5,Gb:-6,Cb:-7,Am:0,Em:1,Bm:2,'F#m':3,'C#m':4,'G#m':5,'D#m':6,'A#m':7,Dm:-1,Gm:-2,Cm:-3,Fm:-4,Bbm:-5,Ebm:-6,Abm:-7};
 const count=signatures[key]||0,order=count>=0?'FCGDAEB':'BEADGCF';
 let delta=order.slice(0,Math.abs(count)).includes(letter)?Math.sign(count):0;
 if(Object.hasOwn(carry,pitch))delta=carry[pitch];
 if(accidental){delta={'#':1,b:-1,n:0,'##':2,bb:-2,'+':.5,d:-.5}[accidental];carry[pitch]=delta;}
 return 440*Math.pow(2,((octave+1)*12+base[letter]+delta-69)/12);
}
const api={durations,keys,wholeUnits,units,measureUnits,effectiveTime,barUnits,positionOf,voiceOf,normalizeBar,clone,ticks,capacity,staves,staffOf,lane,used,fresh,add,insert,copySelection,pasteSelection,trimmedMeasures,asRest,compactDelete,prepare,measureSource,performanceOrder,timeline,frequency};if(typeof module==='object')module.exports=api;root.NotationModel=api;
})(globalThis);
