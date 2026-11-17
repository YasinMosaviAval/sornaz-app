const assert=require('node:assert/strict');
const M=require('../assets/notation/model.js'),I=require('../assets/notation/importer.js');
const s=M.fresh();s.metadata.title='Mixed meters';
const note=pitch=>({pitch,duration:'q',dots:0,rest:false,accidental:'n'});
s.score={time:'4/4',measures:[{notes:[note('C4')]}],subsections:[{time:'free',measures:[{notes:[{...note('D4'),durationSeconds:.25}]}]}],sections:[{time:'3/4',measures:[{notes:[note('E4')]}],subsections:[{time:'5/8',measures:[{notes:[note('F4')]}]}]}]};
const before=JSON.stringify(s),joined=M.joinSections(s);
assert.deepEqual(joined.score.measures.map((_,i)=>M.effectiveTime(joined,i)),['4/4','free','3/4','5/8']);
const line=M.timeline(joined);[0,2.4,2.65,4.45].forEach((start,i)=>assert.ok(Math.abs(line.events[i].start-start)<1e-10));
assert.ok(Math.abs(line.duration-5.95)<1e-10,'mixed sections concatenate without free-meter padding');
assert.equal(line.events[1].freeMeter,true);assert.equal(line.events[2].freeMeter,false);
assert.equal(JSON.stringify(s),before,'joining and playback preserve stored section data');
const imported=I.validate({format:'sornaz-notation',version:2,metadata:s.metadata,score:s.score}).sheet;
assert.equal(imported.score.subsections[0].time,'free');assert.equal(imported.score.sections[0].time,'3/4');
assert.equal(imported.score.sections[0].subsections[0].time,'5/8');
assert.ok(Math.abs(M.ensembleTimeline(imported).duration-line.duration)<1e-10);
const inverted=M.clone(s);inverted.metadata.time='free';assert.equal(M.isFree(inverted),false,'section override wins over the part default');
M.insert(inverted,0,note('G4'));assert.equal(inverted.score.measures[0].notes.length,2);
M.prepare(inverted);assert.equal(M.effectiveTime(inverted,0),'4/4');
for(const invalid of [null,[],{},'bad','0/4','33/4']){
 const bad=M.clone(s);bad.score.sections[0].time=invalid;assert.throws(()=>I.validate({format:'sornaz-notation',version:2,metadata:bad.metadata,score:bad.score}));
}
const legacy=M.fresh();legacy.metadata.title='Legacy';delete legacy.score.time;M.insert(legacy,0,note('A4'));assert.equal(M.isFree(legacy),false);
console.log('Section meters: mixed playback, subsection overrides, JSON, atomic reads, malformed meters and legacy defaults passed.');
