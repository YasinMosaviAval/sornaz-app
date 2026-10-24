import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'panel_ui.dart';
import 'panel_schedule_contract.dart';
import 'panel_schedule_week.dart';

class PanelScheduleCancellation extends StatefulWidget {
  const PanelScheduleCancellation({
    super.key,
    required this.api,
    required this.session,
  });
  final PanelApi api;
  final Json session;
  @override
  State<PanelScheduleCancellation> createState() =>
      _PanelScheduleCancellationState();
}

class _PanelScheduleCancellationState extends State<PanelScheduleCancellation> {
  final reason = TextEditingController();
  Json term = {}, bootstrap = {};
  String date = '', start = '', message = '';
  List<String> times = [];
  bool loading = true, saving = false;
  int generation = 0;
  String tr(String fa, String en) => socialText(context, fa, en);
  int minute(String time) {
    final parts = time.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 +
        (int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0);
  }

  int get duration =>
      minute('${widget.session['endTime']}') -
      minute('${widget.session['startTime']}');
  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    generation++;
    reason.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      bootstrap = await widget.api.live('/schedules/term-context');
      if (!mounted) return;
      term =
          objects(bootstrap['terms'] ?? [])
              .where((t) => '${t['id']}' == '${widget.session['termId']}')
              .firstOrNull ??
          {};
      if (term.isEmpty)
        throw const SocialException(
          'اطلاعات ترم برای تعیین جبرانی در دسترس نیست.',
        );
      if (duration <= 0) throw const SocialException('مدت جلسه معتبر نیست.');
      final active =
          objects(term['sessions'] ?? [])
              .where(
                (s) =>
                    !['canceled', 'rejected'].contains(s['bookingStatus']) &&
                    s['cancellationStatus'] != 'approved',
              )
              .map((s) => '${s['date'] ?? ''}')
              .where((d) => DateTime.tryParse(d) != null)
              .toList()
            ..sort();
      date = panelScheduleISO(
        panelNextSessionDate(
          DateTime.parse(
            active.isEmpty ? '${widget.session['date']}' : active.last,
          ),
          '${term['repeatType'] ?? 'no-period'}',
        ),
      );
      await availability(autoAdvance: true);
    } catch (error) {
      if (mounted)
        setState(() {
          loading = false;
          message = '$error';
        });
    }
  }

  Future<void> availability({bool autoAdvance = false}) async {
    final request = ++generation;
    setState(() {
      loading = true;
      times = [];
      start = '';
      message = '';
    });
    try {
      final course =
          objects(
            bootstrap['courses'] ?? [],
          ).where((c) => '${c['id']}' == '${term['courseId']}').firstOrNull ??
          {};
      final organization =
          objects(bootstrap['branches'] ?? [])
              .where((b) => '${b['id']}' == '${course['organizationUserId']}')
              .firstOrNull ??
          {};
      final original =
          objects(term['sessions'] ?? [])
              .where((s) => '${s['id']}' == '${widget.session['id']}')
              .firstOrNull ??
          widget.session;
      var candidate = date;
      List<String> available = [];
      var closed = false, attempts = 0;
      for (; attempts < 60; attempts++) {
        final result = await widget.api.live('/schedules/available-times', {
          'branch': '${term['branchId'] ?? widget.session['branchId']}',
          'classroom':
              '${term['classroomId'] ?? widget.session['classroomId']}',
          'date': candidate,
          'duration': '$duration',
          'excludeTerm': '0',
          'organizationKind': '${organization['kind'] ?? 'branch'}',
          'organizationUserId': '${course['organizationUserId'] ?? 0}',
          'timezoneId': '${original['timezoneId'] ?? 0}',
          'selectedStart': '${widget.session['startTime'] ?? ''}',
        });
        if (!mounted || request != generation) return;
        closed = result['closed'] == true;
        available = (result['times'] as List? ?? []).map((v) => '$v').toList();
        if (!autoAdvance ||
            !closed && available.contains('${widget.session['startTime']}') ||
            attempts == 59)
          break;
        candidate = panelScheduleISO(
          panelNextSessionDate(
            DateTime.parse(candidate),
            '${term['repeatType'] ?? 'no-period'}',
          ),
        );
      }
      if (!mounted || request != generation) return;
      setState(() {
        date = candidate;
        times = closed ? [] : available;
        start = times.contains('${widget.session['startTime']}')
            ? '${widget.session['startTime']}'
            : times.firstOrNull ?? '';
        loading = false;
        message = times.isEmpty
            ? closed
                  ? tr(
                      'شعبه یا آموزشگاه در این تاریخ تعطیل است.',
                      'The organization is closed on this date.',
                    )
                  : tr(
                      'در این تاریخ ساعت خالی وجود ندارد.',
                      'No available times on this date.',
                    )
            : attempts > 0
            ? tr(
                'تاریخ پیشنهادی اولیه قابل برگزاری نبود؛ تاریخ جبرانی به زمان آزاد بعدی منتقل شد.',
                'The initial date was unavailable; the next available date is selected.',
              )
            : tr(
                'تاریخ و ساعت جلسه جبرانی قابل برگزاری است.',
                'The makeup session time is available.',
              );
      });
    } catch (error) {
      if (mounted && request == generation)
        setState(() {
          loading = false;
          message = '$error';
        });
    }
  }

  Future<void> save() async {
    if (reason.text.trim().isEmpty) {
      setState(
        () => message = tr(
          'دلیل لغو جلسه الزامی است.',
          'A cancellation reason is required.',
        ),
      );
      return;
    }
    if (loading || saving || !times.contains(start)) return;
    setState(() => saving = true);
    try {
      final total = minute(start) + duration;
      final end =
          '${(total ~/ 60 % 24).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
      await widget.api.act(
        'schedules',
        'cancel',
        params: {
          'termId': '${widget.session['termId']}',
          'id': '${widget.session['id']}',
        },
        values: {
          'reason': reason.text.trim(),
          'makeupDate': date,
          'startTime': start,
          'endTime': end,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(() {
          saving = false;
          message = '$error';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PanelModal(
    busy: saving,
    title: tr('لغو جلسه و تعیین جبرانی', 'Cancel and reschedule'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${widget.session['title'] ?? ''}'),
        const SizedBox(height: 12),
        TextField(
          controller: reason,
          enabled: !saving,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: tr('دلیل لغو *', 'Cancellation reason *'),
          ),
        ),
        const SizedBox(height: 12),
        if (date.isNotEmpty)
          PanelField(
            field: {
              'key': 'makeupDate',
              'label': tr('تاریخ جلسه جبرانی *', 'Makeup session date *'),
              'type': 'date',
              'readOnly': saving,
            },
            value: date,
            data: const {},
            changed: (value) {
              if (value == null || '$value' == date) return;
              date = '$value';
              availability();
            },
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 12),
        PanelField(
          field: {
            'key': 'startTime',
            'label': tr('ساعت شروع', 'Start time'),
            'type': 'select',
            'required': true,
            'readOnly': loading || saving,
            'options': {for (final time in times) time: time},
          },
          value: start,
          data: const {},
          changed: (value) => setState(() => start = '$value'),
        ),
        const SizedBox(height: 12),
        Text(
          '${tr('مدت جلسه', 'Session duration')}: $duration ${tr('دقیقه', 'minutes')}',
        ),
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(message),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: loading || saving || start.isEmpty ? null : save,
              child: Text(
                tr('ثبت لغو و جلسه جبرانی', 'Save cancellation and makeup'),
              ),
            ),
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: Text(tr('انصراف', 'Cancel')),
            ),
          ],
        ),
      ],
    ),
  );
}
