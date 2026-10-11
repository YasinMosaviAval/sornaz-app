/* Offline structured score import. Never mutate the currently open score. */
(function(root){
'use strict';
const M=root.NotationModel||require('./model.js');
const fail=message=>{throw Error(message);};
const object=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
const clefs=new Set(['treble','bass','alto','tenor','soprano','mezzo-soprano','baritone-f','treble_8va','treble_8vb','bass_8va','bass_8vb']);
function validate(raw){
 if(!object(raw)||raw.format!=='sornaz-notation'||raw.version!==1||!object(raw.metadata)||!object(raw.score)||!Array.isArray(raw.score.measures))fail('Unsupported score format.');
 const sheet=M.fresh(),meta=raw.metadata,bars=raw.score.measures;
 if(!bars.length||bars.length>64||typeof meta.title!=='string'||!meta.title.trim()||meta.title.length>200||typeof meta.instrument!=='string'||!meta.instrument||!M.keys.includes(meta.key)||!Number.isInteger(Number(meta.bpm))||Number(meta.bpm)<20||Number(meta.bpm)>300)fail('Invalid score metadata.');
 if(meta.staves!==undefined&&(!Array.isArray(meta.staves)||![1,2].includes(meta.staves.length)||meta.staves.some(s=>!object(s)||!clefs.has(s.clef))))fail('Invalid staff layout.');
 if(meta.clef!==undefined&&!clefs.has(meta.clef))fail('Invalid clef.');
 sheet.metadata=M.clone(meta);sheet.metadata.staves??=meta.instrument.toLowerCase()==='piano'?[{clef:'treble'},{clef:'bass'}]:[{clef:meta.clef||'treble'}];
 try{if(!Number.isInteger(M.measureUnits(meta))||!Number.isInteger(M.units({duration:meta.tempo_note||'q',dots:meta.tempo_dots||0})))fail('Invalid score metadata.');}catch(_){fail('Invalid score metadata.');}
 sheet.score.measures=[];let count=0,rests=0,chords=0;
 for(const source of bars){
  if(!object(source)||!Array.isArray(source.notes)||source.notes.length>256)fail('Invalid measure.');
  const bar=M.clone(source);bar.notes=[];bar.preserve=true;sheet.score.measures.push(bar);
  try{const capacity=M.barUnits(sheet,sheet.score.measures.length-1);if(!Number.isInteger(capacity)||capacity<=0||capacity>M.wholeUnits*4)fail('Invalid measure length.');}catch(_){fail('Invalid measure length.');}
  const cursors=new Map();
  for(const note of source.notes){
   if(!object(note)||!M.durations[note.duration]||!Number.isInteger(note.dots||0)||(note.dots||0)>2||!Number.isInteger(note.staff||1)||(note.staff||1)<1||(note.staff||1)>sheet.metadata.staves.length||!Number.isInteger(note.voice||1)||(note.voice||1)<1||(note.voice||1)>4||!note.rest&&!/^[A-G][0-8]$/.test(note.pitch||''))fail('Invalid note.');
   if(note.rest&&note.pitches?.length||note.pitches!==undefined&&(!Array.isArray(note.pitches)||note.pitches.length>12||note.pitches.some(t=>!object(t)||!/^[A-G][0-8]$/.test(t.pitch||''))))fail('Invalid chord.');
   const lane=(note.staff||1)+':'+(note.voice||1),at=note.at===undefined?(cursors.get(lane)||0):note.at;
   if(!Number.isInteger(at)||at<0)fail('Invalid note timing.');
   try{M.add(sheet,sheet.score.measures.length-1,{...note,at});cursors.set(lane,Math.max(cursors.get(lane)||0,at+M.units(note)));}catch(_){fail('Overlapping or out-of-range notes.');}
   count++;rests+=!!note.rest;chords+=!!note.pitches?.length;
  }
 }
 try{M.performanceOrder(sheet);M.timeline(sheet);}catch(error){fail(error.message||'Invalid score structure.');}
 return {sheet,summary:{measures:bars.length,notes:count,rests,chords,staves:sheet.metadata.staves.length}};
}
function parse(content,name=''){
 if(typeof content!=='string'||new TextEncoder().encode(content).length>1000000)fail('Score file is too large.');
 const xml=/\.((musicxml)|(xml))$/i.test(name)||/^\s*</.test(content);
 if(xml)return validate(fromMusicXml(content,name));
 let raw;try{raw=JSON.parse(content);}catch(_){fail('Invalid JSON file.');}return validate(raw);
}
function fromMusicXml(content,name){
 if(/<!\s*(DOCTYPE|ENTITY)/i.test(content))fail('Unsupported MusicXML content.');
 if(typeof DOMParser==='undefined')fail('MusicXML import is unavailable.');
 const doc=new DOMParser().parseFromString(content,'application/xml');
 if(doc.querySelector('parsererror')||doc.documentElement.localName!=='score-partwise')fail('Invalid MusicXML file.');
 const parts=[...doc.documentElement.children].filter(n=>n.localName==='part');if(parts.length!==1)fail('MusicXML must contain one instrument part.');
 const children=(node,tag)=>[...(node?.children||[])].filter(n=>n.localName===tag),one=(node,tag)=>children(node,tag)[0],value=(node,tag)=>one(node,tag)?.textContent?.trim();
 const measures=children(parts[0],'measure');if(!measures.length||measures.length>64)fail('Invalid MusicXML measures.');
 const first=one(measures[0],'attributes'),divisions=Number(value(first,'divisions'));if(!Number.isInteger(divisions)||divisions<1||divisions>10000000)fail('Invalid MusicXML divisions.');
 const time=one(first,'time'),key=one(first,'key'),fifths=Number(value(key,'fifths')||0),major=['Cb','Gb','Db','Ab','Eb','Bb','F','C','G','D','A','E','B','F#','C#'],minor=['Abm','Ebm','Bbm','Fm','Cm','Gm','Dm','Am','Em','Bm','F#m','C#m','G#m','D#m','A#m'];
 if(!Number.isInteger(fifths)||fifths<-7||fifths>7)fail('Unsupported MusicXML key.');
 const keyName=(value(key,'mode')==='minor'?minor:major)[fifths+7],staffCount=Number(value(first,'staves')||children(first,'clef').length||1);
 if(![1,2].includes(staffCount))fail('Unsupported MusicXML staff layout.');
 const clefName=node=>{const sign=value(node,'sign'),line=value(node,'line');if(sign==='G'&&line==='2')return 'treble';if(sign==='F'&&line==='4')return 'bass';if(sign==='C'&&line==='3')return 'alto';if(sign==='C'&&line==='4')return 'tenor';fail('Unsupported MusicXML clef.');};
 const staffClefs=children(first,'clef').map(clefName);while(staffClefs.length<staffCount)staffClefs.push(staffCount===2&&staffClefs.length===1?'bass':'treble');
 const sheet=M.fresh();Object.assign(sheet.metadata,{title:value(one(doc.documentElement,'work'),'work-title')||value(doc.documentElement,'movement-title')||name.replace(/\.[^.]+$/,'')||'Imported score',instrument:staffCount===2?'Piano':'Voice',staves:staffClefs.map(clef=>({clef})),clef:staffClefs[0],key:keyName,time:`${value(time,'beats')||4}/${value(time,'beat-type')||4}`,bpm:100});
 const types={whole:'w',half:'h',quarter:'q',eighth:'8','16th':'16','32nd':'32','64th':'64','128th':'128','256th':'256'};sheet.score.measures=[];let currentFifths=fifths;
 for(const measure of measures){
  const bar={notes:[],preserve:true};sheet.score.measures.push(bar);let cursor=0,last=null;
  for(const item of measure.children){
   if(item.localName==='attributes'){
    if(children(item,'measure-style').length||children(item,'transpose').length)fail('Unsupported MusicXML notation.');
    if((bar.notes.length||cursor)&&children(item,'clef').length)fail('Unsupported MusicXML clef change.');
    const t=one(item,'time'),k=one(item,'key');if(t)bar.time=`${value(t,'beats')}/${value(t,'beat-type')}`;if(k){const n=Number(value(k,'fifths'));if(!Number.isInteger(n)||n<-7||n>7)fail('Unsupported MusicXML key.');bar.key=(value(k,'mode')==='minor'?minor:major)[n+7];currentFifths=n;}
    const cs=children(item,'clef');if(cs.length)bar.clefs=Object.fromEntries(cs.map(c=>[Number(c.getAttribute('number')||1),clefName(c)]));continue;
   }
   if(item.localName==='backup'||item.localName==='forward'){const d=Number(value(item,'duration'));if(!Number.isInteger(d)||d<0)fail('Invalid MusicXML timing.');cursor+=(item.localName==='backup'?-1:1)*d;continue;}
   if(item.localName==='direction'){
    const mark=one(item,'direction-type'),metronome=one(mark,'metronome');
    if(sheet.score.measures.length===1&&metronome){const bpm=Number(value(metronome,'per-minute'));if(!Number.isInteger(bpm)||bpm<20||bpm>300)fail('Invalid MusicXML tempo.');sheet.metadata.bpm=bpm;sheet.metadata.tempo_text=value(mark,'words')||'';const beat={whole:'w',half:'h',quarter:'q',eighth:'8','16th':'16'}[value(metronome,'beat-unit')];if(beat)sheet.metadata.tempo_note=beat;sheet.metadata.tempo_dots=children(metronome,'beat-unit-dot').length;continue;}
    fail('Unsupported MusicXML notation.');
   }
   if(item.localName==='barline'||item.localName==='harmony')fail('Unsupported MusicXML notation.');
   if(item.localName!=='note')continue;
   if(one(item,'grace')||one(item,'time-modification')||one(item,'notations')||one(item,'lyric')||one(item,'tie')||one(item,'cue'))fail('Unsupported MusicXML notation.');
   if(one(item,'rest')?.getAttribute('measure')==='yes'){
    const full=Number(value(item,'duration'));if(!Number.isInteger(full)||full<1||full*M.wholeUnits/(divisions*4)!==M.barUnits({...sheet,score:{measures:sheet.score.measures}},sheet.score.measures.length-1))fail('Invalid MusicXML rest.');cursor+=full;last=null;continue;
   }
   const duration=types[value(item,'type')],dots=children(item,'dot').length,d=Number(value(item,'duration')),expected=duration?M.units({duration,dots})*divisions/(M.wholeUnits/4):NaN;
   if(!duration||!Number.isInteger(d)||d!==expected||dots>2)fail('Unsupported MusicXML duration.');
   const staff=Number(value(item,'staff')||1),rawVoice=Number(value(item,'voice')||1),voice=staff===2&&rawVoice>=5&&rawVoice<=8?rawVoice-4:rawVoice,chord=!!one(item,'chord'),at=chord?last?.at:cursor;
   if(!Number.isInteger(at)||at<0||!Number.isInteger(at*M.wholeUnits/(divisions*4)))fail('Invalid MusicXML timing.');
   const pitch=one(item,'pitch'),step=value(pitch,'step'),alter=Number(value(pitch,'alter')||0),octave=value(pitch,'octave');if(!one(item,'rest')&&(!/^[A-G]$/.test(step||'')||!['-1','0','1'].includes(String(alter))||!/^[0-8]$/.test(octave||'')))fail('Unsupported MusicXML pitch.');
   if(one(item,'accidental')&&!['sharp','flat','natural'].includes(value(item,'accidental')))fail('Unsupported MusicXML accidental.');
   const keyOrder=currentFifths>=0?'FCGDAEB':'BEADGCF',implicit=keyOrder.slice(0,Math.abs(currentFifths)).includes(step)?Math.sign(currentFifths):0;
   const symbol=value(item,'accidental'),accidental=symbol==='natural'?'n':symbol==='sharp'?'#':symbol==='flat'?'b':alter===1?'#':alter===-1?'b':one(pitch,'alter')&&implicit?'n':'';
   const tone={pitch:step+octave,accidental};
   if(chord){if(!last||last.staff!==staff||last.voice!==voice||last.at!==at||last.duration!==duration||last.dots!==dots)fail('Invalid MusicXML chord.');last.note.pitches??=[];last.note.pitches.push(tone);continue;}
   const note={pitch:pitch?tone.pitch:'B4',duration,dots,rest:!!one(item,'rest'),staff,voice,at:at*M.wholeUnits/(divisions*4),accidental:pitch?tone.accidental:''};bar.notes.push(note);last={note,staff,voice,at,duration,dots};cursor+=d;
  }
 }
 return {format:'sornaz-notation',version:1,metadata:sheet.metadata,score:sheet.score};
}
const api={parse,validate,fromMusicXml};root.NotationImporter=api;if(typeof module==='object')module.exports=api;
})(typeof window!=='undefined'?window:globalThis);
