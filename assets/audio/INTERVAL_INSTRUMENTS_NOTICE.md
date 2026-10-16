Interval Recognition instrument samples (MIDI 21 through 108).

FluidR3_GM soundfont by Frank Wen and contributors, pre-rendered and packaged
by gleitz/midi-js-soundfonts and contributors.
License: Creative Commons Attribution 3.0
https://creativecommons.org/licenses/by/3.0/
Source and license information:
https://github.com/gleitz/midi-js-soundfonts/blob/gh-pages/README.md

Source MP3 banks:
https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/acoustic_grand_piano-mp3.js
https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/acoustic_guitar_nylon-mp3.js
https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/violin-mp3.js
https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/viola-mp3.js
https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/cello-mp3.js

Base64 data was extracted and files named using MIDI note numbers. Most MP3
bytes are unchanged. Silent notes outside the violin/viola SoundFont's register
were replaced by resampling the nearest audible sample of that same instrument
at the exact equal-tempered semitone ratio, then applying tempo compensation to
retain sufficient sample duration for two-second notes. These modifications are recorded in
interval_samples_audit.csv (source_midi and pitch_shift_semitones).
Each bank contains all 88 required piano-range notes, including extended-register
samples for instruments with narrower natural ranges.
No question note is clamped, transposed or omitted when selecting an instrument.
Playback applies a short volume release at the end of the selected note duration.

24-TET additions: interval_*_quarter contains 87 halfway pitches per instrument
(MIDI 21.5 through 107.5). Each is derived from the original lower semitone sample
of that same instrument, using a 50-cent rate shift at 176400 Hz followed by
duration compensation and MP3 encoding. Nominal ratio: 2^(1/24).
The finite sample-rate rounding error is recorded in interval_quarter_audit.csv.
Existing whole-semitone samples are unchanged. No runtime pitch state is used,
so quarter-tone playback cannot detune subsequent Western Music notes.
