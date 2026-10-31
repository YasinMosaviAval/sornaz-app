import 'package:sornaz/components/app_async_state.dart';
import 'dart:async';
import '../../helpers/development_access.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'models.dart';
import 'progress.dart';
import 'text.dart';
import 'training_screen.dart';
import 'access.dart';
import 'settings.dart';
import 'results.dart';
import 'sync.dart';
import 'stars.dart';

class IntervalLevelsScreen extends StatefulWidget {
  const IntervalLevelsScreen({
    super.key,
    this.store,
    this.music = IntervalMusic.western,
    this.settings,
  });
  final IntervalMusic music;
  final IntervalAudioSettings? settings;
  final IntervalProgressStore? store;
  @override
  State<IntervalLevelsScreen> createState() => _IntervalLevelsScreenState();
}

class _IntervalLevelsScreenState extends State<IntervalLevelsScreen>
    with WidgetsBindingObserver {
  late IntervalProgressStore _store;
  IntervalAccess _access = const IntervalAccess();
  String? _scope;
  int _loadGeneration = 0;
  IntervalResultsSync? _sync;
  Timer? _syncTimer;
  late final IntervalAudioSettings _settings;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
        unawaited(_synchronize(force: true));
    });
    _settings = widget.settings ?? IntervalAudioSettings();
    _settings.addListener(_settingsChanged);
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _sync?.dispose();
    _settings.removeListener(_settingsChanged);
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  IntervalProgress? _progress;
  bool _error = false;
  bool _opening = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthSession?>();
    final access = IntervalAccess.fromSession(auth);
    if (_scope != access.scope) {
      _scope = access.scope;
      _access = access;
      _sync?.dispose();
      _sync = null;
      final journal = widget.store == null
          ? IntervalResultJournal(userId: access.userId, music: widget.music)
          : null;
      _store =
          widget.store ??
          IntervalProgressRepository(
            userId: access.userId,
            music: widget.music,
            journal: journal,
          );
      if (journal != null && access.userId != null) {
        _sync = IntervalResultsSync(
          journal: journal,
          store: _store,
          api: IntervalResultsApi(
            token: () =>
                auth?.isAuthenticated == true && auth!.user!.id == access.userId
                ? auth.token
                : null,
          ),
        );
      }
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final store = _store;
    setState(() {
      _error = false;
      _progress = null;
    });
    try {
      final progress = await store.load();
      if (mounted && generation == _loadGeneration) {
        setState(() => _progress = progress);
        unawaited(_synchronize());
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      unawaited(_synchronize(force: true));
  }

  Future<void> _synchronize({bool force = false}) async {
    final sync = _sync;
    final store = _store;
    if (sync == null) return;
    await sync.sync(force: force);
    if (!mounted || !identical(sync, _sync)) return;
    try {
      final progress = await store.load();
      if (mounted && identical(sync, _sync))
        setState(() => _progress = progress);
    } catch (_) {
      /* Keep the visible local progress and allow retry. */
    }
  }

  Future<void> _open(IntervalLevel level) async {
    if (_opening ||
        _progress == null ||
        !_access.canEnter(level.number, _progress!, music: widget.music)) {
      return;
    }
    _opening = true;
    final progress = _progress!;
    final store = _store;
    final access = _access;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IntervalTrainingScreen(
          levelNumber: level.number,
          store: store,
          progress: progress,
          access: access,
          music: widget.music,
          settings: _settings,
          onResultSaved: (force) => _synchronize(force: force),
        ),
      ),
    );
    _opening = false;
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.music == IntervalMusic.iranian &&
        !DevelopmentAccess.watch(context)) {
      return DevelopmentGate(builder: (_) => const SizedBox.shrink());
    }
    final t = IntervalText(context);
    final theme = Theme.of(context);
    return Directionality(
      textDirection: t.direction,
      child: Scaffold(
        bottomNavigationBar: _sync?.hasError == true
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t('interval.syncPending'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            : null,
        appBar: SornazAppBar(
          title: t(
            !DevelopmentAccess.watch(context)
                ? 'interval.title'
                : widget.music == IntervalMusic.western
                ? 'interval.westernTitle'
                : 'interval.iranianTitle',
          ),
        ),
        body: _error
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('interval.loadError'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _load,
                      child: Text(t('interval.retry')),
                    ),
                  ],
                ),
              )
            : _progress == null
            ? const AppLoadingIndicator()
            : SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  itemCount: IntervalLevel.levelsFor(widget.music).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final level = IntervalLevel.levelsFor(widget.music)[i];
                    final unlocked = _access.canEnter(
                      level.number,
                      _progress!,
                      music: widget.music,
                    );
                    final completed = _progress!.completed.contains(
                      level.number,
                    );
                    final status = completed
                        ? 'completed'
                        : unlocked
                        ? 'available'
                        : 'locked';
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: appRadius(context),
                        ),
                        enabled: unlocked,
                        onTap: unlocked ? () => _open(level) : null,
                        leading: Icon(
                          !DevelopmentAccess.watch(context) && completed
                              ? Icons.check_circle
                              : unlocked
                              ? Icons.play_circle_outline
                              : Icons.lock_outline,
                          color: unlocked
                              ? theme.colorScheme.primary
                              : theme.disabledColor,
                        ),
                        title: Text(
                          t('interval.level', {
                            'level': t.number(level.number),
                          }),
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (DevelopmentAccess.watch(context))
                              IntervalStars(
                                count: _progress!.starsFor(level.number),
                              ),
                            Wrap(
                              textDirection: t.direction,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final (index, part) in [
                                  t('interval.${level.direction.name}'),
                                  t(
                                    level.variableRoot
                                        ? 'interval.variableRoot'
                                        : 'interval.fixedRoot',
                                  ),
                                  t('interval.count', {
                                    'count': t.number(level.intervals.length),
                                  }),
                                  t('interval.$status'),
                                ].indexed) ...[
                                  if (index > 0)
                                    Text(
                                      ' - ',
                                      style: theme.textTheme.bodyMedium,
                                      textDirection: t.direction,
                                    ),
                                  if (index == 1 && !level.variableRoot)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      textDirection: t.direction,
                                      children: [
                                        Text(
                                          t('interval.rootLabel'),
                                          style: theme.textTheme.bodyMedium,
                                          textDirection: t.direction,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          IntervalAudioSettings.noteName(
                                            _settings.startingMidi,
                                          ),
                                          style: theme.textTheme.bodyMedium,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      part,
                                      style: theme.textTheme.bodyMedium,
                                      textDirection: t.direction,
                                    ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
