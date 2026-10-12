import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'models.dart';
import 'progress.dart';
import 'text.dart';
import 'training_screen.dart';

class IntervalLevelsScreen extends StatefulWidget {
  const IntervalLevelsScreen({super.key, this.store});
  final IntervalProgressStore? store;
  @override
  State<IntervalLevelsScreen> createState() => _IntervalLevelsScreenState();
}

class _IntervalLevelsScreenState extends State<IntervalLevelsScreen> {
  late final IntervalProgressStore _store =
      widget.store ?? IntervalProgressRepository();
  IntervalProgress? _progress;
  bool _error = false;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _progress = null;
    });
    try {
      final progress = await _store.load();
      if (mounted) setState(() => _progress = progress);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _open(IntervalLevel level) async {
    if (_opening || _progress == null || !_progress!.isUnlocked(level.number)) {
      return;
    }
    _opening = true;
    final progress = _progress!;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IntervalTrainingScreen(
          levelNumber: level.number,
          store: _store,
          progress: progress,
        ),
      ),
    );
    _opening = false;
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = IntervalText(context);
    final theme = Theme.of(context);
    return Directionality(
      textDirection: t.direction,
      child: Scaffold(
        appBar: SornazAppBar(title: t('interval.title')),
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
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  itemCount: IntervalLevel.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final level = IntervalLevel.all[i];
                    final unlocked = _progress!.isUnlocked(level.number);
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
                          completed
                              ? Icons.check_circle_outline
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
                        subtitle: Wrap(
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
                                      t('interval.middleC'),
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
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
