import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/reference_timeline.dart';

String score(String measures) =>
    '''
<score-partwise version="4.0">
  <work><work-title>Practice</work-title></work>
  <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
  <part id="P1">$measures</part>
</score-partwise>''';

void main() {
  const parser = ReferenceTimelineParser();

  test('quarter positions and seconds include rests and measure padding', () {
    final result = parser.parse(
      score('''
      <measure number="1"><attributes><divisions>480</divisions>
        <time><beats>4</beats><beat-type>4</beat-type></time></attributes>
        <direction><sound tempo="60"/></direction>
        <note><pitch><step>C</step><octave>4</octave></pitch>
          <duration>480</duration><type>quarter</type></note>
        <note><rest/><duration>480</duration><type>quarter</type></note>
      </measure>
      <measure number="2"><note><pitch><step>D</step><alter>1</alter>
        <octave>4</octave></pitch><duration>480</duration></note></measure>
    '''),
    );
    expect(result.title, 'Practice');
    expect(result.notes.map((n) => n.quarterPosition), [0, 1, 4]);
    expect(result.notes.map((n) => n.startSeconds), [0, 1, 4]);
    expect(result.notes[1].isRest, true);
    expect(result.notes[2].midiPitch, 63);
    expect(result.durationQuarters, 8);
    expect(result.durationSeconds, 8);
  });

  test(
    'dotted duration uses divisions and tempo change integrates over note',
    () {
      final result = parser.parse(
        score('''
      <measure number="1"><attributes><divisions>480</divisions>
        <time><beats>4</beats><beat-type>4</beat-type></time></attributes>
        <direction><sound tempo="60"/></direction>
        <note><pitch><step>C</step><octave>4</octave></pitch>
          <duration>720</duration><type>quarter</type><dot/></note>
        <direction><sound tempo="120"/></direction>
        <note><pitch><step>D</step><octave>4</octave></pitch>
          <duration>480</duration></note>
      </measure>
    '''),
      );
      expect(result.notes[0].quarterDuration, 1.5);
      expect(result.notes[0].durationSeconds, 1.5);
      expect(result.notes[1].startSeconds, 1.5);
      expect(result.notes[1].durationSeconds, 0.5);
      expect(result.tempos.map((t) => t.quarterBpm), [60, 120]);
      expect(result.durationSeconds, 2.75);
    },
  );

  test('metronome half and dotted beat convert to quarter BPM', () {
    final result = parser.parse(
      score('''
      <measure number="1"><attributes><divisions>1</divisions></attributes>
        <direction><direction-type><metronome><beat-unit>half</beat-unit>
          <beat-unit-dot/><per-minute>60</per-minute>
        </metronome></direction-type></direction>
        <note><rest/><duration>3</duration></note>
      </measure>
    '''),
    );
    expect(result.tempos.single.quarterBpm, 180);
    expect(result.durationSeconds, 1);
  });

  test('bundled export keeps dotted metronome unit authoritative', () {
    final result = parser.parse(
      score('''
      <measure number="1"><attributes><divisions>16</divisions></attributes>
        <direction><direction-type><metronome><beat-unit>quarter</beat-unit>
          <beat-unit-dot/><per-minute>60</per-minute>
        </metronome></direction-type><sound tempo="60"/></direction>
        <note><rest/><duration>24</duration><type>quarter</type><dot/></note>
      </measure>
    '''),
    );
    expect(result.tempos.single.quarterBpm, 90);
    expect(result.durationSeconds, 1);
  });

  test('backup and chord retain independent voices and simultaneous onset', () {
    final result = parser.parse(
      score('''
      <measure number="1"><attributes><divisions>1</divisions></attributes>
        <note><pitch><step>C</step><octave>4</octave></pitch>
          <duration>1</duration><voice>1</voice></note>
        <note><chord/><pitch><step>E</step><octave>4</octave></pitch>
          <duration>1</duration><voice>1</voice></note>
        <backup><duration>1</duration></backup>
        <note><pitch><step>G</step><octave>3</octave></pitch>
          <duration>1</duration><voice>2</voice></note>
      </measure>
    '''),
    );
    expect(result.notes.map((n) => n.quarterPosition), [0, 0, 0]);
    expect(result.notes.map((n) => n.voice), ['1', '1', '2']);
    expect(result.notes.map((n) => n.midiPitch), [60, 64, 55]);
  });

  test('tie continuation is a sustained segment rather than a new attack', () {
    final result = parser.parse(
      score('''
      <measure number="1"><attributes><divisions>1</divisions></attributes>
        <note><pitch><step>C</step><octave>4</octave></pitch>
          <duration>1</duration><tie type="start"/></note></measure>
      <measure number="2"><note><pitch><step>C</step><octave>4</octave></pitch>
        <duration>1</duration><tie type="stop"/></note></measure>
    '''),
    );
    expect(result.notes.map((n) => n.isAttack), [true, false]);
    expect(result.notes.map((n) => n.quarterPosition), [0, 1]);
  });

  test('invalid and unsupported input fails explicitly', () {
    expect(
      () => parser.parse('<broken'),
      throwsA(isA<ReferenceFormatException>()),
    );
    expect(
      () => parser.parse('<score-timewise/>'),
      throwsA(isA<ReferenceFormatException>()),
    );
    expect(
      () => parser.parse(score('<measure><note><rest/></note></measure>')),
      throwsA(isA<ReferenceFormatException>()),
    );
    expect(
      () => parser.parse(
        score(
          '''<measure><attributes><divisions>1</divisions>
      </attributes><barline><repeat direction="backward"/></barline></measure>''',
        ),
      ),
      throwsA(isA<ReferenceFormatException>()),
    );
  });
}
