import 'package:sornaz/components/app_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_bar.dart';
import '../../components/app_hierarchy_row.dart';
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
import 'practice_icons.dart';
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
  bool hierarchyMode = false;
  final expandedNodes = <int>{};
  final publishingItems = <String>{};
  final deletingItems = <String>{};
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
      hierarchyMode = false;
      expandedNodes.clear();
      if (widget.repository == null) repository?.dispose();
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
        error = repo.offline ? null : data['offlineMessage'] as String?;
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
      final hierarchy = await MusicPracticeSettingsPage.hierarchyMode(account);
      if (!mounted || current != generation || repository != repo) return;
      setState(() {
        catalog = data;
        progress = p;
        listMode = showList;
        hierarchyMode = hierarchy;
        loading = false;
        error = repo.offline ? null : data['offlineMessage'] as String?;
      });
    } catch (e) {
      if (mounted && current == generation) {
        setState(() {
          loading = false;
          recordError(e);
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

  void recordError(Object e) {
    if (e is SocialException && [401, 403].contains(e.status)) {
      repository?.offline = false;
    }
    if (MusicPracticeRepository.connectionFailure(e)) {
      repository?.offline = true;
    }
    error = repository?.offline == true ? null : e.toString();
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
      if (mounted) setState(() => recordError(e));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
        ),
        if (plan.exams.isNotEmpty)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${plan.currentLevel}/${plan.exams.length}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget fittedStars({required int count}) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: IntervalStars(count: count),
  );

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
    final hierarchy = await MusicPracticeSettingsPage.hierarchyMode(account);
    if (mounted) {
      setState(() {
        listMode = value;
        hierarchyMode = hierarchy;
      });
    }
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

  List<Widget> hierarchyRows(PracticeJson? data) {
    final tree = PracticeTree(
      (data?['nodes'] as List? ?? []).map(
        (n) => Map<String, dynamic>.from(n as Map),
      ),
    );
    final exams = <int, List<PracticeJson>>{};
    for (final row in data?['exams'] as List? ?? []) {
      final exam = Map<String, dynamic>.from(row as Map);
      exams.putIfAbsent(exam['nodeId'] as int, () => []).add(exam);
    }
    final rows = <Widget>[], visited = <int>{};
    void add(int? parent, int depth) {
      for (final node in tree.children(parent)) {
        final id = node['id'] as int;
        if (!visited.add(id)) continue;
        final levels = PracticeJourney(exams[id] ?? [], progress).exams;
        final expandable = tree.children(id).isNotEmpty || levels.isNotEmpty;
        final expanded = expandedNodes.contains(id);
        rows.add(
          AppHierarchyRow(
            key: ValueKey('practice-tree-node-$id'),
            depth: depth,
            iconColor: Colors.black,
            titleAlignment: ListTileTitleAlignment.center,
            horizontalTitleGap: 8,
            minLeadingWidth: 0,
            icon: PracticeIcons.forNode(node, expanded: expanded),
            title: groupHeading(title(node), levels),
            expanded: expanded,
            expandable: expandable,
            enabled: tree.available(node['parentId'] as int?),
            actions: cardActions(node),
            subtitle: levels.isEmpty
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fittedStars(
                        count: PracticeJourney(levels, progress).stars,
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        key: ValueKey('practice-start-$id'),
                        icon: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.black,
                        ),
                        label: Text(
                          socialText(
                            context,
                            'شروع / ادامهٔ آزمون',
                            'Start / continue test',
                          ),
                        ),
                        onPressed: opening || !tree.available(id)
                            ? null
                            : () => openJourney(levels, groupTitle(id)),
                      ),
                    ],
                  ),
            onTap: opening || !expandable
                ? null
                : () => setState(() {
                    if (!expandedNodes.remove(id)) expandedNodes.add(id);
                  }),
          ),
        );
        if (!expanded) continue;
        add(id, depth + 1);
        for (final exam in levels) {
          rows.add(
            Material(
              key: ValueKey('practice-tree-exam-${exam['id']}'),
              color: AppHierarchyRow.background(context, depth + 1),
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: (depth + 1) * 12.0),
                child: examTile(exam),
              ),
            ),
          );
        }
        rows.add(proposalControls(id));
      }
    }

    add(null, 0);
    return rows;
  }

  Widget examTile(PracticeJson exam) {
    final p = progress.where(
          (p) => p['examId'] == exam['id'] && p['version'] == exam['version'],
        ),
        stars = p.isEmpty ? 0 : p.first['stars'] as int? ?? 0,
        done = p.isEmpty ? 0 : (p.first['completedStages'] as List).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 12),
        horizontalTitleGap: 8,
        minLeadingWidth: 0,
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
        leading: Icon(
          exam['access'] == true
              ? done >= (exam['stageCount'] as int)
                    ? Icons.check_circle
                    : Icons.play_circle_outline
              : Icons.lock_outline,
          color: Colors.black,
        ),
        title: Text(
          title(exam),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
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
            fittedStars(count: stars),
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
        trailing: cardActions(exam, exam: true),
        onTap: opening ? null : () => openExam(exam),
      ),
    );
  }

  Widget nodeActions(int? id) {
    final matches = (managementCatalog?['nodes'] as List? ?? []).where(
      (n) => n['id'] == id,
    );
    return matches.isEmpty
        ? const SizedBox.shrink()
        : cardActions(Map<String, dynamic>.from(matches.first as Map));
  }

  Widget actionMenu(String id, List<PopupMenuEntry<VoidCallback>> items) {
    if (items.isEmpty || repository?.offline == true) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<VoidCallback>(
      key: ValueKey('practice-menu-$id'),
      padding: EdgeInsets.zero,
      tooltip: socialText(context, 'گزینه‌ها', 'Options'),
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onSelected: (action) => action(),
      itemBuilder: (_) => items,
    );
  }

  PopupMenuItem<VoidCallback> menuAction(
    String fa,
    String en,
    VoidCallback action, {
    bool enabled = true,
    bool destructive = false,
  }) => PopupMenuItem<VoidCallback>(
    value: action,
    enabled: enabled,
    child: Text(
      socialText(context, fa, en),
      style: destructive
          ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)
          : null,
    ),
  );

  Future<void> changeVisibility(PracticeJson item, {bool exam = false}) async {
    final key = '${exam ? 'exam' : 'node'}-${item['id']}';
    if (!publishingItems.add(key)) return;
    setState(() {});
    try {
      await repository!.request('publish', {
        'kind': exam ? 'exam' : 'node',
        'id': item['id'],
        'version': item['version'],
        'published': item['published'] != true,
      });
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => recordError(e));
    } finally {
      publishingItems.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> deleteItem(PracticeJson item, {bool exam = false}) async {
    final key = '${exam ? 'exam' : 'node'}-${item['id']}';
    if (!deletingItems.add(key)) return;
    setState(() {});
    try {
      final confirmed = await showDeleteConfirmation(
        context,
        title: socialText(context, 'حذف سطح؟', 'Delete level?'),
        message: socialText(
          context,
          'نتایج و خریدهای قبلی حفظ می‌شوند.',
          'Existing results and purchases will be preserved.',
        ),
      );
      if (!mounted || confirmed != true) return;
      await repository!.request(exam ? 'exams/delete' : 'nodes/delete', {
        'id': item['id'],
        'version': item['version'],
      });
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => recordError(e));
    } finally {
      deletingItems.remove(key);
      if (mounted) setState(() {});
    }
  }

  Widget itemIcon(
    String key,
    String fa,
    String en,
    IconData icon,
    VoidCallback? action, {
    Color? color,
  }) => SizedBox(
    width: 36,
    height: 44,
    child: IconButton(
      key: ValueKey(key),
      tooltip: socialText(context, fa, en),
      padding: EdgeInsets.zero,
      color: color ?? Colors.black,
      onPressed: action,
      icon: Icon(icon),
    ),
  );

  Widget cardActions(PracticeJson item, {bool exam = false}) {
    if (managementCatalog == null || repository?.offline == true) {
      return const SizedBox.shrink();
    }
    final caps = catalog?['capabilities'] as Map? ?? {};
    final tree = PracticeTree(
      (managementCatalog?['nodes'] as List? ?? []).map(
        (n) => Map<String, dynamic>.from(n as Map),
      ),
    );
    final enabled = tree.available(
      exam ? item['nodeId'] as int? : item['parentId'] as int?,
    );
    final publicControl =
        caps['publish'] == true && (exam || item['canManage'] == true);
    final key = '${exam ? 'exam' : 'node'}-${item['id']}';
    final canManage = exam || item['canManage'] == true;
    final menuItems = <PopupMenuEntry<VoidCallback>>[
      if (caps['create'] == true) ...[
        menuAction(
          'افزودن آزمون',
          'Add test',
          () =>
              editItem('exams', {'nodeId': exam ? item['nodeId'] : item['id']}),
          enabled: enabled && (exam || item['published'] == true),
        ),
        menuAction(
          'پیشنهاد اشتراک',
          'Propose subscription',
          () => editItem('plans/propose', {
            '_rootNodeId': exam ? item['nodeId'] : item['id'],
            'title': exam ? groupTitle(item['nodeId'] as int?) : title(item),
            'days': 30,
          }),
        ),
      ],
      if (exam && caps['approvePlans'] == true)
        menuAction(
          'سهم درآمد',
          'Revenue share',
          () => editItem('shares', item),
        ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (publicControl)
          itemIcon(
            'practice-visibility-${exam ? 'exam-' : ''}${item['id']}',
            item['published'] == true ? 'عدم نمایش عمومی' : 'نمایش عمومی',
            item['published'] == true ? 'Hide from public' : 'Show publicly',
            item['published'] == true
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            enabled && !publishingItems.contains(key)
                ? () => changeVisibility(item, exam: exam)
                : null,
          ),
        if (caps['edit'] == true && canManage)
          itemIcon(
            'practice-edit-$key',
            'ویرایش',
            'Edit',
            Icons.edit_outlined,
            enabled ? () => editItem(exam ? 'exams' : 'nodes', item) : null,
          ),
        if (caps['delete'] == true &&
            canManage &&
            catalog?[exam ? 'levelDeletion' : 'nodeDeletion'] == true &&
            (exam || catalog?['levelDeletion'] == true))
          itemIcon(
            'practice-delete-$key',
            'حذف سطح',
            'Delete level',
            Icons.delete_outline,
            enabled && !deletingItems.contains(key)
                ? () => deleteItem(item, exam: exam)
                : null,
            color: Colors.red,
          ),
        if (menuItems.isNotEmpty)
          SizedBox(width: 36, height: 44, child: actionMenu(key, menuItems)),
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
          trailing: actionMenu('plan-${plan['id']}', [
            if ('${plan['teacher_id']}' == '${account ?? 0}')
              menuAction(
                'ویرایش پیشنهاد',
                'Edit proposal',
                () => editItem('plans/propose', plan),
              ),
            if (catalog?['capabilities']?['approvePlans'] == true)
              menuAction(
                'تأیید پیشنهاد',
                'Review proposal',
                () => editItem('plans/approve', plan),
              ),
          ]),
        ),
    ],
  );

  Future<void> openNode(PracticeJson node) async {
    if (opening) return;
    final exams = groupExams(node['id'] as int);
    final hasChildren = (catalog?['nodes'] as List? ?? []).any(
      (n) => n['parentId'] == node['id'],
    );
    if (!listMode && exams.isNotEmpty && !hasChildren && node['depth'] == 3) {
      await openJourney(exams, groupTitle(node['id'] as int));
      return;
    }
    setState(() => opening = true);
    try {
      await socialPush(
        context,
        MusicPracticePage(
          nodeId: node['id'] as int,
          nodeTitle: title(node),
          repository: widget.repository,
        ),
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
      if (mounted) setState(() => recordError(e));
    }
  }

  @override
  void dispose() {
    unawaited(syncUpdates?.cancel());
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.repository == null) repository?.dispose();
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
          icon: const Icon(Icons.settings, size: 24, color: Colors.black),
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
              : const Icon(Icons.upload, color: Colors.black),
        ),
      if (managementCatalog != null &&
          capabilities['create'] == true &&
          (widget.nodeId == null ||
              (displayCatalog?['nodes'] as List? ?? []).any(
                (n) => n['id'] == widget.nodeId && (n['depth'] as int) < 3,
              )))
        IconButton(
          tooltip: socialText(context, 'افزودن سطح', 'Add section'),
          icon: const Icon(Icons.add, color: Colors.black),
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
          if (error != null && repository?.offline != true)
            Text(error!, style: Theme.of(context).textTheme.bodyMedium),
          if (widget.nodeId == null && hierarchyMode)
            ...hierarchyRows(displayCatalog)
          else ...[
            for (final node in nodes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  enabled: PracticeTree(
                    (displayCatalog?['nodes'] as List? ?? []).map(
                      (n) => Map<String, dynamic>.from(n as Map),
                    ),
                  ).available(node['parentId'] as int?),
                  shape: RoundedRectangleBorder(
                    borderRadius: appRadius(context),
                  ),
                  contentPadding: const EdgeInsetsDirectional.only(start: 12),
                  leading: Icon(PracticeIcons.forNode(node)),
                  horizontalTitleGap: 8,
                  minLeadingWidth: 0,
                  iconColor: Colors.black,
                  title: groupHeading(
                    title(node),
                    groupExams(node['id'] as int),
                  ),
                  titleAlignment: ListTileTitleAlignment.center,
                  subtitle:
                      groupExams(node['id'] as int).isEmpty &&
                          !proposals.any(
                            (p) =>
                                p['exam_id'] == null &&
                                (int.tryParse('${p['node_id']}') ?? 0) ==
                                    node['id'],
                          )
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            groupExams(node['id'] as int).isEmpty
                                ? const SizedBox.shrink()
                                : fittedStars(
                                    count: PracticeJourney(
                                      groupExams(node['id'] as int),
                                      progress,
                                    ).stars,
                                  ),
                            proposalControls(node['id'] as int),
                          ],
                        ),
                  trailing: cardActions(node),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(start: 12),
                  title: groupHeading(name, exams),
                  horizontalTitleGap: 8,
                  minLeadingWidth: 0,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fittedStars(
                        count: PracticeJourney(exams, progress).stars,
                      ),
                      proposalControls(widget.nodeId ?? 0),
                    ],
                  ),
                  trailing: nodeActions(widget.nodeId),
                  leading: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.black,
                  ),
                  onTap: opening || exams.isEmpty
                      ? null
                      : () => openJourney(
                          exams.toList(),
                          groupTitle(widget.nodeId),
                        ),
                ),
              ),
            for (final exam
                in listMode || managementCatalog != null
                    ? exams
                    : <PracticeJson>[])
              examTile(exam),
          ],
          if (widget.nodeId == null) proposalControls(0),
          if (!loading &&
              error == null &&
              repository?.offline != true &&
              nodes.isEmpty &&
              exams.isEmpty)
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
