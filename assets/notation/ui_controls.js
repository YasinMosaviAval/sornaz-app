/* Graphic notation controls. Original form fields keep the editor's data contract. */
(function (global) {
'use strict';
if (global.NotationControls) return;
let scope, locale='en', popup=null, help=null, hoverTimer, touchTimer, touch=null, suppressedUntil=0, suppressedTarget=null, serial=0;
const fields={
 displayNumber:['شماره میزان','Measure number','شماره‌ای که کنار میزان در پارتیتور و خروجی چاپ می‌شود؛ ترتیب میزان‌ها یا زمان پخش را عوض نمی‌کند. خالی‌بودن یعنی شماره‌گذاری خودکار.','The printed measure number. It does not reorder measures or change playback. Leave it empty for automatic numbering.'],
 rehearsal:['علامت تمرین','Rehearsal mark','حرف یا شماره‌ای مانند A یا B در یک کادر بالای میزان نمایش می‌دهد تا نوازندگان محل شروع تمرین را سریع پیدا کنند. اثری بر صدا ندارد.','Places a boxed letter or number, such as A or B, above this measure so musicians can find a rehearsal point. It does not change the sound.'],
 text:['توضیح میزان','Measure note','یک دستور نوشتاری مانند «آرام» را بالای این میزان قرار می‌دهد. این متن با شعر متصل به نت متفاوت است و به‌تنهایی پخش را تغییر نمی‌دهد.','Places a written instruction above this measure. It is separate from lyrics attached to a note and does not itself change playback.'],
 key:['تغییر سرکلید','Key change','سرکلید را از این میزان تا تغییر بعدی تعیین می‌کند. گزینه بازگشت، سرکلید قبلی قطعه را ادامه می‌دهد.','Changes the key signature from this measure until the next change. The inherit option continues the previous key.'],
 clef1:['کلید حامل بالا','Upper staff clef','کلید حامل اول را از این میزان تغییر می‌دهد. شکل کلید و جای آن روی خطوط، ارتفاع نت‌های نوشته‌شده را مشخص می‌کند.','Changes the first staff clef from this measure. The clef shape and position on the staff define how written pitches are read.'],
 clef2:['کلید حامل پایین','Lower staff clef','کلید حامل دوم را از این میزان تغییر می‌دهد. با گزینه بازگشت، کلید قبلی این حامل ادامه پیدا می‌کند.','Changes the second staff clef from this measure. Inherit continues that staff’s previous clef.'],
 tempoMode:['تغییر تمپو','Tempo change','تغییر فوری سرعت، کندشدن تدریجی، تندشدن تدریجی یا بازگشت به سرعت اصلی را از این میزان مشخص می‌کند.','Sets an immediate tempo change, gradual slowing, gradual speeding up, or a return to the original tempo from this measure.'],
 tempoBpm:['سرعت مقصد','Target BPM','سرعت پایان تغییر را با تعداد ضرب در دقیقه تعیین می‌کند. ابتدا نوع تغییر تمپو را انتخاب کنید؛ برای بازگشت به تمپوی اصلی، سرعت از مشخصات قطعه خوانده می‌شود.','Sets the target beats per minute. Choose a tempo-change type first. A Tempo uses the original score tempo automatically.'],
 time:['میزان‌نما','Time signature','تعداد ضرب‌ها و واحد ضرب این میزان و میزان‌های بعدی را مشخص می‌کند. تغییر میزان‌نما نباید نت‌های موجود را از ظرفیت میزان خارج کند.','Sets the number of beats and beat unit for this and following measures. Existing notes must still fit the measure.'],
 beamPattern:['گروه‌بندی چنگ‌ها','Beam grouping','نحوه اتصال چنگ‌ها را با جمع‌هایی مانند ۳+۳ تعیین می‌کند. جمع گروه‌ها باید با صورت میزان‌نما برابر باشد؛ کشش نت‌ها تغییر نمی‌کند.','Groups beams with a pattern such as 3+3. The total must match the time-signature numerator; note durations do not change.'],
 timeSymbol:['نماد میزان‌نما','Time symbol','نماد C برای چهارچهارم و C خط‌دار برای دو دوم است. حالت معمولی، میزان‌نما را به صورت عددی نمایش می‌دهد.','Common time C means 4/4; cut time means 2/2. Normal displays a numeric time signature.'],
 length:['میزان ناقص','Pickup length','ظرفیت این میزان را برای پیش‌ضرب یا میزان پایانی کوتاه می‌کند. گزینه کامل، ظرفیت عادی میزان‌نما را برمی‌گرداند.','Shortens this measure for a pickup or short final measure. Full restores the time signature’s normal capacity.'],
 barline:['خط میزان','Barline','شکل خط پایان میزان را انتخاب می‌کند: معمولی، دولا، پایان یا پنهان. این گزینه با خط تکرار متفاوت است.','Chooses a normal, double, final, or hidden end barline. Repeat barlines are configured separately.'],
 multiRest:['سکوت چندمیزانی','Multi-measure rest','چند میزان خالی و بدون علامت ساختاری را در یک نماد سکوت فشرده می‌کند. عدد روی نماد، تعداد میزان‌های سکوت است.','Condenses consecutive empty measures without structural markings into one rest symbol. The number shows how many measures to rest.'],
 repeatLine:['خط تکرار','Repeat barline','نقطه‌های رو به داخل، شروع یا پایان بخش تکرارشونده را مشخص می‌کنند. برای تعداد اجرا و ولت، ابتدا بخش تکرار را تعیین کنید.','Marks the start or end of a repeated passage with inward-facing dots. Establish the repeat before setting repeat count or alternate endings.'],
 repeatCount:['تعداد تکرار','Repeat count','تعداد اجرای بخش تکرارشونده را در خط پایان تکرار تعیین می‌کند. بدون پایان تکرار، این گزینه کاربرد ندارد.','Sets how many times the repeated passage is played at its closing repeat barline. It requires an end repeat.'],
 ending:['ولت','Alternate ending','شماره داخل کادر ولت مشخص می‌کند این بخش در کدام بار اجرای تکرار نواخته شود. ابتدا یک بخش تکرارشونده تعریف کنید.','The bracket number specifies on which repeat pass this ending is played. Define a repeated passage first.'],
 measureRepeat:['تکرار میزان قبلی','Measure repeat','به جای نوشتن دوباره نت‌ها، یک یا دو میزان قبلی را تکرار می‌کند. باید به تعداد لازم میزان قبلی وجود داشته باشد.','Repeats the previous one or two measures without rewriting their notes. Enough preceding measures must exist.'],
 marker:['علامت راهنما','Navigation marker','محل سنیو، کودا، رفتن به کودا یا پایان را در قطعه مشخص می‌کند. دستورهای پرش برای یافتن مقصد از این علامت‌ها استفاده می‌کنند.','Places a Segno, Coda, To Coda, or Fine marker. Jump instructions use these markers as navigation destinations.'],
 jump:['دستور پرش','Jump instruction','D.C. به آغاز قطعه و D.S. به سنیو برمی‌گردد. گزینه‌های al Fine و al Coda تا علامت پایان یا کودا ادامه می‌دهند؛ مقصد لازم باید در قطعه وجود داشته باشد.','D.C. returns to the beginning; D.S. returns to Segno. Al Fine and al Coda continue to the corresponding ending or Coda marker. Required destination markers must exist.'],
 'note-size':['اندازه نت','Note size','نت معمولی، نت کوچک یا نت راهنمای بی‌صدا را انتخاب می‌کند. نت راهنما برای نشان‌دادن ورود نوازنده است و پخش نمی‌شود.','Chooses normal, small, or silent cue notation. A cue shows another part as a performance guide and does not play.'],
 'note-hairpin':['تغییر تدریجی شدت','Hairpin','علامت بازشونده شدت را زیاد و علامت بسته‌شونده شدت را کم می‌کند. علامت پایان، تغییر تدریجی قبلی را می‌بندد.','An opening wedge increases loudness; a closing wedge decreases it. The stop option closes the preceding hairpin.'],
 'note-slide':['لغزش به نت بعدی','Slide to next note','گلیساندو یا پورتامنتو را از این نت به نت بعدی همین حامل و صدا می‌کشد. برای این گزینه باید نت مقصد وجود داشته باشد.','Draws a glissando or portamento from this note to the next note in the same staff and voice. A destination note must exist.'],
 'note-octave-shift':['انتقال اکتاو','Octave shift','علامت 8va یا 15ma صدا را بالاتر و 8vb یا 15mb پایین‌تر می‌برد، در حالی که نت‌نویسی خواناتر می‌ماند. گزینه پایان، خط انتقال را می‌بندد.','8va/15ma sound one/two octaves higher; 8vb/15mb sound lower while keeping notation readable. Stop closes the octave line.'],
 'grace-kind':['نوع نت زینت','Grace-note type','نوع نت زینت را برای حالت افزودن زینت انتخاب می‌کند: نت زینت ساده، آپوجیاتورا یا آچاکاتورای خط‌خورده. ابتدا افزودن نت زینت را فعال کنید.','Chooses a grace note, appoggiatura, or slashed acciaccatura for grace-entry mode. Enable Add grace note first.'],
 'note-tremolo':['ترمولو','Tremolo','خط‌های روی ساقه، اجرای سریع و تکرارشونده نت را نشان می‌دهند. تعداد خط‌ها نوع تقسیم ترمولو را مشخص می‌کند.','Stem strokes indicate rapid repeated notes. The number of strokes specifies the tremolo subdivision.'],
 'note-chord-symbol':['نماد آکورد','Chord symbol','نام آکوردی مانند Am یا Cmaj7 را بالای این نت می‌نویسد. این نام به‌تنهایی نت تازه‌ای به آکورد اضافه نمی‌کند.','Writes a chord name such as Am or Cmaj7 above this note. The name alone does not add notes to the chord.'],
 'note-lyric':['متن ترانه','Lyric','واژه یا هجای ترانه را به همین نت متصل و زیر حامل نمایش می‌دهد. دستور کلی یک میزان را در توضیح میزان بنویسید.','Attaches a word or syllable to this note below the staff. Use the measure-note field for general performance instructions.'],
 'note-pedal':['پدال پیانو','Piano pedal','گرفتن و رهاکردن پدال دمپر یا سوستنوتو و تغییر اونا کوردا را از محل این نت مشخص می‌کند.','Marks sustain or sostenuto pedal press/release and una-corda changes at this note.'],
 'tone-finger':['انگشت‌گذاری نت آکورد','Chord-tone fingering','شماره انگشت را فقط برای این نت از آکورد نمایش می‌دهد. ارتفاع و کشش آن نت تغییر نمی‌کند.','Displays a fingering number for this individual chord tone without changing its pitch or duration.'],
 'clef-change':['تغییر کلید در محل نت','Clef change at note','کلید را در زمان شروع این نت و روی همین حامل تغییر می‌دهد؛ تغییر کلید ابتدای میزان از ابزارهای میزان انجام می‌شود.','Changes the clef at this note’s start time on the same staff. Use measure tools for a change at the beginning of the measure.'],
 harmonic:['هارمونیک طبیعی','Natural harmonic','نماد لوزی و صدای هارمونیک طبیعی را با هارمونیک دوم، سوم یا چهارم مشخص می‌کند. فقط برای نت صدادار کاربرد دارد.','Uses diamond notation for the second, third, or fourth natural harmonic. It applies to pitched notes.'],
 'arpeggio-direction':['جهت آرپژ','Arpeggio direction','جهت اجرای نت‌های آکورد را از پایین به بالا یا از بالا به پایین تعیین می‌کند. ابتدا آرپژ را برای آکورد فعال کنید.','Sets whether the chord is arpeggiated from low to high or high to low. Enable arpeggio on a chord first.'],
 'ornament-accidental':['علامت تغییر زینت','Ornament accidental','علامت تغییر نت بالایی یا پایینی زینت انتخاب‌شده را مشخص می‌کند؛ بدون انتخاب زینت، این تنظیم کاربرد ندارد.','Sets the upper or lower accidental for the selected ornament. Choose an ornament first.'],
 accidental:['علامت تغییر','Accidental','ارتفاع نت را با دیز، بمل، بکار یا علامت ربع‌پرده تغییر می‌دهد. روی نت انتخاب‌شده یا نت تازه اثر می‌گذارد.','Alters pitch with a sharp, flat, natural, or quarter-tone accidental, for the selected note or the next note entered.'],
 dynamic:['دینامیک','Dynamics','شدت اجرای نت را با علامت‌هایی مانند p، mf و f مشخص می‌کند.','Sets performance loudness with markings such as p, mf, and f.'],
 articulation:['تلفظ نت','Articulation','شیوه اجرای نت، مانند استاکاتو، تنوتو، آکسان یا فرما را مشخص می‌کند.','Sets how the note is played, such as staccato, tenuto, accent, or fermata.'],
 bow:['جهت آرشه','Bowing','علامت آرشه بالا یا آرشه پایین را به نت اضافه می‌کند.','Adds an up-bow or down-bow mark to the note.'],
 finger:['انگشت‌گذاری','Fingering','شماره انگشت پیشنهادی را کنار نت نمایش می‌دهد؛ صفر معمولاً سیم آزاد را نشان می‌دهد.','Displays the suggested fingering next to the note; zero usually indicates an open string.'],
 ornament:['زینت','Ornament','تریل، موردان یا گردش را به نت اضافه می‌کند. تنظیم علامت تغییر زینت پس از انتخاب آن در دسترس است.','Adds a trill, mordent, or turn. Ornament accidentals become relevant after choosing an ornament.'],
 tuplet:['تقسیم نامنظم','Tuplet','تعداد مشخصی نت را در زمان تعداد معمول دیگری قرار می‌دهد؛ مثلاً سه نت در زمان دو نت.','Fits a group of notes into the time normally occupied by another number, such as three in the time of two.']
};
const actions={
 back:['به صفحه قبلی برمی‌گردد؛ برای تغییرات ذخیره‌نشده ابتدا ذخیره یا انصراف را انتخاب کنید.','Returns to the previous page. Save or discard unsaved changes when prompted.'],
 save:['نت و مشخصات آن را ذخیره می‌کند. وضعیت ذخیره‌شده کنار عنوان قطعه نمایش داده می‌شود.','Saves the score and its metadata. The status beside the title indicates whether changes are saved.'],
 play:['پخش قطعه را شروع یا متوقف می‌کند؛ نت در حال اجرا روی حامل مشخص می‌شود.','Starts or pauses score playback. The current note is highlighted on the staff.'],
 metadata:['مشخصات قطعه، ساز، میزان‌نما و تمپوی اصلی را برای ویرایش باز می‌کند.','Opens the score metadata, instrument, time signature, and original tempo for editing.'],
 undo:['آخرین تغییر نت‌نویسی را واگرد می‌کند.','Undoes the most recent notation change.'],
 redo:['تغییر واگردشده را دوباره اعمال می‌کند.','Reapplies the most recently undone change.'],
 'add-bar':['یک میزان خالی به قطعه اضافه می‌کند.','Adds an empty measure to the score.'],
 'remove-bar':['میزان جاری و نت‌های داخل آن را حذف می‌کند. این تغییر با واگرد قابل بازگردانی است.','Removes the current measure and its notes. Undo can restore the change.'],
 staff:['حاملی را انتخاب می‌کند که نت بعدی روی آن نوشته می‌شود.','Chooses the staff where the next note will be entered.'],
 voice:['صدای مستقل نت‌های بعدی را انتخاب می‌کند؛ صداها می‌توانند در یک حامل هم‌زمان اجرا شوند.','Chooses the independent voice for new notes. Voices can sound simultaneously on one staff.'],
 'copy-notes':['نت‌های انتخاب‌شده را بدون حذف آن‌ها در حافظه کپی می‌کند.','Copies the selected notes to the clipboard without removing them.'],
 'cut-notes':['نت‌های انتخاب‌شده را برای انتقال در حافظه قرار می‌دهد و از محل فعلی برمی‌دارد.','Cuts the selected notes to the clipboard for moving to another location.'],
 'duplicate-notes':['یک نسخه تازه از نت‌های انتخاب‌شده در قطعه ایجاد می‌کند.','Creates another copy of the selected notes in the score.'],
 'paste-notes':['نت‌های کپی یا بریده‌شده را در محل انتخاب‌شده قرار می‌دهد.','Inserts copied or cut notes at the selected location.'],
 'beam-group':['چنگ‌های انتخاب‌شده در یک صدا و میزان را به یک گروه متصل یا اتصال دستی آن‌ها را حذف می‌کند.','Groups selected short notes in one voice and measure under one beam, or removes their manual beam group.'],
 'cross-beam':['چنگ‌های انتخاب‌شده روی دو حامل یک میزان را به هم متصل یا این اتصال را حذف می‌کند.','Connects selected short notes across two staves in one measure, or removes that cross-staff beam.'],
 'move-staff':['نت‌های انتخاب‌شده را به حامل مقصد منتقل می‌کند.','Moves selected notes to the destination staff.'],
 chord:['افزودن نت به آکورد را فعال یا غیرفعال می‌کند؛ با انتخاب کلاویه، یک ارتفاع هم‌زمان به نت انتخاب‌شده اضافه می‌شود.','Toggles chord-entry mode. A piano key adds a simultaneous pitch to the selected note.'],
 'chord-tone':['این ارتفاع از آکورد را برای ویرایش انتخاب می‌کند.','Selects this pitch within the chord for editing.'],
 'remove-chord-tone':['فقط این ارتفاع را از آکورد برمی‌دارد. سایر نت‌های آکورد حفظ می‌شوند.','Removes only this pitch from the chord; the other chord tones remain.'],
 'grace-mode':['ورود نت زینت را فعال یا تمام می‌کند. پس از فعال‌کردن، نوع زینت را انتخاب و کلاویه را لمس کنید.','Starts or stops grace-note entry. Enable it, choose a grace type, and use the piano keys.'],
 'remove-grace':['این نت زینت را از نت اصلی برمی‌دارد.','Removes this grace note from its principal note.'],
 'tone-tie':['این ارتفاع از آکورد را به همان ارتفاع در نت مجاور وصل می‌کند تا بدون حمله دوباره ادامه یابد.','Ties this chord tone to the same pitch in an adjacent note so it continues without a new attack.'],
 'remove-clef-change':['تغییر کلید ثبت‌شده در این زمان را حذف می‌کند و کلید قبلی ادامه پیدا می‌کند.','Removes this timed clef change so the preceding clef continues.'],
 'measure-tools-open':['تنظیمات میزان جاری، شامل کلیدها، تکرارها و علامت‌های راهنما را باز می‌کند.','Opens the current measure’s clefs, repeats, navigation, and other measure settings.'],
 palette:['ابزارهای نت‌نویسی، علائم تغییر، دینامیک و زینت را باز یا بسته می‌کند.','Opens or closes the notation palette for accidentals, dynamics, and ornaments.'],
 duration:['کشش نت‌های بعدی را انتخاب می‌کند؛ شکل نماد، مقدار زمانی نت را نشان می‌دهد.','Chooses the duration of newly entered notes; the symbol shows the note’s time value.'],
 dots:['یک یا دو نقطه به کشش اضافه می‌کند. نقطه اول نصف کشش و نقطه دوم یک‌چهارم کشش پایه را می‌افزاید.','Adds one or two duration dots. The first adds half the base duration; the second adds another quarter.'],
 'rest-duration':['یک سکوت با کشش نماد انتخاب‌شده وارد می‌کند؛ کشش نت عادی تغییر نمی‌کند.','Inserts a rest with the selected symbol’s duration without changing the ordinary note duration.'],
 rest:['انتخاب‌گر کشش سکوت را باز می‌کند؛ با انتخاب نماد، سکوت همان کشش درج می‌شود.','Opens the rest-duration picker; choosing a symbol inserts a rest of that duration.'],
 'delete-note-rest':['نت انتخاب‌شده را به سکوت هم‌کشش تبدیل می‌کند.','Replaces the selected note with a rest of the same duration.'],
 'delete-note-compact':['نت انتخاب‌شده را حذف و فضای آن را از این صدا جمع می‌کند.','Deletes the selected note and closes its time gap within that voice.'],
 'import-score':['یک فایل نت پشتیبانی‌شده را برای پیش‌نمایش و ورود به ویرایشگر انتخاب می‌کند.','Chooses a supported score file for preview and import.'],
 export:['یک نسخه قابل نگهداری از نت را به فایل خروجی می‌دهد.','Exports a portable copy of the score to a file.'],
 pdf:['نمای چاپ پارتیتور را برای چاپ یا ذخیره PDF باز می‌کند.','Opens the printable score for printing or saving as PDF.']
};
actions.yes=['عملیات نوشته‌شده در این پنجره را تأیید و اجرا می‌کند. پیش از تأیید، متن پنجره را بخوانید.','Confirms and performs the operation described in this dialog. Read the dialog before confirming.'];
actions.no=['این عملیات را لغو می‌کند و به صفحه قبلی برمی‌گردد.','Cancels this operation and returns to the previous view.'];
const pickSelector='select[data-measure-choice],select[data-note-size],select[data-note-hairpin],select[data-note-slide],select[data-note-octave-shift],select[data-grace-kind],select[data-note-tremolo],select[data-note-pedal],select[data-tone-finger],select[data-clef-change],select[data-harmonic],select[data-arpeggio-direction],select[data-ornament-accidental]';
const keyAttributes=['note-size','note-hairpin','note-slide','note-octave-shift','grace-kind','note-tremolo','note-chord-symbol','note-lyric','note-pedal','tone-finger','clef-change','harmonic','arpeggio-direction','ornament-accidental'];
const tr=(fa,en)=>locale==='fa'?fa:en;
function keyOf(node){return node.dataset.measureChoice||node.dataset.measureNumber||node.dataset.measureText||node.dataset.ornamentAccidental||keyAttributes.find(key=>node.hasAttribute('data-'+key))||node.dataset.choice||(node.hasAttribute('data-tuplet')?'tuplet':'');}
function fieldInfo(key){const ornament=/^ornament(Upper|Lower)Accidental$/.test(key),info=fields[key]||fields[key.replace(/^clef[12]$/,'clef1')]||(ornament?fields['ornament-accidental']:null);if(!info)return null;let name=locale==='fa'?info[0]:info[1];if(ornament)name=key.includes('Upper')?tr('علامت تغییر بالای زینت','Upper ornament accidental'):tr('علامت تغییر پایین زینت','Lower ornament accidental');return {name,text:locale==='fa'?info[2]:info[3]};}
function labelOf(node){return node.getAttribute('aria-label')||node.getAttribute('title')||node.closest('label')?.textContent.trim().replace(/\s+/g,' ').slice(0,120)||node.textContent.trim().replace(/\s+/g,' ').slice(0,120)||tr('ابزار نت‌نویسی','Notation tool');}
function controlInfo(node){
 const key=keyOf(node),field=fieldInfo(key);if(field)return field;
 const name=labelOf(node),action=node.dataset.action;
 if(node.hasAttribute('data-pitch'))return {name:node.dataset.pitch.replace(/^([A-G])/,'$1'+(node.dataset.accidental||'')),text:tr('با لمس کوتاه، این نت را با کشش فعلی وارد می‌کند. در حالت آکورد، ارتفاع هم‌زمان اضافه می‌شود. برای راهنما لمس را نگه دارید.','Tap to enter this pitch with the current duration. In chord mode it adds a simultaneous pitch. Hold for help.')};
 if(node.hasAttribute('data-note'))return {name:tr('نت روی حامل','Staff note'),text:tr('برای انتخاب و ویرایش این نت لمس کنید. برای جابه‌جایی نت، آن را بکشید؛ لمس طولانی بدون حرکت این راهنما را نشان می‌دهد.','Tap to select and edit this note. Drag to move it; a stationary long press shows this help.')};
 if(action==='note-mark'){
  const f=node.dataset.field;
  if(f==='tieNext'||f==='tiePrevious')return {name,text:tr('خط اتحاد دو نت هم‌ارتفاع را به یک صدای پیوسته تبدیل می‌کند. شروع به نت بعدی و پایان به نت قبلی متصل می‌شود.','A tie joins equal pitches into one sustained sound. Start connects to the next note; end connects from the previous note.')};
  if(f==='slurStart'||f==='slurEnd')return {name,text:tr('خط اتصال یک عبارت پیوسته را بین شروع و پایان نشان می‌دهد. برخلاف خط اتحاد، ارتفاع نت‌های عبارت می‌تواند متفاوت باشد.','A slur marks a connected musical phrase between a start and an end. Unlike a tie, its notes may have different pitches.')};
  if(f==='arpeggio')return {name,text:tr('نت‌های آکورد را به ترتیب سریع اجرا می‌کند، به‌جای اینکه هم‌زمان آغاز شوند. جهت اجرا پس از فعال‌شدن قابل انتخاب است.','Plays chord pitches in quick succession instead of together. Choose the direction after enabling arpeggio.')};
  if(f==='cautionary')return {name,text:tr('علامت تغییر این نت را برای یادآوری داخل پرانتز نمایش می‌دهد؛ ارتفاع نت را عوض نمی‌کند.','Shows this note’s accidental in parentheses as a reminder, without changing its pitch.')};
 }
 if(actions[action])return {name,text:locale==='fa'?actions[action][0]:actions[action][1]};
 if(node.matches('.measure-tools>summary'))return {name:tr('ابزارهای میزان','Measure tools'),text:tr('ابزارهای میزان جاری را باز یا بسته می‌کند. نماد هر ابزار را نگه دارید یا روی آن مکث کنید تا کاربردش توضیح داده شود.','Opens or closes the current measure’s tools. Hover or hold a tool to read what it does.')};
 return {name,text:node.matches('input,select,textarea')?tr('مقدار «'+name+'» را برای این قسمت تنظیم می‌کند. تغییر را با انتخاب گزینه یا پایان ویرایش ثبت کنید.','Sets “'+name+'” for this part of the score. Choose a value or finish editing to apply it.'):tr('با انتخاب «'+name+'»، این ابزار نت‌نویسی اجرا می‌شود.','Choose “'+name+'” to use this notation control.')};
}
function annotate(node,info){
 node.dataset.notationHelp=info.text+(node.dataset.disabledReason?' '+node.dataset.disabledReason:'');node.dataset.notationHelpTitle=info.name;
 if(!node.getAttribute('aria-label'))node.setAttribute('aria-label',info.name);
 if(node.hasAttribute('title'))node.removeAttribute('title');
}
function glyph(key,value,label){return global.NotationGlyphs?.option(key,value,label)||global.NotationSymbols?.tool('note')||'';}
function fieldGlyph(key,value=''){return global.NotationGlyphs?.field(key,value)||global.NotationSymbols?.tool('note')||'';}
function actionGlyph(button){
 const action=button.dataset.action,field=button.dataset.field;
 if((action==='note-mark'||action==='tone-tie')&&['tieNext','tiePrevious','slurStart','slurEnd'].includes(field)){
  const end=field==='tiePrevious'||field==='slurEnd',slur=field.startsWith('slur');
  return '<svg class="notation-tool-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><ellipse cx="5" cy="'+(slur?'7':'9')+'" rx="3" ry="2" fill="currentColor" opacity="'+(end?'.3':'1')+'"/><ellipse cx="19" cy="'+(slur?'12':'9')+'" rx="3" ry="2" fill="currentColor" opacity="'+(end?'1':'.3')+'"/><path d="'+(slur?'M3 15q9 7 19 2':'M3 15q9 7 18 0')+'"/><path d="'+(end?'m4 12-3 3 3 3':'m20 12 3 3-3 3')+'"/></svg>';
 }
 if(action==='remove-clef-change')return fieldGlyph('clef1',button.dataset.clef||'treble');
 if(action==='chord-tone')return global.NotationSymbols?.tool('note')||'';
 if(action==='remove-chord-tone')return '<svg class="notation-tool-icon" viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.7"><ellipse cx="8" cy="17" rx="4" ry="2.5" fill="currentColor"/><path d="M12 17V3m4 2 6 6m0-6-6 6"/></svg>';
 return '';
}
function hideLabelText(label){
 for(const node of [...label.childNodes]){
  if(node.nodeType===Node.TEXT_NODE&&node.textContent.trim()){const span=document.createElement('span');span.className='notation-control-label';span.textContent=node.textContent;node.replaceWith(span);}
  else if(node.nodeType===Node.ELEMENT_NODE&&node.tagName==='SPAN')node.classList.add('notation-control-label');
 }
}
function enhanceSelect(select){
 if(select.hasAttribute('data-notation-enhanced'))return;
 const key=keyOf(select),info=controlInfo(select),label=select.closest('label'),wrapper=label||document.createElement('span');
 if(!label)select.before(wrapper);
 if(!label)wrapper.append(select);else hideLabelText(label);
 wrapper.classList.add('notation-symbol-field');wrapper.dataset.controlKey=key;
 select.dataset.notationEnhanced='';select.classList.add('notation-original-select');select.tabIndex=-1;select.setAttribute('aria-hidden','true');
 annotate(select,info);annotate(wrapper,info);
 const button=document.createElement('button');button.type='button';button.className='notation-symbol-picker';button.dataset.controlKey=key;button.setAttribute('aria-haspopup','listbox');button.setAttribute('aria-expanded','false');button.disabled=select.disabled;
 const selected=select.selectedOptions[0];button.innerHTML=glyph(key,select.value,selected?.textContent||'');button.setAttribute('aria-label',info.name+(selected?.textContent?' · '+selected.textContent:''));annotate(button,{...info,name:button.getAttribute('aria-label')});
 if(select.disabled){wrapper.classList.add('is-disabled');wrapper.tabIndex=0;wrapper.setAttribute('aria-disabled','true');const reason=select.dataset.disabledReason;if(reason){wrapper.dataset.notationHelp+=' '+reason;button.dataset.notationHelp+=' '+reason;}}
 select.after(button);button.addEventListener('click',event=>{event.preventDefault();event.stopPropagation();openPicker(button,select);});
 select.addEventListener('change',()=>{if(button.isConnected){const selected=select.selectedOptions[0];button.innerHTML=glyph(key,select.value,selected?.textContent||'');button.setAttribute('aria-label',info.name+' · '+(selected?.textContent||''));}});
}
function enhanceInput(input){
 if(input.hasAttribute('data-notation-enhanced'))return;input.dataset.notationEnhanced='';
 const label=input.closest('label');if(!label)return;
 const key=keyOf(input),info=controlInfo(input);hideLabelText(label);label.classList.add('notation-symbol-field','notation-symbol-input');label.dataset.controlKey=key;
 const icon=document.createElement('span');icon.className='notation-field-icon';icon.innerHTML=fieldGlyph(key);label.insertBefore(icon,label.firstChild);annotate(input,info);annotate(label,info);
 if(input.disabled){label.classList.add('is-disabled');label.tabIndex=0;label.setAttribute('aria-disabled','true');if(input.dataset.disabledReason)label.dataset.notationHelp+=' '+input.dataset.disabledReason;}
}
function viewport(){
 const style=getComputedStyle(document.documentElement),center=parseFloat(style.getPropertyValue('--notation-dialog-center')),height=parseFloat(style.getPropertyValue('--notation-visible-height'));
 return {left:8,right:Math.max(8,innerWidth-8),top:Number.isFinite(center)&&Number.isFinite(height)?Math.max(8,center-height/2+8):8,bottom:Number.isFinite(center)&&Number.isFinite(height)?Math.min(innerHeight-8,center+height/2-8):innerHeight-8};
}
function position(box,anchor){
 const bounds=viewport(),a=anchor.getBoundingClientRect(),height=Math.max(32,bounds.bottom-bounds.top),width=Math.max(64,bounds.right-bounds.left);box.style.maxHeight=height+'px';box.style.maxWidth=width+'px';
 const rect=box.getBoundingClientRect(),left=Math.max(bounds.left,Math.min(a.left+(a.width-rect.width)/2,bounds.right-rect.width)),below=bounds.bottom-a.bottom-7,above=a.top-bounds.top-7;
 let top=below>=rect.height||below>=above?a.bottom+7:a.top-rect.height-7;top=Math.max(bounds.top,Math.min(top,bounds.bottom-rect.height));box.style.left=Math.round(left)+'px';box.style.top=Math.round(top)+'px';
}
function visibleAnchor(node){
 if(!node?.isConnected||!node.getClientRects().length)return false;
 const bounds=viewport(),rect=node.getBoundingClientRect();let left=Math.max(bounds.left,rect.left),right=Math.min(bounds.right,rect.right),top=Math.max(bounds.top,rect.top),bottom=Math.min(bounds.bottom,rect.bottom);
 for(let parent=node.parentElement;parent&&parent!==document.body;parent=parent.parentElement){const style=getComputedStyle(parent),box=parent.getBoundingClientRect();if(/auto|scroll|hidden|clip/.test(style.overflowX)){left=Math.max(left,box.left);right=Math.min(right,box.right);}if(/auto|scroll|hidden|clip/.test(style.overflowY)){top=Math.max(top,box.top);bottom=Math.min(bottom,box.bottom);}}
 return right>left&&bottom>top;
}
function underPointer(node,point){return !!point&&node.contains(document.elementFromPoint(point.x,point.y));}
function topLayer(box){document.body.append(box);if(box.showPopover){box.setAttribute('popover','manual');try{box.showPopover();}catch(_){box.removeAttribute('popover');}}}
function removeTopLayer(box){if(!box)return;try{if(box.matches(':popover-open'))box.hidePopover();}catch(_){}box.remove();}
function hideHelp(){clearTimeout(hoverTimer);if(help){const {node,box,described}=help;removeTopLayer(box);if(node.isConnected){if(described===null)node.removeAttribute('aria-describedby');else node.setAttribute('aria-describedby',described);}help=null;}}
function showHelp(node,source='focus',point=null){
 if(!node?.isConnected||!node.dataset.notationHelp)return;
 if(source==='hover'&&(!visibleAnchor(node)||!underPointer(node,point)))return;
 hideHelp();const box=document.createElement('div');box.className='notation-control-help';box.id='notation-help-'+(++serial);box.setAttribute('role','tooltip');box.dir=locale==='fa'?'rtl':'ltr';
 const title=document.createElement('strong');title.textContent=node.dataset.notationHelpTitle||labelOf(node);const body=document.createElement('div');body.textContent=node.dataset.notationHelp;box.append(title,body);
 const described=node.getAttribute('aria-describedby');node.setAttribute('aria-describedby',((described||'')+' '+box.id).trim());help={node,box,described,source,point};topLayer(box);position(box,node);
}
function closePicker(focus=false){if(!popup)return;const {box,button}=popup;if(help&&box.contains(help.node))hideHelp();popup=null;removeTopLayer(box);button.setAttribute('aria-expanded','false');button.removeAttribute('aria-controls');if(focus&&button.isConnected)button.focus({preventScroll:true});}
function openPicker(button,select){
 if(select.disabled)return;if(popup?.button===button){closePicker(true);return;}closePicker();hideHelp();
 const key=keyOf(select),info=controlInfo(select),box=document.createElement('div');box.className='notation-symbol-popup';box.id='notation-choices-'+(++serial);box.setAttribute('role','listbox');box.setAttribute('aria-label',info.name);box.dir=locale==='fa'?'rtl':'ltr';
 for(const option of select.options){const choice=document.createElement('button');choice.type='button';choice.className='notation-symbol-option';choice.dataset.notationOption=option.value;choice.setAttribute('role','option');choice.setAttribute('aria-label',option.textContent||tr('بدون علامت','No marking'));choice.setAttribute('aria-selected',String(option.selected));choice.disabled=option.disabled;choice.innerHTML=glyph(key,option.value,option.textContent);annotate(choice,{name:choice.getAttribute('aria-label'),text:info.text+(option.dataset.disabledReason?' '+option.dataset.disabledReason:'')});choice.addEventListener('click',event=>{event.preventDefault();event.stopPropagation();if(choice.disabled)return;const value=option.value;closePicker(true);select.value=value;select.dispatchEvent(new Event('change',{bubbles:true}));});box.append(choice);}
 popup={box,button,select};button.setAttribute('aria-expanded','true');button.setAttribute('aria-controls',box.id);topLayer(box);position(box,button);const selected=box.querySelector('[aria-selected=true]:not(:disabled)')||box.querySelector('button:not(:disabled)');selected?.focus({preventScroll:true});
}
function helpTarget(event){const node=event.target instanceof Element?event.target.closest('[data-notation-help],button,input,select,textarea,summary,[data-pitch],#score [data-note]'):null;if(node&&!node.dataset.notationHelp)annotate(node,controlInfo(node));return node;}
function inScope(node){return !!node&&(scope?.contains(node)||popup?.box.contains(node)||(scope?.querySelector('#score')&&node.closest('dialog')));}
function pointerOver(event){if(event.pointerType==='touch')return;const node=helpTarget(event);if(!inScope(node)||node===help?.node)return;const point={x:event.clientX,y:event.clientY};clearTimeout(hoverTimer);hoverTimer=setTimeout(()=>showHelp(node,'hover',point),320);}
function pointerOut(event){if(help?.node?.contains(event.relatedTarget))return;const node=helpTarget(event);if(node&&(!event.relatedTarget||!node.contains(event.relatedTarget)))hideHelp();}
function refind(node){
 if(node.isConnected)return node;
 if(node.dataset.pitch)return scope?.querySelector('[data-pitch="'+CSS.escape(node.dataset.pitch)+'"]');
 if(node.dataset.note!==undefined&&node.dataset.bar!==undefined)return scope?.querySelector('[data-note="'+CSS.escape(node.dataset.note)+'"][data-bar="'+CSS.escape(node.dataset.bar)+'"]');
 return null;
}
function pointerDown(event){
 if(popup&&!popup.box.contains(event.target)&&!popup.button.contains(event.target))closePicker();
 const node=helpTarget(event);if(!inScope(node)){hideHelp();return;}if(event.pointerType==='mouse'||event.button>0)return;
 hideHelp();clearTimeout(touchTimer);touch={id:event.pointerId,x:event.clientX,y:event.clientY,node};
 touchTimer=setTimeout(()=>{const current=touch;if(!current)return;touch=null;const original=current.node,live=refind(original)||scope;live?.dispatchEvent(new PointerEvent('pointercancel',{bubbles:true,pointerId:current.id,pointerType:event.pointerType||'touch'}));const target=refind(original);suppressedUntil=performance.now()+1000;suppressedTarget=target||original;if(target){if(!target.dataset.notationHelp)annotate(target,controlInfo(target));showHelp(target,'touch');}},550);
}
function pointerMove(event){if(touch&&event.pointerId===touch.id&&Math.hypot(event.clientX-touch.x,event.clientY-touch.y)>8){clearTimeout(touchTimer);touch=null;}}
function pointerEnd(){clearTimeout(touchTimer);touch=null;}
function clickCapture(event){if(performance.now()<suppressedUntil&&(suppressedTarget?.contains(event.target)||event.target.closest?.('[data-notation-help]')===suppressedTarget)){event.preventDefault();event.stopImmediatePropagation();suppressedUntil=0;}}
function keys(event){
 if(event.key==='Escape'){if(popup){event.preventDefault();event.stopPropagation();closePicker(true);}hideHelp();return;}
 if(event.key==='F1'&&inScope(document.activeElement)){event.preventDefault();showHelp(document.activeElement);return;}
 if(!popup||!popup.box.contains(event.target))return;
 const choices=[...popup.box.querySelectorAll('button:not(:disabled)')],index=choices.indexOf(document.activeElement);let next;
 if(['ArrowRight','ArrowDown'].includes(event.key))next=(index+1)%choices.length;
 else if(['ArrowLeft','ArrowUp'].includes(event.key))next=(index+choices.length-1)%choices.length;
 else if(event.key==='Home')next=0;else if(event.key==='End')next=choices.length-1;else if(event.key==='Tab'){closePicker();return;}
 if(next!==undefined){event.preventDefault();event.stopPropagation();hideHelp();choices[next]?.focus({preventScroll:true});}
}
function decorate(root,options={}){
 scope=root;locale=options.locale||document.documentElement.lang||'en';
 if(touch){const live=refind(touch.node);if(live)touch.node=live;else{clearTimeout(touchTimer);touch=null;}}
 for(const select of root.querySelectorAll(pickSelector))enhanceSelect(select);
 for(const input of root.querySelectorAll('.measure-tools input,.notation-selected-tools input'))enhanceInput(input);
 for(const button of root.querySelectorAll('.notation-selected-tools>button,.notation-selected-tools .chord-controls>button,.measure-tools [data-action=remove-clef-change]')){
  const info=controlInfo(button);annotate(button,info);button.classList.add('notation-symbol-action');
  const action=button.dataset.action,replacement=actionGlyph(button);if(replacement){button.querySelector('svg')?.remove();button.insertAdjacentHTML('afterbegin',replacement);}else if(!button.querySelector('svg')){const icon=global.NotationSymbols?.tool(action==='remove-grace'?'grace':'note');if(icon)button.insertAdjacentHTML('afterbegin',icon);}
  if(['note-mark','tone-tie','grace-mode','chord','chord-tone'].includes(action))button.setAttribute('aria-pressed',String(button.classList.contains('is-active')));
  for(const node of [...button.childNodes]){if(node.nodeType===Node.TEXT_NODE&&node.textContent.trim()){const text=document.createElement('span');text.className='notation-control-label';text.textContent=node.textContent;node.replaceWith(text);}else if(node.nodeType===Node.ELEMENT_NODE&&node.tagName==='SPAN')node.classList.add('notation-control-label');}
  if(['chord-tone','remove-chord-tone','tone-tie','remove-grace'].includes(action)&&!button.querySelector('.notation-tone-badge')){const pitch=(info.name+' '+button.textContent).match(/[A-G](?:#|b)?-?\d/);if(pitch){const badge=document.createElement('small');badge.className='notation-tone-badge';badge.textContent=pitch[0];button.append(badge);}}
 }
 for(const label of root.querySelectorAll('.measure-tools .chord-controls>span'))label.hidden=true;
 for(const node of root.querySelectorAll('button,input,select,textarea,summary,[data-pitch],#score [data-note]')){if(!node.dataset.notationHelp)annotate(node,controlInfo(node));}
 if(root.querySelector('#score'))for(const button of root.querySelectorAll('button:disabled')){
  if(button.closest('.notation-symbol-field,.notation-disabled-action'))continue;
  const wrapper=document.createElement('span');wrapper.className='notation-disabled-action';wrapper.tabIndex=0;wrapper.setAttribute('aria-disabled','true');annotate(wrapper,controlInfo(button));if(button.dataset.disabledReason)wrapper.dataset.notationHelp+=' '+button.dataset.disabledReason;button.before(wrapper);wrapper.append(button);
 }
}
function dispose(){closePicker();hideHelp();if(!touch?.node.matches('[data-note],[data-pitch]')){clearTimeout(touchTimer);touch=null;}}
document.addEventListener('pointerover',pointerOver,true);document.addEventListener('pointerout',pointerOut,true);document.addEventListener('pointerdown',pointerDown,true);document.addEventListener('pointermove',pointerMove,true);document.addEventListener('pointerup',pointerEnd,true);document.addEventListener('pointercancel',pointerEnd,true);document.addEventListener('click',clickCapture,true);document.addEventListener('keydown',keys,true);
document.addEventListener('contextmenu',event=>{if(performance.now()<suppressedUntil&&inScope(helpTarget(event)))event.preventDefault();},true);
document.addEventListener('focusin',event=>{const node=helpTarget(event);if(inScope(node)&&!popup?.box.contains(node))showHelp(node);},true);document.addEventListener('focusout',event=>{if(help?.node===helpTarget(event))hideHelp();},true);
function viewportChanged(){closePicker();if(help){if(!visibleAnchor(help.node)||(help.source==='hover'&&!underPointer(help.node,help.point)))hideHelp();else position(help.box,help.node);}}
global.addEventListener('resize',viewportChanged);global.addEventListener('scroll',event=>{if(popup?.box.contains(event.target)||help?.box.contains(event.target))return;viewportChanged();},{capture:true,passive:true});
global.NotationControls={decorate,dispose,close:()=>{closePicker();hideHelp();}};
})(globalThis);
