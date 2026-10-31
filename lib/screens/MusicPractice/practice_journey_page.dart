import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Authentication/providers/auth_session.dart';
import '../../components/app_bar.dart';
import '../IntervalRecognition/stars.dart';
import '../Social/social_widgets.dart';
import 'practice_journey.dart';
import 'practice_repository.dart';
import 'practice_player_page.dart';

class MusicPracticeJourneyPage extends StatefulWidget {
  const MusicPracticeJourneyPage({
    super.key,
    required this.repository,
    required this.exams,
    required this.progress,
    required this.title,
    this.stopAtRoundBoundary = true,
  });
  final MusicPracticeRepository repository;
  final List<PracticeJson> exams, progress;
  final String title;
  final bool stopAtRoundBoundary;
  @override
  State<MusicPracticeJourneyPage> createState() =>
      _MusicPracticeJourneyPageState();
}

class _MusicPracticeJourneyPageState extends State<MusicPracticeJourneyPage> {
  late List<PracticeJson> progress = widget.progress
      .map((p) => Map<String, dynamic>.from(p))
      .toList();
  PracticeJourney get journey => PracticeJourney(widget.exams, progress);
  late final int? round;
  @override
  void initState() {
    super.initState();
    round = journey.next?.stage;
  }

  bool complete = false;
  Future<void> passed(PracticeJourneyStep step) async {
    List<PracticeJson> saved;
    try {
      saved = await widget.repository.progress(refresh: false);
    } catch (_) {
      saved = [];
    }
    if (!mounted) return;
    final rows = [...progress, ...saved];
    rows.add({
      'examId': step.exam['id'],
      'version': step.exam['version'],
      'completedStages': [step.stage],
    });
    final merged = <String, PracticeJson>{};
    for (final row in rows) {
      final key = '${row['examId']}:${row['version']}';
      final stages = <int>{
        ...List<int>.from(merged[key]?['completedStages'] as List? ?? []),
        ...List<int>.from(row['completedStages'] as List? ?? []),
      };
      merged[key] = {...row, 'completedStages': stages.toList()};
    }
    setState(() {
      progress = merged.values.toList();
      final next = journey.next;
      complete =
          next == null || (widget.stopAtRoundBoundary && next.stage != round);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = journey, step = plan.next;
    final auth = context.watch<AuthSession?>();
    final actor = auth?.isAuthenticated == true ? auth!.user!.id : null;
    final unavailable =
        actor != widget.repository.userId ||
        !complete &&
            step != null &&
            (step.exam['access'] != true ||
                actor != null &&
                    DateTime.now().millisecondsSinceEpoch ~/ 1000 >
                        (step.exam['permitExpiresAt'] as int? ?? 0));
    if (unavailable) {
      return Scaffold(
        appBar: SornazAppBar(title: widget.title),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            socialText(
              context,
              'دسترسی تغییر کرده است؛ به بخش آزمون‌ها برگردید و فهرست را تازه کنید.',
              'Access changed; return to tests and refresh the catalog.',
            ),
          ),
        ),
      );
    }
    if (!complete && step != null) {
      return MusicPracticePlayerPage(
        key: ValueKey(
          '${step.exam['id']}:${step.exam['version']}:${step.stage}',
        ),
        repository: widget.repository,
        exam: step.exam,
        stage: step.stage,
        stars: plan.stars,
        onPassed: () => passed(step),
      );
    }
    return Scaffold(
      appBar: SornazAppBar(title: widget.title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                socialText(
                  context,
                  'آزمون ${widget.title} کامل شد',
                  '${widget.title} test completed',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 16),
              Center(child: IntervalStars(count: plan.stars)),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 10),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  socialText(context, 'بازگشت به آزمون‌ها', 'Back to tests'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
