const assert=require('node:assert/strict');
const M=require('../assets/notation/model.js'),I=require('../assets/notation/importer.js');
const fresh=()=>{const s=M.fresh();s.metadata.title='Free timing';s.metadata.time='free';return s;};
const note=(seconds,pitch='C4',rest=false,voice=1)=>({pitch,duration:'q',dots:0,rest,accidental:'n',durationSeconds:seconds,voice});
const s=fresh();
for(const value of [.01,.29,5,.51])M.insert(s,0,note(value));
assert.equal(s.score.measures.length,1,'no automatic metrical splitting');
M.timeline(s).events.forEach((event,i)=>{assert.ok(Math.abs(event.start-[0,.01,.3,5.3][i])<1e-12);assert.ok(Math.abs(event.length-[.01,.29,5,.51][i])<1e-12);});
assert.equal(M.timeline(s).duration,5.81);
s.metadata.bpm=300;s.metadata.tempo_note='256';
assert.equal(M.timeline(s).duration,5.81,'tempo and beat unit do not affect seconds');
M.insert(s,0,note(2,'D4'),1);
assert.deepEqual(s.score.measures[0].notes.map(n=>n.durationSeconds),[.01,2,5,.51]);
assert.equal(M.timeline(s).events[2].start,2.01,'editing duration ripples subsequent notes');
M.insert(s,0,note(.25,'B4',true));
assert.equal(M.timeline(s).events.at(-1).hz,0,'explicit timed rest');
M.insert(s,0,note(.5,'G4',false,2));
assert.equal(M.timeline(s).events.find(e=>e.voice===2).start,0,'voices remain independent');
for(const value of [0,.001,.015,5.01,'1',null,NaN,Infinity]){
 const before=JSON.stringify(s);assert.throws(()=>M.insert(s,0,note(value)),/Duration/);assert.equal(JSON.stringify(s),before,'invalid duration is atomic');
}
const raw={format:'sornaz-notation',version:1,metadata:s.metadata,score:s.score};
const imported=I.validate(raw).sheet;
assert.deepEqual(imported.score.measures[0].notes,s.score.measures[0].notes,'JSON round trip preserves seconds and positions');
assert.equal(M.timeline(imported).duration,M.timeline(s).duration);
for(const field of ['time','length','repeat','barline','multiRest','beamPattern']){
 const bad=M.clone(raw);bad.score.measures[0][field]=field==='time'?'4/4':1;assert.throws(()=>I.validate(bad),/Measure markings/);
}
const legacy=M.fresh();assert.throws(()=>M.add(legacy,0,note(1)),/free meter/);
const long=fresh();for(let i=0;i<129;i++)M.insert(long,long.score.measures.length-1,note(.01));
assert.deepEqual(long.score.measures.map(b=>b.notes.length),[128,1]);
assert.ok(Math.abs(M.timeline(long).duration-1.29)<1e-12,'internal storage chunks add no silence');
const copied=M.copySelection(long,new Set(['0:127','1:0']));
assert.equal(copied[1].offset,M.secondsUnits(.01),'copy across storage chunks has no metrical gap');
const target=fresh();M.pasteSelection(target,copied,0,1);assert.equal(M.timeline(target).duration,.02);
const all=new Set(long.score.measures.flatMap((bar,b)=>bar.notes.map((_,i)=>b+':'+i))),duplicate=fresh();
M.pasteSelection(duplicate,M.copySelection(long,all),0,1);assert.deepEqual(duplicate.score.measures.map(bar=>bar.notes.length),[128,1]);
const readonly=fresh();readonly.editable=false;assert.throws(()=>M.insert(readonly,0,note(1)),/read-only/);
const unordered=fresh();M.add(unordered,0,{...note(1,'D4'),at:M.secondUnits});M.add(unordered,0,{...note(1,'C4'),at:0});
M.insert(unordered,0,{...unordered.score.measures[0].notes[1],durationSeconds:2},1);
assert.deepEqual(M.timeline(unordered).events.map(e=>[e.pitch,e.start]),[['C4',0],['D4',2]],'duration edits preserve chronological order after paste');
console.log('Free meter: exact seconds, bounds, ripple editing, rests, voices, JSON, storage chunks and read-only checks passed.');
