import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_bar.dart';
import '../../components/bottom_nav.dart';
import '../../components/main_tabs.dart';
import '../Authentication/providers/auth_session.dart';
import '../Social/social_widgets.dart';
import '../Social/social_api.dart';
import 'practice_repository.dart';
import 'practice_player_page.dart';
import 'practice_manage_page.dart';
import '../Players/ui/components/music_playback_entry.dart';
import '../Players/services/player_settings.dart';

class MusicPracticePage extends StatefulWidget {
  const MusicPracticePage({super.key, this.nodeId, this.nodeTitle});
  final int? nodeId;
  final String? nodeTitle;
  @override
  State<MusicPracticePage> createState() => _MusicPracticePageState();
}

class _MusicPracticePageState extends State<MusicPracticePage>
    with WidgetsBindingObserver {
  MusicPracticeRepository? repository;
  int? account;
  bool initialized = false, loading = true, uploading = false, opening = false;
  PracticeJson? catalog;
  List<PracticeJson> progress = [];
  String? error;
  Timer? timer;
  int generation = 0;
  final checkoutKeys = <String, String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted &&
          !opening &&
          !uploading &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (widget.nodeId != null ||
              MainTabsScope.maybeOf(context)?.index == 5)) {
        unawaited(load());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.nodeId == null && MainTabsScope.maybeOf(context) == null) return;
    final auth = context.watch<AuthSession?>(),
        id = auth?.isAuthenticated == true ? auth!.user!.id : null;
    if (!initialized || id != account) {
      initialized = true;
      account = id;
      repository?.dispose();
      repository = MusicPracticeRepository(
        userId: id,
        token: () => auth?.isAuthenticated == true && auth!.user!.id == id
            ? auth.token
            : null,
      );
      catalog = null;
      progress = [];
      unawaited(load(legacy: widget.nodeId == null));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !opening) unawaited(load());
  }

  Future<void> load({bool legacy = false}) async {
    final repo = repository;
    if (repo == null) return;
    final current = ++generation;
    if (mounted) setState(() => loading = catalog == null);
    try {
      final data = await repo.catalog();
      if (!mounted || current != generation || repository != repo) return;
      setState(() {
        catalog = data;
        loading = false;
        error = null;
      });
      if (legacy && !repo.offline && repo.userId != null) {
        unawaited(
          repo
              .uploadLegacy()
              .then((_) {
                if (mounted && repository == repo) unawaited(load());
              })
              .catchError((Object _) {}),
        );
      }
      final p = await repo.progress();
      if (!mounted || current != generation || repository != repo) return;
      setState(() {
        catalog = data;
        progress = p;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          loading = false;
          error = e.toString();
          if (e is SocialException && [401, 403].contains(e.status)) {
            catalog = null;
            progress = [];
          }
        });
      }
    }
  }

  Future<void> upload() async {
    final repo = repository;
    if (repo == null || uploading) return;
    setState(() => uploading = true);
    try {
      await repo.uploadLegacy();
      await repo.upload();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(
                context,
                'نتایج ذخیره‌شده بارگذاری شدند.',
                'Saved results uploaded.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  String title(PracticeJson row) =>
      row[Localizations.localeOf(context).languageCode == 'en'
              ? 'titleEn'
              : 'titleFa']
          .toString();
  Future<void> openExam(PracticeJson exam) async {
    if (opening || repository == null) return;
    if (exam['access'] != true) {
      await offers(exam['ownerId'] as int, exam['id'] as int);
      return;
    }
    if (account != null &&
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >
            (exam['permitExpiresAt'] as int? ?? 0)) {
      setState(
        () => error = socialText(
          context,
          'برای تمدید دسترسی آفلاین، آزمون را دوباره دریافت کنید.',
          'Refresh this test to renew offline access.',
        ),
      );
      return;
    }
    final p = progress.where(
          (p) => p['examId'] == exam['id'] && p['version'] == exam['version'],
        ),
        completed = p.isEmpty
            ? <int>{}
            : Set<int>.from(p.first['completedStages'] as List);
    var stage = 1;
    while (completed.contains(stage)) {
      stage++;
    }
    stage = stage.clamp(1, exam['stageCount'] as int);
    setState(() => opening = true);
    await socialPush(
      context,
      MusicPlaybackEntry(
        reason: PlaybackInterruption.solfege,
        child: MusicPracticePlayerPage(
          repository: repository!,
          exam: exam,
          stage: stage,
        ),
      ),
    );
    if (mounted) {
      setState(() => opening = false);
      await load();
    }
  }

  Future<void> offers(int teacher, int examId) async {
    final repo = repository!;
    try {
      final data = await repo.request('plans'),
          plans = (data['plans'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .where(
                (p) =>
                    p['teacher_id'].toString() == '$teacher' &&
                    p['status'] == 'approved' &&
                    (p['exam_id'] == null ||
                        p['exam_id'].toString() == '$examId'),
              )
              .toList();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: SornazAppBar(
              title: socialText(
                context,
                'اشتراک آزمون‌های مدرس',
                'Teacher test subscription',
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (plans.isEmpty)
                  Text(
                    socialText(
                      context,
                      'هنوز پلن تأییدشده‌ای وجود ندارد.',
                      'No approved plans are available.',
                    ),
                  ),
                for (final plan in plans)
                  Card(
                    child: ListTile(
                      title: Text(plan['title'].toString()),
                      subtitle: Text(
                        '${plan['amount']} ${socialText(context, 'تومان', 'toman')} · ${plan['exam_id'] != null ? socialText(context, 'خرید دائمی این آزمون', 'Permanent access to this test') : '${plan['days']} ${socialText(context, 'روز؛ همه آزمون‌های مدرس', 'days; all teacher tests')}'}',
                      ),
                      trailing: IconButton(
                        tooltip: socialText(
                          context,
                          'خرید اشتراک',
                          'Subscribe',
                        ),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        onPressed: () async {
                          try {
                            final response = await repo.request('purchase', {
                                  'planId': int.parse(plan['id'].toString()),
                                  'planVersion': int.parse(
                                    plan['version'].toString(),
                                  ),
                                  'checkoutKey': checkoutKeys.putIfAbsent(
                                    plan['id'].toString(),
                                    () => repo.newRunId(),
                                  ),
                                }),
                                url = Uri.parse(
                                  SocialApi.base,
                                ).resolve(response['redirectUrl'].toString());
                            if (url.scheme != 'https' ||
                                ![
                                  'www.zarinpal.com',
                                  'sandbox.zarinpal.com',
                                  Uri.parse(SocialApi.base).host,
                                ].contains(url.host)) {
                              throw StateError('Invalid checkout origin');
                            }
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    repository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodeId == null && MainTabsScope.maybeOf(context) == null) {
      return MainTabs(initialIndex: 5, initialChild: widget);
    }
    final nodes = (catalog?['nodes'] as List? ?? [])
            .map((n) => Map<String, dynamic>.from(n as Map))
            .where((n) => n['parentId'] == widget.nodeId),
        exams = (catalog?['exams'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((e) => e['nodeId'] == widget.nodeId);
    final capabilities = Map<String, dynamic>.from(
          catalog?['capabilities'] as Map? ?? {},
        ),
        name = widget.nodeTitle ?? socialText(context, 'آزمون‌ها', 'Tests');
    final actions = <Widget>[
      if (widget.nodeId == null ||
          (catalog?['nodes'] as List? ?? []).any(
            (n) => n['id'] == widget.nodeId && n['depth'] == 1,
          ))
        IconButton(
          tooltip: socialText(
            context,
            'بارگذاری نتایج ذخیره‌شده',
            'Upload saved results',
          ),
          onPressed: uploading ? null : upload,
          icon: uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
        ),
      IconButton(
        tooltip: socialText(context, 'به‌روزرسانی', 'Refresh'),
        onPressed: loading ? null : load,
        icon: const Icon(Icons.refresh),
      ),
      if (capabilities.values.any((v) => v == true))
        IconButton(
          tooltip: socialText(context, 'مدیریت آزمون‌ها', 'Manage tests'),
          icon: const Icon(Icons.edit_note),
          onPressed: () async {
            await socialPush(
              context,
              MusicPracticeManagePage(repository: repository!),
            );
            if (mounted) await load();
          },
        ),
    ];
    final body = RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (loading) const LinearProgressIndicator(),
          if (repository?.offline == true)
            Text(
              socialText(
                context,
                'نسخهٔ ذخیره‌شده؛ حالت آفلاین',
                'Saved catalog; offline mode',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (error != null)
            Text(error!, style: Theme.of(context).textTheme.bodyMedium),
          for (final node in nodes)
            Card(
              child: ListTile(
                leading: Icon(
                  node['depth'] == 1
                      ? Icons.library_music
                      : Icons.folder_outlined,
                ),
                title: Text(title(node)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  opening = true;
                  await socialPush(
                    context,
                    MusicPracticePage(
                      nodeId: node['id'] as int,
                      nodeTitle: title(node),
                    ),
                  );
                  opening = false;
                  if (mounted) await load();
                },
              ),
            ),
          for (final exam in exams)
            Builder(
              builder: (context) {
                final p = progress.where(
                      (p) =>
                          p['examId'] == exam['id'] &&
                          p['version'] == exam['version'],
                    ),
                    stars = p.isEmpty ? 0 : p.first['stars'] as int? ?? 0,
                    done = p.isEmpty
                        ? 0
                        : (p.first['completedStages'] as List).length;
                return Card(
                  child: ListTile(
                    title: Text(title(exam)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 5; i++)
                              Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                        Text(
                          '$done/${exam['stageCount']} ${socialText(context, 'مرحله', 'stages')}',
                        ),
                      ],
                    ),
                    trailing: Icon(
                      exam['access'] == true
                          ? Icons.play_arrow
                          : Icons.lock_outline,
                    ),
                    onTap: opening ? null : () => openExam(exam),
                  ),
                );
              },
            ),
          if (!loading && nodes.isEmpty && exams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                socialText(
                  context,
                  'هنوز آزمونی در این بخش منتشر نشده است.',
                  'No tests have been published in this section yet.',
                ),
              ),
            ),
        ],
      ),
    );
    return SocialScaffold(
      tabIndex: widget.nodeId == null ? 5 : null,
      title: name,
      appBar: SornazAppBar(
        title: name,
        showBackButton: widget.nodeId != null,
        actions: actions,
      ),
      bottom: widget.nodeId == null
          ? const BottomNavBarWidget(selectedIndex: 5)
          : null,
      body: body,
    );
  }
}
