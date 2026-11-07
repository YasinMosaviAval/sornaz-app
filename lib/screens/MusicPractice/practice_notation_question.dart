import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Social/social_widgets.dart';
import 'practice_audio_recording.dart';
import 'practice_notation_grade.dart';

class PracticeNotationPreview extends StatelessWidget {
  const PracticeNotationPreview({super.key, required this.svg});
  final String svg;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(8),
    child: SvgPicture.string(
      svg,
      width: MediaQuery.sizeOf(context).width,
      fit: BoxFit.contain,
    ),
  );
}

class PracticeNotationQuestion extends StatefulWidget {
  const PracticeNotationQuestion({
    super.key,
    required this.question,
    required this.assessment,
    required this.onAnswer,
    required this.enabled,
  });
  final Map question;
  final String assessment;
  final bool enabled;
  final Future<void> Function(Map<String, dynamic>) onAnswer;
  @override
  State<PracticeNotationQuestion> createState() =>
      _PracticeNotationQuestionState();
}

class _PracticeNotationQuestionState extends State<PracticeNotationQuestion>
    with WidgetsBindingObserver {
  final recorder = PracticeAudioRecording(), player = AudioPlayer();
  bool recording = false, processing = false;
  Uint8List? wav;
  Map<String, dynamic>? observations, grade;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && recording) unawaited(stop());
  }

  Future<void> start() async {
    if (processing || recording || !widget.enabled) return;
    setState(() {
      processing = true;
      error = null;
      observations = null;
      wav = null;
      grade = null;
    });
    try {
      await player.stop();
      await recorder.start(() {
        if (mounted && recording) unawaited(stop());
      });
      if (mounted) setState(() => recording = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = socialText(
            context,
            'ضبط انجام نشد؛ دسترسی میکروفن را بررسی کنید.',
            'Recording failed; check microphone permission.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> stop() async {
    if (!recording || processing) return;
    setState(() {
      processing = true;
      recording = false;
    });
    try {
      final result = await recorder.stop();
      final evaluated = PracticeNotationGrade.evaluate(
        widget.question['reference'] as Map,
        result.observations,
        widget.assessment,
      );
      if (mounted) {
        setState(() {
          wav = result.wav;
          observations = result.observations;
          grade = evaluated;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = socialText(
            context,
            'صدای قابل بررسی ضبط نشد؛ دوباره ضبط کنید.',
            'No usable recording; try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(recorder.dispose());
    unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PracticeNotationPreview(svg: widget.question['preview'] as String),
      const SizedBox(height: 12),
      Text(
        socialText(
          context,
          'از روی نت بخوانید و پاسخ را ضبط کنید. حداکثر زمان ضبط ۴۰ ثانیه است.',
          'Read the score and record your response. Maximum recording: 40 seconds.',
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: widget.enabled && !processing
            ? (recording ? stop : start)
            : null,
        icon: Icon(recording ? Icons.stop : Icons.mic),
        label: Text(
          socialText(
            context,
            recording ? 'پایان ضبط و بررسی' : 'ضبط پاسخ',
            recording ? 'Stop and assess' : 'Record response',
          ),
        ),
      ),
      if (processing) const LinearProgressIndicator(),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (grade != null) ...[
        Text(
          socialText(
            context,
            'نت: ${grade!['pitch']}٪ ـ ریتم: ${grade!['rhythm']}٪',
            'Pitch: ${grade!['pitch']}% · Rhythm: ${grade!['rhythm']}%',
          ),
        ),
        Text(
          socialText(
            context,
            grade!['passed'] == true
                ? 'پاسخ درست است.'
                : 'پاسخ نیاز به تمرین دارد.',
            grade!['passed'] == true
                ? 'Correct response.'
                : 'This response needs more practice.',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              player.play(BytesSource(wav!, mimeType: 'audio/wav')),
          icon: const Icon(Icons.play_arrow),
          label: Text(socialText(context, 'شنیدن ضبط', 'Listen to recording')),
        ),
        FilledButton(
          onPressed: widget.enabled
              ? () => widget.onAnswer(observations!)
              : null,
          child: Text(
            socialText(context, 'ثبت پاسخ و ادامه', 'Submit and continue'),
          ),
        ),
      ],
    ],
  );
}
