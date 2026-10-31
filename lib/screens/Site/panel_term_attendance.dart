import 'package:sornaz/components/app_async_state.dart';
import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'panel_parity.dart';
import 'panel_ui.dart';
import 'panel_session_files.dart';

class PanelTermAttendance extends StatefulWidget {
  const PanelTermAttendance({
    super.key,
    required this.api,
    required this.termId,
  });
  final PanelApi api;
  final String termId;
  @override
  State<PanelTermAttendance> createState() => _PanelTermAttendanceState();
}

class _PanelTermAttendanceState extends State<PanelTermAttendance> {
  List<Json>? sessions;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = <Json>[];
      for (var page = 1; ; page++) {
        final response = await widget.api.live('/terms/attendance', {
          'termId': widget.termId,
          'page': '$page',
          'perPage': '100',
        });
        if (!mounted) return;
        final chunk = objects(response['schedules'] ?? []);
        rows.addAll(chunk);
        if (rows.length >=
            (num.tryParse('${response['total']}') ?? rows.length))
          break;
        if (chunk.isEmpty || page >= 1000)
          throw const SocialException('دریافت جلسه‌ها کامل نشد.');
      }
      if (mounted)
        setState(() {
          sessions = rows;
          failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> edit(Json session) async {
    final people = objects(session['attendance'] ?? []);
    var saved = false;
    await showDialog<PanelFormResult>(
      context: context,
      builder: (_) => PanelFormPage(
        dialog: true,
        title: socialText(context, 'حضور و غیاب', 'Attendance'),
        fields: [
          if (session['canWriteTeacherNote'] == true)
            const {
              'key': 'teacherNote',
              'label': 'یادداشت استاد',
              'en': 'Teacher note',
              'type': 'multiline',
              'maxLength': 10000,
            },
          {
            'key': 'attendance',
            'label': 'حضور و غیاب',
            'en': 'Attendance',
            'type': 'rows',
            'options': [
              {
                'key': 'memberId',
                'label': 'عضو',
                'en': 'Member',
                'type': 'select',
                'required': true,
                'options': {'source': 'attendance'},
              },
              {
                'key': 'status',
                'label': 'وضعیت',
                'en': 'Status',
                'type': 'select',
                'required': true,
                'options': {
                  'present': 'حاضر',
                  'absent': 'غایب',
                  'late': 'تأخیر',
                  'leave': 'مرخصی',
                  'excused_absence': 'غیبت موجه',
                  'online': 'آنلاین',
                },
              },
              {'key': 'description', 'label': 'توضیح', 'en': 'Note'},
            ],
          },
        ],
        data: {'attendance': people},
        initial: {
          if (session['canWriteTeacherNote'] == true)
            'teacherNote': session['teacherNote'] ?? '',
          'attendance': [
            for (final person in people) {...person, 'memberId': person['id']},
          ],
        },
        onSubmit: (result) async {
          await widget.api.act(
            'schedules',
            'attendance',
            params: {'id': '${session['id']}'},
            values: result.values,
          );
          saved = true;
        },
      ),
    );
    if (mounted) await load();
    if (mounted && saved)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            socialText(context, 'حضور و غیاب ذخیره شد.', 'Attendance saved.'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => PanelModal(
    title: socialText(context, 'حضور و غیاب ترم', 'Term attendance'),
    child: failed
        ? TextButton(
            onPressed: load,
            child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
          )
        : sessions == null
        ? const AppLoadingIndicator()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sessions!.isEmpty)
                Text(
                  socialText(
                    context,
                    'جلسه‌ای یافت نشد.',
                    'No sessions found.',
                  ),
                ),
              for (final session in sessions!)
                ListTile(
                  title: Text('${session['title'] ?? ''}'),
                  subtitle: Text(
                    '${panelDate(session['date'], fa: Localizations.localeOf(context).languageCode == 'fa')} · ${session['time'] ?? ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: socialText(
                          context,
                          'فایل‌های جلسه',
                          'Session files',
                        ),
                        onPressed: () =>
                            showPanelSessionFiles(context, widget.api, session),
                        icon: const Icon(Icons.attach_file),
                      ),
                      const Icon(Icons.fact_check_outlined),
                    ],
                  ),
                  onTap: () => edit(session),
                ),
            ],
          ),
  );
}
