/* Shared score model. Durations are expressed in sixty-fourth-note units. */
(function(root){
'use strict';
const durations={w:64,h:32,q:16,'8':8,'16':4,'32':2,'64':1,'128':.5,'256':.25};
const keys=['C','G','D','A','E','B','F#','C#','F','Bb','Eb','Ab','Db','Gb','Cb','Am','Em','Bm','F#m','C#m','G#m','D#m','A#m','Dm','Gm','Cm','Fm','Bbm','Ebm','Abm'];
const clone=v=>JSON.parse(JSON.stringify(v));
const ticks=n=>durations[n.duration]*(2-Math.pow(.5,n.dots||0));
const capacity=m=>{const[a,b]=m.time.split('/').map(Number);return a*64/b;};
const staves=m=>Array.isArray(m.staves)&&m.staves.length===2?m.staves.map(s=>({clef:s.clef||'treble'})):[{clef:m.clef||'treble'}];
const staffOf=n=>n.staff===2?2:1;
const lane=(bar,staff)=>bar.notes.filter(n=>staffOf(n)===staff);
const used=(bar,staff)=>lane(bar,staff).reduce((sum,n)=>sum+ticks(n),0);
function fresh(){return {id:0,version:0,editable:true,visibility:'private',metadata:{title:'',subtitle:'',composer:'',arranger:'',lyricist:'',instrument:'Tar',scale_type:'major',key:'C',time:'4/4',tempo_text:'Allegro',tempo_note:'q',tempo_dots:0,bpm:100,clef:'treble'},score:{measures:[{notes:[]}]}};}
function add(sheet,bar,note){if(!sheet.editable)throw Error('This sheet is read-only.');const measure=sheet.score.measures[bar];if(used(measure,staffOf(note))+ticks(note)>capacity(sheet.metadata)+.0001)throw Error('This measure is full.');measure.notes.push(clone(note));return measure.notes.length-1;}
// Plan the complete insertion before mutating, including overflow into later bars.
function insert(sheet,bar,note,replaceIndex=null){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const measures=clone(sheet.score.measures),cap=capacity(sheet.metadata),values=Object.keys(durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:ticks({duration,dots})}))).sort((a,b)=>b.value-a.value);
 const inserted={...clone(note),_inserted:true};delete inserted.tieNext;delete inserted.tiePrevious;
 const staff=staffOf(note),initial=measures[bar]?.notes||[];
 let queue=initial.filter(n=>staffOf(n)===staff),lastBar=bar;
 if(replaceIndex===null)queue.push(inserted);else{const preceding=initial.slice(0,replaceIndex).filter(n=>staffOf(n)===staff).length;queue.splice(preceding,1,inserted);}
 while(queue.length){
  if(bar>=64)throw Error('At most 64 measures.');
  const output=[];let room=cap;
  while(queue.length&&room>.0001){
   const n=queue.shift(),length=ticks(n);
   if(length<=room+.0001){output.push(n);room-=length;continue;}
   const first=[],remaining=[];let left=length,target=Math.min(room,length);
   while(left>.0001){const part=values.find(v=>v.value<=Math.min(target||left,left)+.0001);if(!part)throw Error('Invalid note duration.');const item={...n,duration:part.duration,dots:part.dots};(target>0?first:remaining).push(item);left-=part.value;if(target>0)target-=part.value;}
   const parts=[...first,...remaining];if(!n.rest)parts.forEach((part,i)=>{part.tiePrevious=i>0||!!n.tiePrevious;part.tieNext=i<parts.length-1||!!n.tieNext;});
   output.push(...first);queue.unshift(...remaining);room=0;
  }
  for(const n of output){if(n._inserted)lastBar=bar;delete n._inserted;}
  const other=(measures[bar]?.notes||[]).filter(n=>staffOf(n)!==staff);
  measures[bar]={...(measures[bar]||{}),notes:staff===1?[...output,...other]:[...other,...output]};bar++;
  if(queue.length)queue.push(...(measures[bar]?.notes||[]).filter(n=>staffOf(n)===staff));
 }
 sheet.score.measures=measures;return lastBar;
}

function trimmedMeasures(sheet){const measures=clone(sheet.score.measures);while(measures.length&&!measures.at(-1).notes.length&&!measures.at(-1).preserve)measures.pop();return measures;}
function asRest(note){const rest={...clone(note),pitch:'B4',rest:true,accidental:'',dynamic:'',articulation:'',bow:'',finger:'',ornament:'',tieNext:false,tiePrevious:false};delete rest.pitches;return rest;}
// Ripple only within the selected measure and staff. Fill the vacated time with rests.
function compactDelete(sheet,selected){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const values=Object.keys(durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:ticks({duration,dots})}))).sort((a,b)=>b.value-a.value);
 sheet.score.measures.forEach((bar,barIndex)=>{
  const original=bar.notes;
  const removed=[1,2].map(staff=>original.reduce((sum,n,i)=>sum+(staffOf(n)===staff&&selected.has(barIndex+':'+i)?ticks(n):0),0));
  if(!removed.some(Boolean))return;
  const lanes=[1,2].map(staff=>original.filter((n,i)=>staffOf(n)===staff&&!selected.has(barIndex+':'+i)));
  lanes.forEach((notes,index)=>{let remaining=removed[index];while(remaining>0.0001){const part=values.find(v=>v.value<=remaining+0.0001);if(!part)throw Error('Invalid note duration.');notes.push({pitch:'B4',duration:part.duration,dots:part.dots,rest:true,staff:index+1,accidental:''});remaining-=part.value;}});
  bar.notes=[...lanes[0],...lanes[1]];bar.preserve=true;
 });
 return sheet;
}
function prepare(sheet){
 const measures=trimmedMeasures(sheet);
 if(sheet.editable&&(!measures.length||staves(sheet.metadata).some((_,i)=>used(measures.at(-1),i+1)>=capacity(sheet.metadata)))){if(measures.length<64)measures.push({notes:[]});}
 sheet.score.measures=measures;return sheet;
}
function timeline(sheet){
 const events=[],meta=sheet.metadata,beatTicks=ticks({duration:meta.tempo_note,dots:meta.tempo_dots||0}),unit=60/meta.bpm/beatTicks,lastByStaff=new Map();let elapsed=0;
 sheet.score.measures.forEach((bar,barIndex)=>{
  for(let staff=1;staff<=staves(meta).length;staff++){
   const carry={},notes=bar.notes.map((n,i)=>({n,i})).filter(({n})=>staffOf(n)===staff);
   let position=0;const previous=lastByStaff.get(staff)||new Map();
   for(const {n,i} of notes){
    const length=ticks(n)*unit,start=elapsed+position*unit;
    for(const tone of [{pitch:n.pitch,accidental:n.accidental},...(n.pitches||[])]){
     const pitch=typeof tone==='string'?tone:tone.pitch,accidental=typeof tone==='string'?'':tone.accidental;
     const hz=n.rest?0:frequency(pitch,accidental,meta.key,carry);
     const event={bar:barIndex,note:i,staff,start,length,hz,soundLength:length};
     const last=previous.get(pitch);
     if(n.tiePrevious&&last?.source.tieNext&&!n.rest){event.hz=0;last.attack.soundLength+=length;event.attack=last.attack;}else event.attack=event;
     events.push(event);previous.set(pitch,{source:n,attack:event.attack});
    }
    if(n.rest)previous.clear();
    position+=ticks(n);
   }
   if(position<capacity(meta)-.0001)previous.clear();
   lastByStaff.set(staff,previous);
  }
  elapsed+=capacity(meta)*unit;
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
const api={durations,keys,clone,ticks,capacity,staves,staffOf,lane,used,fresh,add,insert,trimmedMeasures,asRest,compactDelete,prepare,timeline,frequency};if(typeof module==='object')module.exports=api;root.NotationModel=api;
})(globalThis);
