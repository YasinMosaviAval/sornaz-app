import 'package:sornaz/components/app_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_bar.dart';
import '../../components/home_top_bar.dart';
import '../../helpers/app_appearance.dart';
import '../IntervalRecognition/stars.dart';
import '../IntervalRecognition/text.dart';
import '../../components/bottom_nav.dart';
import '../../components/main_tabs.dart';
import '../Authentication/providers/auth_session.dart';
import '../Social/social_widgets.dart';
import '../Social/social_api.dart';
import 'practice_repository.dart';
import 'practice_sync.dart';
import 'practice_journey.dart';
import 'practice_journey_page.dart';
import 'practice_settings_page.dart';
import 'practice_manage_page.dart';
import 'practice_tree.dart';
import '../Players/ui/components/music_playback_entry.dart';
import '../Players/services/player_settings.dart';

class MusicPracticePage extends StatefulWidget {
  const MusicPracticePage({
    super.key,
    this.nodeId,
    this.nodeTitle,
    this.repository,
    this.showLevels = false,
  });
  final bool showLevels;
  final MusicPracticeRepository? repository;
  final int? nodeId;
  final String? nodeTitle;
  @override
  State<MusicPracticePage> createState() => _MusicPracticePageState();
}

class _MusicPracticePageState extends State<MusicPracticePage>
    with WidgetsBindingObserver {
  MusicPracticeRepository? repository;
  int? account;
  bool listMode = false;
  bool initialized = false, loading = true, uploading = false, opening = false;
  PracticeJson? catalog;
  PracticeJson? managementCatalog;
  List<PracticeJson> proposals = [];
  List<PracticeJson> progress = [];
  String? error;
  Timer? timer;
  StreamSubscription<int?>? syncUpdates;
  int generation = 0;
  final checkoutKeys = <String, String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    syncUpdates = MusicPracticeSync.updates.stream.listen((id) {
      if (mounted && initialized && id == account && !opening) {
        repository?.offline = false;
        repository?.lastSyncError = null;
        unawaited(load(cached: true));
      }
    });
    timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted &&
          !opening &&
          !uploading &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (widget.nodeId != null ||
              MainTabsScope.maybeOf(context)?.index == 4)) {
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
      managementCatalog = null;
      proposals = [];
      listMode = false;
      repository?.dispose();
      repository =
          widget.repository ??
          MusicPracticeRepository(
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

  Future<void> load({
    bool legacy = false,
    bool cached = false,
    bool force = false,
  }) async {
    final repo = repository;
    if (repo == null) return;
    final current = ++generation;
    if (mounted) setState(() => loading = catalog == null);
    try {
      if (!cached && catalog == null) {
        final saved = await repo.cachedCatalog();
        if (saved != null && mounted && current == generation) {
          setState(() => catalog = saved);
        }
      }
      final data = cached
          ? await repo.cachedCatalog()
          : await repo.catalog(allowCached: !force);
      if (data == null) return;
      if (!mounted || current != generation || repository != repo) return;
      PracticeJson? managed;
      List<PracticeJson> offers = [];
      if (!repo.offline &&
          (data['capabilities'] as Map? ?? {}).values.any((v) => v == true)) {
        managed = await repo.catalog(manage: true);
        final response = await repo.request('plans');
        offers = (response['plans'] as List? ?? [])
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
      }
      if (!mounted || current != generation || repository != repo) return;
      setState(() {
        managementCatalog = managed;
        proposals = offers;
        catalog = data;
        loading = false;
        error = repo.offline
            ? repo.lastSyncError?.toString()
            : data['offlineMessage'] as String?;
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
      final p = await repo.progress(refresh: !cached);
      final showList = await MusicPracticeSettingsPage.listMode(account);
      if (!mounted || current != generation || repository != repo) return;
      setState(() {
        catalog = data;
        progress = p;
        listMode = showList;
        loading = false;
        error = repo.offline
            ? repo.lastSyncError?.toString()
            : data['offlineMessage'] as String?;
      });
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          loading = false;
          error = e.toString();
          if (e is SocialException && [401, 403].contains(e.status)) {
            catalog = null;
            managementCatalog = null;
            proposals = [];
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
  List<PracticeJson> groupExams(int? nodeId) =>
      (catalog?['exams'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => e['nodeId'] == nodeId)
          .toList();
  Widget groupHeading(String label, Iterable<PracticeJson> levels) {
    final plan = PracticeJourney(levels, progress);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 14),
          ),
        ),
        if (plan.exams.isNotEmpty) ...[
          const SizedBox(width: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${plan.currentLevel}/${plan.exams.length}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  String groupTitle(int? nodeId) {
    final nodes = (catalog?['nodes'] as List? ?? [])
        .map((n) => Map<String, dynamic>.from(n as Map))
        .toList();
    final path = <String>[];
    final visited = <int>{};
    while (nodeId != null && visited.add(nodeId)) {
      final matches = nodes.where((n) => n['id'] == nodeId);
      if (matches.isEmpty) break;
      final node = matches.first;
      path.insert(0, title(node));
      nodeId = node['parentId'] as int?;
    }
    if (path.length > 2) path.removeRange(0, path.length - 2);
    return path.join(' ');
  }

  Future<void> openSettings() async {
    await socialPush(context, const MusicPracticeSettingsPage());
    final value = await MusicPracticeSettingsPage.listMode(account);
    if (mounted) setState(() => listMode = value);
  }

  Future<void> editItem(String kind, [PracticeJson? item]) async {
    if (repository == null || managementCatalog == null) return;
    await socialPush(
      context,
      MusicPracticeEditPage(
        repository: repository!,
        catalog: managementCatalog!,
        kind: kind,
        item: item,
      ),
    );
    if (mounted) await load();
  }

  Widget cardActions(PracticeJson item, {bool exam = false}) {
    if (managementCatalog == null) return const SizedBox.shrink();
    final caps = catalog?['capabilities'] as Map? ?? {};
    final tree = PracticeTree(
      (managementCatalog?['nodes'] as List? ?? []).map(
        (n) => Map<String, dynamic>.from(n as Map),
      ),
    );
    final enabled = tree.available(
      exam ? item['nodeId'] as int? : item['parentId'] as int?,
    );
    return Wrap(
      children: [
        if (caps['edit'] == true && (exam || item['canManage'] == true))
          IconButton(
            tooltip: socialText(context, 'ویرایش', 'Edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: enabled
                ? () => editItem(exam ? 'exams' : 'nodes', item)
                : null,
          ),
        if (caps['publish'] == true && (exam || item['canManage'] == true))
          IconButton(
            tooltip: socialText(context, 'تغییر انتشار', 'Change visibility'),
            icon: Icon(
              item['published'] != true
                  ? Icons.visibility_off_outlined
                  : (item['audience'] ?? 'public') == 'public'
                  ? Icons.lock_open_outlined
                  : Icons.lock_outline,
            ),
            onPressed: enabled
                ? () async {
                    try {
                      await repository!.request('publish', {
                        'kind': exam ? 'exam' : 'node',
                        'id': item['id'],
                        'version': item['version'],
                        'published': item['published'] != true,
                      });
                      if (mounted) await load();
                    } catch (e) {
                      if (mounted) setState(() => error = e.toString());
                    }
                  }
                : null,
          ),
        if (!exam && caps['create'] == true) ...[
          IconButton(
            tooltip: socialText(context, 'افزودن آزمون', 'Add test'),
            icon: const Icon(Icons.playlist_add),
            onPressed: enabled && item['published'] == true
                ? () => editItem('exams', {'nodeId': item['id']})
                : null,
          ),
          IconButton(
            tooltip: socialText(
              context,
              'پیشنهاد اشتراک',
              'Propose subscription',
            ),
            icon: const Icon(Icons.card_membership),
            onPressed: () => editItem('plans/propose', {
              '_rootNodeId': item['id'],
              'title': title(item),
              'days': 30,
            }),
          ),
        ],
        if (!exam &&
            caps['edit'] == true &&
            groupExams(item['id'] as int).isNotEmpty)
          IconButton(
            tooltip: socialText(context, 'سطح‌های آزمون', 'Test levels'),
            icon: const Icon(Icons.format_list_numbered),
            onPressed: enabled
                ? () async {
                    await socialPush(
                      context,
                      MusicPracticePage(
                        nodeId: item['id'] as int,
                        nodeTitle: title(item),
                        showLevels: true,
                      ),
                    );
                    if (mounted) await load();
                  }
                : null,
          ),
        if (exam && caps['create'] == true)
          IconButton(
            tooltip: socialText(context, 'افزودن آزمون', 'Add test'),
            icon: const Icon(Icons.playlist_add),
            onPressed: enabled
                ? () => editItem('exams', {'nodeId': item['nodeId']})
                : null,
          ),
        if (exam && caps['create'] == true)
          IconButton(
            tooltip: socialText(
              context,
              'پیشنهاد اشتراک کل آزمون',
              'Propose full test subscription',
            ),
            icon: const Icon(Icons.card_membership),
            onPressed: () => editItem('plans/propose', {
              '_rootNodeId': item['nodeId'],
              'title': groupTitle(item['nodeId'] as int?),
              'days': 30,
            }),
          ),
        if (exam && caps['approvePlans'] == true)
          IconButton(
            tooltip: socialText(context, 'سهم درآمد', 'Revenue share'),
            icon: const Icon(Icons.percent),
            onPressed: () => editItem('shares', item),
          ),
        if (caps['delete'] == true &&
            (exam || item['canManage'] == true) &&
            catalog?[exam ? 'levelDeletion' : 'nodeDeletion'] == true)
          IconButton(
            tooltip: socialText(context, 'حذف سطح', 'Delete level'),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDeleteConfirmation(
                context,
                title: socialText(context, 'حذف سطح؟', 'Delete level?'),
                message: socialText(
                  context,
                  'نتایج و خریدهای قبلی حفظ می‌شوند.',
                  'Existing results and purchases will be preserved.',
                ),
              );
              if (confirmed != true) return;
              try {
                await repository!.request(
                  exam ? 'exams/delete' : 'nodes/delete',
                  {'id': item['id'], 'version': item['version']},
                );
                if (mounted) await load();
              } catch (e) {
                if (mounted) setState(() => error = e.toString());
              }
            },
          ),
      ],
    );
  }

  Widget proposalControls(int id) => Column(
    children: [
      for (final plan in proposals.where(
        (p) =>
            p['exam_id'] == null &&
            (int.tryParse('${p['node_id']}') ?? 0) == id,
      ))
        ListTile(
          title: Text(
            '${plan['title']}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          subtitle: Text(
            '${plan['amount']} · ${plan['days']}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          trailing: Wrap(
            children: [
              if ('${plan['teacher_id']}' == '${account ?? 0}')
                IconButton(
                  tooltip: socialText(
                    context,
                    'ویرایش پیشنهاد',
                    'Edit proposal',
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => editItem('plans/propose', plan),
                ),
              if (catalog?['capabilities']?['approvePlans'] == true)
                IconButton(
                  tooltip: socialText(
                    context,
                    'تأیید پیشنهاد',
                    'Review proposal',
                  ),
                  icon: const Icon(Icons.verified_outlined),
                  onPressed: () => editItem('plans/approve', plan),
                ),
            ],
          ),
        ),
    ],
  );

  Future<void> openNode(PracticeJson node) async {
    if (opening) return;
    final exams = groupExams(node['id'] as int);
    final hasChildren = (catalog?['nodes'] as List? ?? []).any(
      (n) => n['parentId'] == node['id'],
    );
    if (!listMode && exams.isNotEmpty && !hasChildren) {
      await openJourney(exams, groupTitle(node['id'] as int));
      return;
    }
    setState(() => opening = true);
    try {
      await socialPush(
        context,
        MusicPracticePage(nodeId: node['id'] as int, nodeTitle: title(node)),
      );
    } finally {
      if (mounted) {
        setState(() => opening = false);
        await load();
      }
    }
  }

  Future<void> openExam(PracticeJson exam) => openJourney(
    [exam],
    '${groupTitle(exam['nodeId'] as int?)} ${title(exam)}',
    stopAtRoundBoundary: false,
  );
  Future<void> openJourney(
    List<PracticeJson> exams,
    String name, {
    bool stopAtRoundBoundary = true,
  }) async {
    final repo = repository;
    if (opening || repo == null) return;
    final next = PracticeJourney(exams, progress).next;
    if (next != null) {
      final exam = next.exam;
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
    }
    setState(() => opening = true);
    try {
      await socialPush(
        context,
        MusicPlaybackEntry(
          reason: PlaybackInterruption.solfege,
          child: MusicPracticeJourneyPage(
            repository: repo,
            exams: exams,
            progress: progress,
            title: name,
            stopAtRoundBoundary: stopAtRoundBoundary,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => opening = false);
        await load();
      }
    }
  }

  Future<void> offers(int teacher, int examId) async {
    final repo = repository!;
    try {
      final exam = (catalog?['exams'] as List? ?? [])
          .where((e) => e['id'] == examId)
          .first;
      var rootId = exam['nodeId'] as int?;
      final visited = <int>{};
      while (rootId != null && visited.add(rootId)) {
        final nodes = (catalog?['nodes'] as List? ?? []).where(
          (n) => n['id'] == rootId,
        );
        if (nodes.isEmpty || nodes.first['parentId'] == null) break;
        rootId = nodes.first['parentId'] as int?;
      }
      final data = await repo.request('plans?examId=$examId'),
          plans = (data['plans'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .where(
                (p) =>
                    p['teacher_id'].toString() == '$teacher' &&
                    p['status'] == 'approved' &&
                    (p['node_id'] == null ||
                        visited.contains(int.tryParse('${p['node_id']}'))) &&
                    p['exam_id'] == null,
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
                      titleTextStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      subtitleTextStyle: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      title: Text(
                        plan['title'].toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                      subtitle: Text(
                        '${plan['amount']} ${socialText(context, 'تومان', 'toman')} · ${plan['days']} ${plan['node_id'] != null ? socialText(context, 'روز؛ تمام سطح‌های این بخش', 'days; all levels in this section') : socialText(context, 'روز؛ همه آزمون‌های مدرس', 'days; all teacher tests')}',
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
    unawaited(syncUpdates?.cancel());
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    repository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodeId == null && MainTabsScope.maybeOf(context) == null) {
      return MainTabs(initialIndex: 4, initialChild: widget);
    }
    final displayCatalog = managementCatalog ?? catalog;
    final nodes = (displayCatalog?['nodes'] as List? ?? [])
            .map((n) => Map<String, dynamic>.from(n as Map))
            .where((n) => n['parentId'] == widget.nodeId),
        exams = (displayCatalog?['exams'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((e) => e['nodeId'] == widget.nodeId);
    final capabilities = Map<String, dynamic>.from(
          catalog?['capabilities'] as Map? ?? {},
        ),
        name = widget.nodeTitle ?? socialText(context, 'آزمون‌ها', 'Tests');
    final actions = <Widget>[
      if (widget.nodeId == null ||
          nodes.any((n) => groupExams(n['id'] as int).isNotEmpty))
        IconButton(
          tooltip: socialText(context, 'تنظیمات', 'Settings'),
          icon: const Icon(Icons.settings, size: 24),
          onPressed: openSettings,
        ),
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
      if (managementCatalog != null &&
          capabilities['create'] == true &&
          (widget.nodeId == null ||
              (displayCatalog?['nodes'] as List? ?? []).any(
                (n) => n['id'] == widget.nodeId && (n['depth'] as int) < 3,
              )))
        IconButton(
          tooltip: socialText(context, 'افزودن سطح', 'Add section'),
          icon: const Icon(Icons.add),
          onPressed:
              PracticeTree(
                (displayCatalog?['nodes'] as List? ?? []).map(
                  (n) => Map<String, dynamic>.from(n as Map),
                ),
              ).available(widget.nodeId)
              ? () => editItem('nodes', {'parentId': widget.nodeId ?? 0})
              : null,
        ),
    ];
    final body = RefreshIndicator(
      onRefresh: () => load(force: true),
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
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
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                enabled: PracticeTree(
                  (displayCatalog?['nodes'] as List? ?? []).map(
                    (n) => Map<String, dynamic>.from(n as Map),
                  ),
                ).available(node['parentId'] as int?),
                shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
                minVerticalPadding: 20,
                leading: Icon(
                  node['slug'].toString().contains('iranian')
                      ? Icons.music_note
                      : node['slug'].toString().contains('western')
                      ? Icons.piano
                      : node['depth'] == 1
                      ? Icons.library_music
                      : Icons.folder_outlined,
                ),
                iconColor: Theme.of(context).colorScheme.primary,
                title: groupHeading(title(node), groupExams(node['id'] as int)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    groupExams(node['id'] as int).isEmpty
                        ? const SizedBox.shrink()
                        : IntervalStars(
                            count: PracticeJourney(
                              groupExams(node['id'] as int),
                              progress,
                            ).stars,
                          ),
                    cardActions(node),
                    proposalControls(node['id'] as int),
                  ],
                ),
                onTap:
                    opening ||
                        !PracticeTree(
                          (displayCatalog?['nodes'] as List? ?? []).map(
                            (n) => Map<String, dynamic>.from(n as Map),
                          ),
                        ).available(node['parentId'] as int?)
                    ? null
                    : () => openNode(node),
              ),
            ),
          if (exams.isNotEmpty && (!listMode || managementCatalog != null))
            Card(
              child: ListTile(
                title: groupHeading(name, exams),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IntervalStars(
                      count: PracticeJourney(exams, progress).stars,
                    ),
                    for (final node
                        in (displayCatalog?['nodes'] as List? ?? []).where(
                          (n) => n['id'] == widget.nodeId,
                        ))
                      cardActions(Map<String, dynamic>.from(node as Map)),
                    proposalControls(widget.nodeId ?? 0),
                  ],
                ),
                leading: const Icon(Icons.play_circle_outline),
                onTap: opening || exams.isEmpty
                    ? null
                    : () => openJourney(
                        exams.toList(),
                        groupTitle(widget.nodeId),
                      ),
              ),
            ),
          for (final exam
              in listMode || (widget.showLevels && managementCatalog != null)
                  ? exams
                  : <PracticeJson>[])
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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: appRadius(context),
                    ),
                    leading: Icon(
                      exam['access'] == true
                          ? done >= (exam['stageCount'] as int)
                                ? Icons.check_circle
                                : Icons.play_circle_outline
                          : Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      title(exam),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exam['audience'] == 'public' &&
                            (exam['config'] as Map?)?['kind'] != 'interval')
                          Text(
                            exam['ownerId'] == 1
                                ? socialText(
                                    context,
                                    'رایگان · مدیر سایت',
                                    'Free · Site administrator',
                                  )
                                : socialText(context, 'رایگان', 'Free'),
                          ),
                        IntervalStars(count: stars),
                        cardActions(exam, exam: true),
                        if ((exam['config'] as Map?)?['kind'] == 'interval')
                          Text(
                            '${IntervalText(context)('interval.${(exam['config'] as Map)['direction']}')} - ${IntervalText(context)((exam['config'] as Map)['variableRoot'] == true ? 'interval.variableRoot' : 'interval.fixedRoot')} - ${IntervalText(context)('interval.count', {'count': IntervalText(context).number(((exam['config'] as Map)['quarterSteps'] as List).length)})} - ${IntervalText(context)(done >= (exam['stageCount'] as int)
                                ? 'interval.completed'
                                : exam['access'] == true
                                ? 'interval.available'
                                : 'interval.locked')}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        if ((exam['config'] as Map?)?['kind'] != 'interval')
                          Text(
                            '$done/${exam['stageCount']} ${socialText(context, 'مرحله', 'stages')}',
                          ),
                      ],
                    ),
                    onTap: opening ? null : () => openExam(exam),
                  ),
                );
              },
            ),
          if (widget.nodeId == null) proposalControls(0),
          if (!loading && error == null && nodes.isEmpty && exams.isEmpty)
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
      tabIndex: widget.nodeId == null ? 4 : null,
      title: name,
      appBar: widget.nodeId == null
          ? HomeTopBar(showLogo: false, extraActions: actions)
          : SornazAppBar(
              title: name,
              showBackButton: widget.nodeId != null,
              actions: actions,
            ),
      bottom: widget.nodeId == null
          ? const BottomNavBarWidget(selectedIndex: 4)
          : null,
      body: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        child: body,
      ),
    );
  }
}
