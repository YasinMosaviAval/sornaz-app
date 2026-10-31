import 'package:sornaz/components/app_async_state.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../components/app_bar.dart';
import '../../helpers/app_appearance.dart';
import '../../helpers/app_colors.dart';
import '../IntervalRecognition/play_button.dart';
import '../IntervalRecognition/stars.dart';
import '../Authentication/providers/auth_session.dart';
import '../Social/social_widgets.dart';
import '../IntervalRecognition/audio.dart';
import '../IntervalRecognition/models.dart';
import '../IntervalRecognition/iranian_curriculum.dart';
import '../IntervalRecognition/settings.dart';
import '../IntervalRecognition/text.dart';
import 'practice_repository.dart';

class MusicPracticePlayerPage extends StatefulWidget {
  const MusicPracticePlayerPage({
    super.key,
    required this.repository,
    required this.exam,
    required this.stage,
    this.stars = 0,
    this.onPassed,
  });
  final MusicPracticeRepository repository;
  final PracticeJson exam;
  final int stage;
  final int stars;
  final Future<void> Function()? onPassed;
  @override
  State<MusicPracticePlayerPage> createState() =>
      _MusicPracticePlayerPageState();
}

class _MusicPracticePlayerPageState extends State<MusicPracticePlayerPage> {
  late final String id = widget.repository.newRunId();
  IntervalAudioSettings? settings;
  IntervalAudio? _audio;
  AudioPlayer? _tick;
  IntervalAudio get audio => _audio ??= InstrumentIntervalAudio(
    settings: settings ??= IntervalAudioSettings(),
  );
  AudioPlayer get tick => _tick ??= AudioPlayer();
  final random = Random(), watch = Stopwatch()..start();
  late PracticeJson question;
  int sequence = 0, streak = 0, generation = 0;
  int? selectedChoice;
  bool busy = false, playing = false, passed = false, leaving = false;
  String? message;
  PracticeJson get config =>
      Map<String, dynamic>.from(widget.exam['config'] as Map);
  bool get validAccount =>
      context.read<AuthSession?>()?.user?.id == widget.repository.userId;
  bool get validPermit =>
      widget.repository.userId == null ||
      DateTime.now().millisecondsSinceEpoch ~/ 1000 <=
          (widget.exam['permitExpiresAt'] as int? ?? 0);
  @override
  void initState() {
    super.initState();
    question = nextQuestion();
    if (config['kind'] == 'interval') {
      settings = IntervalAudioSettings();
      unawaited(
        settings!.ready.then((_) {
          if (mounted && !busy && !playing && !passed) {
            setState(() => question = nextQuestion());
          }
        }),
      );
    }
  }

  PracticeJson nextQuestion() {
    final c = config;
    if (c['kind'] != 'interval') {
      return {'question': random.nextInt((c['questions'] as List).length)};
    }
    final steps = List<int>.from(c['quarterSteps'] as List),
        expected = steps[random.nextInt(steps.length)],
        ascending = c['direction'] == 'ascending';
    final min = (21 + (ascending ? 0 : expected / 2)).ceil(),
        max = (108 - (ascending ? expected / 2 : 0)).floor();
    return {
      'expected': expected,
      'rootMidi': c['variableRoot'] == true
          ? min + random.nextInt(max - min + 1)
          : settings?.startingMidi ?? 60,
    };
  }

  Future<void> play() async {
    if (playing || busy || passed || !validAccount || !validPermit) return;
    setState(() => playing = true);
    final current = ++generation;
    try {
      final c = config;
      if (c['kind'] == 'interval') {
        final steps = question['expected'] as int,
            root = question['rootMidi'] as int,
            interval = IranianInterval.values.firstWhere(
              (i) => i.quarterSteps == steps,
            );
        await audio.play(
          IntervalQuestion(
            id: sequence + 1,
            level: widget.stage,
            interval: interval,
            rootMidi: root,
            targetMidi:
                root + (c['direction'] == 'ascending' ? 1 : -1) * steps / 2,
            direction: c['direction'] == 'ascending'
                ? IntervalDirection.ascending
                : IntervalDirection.descending,
          ),
        );
      } else if (c['kind'] == 'rhythm') {
        final q = (c['questions'] as List)[question['question'] as int] as Map;
        for (final beat in q['beats'] as List) {
          if (current != generation || !mounted) break;
          await tick.play(AssetSource('audio/tick.wav'));
          await Future<void>.delayed(
            Duration(
              milliseconds: (60000 / (q['bpm'] as num) * (beat as num)).round(),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = socialText(
            context,
            'پخش صدا انجام نشد.',
            'Audio playback failed.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => playing = false);
    }
  }

  Future<void> answer(int selected) async {
    if (busy || playing || passed) return;
    if (!validAccount || !validPermit) {
      setState(
        () => message = socialText(
          context,
          'دسترسی تغییر کرده است؛ آزمون را دوباره دریافت کنید.',
          'Access changed; refresh the test.',
        ),
      );
      return;
    }
    setState(() => busy = true);
    final c = config,
        expected = c['kind'] == 'interval'
            ? question['expected']
            : (c['questions'] as List)[question['question'] as int]['correct'];
    try {
      final run = await widget.repository.append(
        id: id,
        exam: widget.exam,
        stage: widget.stage,
        answer: {
          ...question,
          'sequence': sequence + 1,
          'selected': selected,
          'elapsedMs': watch.elapsedMilliseconds.clamp(0, 86400000),
          'answeredAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      sequence++;
      streak = run['streak'] as int;
      passed = run['passed'] == true;
      watch.reset();
      question = nextQuestion();
      selectedChoice = null;
      if (mounted) {
        setState(
          () => message = expected == selected
              ? socialText(context, 'درست', 'Correct')
              : socialText(context, 'دوباره تلاش کنید.', 'Try again.'),
        );
      }
      if (widget.repository.userId != null) {
        unawaited(
          widget.repository.upload().catchError((Object _) {
            if (mounted) {
              setState(
                () => message = socialText(
                  context,
                  'نتیجه روی دستگاه ذخیره شد؛ بارگذاری در انتظار اتصال است.',
                  'Saved on this device; upload is pending.',
                ),
              );
            }
          }),
        );
      }
      if (passed && mounted && widget.onPassed != null) {
        await widget.onPassed!();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = socialText(
            context,
            'ذخیرهٔ پاسخ انجام نشد؛ دوباره تلاش کنید.',
            'The answer could not be saved; try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> close() async {
    if (busy || leaving) return;
    setState(() => busy = true);
    generation++;
    await _audio?.stop();
    await _tick?.stop();
    try {
      await widget.repository.closeRun(id);
      if (widget.repository.userId != null) {
        unawaited(widget.repository.upload().catchError((Object _) {}));
      }
      if (!mounted) return;
      setState(() => leaving = true);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = socialText(
            context,
            'ذخیرهٔ تمرین انجام نشد.',
            'Practice could not be saved.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    generation++;
    if (_audio != null) unawaited(_audio!.dispose());
    if (_tick != null) unawaited(_tick!.dispose());
    settings?.dispose();
    watch.stop();
    super.dispose();
  }

  Widget answerOption(BuildContext context, (int, String) choice) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selectedChoice == choice.$1,
      child: OutlinedButton(
        key: ValueKey('practice.option.${choice.$1}'),
        onPressed: busy || playing
            ? null
            : () => setState(() => selectedChoice = choice.$1),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.all(12),
          backgroundColor: selectedChoice == choice.$1
              ? theme.colorScheme.primary.withValues(alpha: .25)
              : null,
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: selectedChoice == choice.$1
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
          textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
        ),
        child: Text(choice.$2, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AuthSession?>();
    if ((current?.isAuthenticated == true ? current?.user?.id : null) !=
        widget.repository.userId) {
      return Scaffold(
        appBar: SornazAppBar(
          title: socialText(context, 'آزمون‌ها', 'Tests'),
          onBack: close,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            socialText(
              context,
              'حساب کاربری تغییر کرده است؛ به فهرست آزمون‌ها بازگردید.',
              'Your account changed; return to the test catalog.',
            ),
          ),
        ),
      );
    }
    final en = Localizations.localeOf(context).languageCode == 'en', c = config;
    final t = IntervalText(context), theme = Theme.of(context);
    final choices = c['kind'] == 'interval'
        ? List<int>.from(c['quarterSteps'] as List).map((step) {
            final legacy =
                widget.exam['legacyKey']?.toString().startsWith('western:') ??
                false;
            TrainingInterval interval = IranianInterval.values.firstWhere(
              (i) => i.quarterSteps == step,
            );
            if (legacy && step.isEven) {
              interval = MusicalInterval.values.firstWhere(
                (i) => i.quarterSteps == step,
              );
            }
            return (step, IntervalText(context)(interval.translationKey));
          }).toList()
        : List<String>.from(
            ((c['questions'] as List)[question['question'] as int]
                    as Map)['choices']
                as List,
          ).indexed.map((e) => (e.$1, e.$2)).toList();
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(close());
      },
      child: Scaffold(
        appBar: SornazAppBar(
          title: (en ? widget.exam['titleEn'] : widget.exam['titleFa'])
              .toString(),
          onBack: close,
        ),
        bottomNavigationBar: passed
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                    onPressed: selectedChoice == null || busy || playing
                        ? null
                        : () => answer(selectedChoice!),
                    child: Text(IntervalText(context)('interval.check')),
                  ),
                ),
              ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 12).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: passed
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (passed && widget.onPassed != null)
                      const AppLoadingIndicator()
                    else if (passed) ...[
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        socialText(
                          context,
                          'مرحله کامل شد.',
                          'Stage completed.',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        onPressed: busy ? null : close,
                        child: Text(
                          socialText(
                            context,
                            'بازگشت به آزمون‌ها',
                            'Back to tests',
                          ),
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (c['kind'] != 'interval')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  ((c['questions'] as List)[question['question']
                                              as int]
                                          as Map)[en ? 'promptEn' : 'promptFa']
                                      .toString(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (choices.length > 5)
                              LayoutBuilder(
                                builder: (context, constraints) => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final choice in choices)
                                      SizedBox(
                                        width: (constraints.maxWidth - 8) / 2,
                                        child: answerOption(context, choice),
                                      ),
                                  ],
                                ),
                              )
                            else
                              for (final (index, choice)
                                  in choices.indexed) ...[
                                if (index > 0) const SizedBox(height: 8),
                                answerOption(context, choice),
                              ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: IntervalStars(count: widget.stars)),
                            const SizedBox(height: 8),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                t('interval.wins', {
                                  'wins': t.number(streak),
                                  'total': t.number(
                                    widget.exam['requiredWins'] as int,
                                  ),
                                }),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value:
                                  streak / (widget.exam['requiredWins'] as int),
                            ),
                          ],
                        ),
                      ),
                      if (c['kind'] != 'choice')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: IntervalPlayButton(
                            playing: playing,
                            label: t(
                              playing ? 'interval.playing' : 'interval.play',
                            ),
                            onPressed: busy || playing ? null : play,
                          ),
                        ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: message == null
                            ? const SizedBox.shrink()
                            : Semantics(
                                liveRegion: true,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      streak > 0
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: streak > 0
                                          ? AppColors.success
                                          : theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        message!,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
