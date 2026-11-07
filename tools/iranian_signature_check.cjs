const assert = require('node:assert/strict');
const M = require('../assets/notation/model.js');
const examples = [
  ['iran_shur','G',['G','Ak','Bb','C','D','Eb','F']],
  ['iran_shur','A',['A','Bk','C','D','E','F','G']],
  ['iran_homayun','G',['G','Ak','B','C','D','Eb','F']],
  ['iran_segah','A:k',['Ak','Bb','C','Dk','Eb','F','G']],
  ['iran_chahargah','C',['C','Dk','E','F','G','Ak','B']],
];
for (const [mode,tonic,expected] of examples) assert.deepEqual(M.iranianSignature(mode,tonic).degrees.map(d=>d.letter+d.accidental),expected);
const rotate=(a,n)=>a.slice(n).concat(a.slice(0,n));
for(const [mode,n] of [['iran_abuata',1],['iran_bayat_tork',2],['iran_nava',3],['iran_afshari',3],['iran_dashti',4]]) assert.deepEqual(M.iranianIntervals[mode],rotate(M.iranianIntervals.iran_shur,n));
assert.deepEqual(M.iranianIntervals.iran_bayat_esfahan,rotate(M.iranianIntervals.iran_homayun,3));
assert.deepEqual(M.iranianIntervals.iran_rastpanjgah,M.iranianIntervals.iran_mahur);
assert.deepEqual(M.iranianSignature('iran_mahur','C').degrees.map(d=>d.letter+d.accidental),['C','D','E','F','G','A','B']);
let count=0;
for (const [mode] of M.iranianScales) for (const [tonic] of M.iranianTonics) {
  const signature=M.iranianSignature(mode,tonic),pattern=M.iranianIntervals[mode];
  assert.equal(pattern.reduce((a,b)=>a+b),24);
  const sheet=M.fresh();Object.assign(sheet.metadata,{scale_type:mode,key:tonic});
  const first='CDEFGAB'.indexOf(tonic[0]);
  sheet.score.measures[0].notes=signature.degrees.map((d,i)=>({pitch:d.letter+(4+Math.floor((first+i)/7)),duration:'8',dots:0,at:i*M.wholeUnits/8,rest:false}));
  const events=M.timeline(sheet).events;
  for(let i=0;i<7;i++) {
    assert.equal(signature.degrees[(i+1)%7].quarter+(i===6?24:0)-signature.degrees[i].quarter,pattern[i]);
    assert.ok(Math.abs(events[i].hz-M.frequency('C4')*2**(signature.degrees[i].quarter/24))<1e-8,mode+' '+tonic);
  }
  count++;
}
assert.deepEqual(M.iranianSignature('iran_shur','G').accidentals.map(a=>a.letter+a.accidental),['Bb','Eb','Ak']);
assert.deepEqual(M.iranianSignature('iran_shur','F:o').accidentals.map(a=>a.letter+a.accidental),['Fo','Co','Bk','Ek','Ak','Dk']);
assert.throws(()=>M.iranianSignature('iran_shur','C:bad'));
assert.equal(count,288);
console.log('Iranian signatures: 288 mode/tonic combinations, all seven intervals, implicit playback and five supplied examples passed.');
