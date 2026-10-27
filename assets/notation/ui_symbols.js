/* Stable vector symbols: independent of platform music-font metrics. */
(function(root){
'use strict';
const paths={trash:'<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',upload:'<path d="M12 16V3m0 0L7 8m5-5 5 5M4 16v4h16v-4"/>',eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>','eye-off':'<path d="m3 3 18 18M10 5.2c6.5-1 12 6.8 12 6.8a21 21 0 0 1-3 3.8M6 6.5A21 21 0 0 0 2 12s3.5 7 10 7a11 11 0 0 0 4-1M10 10a3 3 0 0 0 4 4"/>',pdf:'<path d="M7 2h13v16H7zM3 6v16h13"/><path d="M9 13V8h1a1.3 1.3 0 0 1 0 2.6H9m4 2.4V8h.5c2 0 2 5 0 5H13m4 0V8h2m-2 2.5h1.7"/>',chevron:'<path d="m5 9 7 7 7-7"/>',rest:'<path fill="currentColor" stroke="none" d="m10 2 7 6-5 6 5 6c-7-3-9 1-4 6-9-4-8-10-2-10l-6-5 7-6Z" transform="translate(2 1) scale(.78)"/>'};
function icon(kind){return '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+paths[kind]+'</svg>';}
const toolPaths={
 'staff-upper':'<path opacity=".35" d="M2 5h20M2 9h20M2 13h20M2 17h20M2 21h20"/><ellipse cx="10" cy="9" rx="3" ry="2" fill="currentColor"/><path d="M13 9V1"/>',
 'staff-lower':'<path opacity=".35" d="M2 3h20M2 7h20M2 11h20M2 15h20M2 19h20"/><ellipse cx="10" cy="15" rx="3" ry="2" fill="currentColor"/><path d="M13 15V6"/>',
 'voice-one':'<ellipse cx="7" cy="14" rx="3" ry="2" fill="currentColor"/><path d="M10 14V3"/><g opacity=".35"><ellipse cx="17" cy="11" rx="3" ry="2" fill="currentColor"/><path d="M14 11v11"/></g>',
 'voice-two':'<g opacity=".35"><ellipse cx="7" cy="14" rx="3" ry="2" fill="currentColor"/><path d="M10 14V3"/></g><ellipse cx="17" cy="11" rx="3" ry="2" fill="currentColor"/><path d="M14 11v11"/>',
 'add-bar':'<path opacity=".45" d="M2 7h13M2 12h13M2 17h13"/><path d="M3 4v16M14 4v16M18 12h6M21 9v6"/>',
 'remove-bar':'<path opacity=".45" d="M2 7h13M2 12h13M2 17h13"/><path d="M3 4v16M14 4v16M18 12h6"/>',
 measure:'<path opacity=".45" d="M2 5h20M2 10h20M2 15h20M2 20h20"/><path d="M5 2v21M19 2v21M11 3v4M14 8v4M10 13v4M14 18v4"/>',
 copy:'<rect x="8" y="8" width="12" height="13" rx="2"/><path d="M15 8V3H3v12h5"/>',
 cut:'<circle cx="5" cy="6" r="3"/><circle cx="5" cy="18" r="3"/><path d="m8 8 13 13M8 16 21 3"/>',
 duplicate:'<ellipse cx="6" cy="17" rx="3" ry="2" fill="currentColor"/><path d="M9 17V4"/><ellipse cx="14" cy="19" rx="3" ry="2" fill="currentColor"/><path d="M17 19V6M17 3h6M20 0v6"/>',
 beam:'<ellipse cx="5" cy="18" rx="3" ry="2" fill="currentColor"/><ellipse cx="17" cy="15" rx="3" ry="2" fill="currentColor"/><path d="M8 18V5l12-3v13M8 8l12-3"/>',
 'move-up':'<path opacity=".35" d="M2 6h20M2 18h20"/><path d="M12 20V4m-5 5 5-5 5 5"/>',
 'move-down':'<path opacity=".35" d="M2 6h20M2 18h20"/><path d="M12 4v16m-5-5 5 5 5-5"/>',
 'cross-beam':'<path opacity=".35" d="M2 6h20M2 18h20"/><ellipse cx="5" cy="18" rx="3" ry="2" fill="currentColor"/><ellipse cx="17" cy="6" rx="3" ry="2" fill="currentColor"/><path d="M8 18V4h6v2"/>',
 paste:'<path d="M8 4H4v18h16V4h-4"/><rect x="8" y="1" width="8" height="6" rx="2"/><path d="M8 12h8M8 16h8"/>',
 chord:'<path d="M15 4v14"/><ellipse cx="11" cy="18" rx="4" ry="2" fill="currentColor"/><ellipse cx="11" cy="13" rx="4" ry="2" fill="currentColor"/><ellipse cx="11" cy="8" rx="4" ry="2" fill="currentColor"/>',
 tie:'<ellipse cx="5" cy="9" rx="3" ry="2" fill="currentColor"/><ellipse cx="19" cy="9" rx="3" ry="2" fill="currentColor"/><path d="M4 15q8 7 16 0"/>',
 slur:'<ellipse cx="5" cy="9" rx="3" ry="2" fill="currentColor"/><ellipse cx="19" cy="13" rx="3" ry="2" fill="currentColor"/><path d="M3 17q9 6 19 1"/>',
 arpeggio:'<path d="M5 2q6 2 0 5t0 5 0 5 0 5M18 3v15"/><ellipse cx="14" cy="18" rx="4" ry="2" fill="currentColor"/><ellipse cx="14" cy="13" rx="4" ry="2" fill="currentColor"/><ellipse cx="14" cy="8" rx="4" ry="2" fill="currentColor"/>',
 accidental:'<path d="M4 3q-5 9 0 18M20 3q5 9 0 18M9 3v18M15 2v18M7 10l10-3M7 17l10-3"/>',
 grace:'<ellipse cx="9" cy="17" rx="3" ry="2" fill="currentColor"/><path d="M12 17V4l6 3M7 12l11-6"/>',
 note:'<ellipse cx="9" cy="18" rx="4" ry="2.5" fill="currentColor"/><path d="M13 18V3"/>'
};
function tool(kind){return '<svg class="notation-tool-icon" viewBox="0 0 24 24" width="24" height="24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">'+(toolPaths[kind]||toolPaths.note)+'</svg>';}
function note(value){
 const flags={8:1,16:2,32:3,64:4,128:5,256:6}[value]||0;
 let content=value==='w'?'<ellipse cx="12" cy="17" rx="6" ry="3.5" fill="none" stroke="currentColor" stroke-width="2" transform="rotate(-16 12 17)"/>':'<ellipse cx="8" cy="27" rx="4.6" ry="3" fill="'+(value==='h'?'none':'currentColor')+'" stroke="currentColor" stroke-width="1.5" transform="rotate(-18 8 27)"/><path d="M12 26V3" stroke="currentColor" stroke-width="1.6"/>';
 for(let i=0;i<flags;i++)content+='<path d="M12 '+(3+i*4)+'c1 4 8 4 6 10 4-7-4-8-6-10" fill="currentColor"/>';
 return '<svg class="note-glyph" viewBox="0 0 24 34" aria-hidden="true">'+content+'</svg>';
}
function rest(value){
 let content;
 if(value==='w'||value==='h'){const y=value==='w'?12:18;content=`<path d="M4 ${y}h16" stroke="currentColor" stroke-width="1.6"/><rect x="7" y="${value==='w'?y:y-5}" width="10" height="5" fill="currentColor"/>`;}
 else if(value==='q')content='<path d="m13 3 5 7-7 8 6 6c-8-3-10 2-5 6-10-5-8-11-3-12l-6-6 8-9Z" fill="currentColor"/>';
 else{const count={8:1,16:2,32:3,64:4,128:5,256:6}[value]||1;content='<path d="M17 4 8 31" stroke="currentColor" stroke-width="1.8"/>';for(let i=0;i<count;i++)content+=`<circle cx="10" cy="${7+i*3}" r="2.2" fill="currentColor"/><path d="M10 ${7+i*3}q5 2 6-3" fill="none" stroke="currentColor" stroke-width="1.5"/>`;}
 return '<svg class="rest-glyph" viewBox="0 0 24 34" aria-hidden="true">'+content+'</svg>';
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
root.NotationSymbols={icon,tool,note,rest,tempos,center};
})(globalThis);
