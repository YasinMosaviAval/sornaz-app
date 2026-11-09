/* Stable vector symbols: independent of platform music-font metrics. */
(function(root){
'use strict';
const paths={close:'<path d="m6 6 12 12M18 6 6 18"/>',trash:'<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',upload:'<path d="M12 16V3m0 0L7 8m5-5 5 5M4 16v4h16v-4"/>',eye:'<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>','eye-off':'<path d="m3 3 18 18M10 5.2c6.5-1 12 6.8 12 6.8a21 21 0 0 1-3 3.8M6 6.5A21 21 0 0 0 2 12s3.5 7 10 7a11 11 0 0 0 4-1M10 10a3 3 0 0 0 4 4"/>',pdf:'<path d="M7 2h13v16H7zM3 6v16h13"/><path d="M9 13V8h1a1.3 1.3 0 0 1 0 2.6H9m4 2.4V8h.5c2 0 2 5 0 5H13m4 0V8h2m-2 2.5h1.7"/>',chevron:'<path d="m5 9 7 7 7-7"/>',rest:'<path fill="currentColor" stroke="none" d="m10 2 7 6-5 6 5 6c-7-3-9 1-4 6-9-4-8-10-2-10l-6-5 7-6Z" transform="translate(2 1) scale(.78)"/>'};
function icon(kind){if(kind==='rest')return rest('q');return '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+paths[kind]+'</svg>';}
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
// Official Bravura 1.480 SMuFL codepoints and glyph bounds (OFL-1.1).
const bravuraGlyphs={"note:w":{"code":57810,"box":[-2,-7.44,22.36,14.92],"name":"noteWhole"},"rest:w":{"code":58595,"box":[-2,-2.36,15.28,9.76],"name":"restWhole"},"note:h":{"code":57811,"box":[-2,-37,17.64,44.8],"name":"noteHalfUp"},"rest:h":{"code":58596,"box":[-2,-7.68,15.28,9.76],"name":"restHalf"},"note:q":{"code":57813,"box":[-2,-37,17.28,44.64],"name":"noteQuarterUp"},"rest:q":{"code":58597,"box":[-1.96,-16.92,14.76,33.92],"name":"restQuarter"},"note:8":{"code":57815,"box":[-2,-36.92,26.64,44.44],"name":"note8thUp"},"rest:8":{"code":58598,"box":[-2,-8.96,13.88,21],"name":"rest8th"},"note:16":{"code":57817,"box":[-2,-36.92,27.24,44.44],"name":"note16thUp"},"rest:16":{"code":58599,"box":[-2,-9.16,16.8,31.16],"name":"rest16th"},"note:32":{"code":57819,"box":[-2,-42.92,26.52,50.44],"name":"note32ndUp"},"rest:32":{"code":58600,"box":[-2,-19.04,18.52,41.04],"name":"rest32nd"},"note:64":{"code":57821,"box":[-2,-50.88,26.52,58.4],"name":"note64thUp"},"rest:64":{"code":58601,"box":[-2,-19.2,20.92,51.32],"name":"rest64th"},"note:128":{"code":57823,"box":[-2,-58.32,26.52,65.84],"name":"note128thUp"},"rest:128":{"code":58602,"box":[-2,-29.56,23.4,61.56],"name":"rest128th"},"note:256":{"code":57825,"box":[-2,-65.2,26.64,72.72],"name":"note256thUp"},"rest:256":{"code":58603,"box":[-2,-29.84,25.64,71.84],"name":"rest256th"}};
function musicGlyph(kind,value){const glyph=bravuraGlyphs[kind+':'+value]||bravuraGlyphs[kind+':q'],reference=kind==='rest'&&['w','h'].includes(value),box=reference?[-4,glyph.box[1],20,glyph.box[3]]:glyph.box;return '<svg class="'+(kind==='note'?'note-glyph':'rest-glyph')+'" direction="ltr" data-music-font="Bravura" data-glyph="'+glyph.name+'" viewBox="'+box.join(' ')+'" aria-hidden="true">'+(reference?'<path class="rest-reference-line" d="M-3 0H15" stroke="currentColor" stroke-width=".8" fill="none"/>':'')+'<text class="bravura-symbol" direction="ltr" text-anchor="start" x="0" y="0" font-size="40" fill="currentColor" stroke="none">'+String.fromCodePoint(glyph.code)+'</text></svg>';}
function note(value){return musicGlyph('note',value);}
function rest(value){return musicGlyph('rest',value);}
// Conventional overlapping practice ranges, in beats of the selected beat unit.
const tempoRanges=[['Larghissimo',20,24],['Grave',25,45],['Largo',40,60],['Lento',45,60],['Larghetto',60,66],['Adagio',66,76],['Adagietto',70,80],['Andante',76,108],['Andantino',80,108],['Marcia moderato',83,85],['Andante moderato',92,112],['Moderato',108,120],['Allegretto',112,120],['Allegro moderato',116,120],['Allegro',120,168],['Vivace',168,176],['Vivacissimo',172,176],['Allegrissimo',172,176],['Presto',168,200],['Prestissimo',200,300]];
function tempos(unit,bpm){return unit&&Number(bpm)>=20&&Number(bpm)<=300?tempoRanges.filter(([,lo,hi])=>Number(bpm)>=lo&&Number(bpm)<=hi).map(([name,lo,hi])=>[name,name+' ('+lo+'–'+hi+' BPM)']):[];}
function center(scope){
 for(const svg of scope.querySelectorAll('.note-glyph,.rest-key svg,.palette-key svg')){if(svg.dataset.musicFont==='Bravura')continue;
  const box=svg.getBBox(),width=24,height=svg.classList.contains('note-glyph')?34:24;
  if(!box.width||!box.height)continue;
  svg.setAttribute('viewBox',[box.x+box.width/2-width/2,box.y+box.height/2-height/2,width,height].join(' '));
 }
}
root.NotationSymbols={icon,tool,note,rest,tempos,center};
})(globalThis);
