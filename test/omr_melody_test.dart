import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sornaz/services/omr/omr_melody.dart';
import 'package:sornaz/services/omr/printed_score_engine.dart';

void main() {
  test('real treble pixels become editable, timed importer events', () {
    final result = analyzePrintedScore(
      File('tool/omr_feasibility/treble.png').readAsBytesSync(),
    );
    expect(result['staffCount'], 1);
    final notes = OmrMelody.fromProbe(result);
    expect(notes.map((n) => n.pitch), ['G4', 'A4', 'B4', 'C5', 'D5', 'E5']);
    for (final note in notes) {
      note.duration = 'q';
    }
    expect(
      () => OmrMelody.toImport(
        notes: notes,
        clef: 'treble',
        numerator: 4,
        denominator: 4,
        title: 'Scan',
      ),
      throwsFormatException,
    );
    notes[1].duration = 'h';
    notes[5].duration = 'h';
    final score = OmrMelody.toImport(
      notes: notes,
      clef: 'treble',
      numerator: 4,
      denominator: 4,
      title: 'Scan',
    );
    final bars = (score['score'] as Map)['measures'] as List;
    expect(bars.length, 2);
    expect(
      ((bars[0] as Map)['notes'] as List)[1]['at'],
      OmrMelody.wholeUnits ~/ 4,
    );
    expect(((bars[1] as Map)['notes'] as List)[0]['at'], 0);
  });

  test(
    'bass clef is recognized and manual pitch changes survive conversion',
    () {
      final result = analyzePrintedScore(
        File('tool/omr_feasibility/bass.png').readAsBytesSync(),
      );
      expect((result['staffs'] as List).single['clef'], 'bass');
      final notes = OmrMelody.fromProbe(result);
      expect(notes.length, 6);
      notes[0].pitch = 'F#2';
      for (final note in notes) {
        note.duration = 'q';
      }
      notes[2].duration = 'h';
      notes[5].duration = 'h';
      final score = OmrMelody.toImport(
        notes: notes,
        clef: 'bass',
        numerator: 4,
        denominator: 4,
        title: 'Bass',
      );
      final first =
          ((((score['score'] as Map)['measures'] as List).first as Map)['notes']
                  as List)
              .first;
      expect(first['pitch'], 'F2');
      expect(first['accidental'], '#');
    },
  );

  test('blank image cannot replace a score', () {
    final result = analyzePrintedScore(
      File('tool/omr_feasibility/invalid.png').readAsBytesSync(),
    );
    expect(result['staffCount'], 0);
    expect(() => OmrMelody.fromProbe(result), throwsFormatException);
  });

  test('phone-shaped PNG screenshot around a score is accepted', () {
    final source = img.decodePng(
      File('tool/omr_feasibility/treble.png').readAsBytesSync(),
    )!;
    final screenshot = img.Image(width: 1080, height: 2400);
    img.fill(screenshot, color: img.ColorRgb8(255, 255, 255));
    final score = img.copyResize(source, width: 1000);
    img.compositeImage(screenshot, score, dstX: 40, dstY: 700);
    final result = analyzePrintedScore(img.encodePng(screenshot));
    expect(result['staffCount'], 1);
    // The clean source has six notes. The scaled screenshot still produces a
    // reviewable draft; the missing note can be added in the review screen.
    expect(OmrMelody.fromProbe(result).length, greaterThanOrEqualTo(5));
  });

  test('a screenshot with two score rows asks for a single-staff crop', () {
    final source = img.decodePng(
      File('tool/omr_feasibility/treble.png').readAsBytesSync(),
    )!;
    final screenshot = img.Image(width: 1200, height: 1800);
    img.fill(screenshot, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(screenshot, source, dstY: 200);
    img.compositeImage(screenshot, source, dstY: 900);
    final result = analyzePrintedScore(img.encodePng(screenshot));
    expect(result['staffCount'], 2);
    expect(() => OmrMelody.fromProbe(result), throwsFormatException);
  });
}
