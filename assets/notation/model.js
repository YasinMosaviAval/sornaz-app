/* Shared score model. Durations are expressed in sixty-fourth-note units. */
(function(root){
'use strict';
const durations={w:64,h:32,q:16,'8':8,'16':4,'32':2,'64':1};
const keys=['C','G','D','A','E','B','F#','C#','F','Bb','Eb','Ab','Db','Gb','Cb','Am','Em','Bm','F#m','C#m','G#m','D#m','A#m','Dm','Gm','Cm','Fm','Bbm','Ebm','Abm'];
const clone=v=>JSON.parse(JSON.stringify(v));
const ticks=n=>durations[n.duration]*(2-Math.pow(.5,n.dots||0));
const capacity=m=>{const[a,b]=m.time.split('/').map(Number);return a*64/b;};
function fresh(){return {id:0,version:0,editable:true,visibility:'private',metadata:{title:'',subtitle:'',composer:'',arranger:'',lyricist:'',copyright:'Sornaz',instrument:'Tar',key:'C',time:'4/4',tempo_text:'Allegro',tempo_note:'q',bpm:100,clef:'treble'},score:{measures:Array.from({length:12},()=>({notes:[]}))}};}
function add(sheet,bar,note){if(!sheet.editable)throw Error('This sheet is read-only.');const notes=sheet.score.measures[bar].notes;if(notes.reduce((s,n)=>s+ticks(n),0)+ticks(note)>capacity(sheet.metadata)+.0001)throw Error('This measure is full.');notes.push(clone(note));return notes.length-1;}
function frequency(pitch,accidental='',key='C',carry={}){
 const letter=pitch[0],octave=Number(pitch.slice(1)),base={C:0,D:2,E:4,F:5,G:7,A:9,B:11};
 const signatures={C:0,G:1,D:2,A:3,E:4,B:5,'F#':6,'C#':7,F:-1,Bb:-2,Eb:-3,Ab:-4,Db:-5,Gb:-6,Cb:-7,Am:0,Em:1,Bm:2,'F#m':3,'C#m':4,'G#m':5,'D#m':6,'A#m':7,Dm:-1,Gm:-2,Cm:-3,Fm:-4,Bbm:-5,Ebm:-6,Abm:-7};
 const count=signatures[key]||0,order=count>=0?'FCGDAEB':'BEADGCF';
 let delta=order.slice(0,Math.abs(count)).includes(letter)?Math.sign(count):0;
 if(Object.hasOwn(carry,pitch))delta=carry[pitch];
 if(accidental){delta={'#':1,b:-1,n:0,'##':2,bb:-2,'+':.5,d:-.5}[accidental];carry[pitch]=delta;}
 return 440*Math.pow(2,((octave+1)*12+base[letter]+delta-69)/12);
}
const api={durations,keys,clone,ticks,capacity,fresh,add,frequency};if(typeof module==='object')module.exports=api;root.NotationModel=api;
})(globalThis);