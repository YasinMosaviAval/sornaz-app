/* Stable vector symbols: independent of platform music-font metrics. */
(function(root){
'use strict';
const paths={trash:'<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>','eye-off':'<path d="m3 3 18 18M10 5.2c6.5-1 12 6.8 12 6.8a21 21 0 0 1-3 3.8M6 6.5A21 21 0 0 0 2 12s3.5 7 10 7a11 11 0 0 0 4-1M10 10a3 3 0 0 0 4 4"/>',pdf:'<path d="M7 2h13v16H7zM3 6v16h13"/><path d="M9 13V8h1a1.3 1.3 0 0 1 0 2.6H9m4 2.4V8h.5c2 0 2 5 0 5H13m4 0V8h2m-2 2.5h1.7"/>',chevron:'<path d="m5 9 7 7 7-7"/>',rest:'<path fill="currentColor" stroke="none" d="m10 2 7 6-5 6 5 6c-7-3-9 1-4 6-9-4-8-10-2-10l-6-5 7-6Z" transform="translate(2 1) scale(.78)"/>'};
function icon(kind){return '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+paths[kind]+'</svg>';}
function note(value){
 const flags={8:1,16:2,32:3,64:4}[value]||0;
 let content=value==='w'?'<ellipse cx="12" cy="17" rx="6" ry="3.5" fill="none" stroke="currentColor" stroke-width="2" transform="rotate(-16 12 17)"/>':'<ellipse cx="8" cy="27" rx="4.6" ry="3" fill="'+(value==='h'?'none':'currentColor')+'" stroke="currentColor" stroke-width="1.5" transform="rotate(-18 8 27)"/><path d="M12 26V3" stroke="currentColor" stroke-width="1.6"/>';
 for(let i=0;i<flags;i++)content+='<path d="M12 '+(3+i*4)+'c1 4 8 4 6 10 4-7-4-8-6-10" fill="currentColor"/>';
 return '<svg class="note-glyph" viewBox="0 0 24 34" aria-hidden="true">'+content+'</svg>';
}
// Conventional overlapping practice ranges, in beats of the selected beat unit.
const tempoRanges=[['Larghissimo',20,24],['Grave',25,45],['Largo',40,60],['Lento',45,60],['Larghetto',60,66],['Adagio',66,76],['Adagietto',70,80],['Andante',76,108],['Andantino',80,108],['Marcia moderato',83,85],['Andante moderato',92,112],['Moderato',108,120],['Allegretto',112,120],['Allegro moderato',116,120],['Allegro',120,168],['Vivace',168,176],['Vivacissimo',172,176],['Allegrissimo',172,176],['Presto',168,200],['Prestissimo',200,300]];
function tempos(unit,bpm){return unit&&Number(bpm)>=20&&Number(bpm)<=300?tempoRanges.filter(([,lo,hi])=>Number(bpm)>=lo&&Number(bpm)<=hi).map(([name,lo,hi])=>[name,name+' ('+lo+'–'+hi+' BPM)']):[];}
function center(scope){
 for(const svg of scope.querySelectorAll('.note-glyph,.rest-key svg,.palette-key svg')){
  const box=svg.getBBox(),width=24,height=svg.classList.contains('note-glyph')?34:24;
  if(!box.width||!box.height)continue;
  svg.setAttribute('viewBox',[box.x+box.width/2-width/2,box.y+box.height/2-height/2,width,height].join(' '));
 }
}
root.NotationSymbols={icon,note,tempos,center};
})(globalThis);
