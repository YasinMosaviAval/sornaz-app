import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Tuner/audio/note_player.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

class RecordingNotePlayer extends NotePlayer {
  final played = <double>[];
  int stopped = 0;

  @override
  Future<void> play(double frequency, int durationSeconds) async {
    played.add(frequency);
  }

  @override
  Future<void> stop() async {
    stopped++;
  }
}

void main() {
  testWidgets('professional intermittent playback stops after ten cycles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final notes = RecordingNotePlayer();
    final tuner = TunerProvider(notePlayer: notes);
    await tuner.setProfessionalMode(true);
    await tuner.setIntermittentPlayback(true);
    await tuner.setNoteDuration(1);
    await tuner.setSilenceSeconds(1);
    await tuner.playNote(440);
    for (var i = 0; i < 21; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(notes.played, List<double>.filled(10, 440));
    final stopsAtEnd = notes.stopped;
    await tester.pump(const Duration(seconds: 5));
    expect(notes.played.length, 10);
    expect(notes.stopped, stopsAtEnd);
    tuner.dispose();
  });

  testWidgets('a new key cancels the previous professional sequence', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final notes = RecordingNotePlayer();
    final tuner = TunerProvider(notePlayer: notes);
    await tuner.setProfessionalMode(true);
    await tuner.setNoteDuration(1);
    await tuner.playNote(440);
    await tuner.playNote(494);
    for (var i = 0; i < 11; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(notes.played.where((frequency) => frequency == 440).length, 1);
    expect(notes.played.where((frequency) => frequency == 494).length, 10);
    tuner.dispose();
  });
}
