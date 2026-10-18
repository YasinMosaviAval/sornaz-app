import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'audio.dart';
import 'controller.dart';
import 'models.dart';
import 'progress.dart';
import 'text.dart';
import 'settings.dart';
import 'settings_screen.dart';
import 'play_button.dart';
import 'access.dart';
import 'stars.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';

class IntervalTrainingScreen extends StatefulWidget {
  const IntervalTrainingScreen({
    super.key,
    required this.levelNumber,
    required this.store,
    required this.progress,
    this.audio,
    this.controller,
    this.settings,
    this.access,
    this.music = IntervalMusic.western,
    this.onResultSaved,
  });
  final int levelNumber;
  final IntervalProgressStore store;
  final IntervalProgress progress;
  final IntervalAudio? audio;
  final IntervalTrainingController? controller;
  final IntervalAudioSettings? settings;
  final IntervalAccess? access;
  final IntervalMusic music;
  final Future<void> Function(bool force)? onResultSaved;
  @override
  State<IntervalTrainingScreen> createState() => _IntervalTrainingScreenState();
}

class _IntervalTrainingScreenState extends State<IntervalTrainingScreen>
    with WidgetsBindingObserver {
  late final IntervalTrainingController _controller;
  late final IntervalAudioSettings _settings;
  bool _openingSettings = false;
  bool _entryDenied = false;
  late final IntervalAccess _access;
  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? IntervalAudioSettings();
    final currentAccess = IntervalAccess.fromSession(
      context.read<AuthSession?>(),
    );
    _access = widget.access ?? currentAccess;
    if (_access.scope != currentAccess.scope ||
        !_access.canEnter(
          widget.levelNumber,
          widget.progress,
          music: widget.music,
        )) {
      _entryDenied = true;
      return;
    }
    _controller =
        widget.controller ??
        IntervalTrainingController(
          levelNumber: widget.levelNumber,
          audio: widget.audio ?? InstrumentIntervalAudio(settings: _settings),
          store: widget.store,
          progress: widget.progress,
          access: _access,
          music: widget.music,
          settings: _settings,
          onResultSaved: widget.onResultSaved,
        );
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _openSettings() async {
    if (_openingSettings || _controller.checking || _controller.accessRevoked) {
      return;
    }
    _openingSettings = true;
    await _controller.stopPlayback();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IntervalSettingsScreen(settings: _settings),
      ),
    );
    await _settings.flush();
    _openingSettings = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = IntervalAccess.fromSession(context.watch<AuthSession?>());
    if (!_entryDenied && current.scope != _access.scope) {
      _controller.revokeAccess();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller.stopPlayback());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_entryDenied) _controller.dispose();
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entryDenied) {
      final t = IntervalText(context);
      return Directionality(
        textDirection: t.direction,
        child: Scaffold(
          appBar: SornazAppBar(title: t('interval.title')),
          body: Center(
            child: Text(
              t('interval.locked'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<IntervalTrainingController>(
        builder: (context, c, _) {
          final t = IntervalText(context);
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return Directionality(
            textDirection: t.direction,
            child: Scaffold(
              appBar: SornazAppBar(
                title: t('interval.trainingTitle', {
                  'level': t.number(c.level.number),
                }),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 24),
                    tooltip: t('interval.settingsTitle'),
                    onPressed: c.checking || c.accessRevoked || c.initializing
                        ? null
                        : _openSettings,
                  ),
                ],
              ),
              bottomNavigationBar: c.finished || c.accessRevoked
                  ? null
                  : SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: FilledButton(
                          onPressed: c.selected == null || c.checking
                              ? null
                              : c.check,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            textStyle: theme.textTheme.bodyLarge,
                          ),
                          child: Text(t('interval.check')),
                        ),
                      ),
                    ),
              body: c.initializing
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
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
                              mainAxisAlignment: c.finished
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: c.accessRevoked
                                  ? [
                                      Text(
                                        t('interval.accountChanged'),
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(t('interval.back')),
                                      ),
                                    ]
                                  : c.finished
                                  ? [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: scheme.primary,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        t(widget.music.finalMessageKey),
                                        style: theme.textTheme.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(t('interval.back')),
                                      ),
                                    ]
                                  : [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (final (index, interval)
                                                in c
                                                    .level
                                                    .intervals
                                                    .indexed) ...[
                                              if (index > 0)
                                                const SizedBox(height: 8),
                                              Builder(
                                                builder: (context) {
                                                  final selected =
                                                      c.selected == interval;
                                                  final result = selected
                                                      ? c.correct
                                                      : null;
                                                  final resultColor =
                                                      result == null
                                                      ? null
                                                      : result
                                                      ? AppColors.success
                                                      : scheme.error;
                                                  final foreground =
                                                      resultColor == null
                                                      ? scheme.onSurface
                                                      : ThemeData.estimateBrightnessForColor(
                                                              resultColor,
                                                            ) ==
                                                            Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black;
                                                  return Semantics(
                                                    selected: selected,
                                                    child: OutlinedButton(
                                                      key: ValueKey(
                                                        'interval.option.${interval.id}',
                                                      ),
                                                      onPressed: c.checking
                                                          ? null
                                                          : () => c.select(
                                                              interval,
                                                            ),
                                                      style: OutlinedButton.styleFrom(
                                                        minimumSize: const Size(
                                                          0,
                                                          56,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        backgroundColor:
                                                            resultColor ??
                                                            (selected
                                                                ? scheme.primary
                                                                      .withValues(
                                                                        alpha:
                                                                            .25,
                                                                      )
                                                                : null),
                                                        foregroundColor:
                                                            foreground,
                                                        disabledForegroundColor:
                                                            foreground,
                                                        side: BorderSide(
                                                          color:
                                                              resultColor ??
                                                              (selected
                                                                  ? scheme
                                                                        .primary
                                                                  : scheme
                                                                        .outline),
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  appRadius(
                                                                    context,
                                                                  ),
                                                            ),
                                                        textStyle: theme
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                      child: Text(
                                                        t(
                                                          interval
                                                              .translationKey,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Center(
                                              child: IntervalStars(
                                                count: c.progress.starsFor(
                                                  c.level.number,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Semantics(
                                              liveRegion: true,
                                              child: Text(
                                                t('interval.wins', {
                                                  'wins': t.number(c.wins),
                                                  'total': t.number(
                                                    IntervalLevel.requiredWins,
                                                  ),
                                                }),
                                                textAlign: TextAlign.center,
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value:
                                                  c.wins /
                                                  IntervalLevel.requiredWins,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: IntervalPlayButton(
                                          playing: c.playing,
                                          label: t(
                                            c.playing
                                                ? 'interval.playing'
                                                : 'interval.play',
                                          ),
                                          onPressed: c.checking ? null : c.play,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (c.correct != null) ...[
                                                Semantics(
                                                  liveRegion: true,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        c.correct!
                                                            ? Icons
                                                                  .check_circle_outline
                                                            : Icons
                                                                  .error_outline,
                                                        color: c.correct!
                                                            ? AppColors.success
                                                            : scheme.error,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          c.completedLevel !=
                                                                      null &&
                                                                  c.level.number <
                                                                      widget
                                                                          .music
                                                                          .levelCount
                                                              ? t(
                                                                  'interval.levelComplete',
                                                                  {
                                                                    'level': t
                                                                        .number(
                                                                          c.completedLevel!,
                                                                        ),
                                                                  },
                                                                )
                                                              : c.correct!
                                                              ? t(
                                                                  'interval.correct',
                                                                )
                                                              : '${t('interval.incorrect')}\n${t('interval.answer', {'answer': t(c.question.interval.translationKey)})}',
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (c.errorKey != null) ...[
                                                const SizedBox(height: 12),
                                                Semantics(
                                                  liveRegion: true,
                                                  child: Text(
                                                    t(c.errorKey!),
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: scheme.error,
                                                        ),
                                                  ),
                                                ),
                                                if ([
                                                  'interval.saveError',
                                                  'interval.resultSaveError',
                                                ].contains(c.errorKey))
                                                  TextButton(
                                                    onPressed: c.transitioning
                                                        ? null
                                                        : c.retrySave,
                                                    child: Text(
                                                      t('interval.retry'),
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox.shrink(),
                                    ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
