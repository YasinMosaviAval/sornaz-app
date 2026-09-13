/* Shared score model. Durations are expressed in sixty-fourth-note units. */
(function(root){
'use strict';
const durations={w:64,h:32,q:16,'8':8,'16':4,'32':2,'64':1,'128':.5,'256':.25};
const keys=['C','G','D','A','E','B','F#','C#','F','Bb','Eb','Ab','Db','Gb','Cb','Am','Em','Bm','F#m','C#m','G#m','D#m','A#m','Dm','Gm','Cm','Fm','Bbm','Ebm','Abm'];
const clone=v=>JSON.parse(JSON.stringify(v));
const ticks=n=>durations[n.duration]*(2-Math.pow(.5,n.dots||0));
const capacity=m=>{const[a,b]=m.time.split('/').map(Number);return a*64/b;};
function fresh(){return {id:0,version:0,editable:true,visibility:'private',metadata:{title:'',subtitle:'',composer:'',arranger:'',lyricist:'',instrument:'Tar',key:'C',time:'4/4',tempo_text:'Allegro',tempo_note:'q',bpm:100,clef:'treble'},score:{measures:[{notes:[]}]}};}
function add(sheet,bar,note){if(!sheet.editable)throw Error('This sheet is read-only.');const notes=sheet.score.measures[bar].notes;if(notes.reduce((s,n)=>s+ticks(n),0)+ticks(note)>capacity(sheet.metadata)+.0001)throw Error('This measure is full.');notes.push(clone(note));return notes.length-1;}
// Plan the complete insertion before mutating, including overflow into later bars.
function insert(sheet,bar,note,replaceIndex=null){
 if(!sheet.editable)throw Error('This sheet is read-only.');
 const measures=clone(sheet.score.measures),cap=capacity(sheet.metadata),values=Object.keys(durations).flatMap(duration=>[0,1,2].map(dots=>({duration,dots,value:ticks({duration,dots})}))).sort((a,b)=>b.value-a.value);
 const inserted={...clone(note),_inserted:true};delete inserted.tieNext;delete inserted.tiePrevious;
 let queue=(measures[bar]?.notes||[]).slice(),lastBar=bar;
 if(replaceIndex===null)queue.push(inserted);else queue.splice(replaceIndex,1,inserted);
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
  measures[bar]={notes:output};bar++;
  if(queue.length)queue.push(...(measures[bar]?.notes||[]));
 }
 sheet.score.measures=measures;return lastBar;
}

function trimmedMeasures(sheet){const measures=clone(sheet.score.measures);while(measures.length&&!measures.at(-1).notes.length)measures.pop();return measures;}
function prepare(sheet){
 const measures=trimmedMeasures(sheet);
 if(sheet.editable&&(!measures.length||measures.at(-1).notes.reduce((v,n)=>v+ticks(n),0)>=capacity(sheet.metadata))){if(measures.length<64)measures.push({notes:[]});}
 sheet.score.measures=measures;return sheet;
}
function timeline(sheet){
 const events=[],meta=sheet.metadata,unit=60/meta.bpm/durations[meta.tempo_note];let elapsed=0,last;
 sheet.score.measures.forEach((bar,barIndex)=>{
  const carry={};let used=0;
  bar.notes.forEach((n,noteIndex)=>{
   const length=ticks(n)*unit,hz=n.rest?0:frequency(n.pitch,n.accidental,meta.key,carry);
   const event={bar:barIndex,note:noteIndex,start:elapsed,length,hz,soundLength:length};
   if(n.tiePrevious&&last?.source.tieNext&&last.source.pitch===n.pitch&&!n.rest){
    event.hz=0;last.attack.soundLength+=length;event.attack=last.attack;
   }else event.attack=event;
   events.push(event);last={source:n,attack:event.attack};elapsed+=length;used+=ticks(n);
  });
  const gap=(capacity(meta)-used)*unit;elapsed+=gap;if(gap>.0001)last=null;
 });
 return {events,duration:events.length?events.at(-1).start+events.at(-1).length:0};
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
const api={durations,keys,clone,ticks,capacity,fresh,add,insert,trimmedMeasures,prepare,timeline,frequency};if(typeof module==='object')module.exports=api;root.NotationModel=api;
})(globalThis);
