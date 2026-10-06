import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/music_analysis_calibration.dart';
import 'package:sornaz/screens/Notation/music_analysis_test_page.dart';
import 'package:sornaz/screens/Notation/note_alignment.dart';
import 'package:sornaz/screens/Notation/performance_assessment.dart';

class _RecordingFilePicker extends FilePicker {
  FileType? selectedType;
  List<String>? selectedExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    selectedType = type;
    selectedExtensions = allowedExtensions;
    return FilePickerResult([
      PlatformFile(
        name: 'export.musicxml',
        size: 64,
        path: '/picked/export.musicxml',
      ),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('requires both inputs before running', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MusicAnalysisTestPage(
          picker: (_) async => null,
          runner: (_, cancellation) async {
            called = true;
            throw StateError('unexpected');
          },
        ),
      ),
    );
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    expect(find.text('Select both files.'), findsOneWidget);
    expect(called, false);
  });

  testWidgets('passes selected XML and audio path and displays raw report', (
    tester,
  ) async {
    const audioPath = '/picked/test.wav';
    CalibrationCase? received;
    await tester.pumpWidget(
      MaterialApp(
        home: MusicAnalysisTestPage(
          picker: (musicXml) async => musicXml
              ? PlatformFile(
                  name: 'test.musicxml',
                  size: 16,
                  path: '/picked/test.musicxml',
                )
              : PlatformFile(name: 'test.wav', size: 3, path: audioPath),
          xmlReader: (_) async => '<score-partwise/>',
          runner: (input, cancellation) async {
            received = input;
            return const CalibrationResult(
              'manual_test',
              'unspecified',
              PerformanceReport(
                notes: [],
                markCounts: {AlignmentMark.matched: 2},
                estimatedQuarterBpm: 120,
                medianAbsolutePitchCents: 4,
                medianAbsoluteOnsetBeats: 0.1,
                medianDurationRatio: 0.9,
                medianSoundStrengthRms: 0.2,
              ),
              {},
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Choose MusicXML'));
    await tester.pump();
    await tester.tap(find.text('Choose audio file'));
    await tester.pump();
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();
    expect(received?.musicXml, '<score-partwise/>');
    expect(received?.source.location, audioPath);
    expect(find.textContaining('120.00 BPM'), findsOneWidget);
    expect(find.text('matched: 2'), findsOneWidget);
    expect(find.textContaining('100'), findsNothing);
  });

  testWidgets('shows an invalid MusicXML error without presenting a report', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MusicAnalysisTestPage(
          picker: (musicXml) async => PlatformFile(
            name: musicXml ? 'bad.musicxml' : 'take.wav',
            size: 1,
            path: musicXml ? '/picked/bad.musicxml' : '/picked/take.wav',
          ),
          xmlReader: (_) async => '<invalid/>',
          runner: (_, cancellation) async =>
              throw const FormatException('Invalid MusicXML'),
        ),
      ),
    );
    await tester.tap(find.text('Choose MusicXML'));
    await tester.pump();
    await tester.tap(find.text('Choose audio file'));
    await tester.pump();
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MusicXML is invalid'), findsOneWidget);
    expect(find.text('PerformanceReport'), findsNothing);
  });

  testWidgets('MusicXML picker does not disable the app export by MIME filter', (
    tester,
  ) async {
    final picker = _RecordingFilePicker();
    FilePicker.platform = picker;
    await tester.pumpWidget(
      MaterialApp(
        home: MusicAnalysisTestPage(
          runner: (_, cancellation) async => throw StateError('not analyzing'),
        ),
      ),
    );
    await tester.tap(find.text('Choose MusicXML'));
    await tester.pump();
    expect(picker.selectedType, FileType.any);
    expect(picker.selectedExtensions, isNull);
    expect(find.text('export.musicxml'), findsOneWidget);
  });

  testWidgets('rejects a non-XML file after broad picker selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MusicAnalysisTestPage(
          picker: (_) async => PlatformFile(
            name: 'wrong.pdf',
            size: 1,
            path: '/picked/wrong.pdf',
          ),
          runner: (_, cancellation) async => throw StateError('not analyzing'),
        ),
      ),
    );
    await tester.tap(find.text('Choose MusicXML'));
    await tester.pump();
    expect(find.text('Choose a .musicxml or .xml file.'), findsOneWidget);
    expect(find.text('Choose MusicXML'), findsOneWidget);
  });
}
