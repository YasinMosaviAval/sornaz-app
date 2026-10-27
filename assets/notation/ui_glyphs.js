/* Compact music notation previews, drawn from the bundled VexFlow font outlines. */
(function(root){
'use strict';
const cache=new Map(),esc=value=>String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const svg=(content,view='0 0 48 40')=>'<svg class="notation-control-glyph" viewBox="'+view+'" width="32" height="32" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">'+content+'</svg>';
const text=(value,x=24,y=25,size=17,extra='')=>'<text x="'+x+'" y="'+y+'" font-size="'+size+'" text-anchor="middle" fill="currentColor" stroke="none" '+extra+'>'+esc(value)+'</text>';
const no='<circle cx="24" cy="20" r="10" opacity=".4"/><path d="m17 27 14-14"/>';
const staff='<path opacity=".3" d="M3 10h42M3 15h42M3 20h42M3 25h42M3 30h42"/>';
const note='<ellipse cx="18" cy="29" rx="5" ry="3" fill="currentColor" stroke="none"/><path d="M23 29V8"/>';
function glyph(code,x,y,size=26){
 const key=[code,x,y,size].join(':');if(cache.has(key))return cache.get(key);
 const F=root.Vex?.Flow||root.VexFlow;let path='';
 const coordinate=value=>Math.round(value*1000)/1000;
 const add=(command,values)=>{path+=command+values.map(coordinate).join(' ');};
 const context={beginPath(){},moveTo(...args){add('M',args);},lineTo(...args){add('L',args);},quadraticCurveTo(...args){add('Q',args);},bezierCurveTo(...args){add('C',args);},fill(){path+='Z';}};
 try{F.Glyph.renderGlyph(context,x,y,size,code);}catch(_){return '';}
 const result='<path d="'+path+'" fill="currentColor" stroke="none"/>';cache.set(key,result);return result;
}
function clef(value){
 const [kind,octave]=String(value||'treble').split('_'),types={treble:['gClef',3],bass:['fClef',1],alto:['cClef',2],tenor:['cClef',1],soprano:['cClef',4],'mezzo-soprano':['cClef',3],'baritone-f':['fClef',2]};
 const [code,line]=types[kind]||types.treble;
 const lines='<path opacity=".32" d="M2 14h36M2 20h36M2 26h36M2 32h36M2 38h36"/>';
 const shape=glyph(code,11,14+line*6,22)||text(kind==='bass'?'𝄢':code==='cClef'?'𝄡':'𝄞',20,37,38);
 return svg(lines+shape+(octave?text('8',20,octave==='8va'?6:54,9):''),'0 0 40 56');
}
const barline=value=>staff+({double:'<path d="M22 7v26M27 7v26"/>',final:'<path d="M20 7v26M27 7v26"/><path stroke-width="4" d="M27 7v26"/>',hidden:'<path stroke-dasharray="3 3" opacity=".5" d="M24 7v26"/>'}[value]||'<path d="M24 7v26"/>');
function repeat(value){
 let content=staff;
 if(['start','both'].includes(value))content+='<path stroke-width="3.5" d="M12 7v26"/><path d="M17 7v26"/><circle cx="22" cy="17" r="1.6" fill="currentColor"/><circle cx="22" cy="23" r="1.6" fill="currentColor"/>';
 if(['end','both'].includes(value))content+='<path stroke-width="3.5" d="M38 7v26"/><path d="M33 7v26"/><circle cx="28" cy="17" r="1.6" fill="currentColor"/><circle cx="28" cy="23" r="1.6" fill="currentColor"/>';
 return content;
}
function accidental(value){
 const names={'#':'accidentalSharp',b:'accidentalFlat',n:'accidentalNatural','##':'accidentalDoubleSharp',bb:'accidentalDoubleFlat'};
 return names[value]?glyph(names[value],18,23,34)||text(value):text(({d:'¼♭','+':'¼♯'})[value]||value);
}
function keySignature(value){
 const major={C:0,G:1,D:2,A:3,E:4,B:5,'F#':6,'C#':7,F:-1,Bb:-2,Eb:-3,Ab:-4,Db:-5,Gb:-6,Cb:-7};
 const minor={Am:0,Em:1,Bm:2,'F#m':3,'C#m':4,'G#m':5,'D#m':6,'A#m':7,Dm:-1,Gm:-2,Cm:-3,Fm:-4,Bbm:-5,Ebm:-6,Abm:-7};
 const count=major[value]??minor[value]??0,code=count<0?'accidentalFlat':'accidentalSharp',positions=count<0?[19,10,22,13,25,16,28]:[10,19,7,16,25,13,22];let content=staff;
 if(!count)return content+glyph('accidentalNatural',21,22,22);
 for(let index=0;index<Math.abs(count);index++)content+=glyph(code,5+index*5.3,positions[index],20);
 return content;
}
function hairpin(value){return value==='stop'?'<path d="M9 10v20M39 10v20"/><path d="m14 12 20 8-20 8"/>':value==='diminuendo'?'<path d="m8 10 31 10L8 30"/>':'<path d="m39 10-31 10 31 10"/>';}
function octave(value){return text(value==='stop'?'8':value||'8va',21,18,15,'font-style="italic"')+'<path d="M5 25h36v7" stroke-dasharray="3 3"/>'+(value==='stop'?'<path d="m33 9 9 9m0-9-9 9"/>':'');}
function symbol(key,value){
 if(/^clef[12]$/.test(key)||key==='clef-change'||key==='clef')return clef(value);
 if(key==='displayNumber')return svg(staff+text(value||'12',24,8,10)+'<path d="M10 13v20M38 13v20"/>');
 if(key==='rehearsal')return svg('<rect x="12" y="5" width="24" height="29" rx="1"/>'+text(value||'A',24,27,22));
 if(key==='text'||key==='note-lyric')return svg(note+text('la',35,35,13)+'<path d="M9 38h31"/>');
 if(key==='note-chord-symbol')return svg(text(value||'C7',24,17,18)+'<path opacity=".3" d="M3 25h42M3 30h42M3 35h42"/>');
 if(key==='key')return svg(keySignature(value||'G'));
 if(key==='tempoBpm')return svg(note+text(value||'♩',36,22,12));
 if(key==='tempoMode')return svg(({ritardando:text('rit.',24,22,20,'font-style="italic"')+'<path d="M5 31h38" stroke-dasharray="3 3"/>',accelerando:text('accel.',24,22,15,'font-style="italic"')+'<path d="M5 31h38" stroke-dasharray="3 3"/>',aTempo:text('a tempo',24,24,12,'font-style="italic"'),instant:note+text('=',35,20,17)})[value]||note+'<path d="M32 7v20m-4-16 4-4 4 4"/>');
 if(key==='time')return svg(/^\d+\/\d+$/.test(value)?text(value.split('/')[0],24,18,18)+text(value.split('/')[1],24,36,18):text('4',24,18,18)+text('4',24,36,18));
 if(key==='timeSymbol')return svg(value==='cut'?glyph('timeSigCutCommon',16,20,42):value==='common'?glyph('timeSigCommon',16,20,42):text('4',24,18,18)+text('4',24,36,18));
 if(key==='length')return svg(staff+'<path d="M7 7v26M24 7v26"/>'+note.replace('18','34').replace('23','39'));
 if(key==='beamPattern')return svg('<path d="M7 28V9h12v19M29 28V9h12v19M7 13h12M29 13h12"/><ellipse cx="3" cy="29" rx="4" ry="2.5" fill="currentColor"/><ellipse cx="15" cy="29" rx="4" ry="2.5" fill="currentColor"/><ellipse cx="25" cy="29" rx="4" ry="2.5" fill="currentColor"/><ellipse cx="37" cy="29" rx="4" ry="2.5" fill="currentColor"/>');
 if(key==='barline')return svg(barline(value));
 if(key==='repeatLine')return svg(repeat(value||'both'));
 if(key==='repeatCount')return svg(repeat('end')+text('×'+(value||'2'),14,11,11));
 if(key==='ending')return svg('<path d="M5 30V9h38v21"/>'+text((value||'1')+'.',15,25,18));
 if(key==='multiRest')return svg('<path d="M7 15v18M41 15v18M7 24h34" stroke-width="3"/>'+text(value||'4',24,11,11));
 if(key==='measureRepeat')return svg(staff+'<circle cx="14" cy="12" r="2.5" fill="currentColor"/><circle cx="32" cy="28" r="2.5" fill="currentColor"/><path d="m14 31 18-22" stroke-width="3"/>'+(value==='2'?'<path d="M25 5v30"/>':''));
 if(key==='marker')return svg(value==='fine'?text('Fine',24,25,17,'font-style="italic"'):(value==='coda'||value==='toCoda'?glyph('coda',13,28,29):glyph('segno',17,29,33))+(value==='toCoda'?'<path d="M2 20h8m-3-3 3 3-3 3"/>':''));
 if(key==='jump')return svg(text(({dc:'D.C.',ds:'D.S.',dcAlFine:'D.C.',dsAlFine:'D.S.',dcAlCoda:'D.C.',dsAlCoda:'D.S.'})[value]||'D.C.',24,18,17)+(value?.includes('Fine')?text('al Fine',24,34,12):value?.includes('Coda')?glyph('coda',17,37,18):'<path d="M37 30H11l5-5m-5 5 5 5"/>'));
 if(key==='note-size')return svg('<g transform="translate('+(value==='cue'?'12 10':value==='small'?'7 5':'0 0')+') scale('+(value==='cue'?'.55':value==='small'?'.75':'1')+')">'+note+'</g>'+(value==='cue'?'<path d="M7 8h5v24H7M35 8h5v24h-5"/>':''));
 if(key==='note-hairpin')return svg(hairpin(value));
 if(key==='note-slide')return svg('<ellipse cx="7" cy="29" rx="4" ry="2.5" fill="currentColor"/><ellipse cx="40" cy="10" rx="4" ry="2.5" fill="currentColor"/>'+ (value==='portamento'?'<path d="m12 26 23-13"/>':'<path d="m12 26 3-5 5 1 1-5 5 1 1-5 5 1"/>'));
 if(key==='note-octave-shift')return svg(octave(value));
 if(key==='grace-kind')return svg('<g transform="translate(2 2) scale(.7)">'+note+'<path d="M23 8q8 1 8 8"/>'+(value==='acciaccatura'?'<path d="m14 20 19-10"/>':'')+'</g><path d="M27 31q9 8 16-1"/>');
 if(key==='note-tremolo'){let content=note;for(let i=0;i<Math.max(1,Math.min(3,Number(value)||1));i++)content+='<path stroke-width="3" d="m17 '+(13+i*5)+' 12-5"/>';return svg(content);}
 if(key==='note-pedal')return svg(value==='sustainUp'?glyph('keyboardPedalUp',16,29,36):value==='sostenutoUp'?text('Sost.',24,18,13)+glyph('keyboardPedalUp',18,37,22):value==='unaCorda'?text('una',24,17,14)+text('corda',24,32,14):value==='treCorde'?text('tre',24,17,14)+text('corde',24,32,14):value==='sostenutoDown'?text('Sost.',24,24,17,'font-style="italic"'):glyph('keyboardPedalPed',8,28,30));
 if(key==='harmonic')return svg('<path d="m18 17 7 7-7 7-7-7Z"/>'+text(value||'◦',34,13,12));
 if(key==='arpeggio-direction')return svg('<path d="M17 6q10 3 0 7t0 7 0 7 0 7M34 7v26"/>'+(value==='down'?'<path d="m29 28 5 5 5-5"/>':'<path d="m29 12 5-5 5 5"/>'));
 if(key==='ornamentUpperAccidental'||key==='ornamentLowerAccidental'){const upper=key==='ornamentUpperAccidental';return svg('<g transform="translate(12 '+(upper?-2:15)+') scale(.5)">'+accidental(value||'#')+'</g>'+text('tr',24,upper?35:15,18,'font-style="italic"'));}
 if(key==='ornament-accidental'||key==='accidental')return svg(accidental(value||'#'));
 if(key==='tone-finger'||key==='finger')return svg(text(value||'1',24,23,20)+'<path d="M12 33h24"/>');
 if(key==='dynamic')return svg(text(value||'mf',24,27,25,'font-family="serif" font-weight="bold" font-style="italic"'));
 if(key==='bow')return svg(value==='up'?'<path d="m10 9 14 24L38 9"/>':'<path d="M12 32V9h24v23M15 9v23"/>');
 if(key==='articulation')return svg(({staccato:'<circle cx="24" cy="20" r="3" fill="currentColor"/>',tenuto:'<path d="M12 20h24" stroke-width="3"/>',accent:'<path d="m13 11 23 9-23 9"/>',marcato:'<path d="m11 28 13-19 13 19"/>',staccatissimo:'<path d="m19 12 5 20 5-20Z" fill="currentColor"/>',fermata:'<path d="M8 27a16 16 0 0 1 32 0"/><circle cx="24" cy="26" r="2.5" fill="currentColor"/>',breath:text(',',24,25,34),caesura:'<path d="m14 30 9-21M25 30l9-21"/>'})[value]||'<circle cx="24" cy="13" r="2" fill="currentColor"/>'+note);
 if(key==='ornament')return svg(value==='trill'?glyph('ornamentTrill',13,27,38):'<path d="m7 20 6-8 8 16 8-16 8 16 5-8"/>'+(value?.startsWith('inverted')?'<path d="M24 7v26"/>':''));
 if(key==='tuplet')return svg('<path d="M5 31V11h38v20"/>'+text((value||'3:2').split(':')[0],24,27,18));
 return svg(note);
}
function field(key,value=''){return symbol(key,String(value));}
function option(key,value,label=''){
 const raw=String(value??'');if(raw===''&&!['note-size','barline','timeSymbol'].includes(key))return svg(no);
 if(key==='note-tremolo'&&raw==='0')return svg(no);
 return symbol(key,raw);
}
root.NotationGlyphs={field,option};
})(globalThis);
