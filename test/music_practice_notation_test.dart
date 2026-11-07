import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sornaz/screens/MusicPractice/practice_repository.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'music_practice_test.dart' show TreePracticeRepository;
import 'social_widget_test.dart' as fixture;
import 'package:sornaz/screens/MusicPractice/practice_audio_recording.dart';
import 'package:sornaz/screens/MusicPractice/practice_notation_grade.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final reference = {
    'notes': [
      [0, 500, 60],
      [500, 1000, 62],
    ],
    'durationMs': 2000,
    'beatMs': 500,
    'pitchTolerance': 35,
  };
  Map<String, dynamic> recording([double ratio = 1]) => {
    'durationMs': 2000,
    'frames': [
      for (var t = 0; t < 2000; t += 50)
        [
          t,
          ((t < 500
                      ? 26163
                      : t < 1000
                      ? 29366
                      : 0) *
                  ratio)
              .round(),
          t < 1000 && ratio != 0 ? 100 : 0,
        ],
    ],
  };
  test('canonical pitch/rhythm policy rejects silence and wrong pitches', () {
    expect(
      PracticeNotationGrade.evaluate(reference, recording(), 'pitch_rhythm'),
      {'passed': true, 'pitch': 100, 'rhythm': 100},
    );
    expect(
      PracticeNotationGrade.evaluate(
        reference,
        recording(math.pow(2, 1 / 12).toDouble()),
        'pitch_rhythm',
      ),
      {'passed': false, 'pitch': 0, 'rhythm': 100},
    );
    expect(
      PracticeNotationGrade.evaluate(
        reference,
        recording(math.pow(2, 1 / 12).toDouble()),
        'rhythm',
      ),
      {'passed': true, 'pitch': 0, 'rhythm': 100},
    );
    expect(PracticeNotationGrade.evaluate(reference, recording(0), 'rhythm'), {
      'passed': false,
      'pitch': 0,
      'rhythm': 0,
    });
  });
  test('PCM detection preserves quarter tones and silent rest', () {
    for (final frequency in [261.63, 440.0, 440 * math.pow(2, 1 / 24)]) {
      final pcm = Uint8List(64000), data = ByteData.sublistView(pcm);
      for (var i = 0; i < 16000; i++) {
        data.setInt16(
          i * 2,
          (6000 * math.sin(2 * math.pi * frequency * i / 16000)).round(),
          Endian.little,
        );
      }
      final result = analyzePracticePcm(pcm), frames = result['frames'] as List;
      expect(result['durationMs'], 2000);
      expect(frames.length, 40);
      expect((frames[3] as List)[1] / 100, closeTo(frequency, 2));
      expect((frames.last as List)[2], 0);
    }
  });
  test('rhythm timing, rests and delayed start affect assessment', () {
    expect(
      PracticeNotationGrade.evaluate(
        {
          'notes': [
            [0, 2000, 60],
          ],
          'durationMs': 2000,
          'beatMs': 500,
          'pitchTolerance': 35,
        },
        {
          'durationMs': 300,
          'frames': (recording()['frames'] as List).take(6).toList(),
        },
        'rhythm',
      )['passed'],
      false,
    );
    final noisy = recording();
    for (final frame in noisy['frames'] as List) {
      frame[2] = 100;
    }
    expect(
      PracticeNotationGrade.evaluate(
        reference,
        noisy,
        'pitch_rhythm',
      )['passed'],
      false,
    );
    final delayed = recording();
    for (final frame in delayed['frames'] as List) {
      frame[0] += 300;
    }
    delayed['durationMs'] = 2300;
    expect(
      PracticeNotationGrade.evaluate(
        reference,
        delayed,
        'pitch_rhythm',
      )['passed'],
      true,
    );
    final wrongTempo = recording();
    for (final frame in wrongTempo['frames'] as List) {
      frame[0] *= 2;
    }
    wrongTempo['durationMs'] = 4000;
    expect(
      PracticeNotationGrade.evaluate(
        reference,
        wrongTempo,
        'pitch_rhythm',
      )['passed'],
      false,
    );
  });
  test(
    'recorded answers remain durable and upload in bounded batches',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-notation-practice-',
      );
      Hive.init(directory.path);
      final chunks = <int>[];
      final repo = MusicPracticeRepository(
        userId: 1,
        token: () => 'fixture',
        client: MockClient((request) async {
          final data = jsonDecode(request.bodyFields['payload']!) as Map,
              answers = data['answers'] as List;
          chunks.add(answers.length);
          return http.Response(
            jsonEncode({
              'data': {
                'success': true,
                'data': {
                  'acceptedThrough': (answers.last as Map)['sequence'],
                  'status': 'in_progress',
                },
              },
            }),
            200,
          );
        }),
      );
      try {
        final exam = <String, dynamic>{
          'id': 1,
          'version': 1,
          'stageCount': 1,
          'requiredWins': 100,
          'permitExpiresAt':
              DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          'downloadPermit': 'fixture',
          'config': {
            'kind': 'notation',
            'assessment': 'pitch_rhythm',
            'questions': [
              {'reference': reference},
            ],
          },
        };
        for (var i = 1; i <= 6; i++) {
          final run = await repo.append(
            id: 'a' * 32,
            exam: exam,
            stage: 1,
            answer: {
              'sequence': i,
              'question': 0,
              'selected': 0,
              'recording': recording(),
              'answeredAt': DateTime.now().toUtc().toIso8601String(),
              'elapsedMs': 2000,
            },
          );
          expect(run['streak'], i);
        }
        await repo.upload();
        expect(chunks, [5, 1]);
        final runs = await repo.runs();
        expect(runs.single['ack'], 6);
      } finally {
        repo.dispose();
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'written level preserves score and audio assessment at 320px ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = TreePracticeRepository(),
            catalog = await repo.catalog(manage: true);
        catalog['notationQuestions'] = true;
        final question = {
          'sheet': {
            'metadata': {'title': 'Question'},
            'score': {'measures': []},
          },
          'preview':
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><path d="M1 1 L30 30"/></svg>',
          'reference': reference,
        };
        await tester.pumpWidget(
          fixture.host(
            MusicPracticeEditPage(
              repository: repo,
              catalog: catalog,
              kind: 'exams',
              item: {
                'id': 1,
                'version': 1,
                'nodeId': 1,
                'titleFa': 'سؤال نمونه',
                'titleEn': 'Sample',
                'stageCount': 1,
                'requiredWins': 1,
                'position': 0,
                'config': {
                  'kind': 'notation',
                  'assessment': 'rhythm',
                  'questions': [question],
                },
              },
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byTooltip('ویرایش صورت سؤال'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip('حذف پرسش'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('ذخیره'));
        await tester.pumpAndSettle();
        final config = repo.writes.last['config'] as Map;
        expect(config['kind'], 'notation');
        expect(config['assessment'], 'rhythm');
        expect((config['questions'] as List).single, {
          'sheet': question['sheet'],
          'preview': question['preview'],
        });
        await tester.pumpWidget(const SizedBox.shrink());
        repo.dispose();
      },
    );
  }
}
