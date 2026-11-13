const assert=require('node:assert/strict'),fs=require('fs'),path=require('path'),vm=require('vm');
const root=process.argv.includes('--web-assets')?'A:/workspace/web/sornaz':path.resolve(__dirname,'..'),M=require(root+'/assets/notation/model.js');
const context={NotationModel:M,Vex:{Flow:{setMusicFont(){},Glyph:class{getMetrics(){return {width:20};}},KeySignature:class{},StaveNote:class{}}}};vm.createContext(context);vm.runInContext(fs.readFileSync(root+'/assets/notation/score_renderer.js','utf8'),context);const R=context.NotationRenderer;
function check(scale,key,pitch,base,other){
 const s=M.fresh();Object.assign(s.metadata,{scale_type:scale,key});
 const sequence=[base,other,other,base,base,other];
 s.score.measures=[{notes:sequence.map((accidental,i)=>({pitch,accidental,duration:'8',staff:1,at:i*M.wholeUnits/8}))},{notes:[{pitch,accidental:base,duration:'q',staff:1,at:0}]}];
 const before=JSON.stringify(s),signs=R.measureAccidentals(s,0,1);
 assert.deepEqual(Array.from(signs.values(),v=>v.tones[0]),['',other,'',base,'',other]);
 assert.equal(R.measureAccidentals(s,1,1).get(0).tones[0],base);assert.equal(JSON.stringify(s),before);
 assert.equal(M.defaultAccidental(s,0,pitch,1),base);
 // A later signature pitch must remain stable when an earlier pitch is edited.
 s.score.measures[0].notes=[{pitch,accidental:base,duration:'q',at:0},{pitch,accidental:M.defaultAccidental(s,0,pitch,1),duration:'q',at:M.wholeUnits/4}];
 s.score.measures[0].notes[0].accidental=other;
 assert.deepEqual(Array.from(R.measureAccidentals(s,0,1).values(),v=>v.tones[0]),[other,base]);
}
check('major','F','B4','b','n');check('major','G','F4','#','n');check('major','C','C4','n','#');
for(const scale of Object.keys(M.iranianIntervals))for(const [key]of M.iranianTonics){const signature=M.iranianSignature(scale,key);for(const degree of signature.degrees){if(!['k','o','bk','#o'].includes(degree.accidental))continue;check(scale,key,degree.letter+'4',degree.accidental,'n');}}
const legacy=M.fresh();legacy.metadata.key='F';legacy.score.measures=[{notes:[{pitch:'B4',duration:'q',accidental:'',at:0},{pitch:'B4',duration:'q',accidental:'',at:M.wholeUnits/4}]}];
const oldSounds=M.timeline(legacy).events.map(e=>e.hz);M.pinAccidentals(legacy,0);assert.deepEqual(M.timeline(legacy).events.map(e=>e.hz),oldSounds);legacy.score.measures[0].notes[0].accidental='n';assert.deepEqual(Array.from(R.measureAccidentals(legacy,0,1).values(),v=>v.tones[0]),['n','b']);

for(const [pitch,base,other]of [['B4','b','n'],['B4','b','k'],['E4','k','n'],['E4','k','b']]){
 const s=M.fresh();Object.assign(s.metadata,{scale_type:'iran_shur',key:'D'});s.score.measures=[{notes:[{pitch,duration:'q',accidental:other}]},{notes:[]},{notes:[{pitch,duration:'q',accidental:base},{pitch,duration:'q',accidental:base,at:M.wholeUnits/4}]}];
 assert.deepEqual(Array.from(R.measureAccidentals(s,2,1).values(),v=>v.tones[0]),[base,'']);
 s.score.measures[0].notes[0].accidental=base;assert.equal(R.measureAccidentals(s,2,1).get(0).tones[0],'');
}
console.log('Accidental state transitions, repetition suppression, signature returns, bar reset and stable edits passed: '+root);
