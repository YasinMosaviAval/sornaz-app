import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';

class PanelNationalHolidaySettings extends StatefulWidget {
  const PanelNationalHolidaySettings({super.key, required this.api});
  final PanelApi api;
  @override
  State<PanelNationalHolidaySettings> createState() =>
      _PanelNationalHolidaySettingsState();
}

class _PanelNationalHolidaySettingsState
    extends State<PanelNationalHolidaySettings> {
  List<Json>? organizations;
  bool failed = false, saving = false, bulk = false;
  final values = <String, bool>{};
  String id(Json row) => '${row['academyId']}:${row['branchId'] ?? 0}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.live('/national-holidays/list');
      if (!mounted) return;
      setState(() {
        bulk = data['organizations'] is List;
        organizations = bulk
            ? objects(data['organizations'])
            : [
                for (final row in objects(data['academies'] ?? []))
                  {...row, 'academyId': row['id'], 'branchId': 0},
              ];
        values.clear();
        for (final row in organizations!) {
          values[id(row)] = row['allowClasses'] == true;
        }
        failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> save() async {
    if (saving || organizations == null || organizations!.isEmpty) return;
    setState(() => saving = true);
    try {
      final rows = [
        for (final row in organizations!)
          {
            'academyId': row['academyId'],
            'branchId': row['branchId'] ?? 0,
            'allowClasses': values[id(row)] ?? false,
          },
      ];
      if (bulk) {
        await widget.api.act(
          'national-holidays',
          'academy-setting',
          params: {'academyId': '${rows.first['academyId']}'},
          values: {'organizations': rows},
        );
      } else {
        for (final row in rows) {
          await widget.api.act(
            'national-holidays',
            'academy-setting',
            params: {'academyId': '${row['academyId']}'},
            values: row,
          );
        }
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(
                context,
                'تنظیمات تعطیلات رسمی ذخیره شد.',
                'National holiday settings saved.',
              ),
            ),
          ),
        );
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (organizations?.isEmpty == true) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      color: Color.alphaBlend(
        theme.colorScheme.primary.withValues(alpha: .2),
        theme.scaffoldBackgroundColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: appRadius(context),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: .3),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              socialText(
                context,
                'برگزاری کلاس در تعطیلات رسمی کشور',
                'Classes on national holidays',
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              socialText(
                context,
                'در حالت پیش‌فرض، تعطیلات رسمی در تعیین خودکار تاریخ جلسات رد می‌شوند. فعال‌کردن این گزینه فقط تعطیلات کشوری را نادیده می‌گیرد و تعطیلات اختصاصی آموزشگاه و شعبه همچنان اعمال می‌شوند.',
                'National holidays are skipped when scheduling sessions by default. Enabling this option ignores national holidays only; academy and branch closures still apply.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            if (failed)
              TextButton(
                onPressed: load,
                child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
              )
            else if (organizations == null)
              const LinearProgressIndicator()
            else ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final row in organizations!)
                      SizedBox(
                        width: constraints.maxWidth >= 600
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: Material(
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: appRadius(context),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: .3,
                              ),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            title: Text('${row['name'] ?? ''}'),
                            value: values[id(row)] ?? false,
                            onChanged: saving
                                ? null
                                : (value) => setState(
                                    () => values[id(row)] = value ?? false,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    socialText(context, 'ذخیره اطلاعات', 'Save settings'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
