import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sornaz/components/charts/app_line_chart.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_parity.dart';

/// Columns follow the web tracking view; API-only metadata is never inferred.
class PanelTracking extends StatelessWidget {
  const PanelTracking({super.key, required this.data});
  final Json data;
  static const sections = {
    'funnel': ('قیف تبدیل', 'Conversion funnel', ['label', 'value']),
    'retention': (
      'بازگشت کاربران',
      'User retention',
      ['users', 'returning_users', 'avg_sessions', 'avg_active_days'],
    ),
    'sessionSegments': ('الگوهای نشست', 'Session segments', ['label', 'value']),
    'trend': (
      'روند فعالیت',
      'Activity trend',
      ['day', 'sessions', 'users', 'page_views', 'events', 'bounce_rate'],
    ),
    'activity': (
      'نوع فعالیت',
      'Activity types',
      ['label', 'seconds', 'intervals'],
    ),
    'hourly': (
      'فعالیت ساعتی',
      'Hourly activity',
      ['hour', 'sessions', 'users'],
    ),
    'weekdays': (
      'فعالیت روزهای هفته',
      'Weekly activity',
      ['weekday', 'sessions'],
    ),
    'popular': (
      'صفحات محبوب',
      'Popular pages',
      [
        'label',
        'views',
        'sessions',
        'avg_seconds',
        'avg_scroll',
        'interactions',
        'exit_rate',
      ],
    ),
    'unpopular': (
      'نیازمند بازبینی',
      'Pages to review',
      [
        'label',
        'views',
        'avg_seconds',
        'avg_scroll',
        'interactions',
        'interest_score',
      ],
    ),
    'features': (
      'امکانات پرکاربرد',
      'Popular features',
      ['label', 'event_name', 'uses', 'users', 'sessions'],
    ),
    'sections': (
      'بخش‌ها',
      'Sections',
      [
        'label',
        'impressions',
        'active_seconds',
        'interactions',
        'clicks',
        'visibility',
      ],
    ),
    'entryPages': (
      'صفحات ورودی',
      'Entry pages',
      ['label', 'sessions', 'bounce_rate', 'avg_seconds'],
    ),
    'exitPages': (
      'صفحات خروج',
      'Exit pages',
      ['label', 'exits', 'avg_seconds'],
    ),
    'transitions': (
      'مسیر حرکت کاربران',
      'Page transitions',
      ['source', 'destination', 'transitions'],
    ),
    'clickedTargets': (
      'عناصر کلیک‌شده',
      'Clicked elements',
      ['label', 'section', 'clicks', 'users', 'sessions'],
    ),
    'forms': (
      'تعامل با فرم‌ها',
      'Form interactions',
      ['label', 'focuses', 'submits', 'sessions', 'completionRate'],
    ),
    'friction': (
      'مشکلات تعامل',
      'Interaction friction',
      [
        'label',
        'views',
        'hidden_rate',
        'idle_rate',
        'scroll_depth',
        'exit_rate',
        'form_interactions',
      ],
    ),
    'technical': (
      'خطاهای فنی',
      'Technical errors',
      ['offline_events', 'online_events', 'affected_sessions'],
    ),
    'referrers': (
      'منابع ورودی',
      'Referrers',
      ['label', 'views', 'sessions', 'avg_seconds'],
    ),
    'campaigns': (
      'کمپین‌ها',
      'Campaigns',
      ['source', 'medium', 'campaign', 'views', 'sessions'],
    ),
    'devices': ('دستگاه‌ها', 'Devices', ['label', 'value']),
    'browsers': ('مرورگرها', 'Browsers', ['label', 'value']),
    'users': (
      'کاربران فعال',
      'Active users',
      [
        'name',
        'sessions',
        'page_views',
        'events',
        'active_minutes',
        'bounce_rate',
      ],
    ),
    'formAbandonment': (
      'رهاکردن فرم',
      'Form abandonment',
      [
        'focusedSessions',
        'submittedSessions',
        'abandonedSessions',
        'completionRate',
      ],
    ),
    'locales': ('زبان‌ها', 'Languages', ['label', 'value']),
    'locations': (
      'موقعیت جغرافیایی',
      'Locations',
      ['country', 'city', 'sessions'],
    ),
    'consents': (
      'رضایت‌نامه‌ها',
      'Consents',
      ['total', 'analytics', 'personalization', 'marketing', 'revoked'],
    ),
    'quality': (
      'کیفیت نشست',
      'Session quality',
      [
        'total',
        'multi_page',
        'engaged',
        'deep_engaged',
        'completed',
        'interrupted',
      ],
    ),
  };
  static const labels = {
    'label': ('عنوان', 'Title'),
    'value': ('تعداد', 'Count'),
    'users': ('کاربران', 'Users'),
    'sessions': ('نشست‌ها', 'Sessions'),
    'pageViews': ('بازدید صفحات', 'Page views'),
    'events': ('رویدادها', 'Events'),
    'avgSessionMs': ('میانگین زمان نشست', 'Average session time'),
    'avgPageMs': ('میانگین ماندگاری صفحه', 'Average page time'),
    'pagesPerSession': ('صفحه در هر نشست', 'Pages per session'),
    'bounceRate': ('نرخ خروج سریع', 'Bounce rate'),
    'returning_users': ('کاربران بازگشتی', 'Returning users'),
    'avg_sessions': ('میانگین نشست هر کاربر', 'Sessions per user'),
    'avg_active_days': ('میانگین روزهای فعال', 'Average active days'),
    'day': ('تاریخ', 'Date'),
    'page_views': ('بازدید', 'Page views'),
    'bounce_rate': ('نرخ خروج سریع', 'Bounce rate'),
    'seconds': ('زمان (ثانیه)', 'Time (seconds)'),
    'intervals': ('بازه‌ها', 'Intervals'),
    'hour': ('ساعت', 'Hour'),
    'weekday': ('روز هفته', 'Weekday'),
    'views': ('بازدید', 'Views'),
    'avg_seconds': ('میانگین زمان (ثانیه)', 'Average seconds'),
    'avg_scroll': ('اسکرول (%)', 'Scroll (%)'),
    'interactions': ('تعامل', 'Interactions'),
    'exit_rate': ('خروج (%)', 'Exit (%)'),
    'interest_score': ('امتیاز علاقه', 'Interest score'),
    'event_name': ('رویداد', 'Event'),
    'uses': ('استفاده', 'Uses'),
    'impressions': ('نمایش', 'Impressions'),
    'active_seconds': ('زمان فعال (ثانیه)', 'Active seconds'),
    'clicks': ('کلیک', 'Clicks'),
    'visibility': ('مشاهده‌پذیری (%)', 'Visibility (%)'),
    'exits': ('خروج', 'Exits'),
    'source': ('منبع', 'Source'),
    'destination': ('مقصد', 'Destination'),
    'transitions': ('تعداد حرکت', 'Transitions'),
    'section': ('بخش', 'Section'),
    'focuses': ('فوکوس', 'Focuses'),
    'submits': ('ارسال', 'Submits'),
    'medium': ('رسانه', 'Medium'),
    'campaign': ('کمپین', 'Campaign'),
    'name': ('نام', 'Name'),
    'active_minutes': ('زمان فعال (دقیقه)', 'Active minutes'),
    'focusedSessions': ('نشست‌های دارای تعامل با فرم', 'Form focus sessions'),
    'submittedSessions': ('نشست‌های دارای ارسال فرم', 'Form submit sessions'),
    'abandonedSessions': ('نشست‌های رهاشده', 'Abandoned sessions'),
    'completionRate': ('نرخ تکمیل (%)', 'Completion rate (%)'),
    'country': ('کشور', 'Country'),
    'city': ('شهر', 'City'),
    'total': ('مجموع', 'Total'),
    'analytics': ('تحلیل', 'Analytics'),
    'personalization': ('شخصی‌سازی', 'Personalization'),
    'marketing': ('بازاریابی', 'Marketing'),
    'revoked': ('لغوشده', 'Revoked'),
    'multi_page': ('چندصفحه‌ای', 'Multiple pages'),
    'engaged': ('تعامل بیش از یک دقیقه', 'Engaged'),
    'deep_engaged': ('تعامل بیش از پنج دقیقه', 'Deep engagement'),
    'completed': ('پایان‌یافته', 'Completed'),
    'interrupted': ('قطع‌شده', 'Interrupted'),
    'hidden_rate': ('مخفی (%)', 'Hidden (%)'),
    'idle_rate': ('بیکار (%)', 'Idle (%)'),
    'scroll_depth': ('اسکرول (%)', 'Scroll (%)'),
    'form_interactions': ('تعامل فرم', 'Form interactions'),
    'offline_events': ('قطع ارتباط', 'Offline events'),
    'online_events': ('اتصال مجدد', 'Online events'),
    'affected_sessions': ('نشست‌های متأثر', 'Affected sessions'),
  };
  static String label(BuildContext context, String key) =>
      socialText(context, labels[key]!.$1, labels[key]!.$2);
  static String cell(BuildContext context, String key, dynamic value) {
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    if (key == 'day') return panelDate(value, fa: fa);
    if (key == 'weekday') {
      final i = int.tryParse('$value');
      if (i != null && i >= 0 && i < 7)
        return socialText(
          context,
          [
            'دوشنبه',
            'سه‌شنبه',
            'چهارشنبه',
            'پنج‌شنبه',
            'جمعه',
            'شنبه',
            'یکشنبه',
          ][i],
          [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][i],
        );
    }
    if (key.endsWith('Ms'))
      return '${panelNumber((num.tryParse('$value') ?? 0) / 1000, fa: fa)} ${socialText(context, 'ثانیه', 'seconds')}';
    return panelNumber(value, fa: fa);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in [
              'sessions',
              'users',
              'pageViews',
              'events',
              'avgSessionMs',
              'avgPageMs',
              'pagesPerSession',
              'bounceRate',
            ])
              SizedBox(
                width: 170,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(label(context, key)),
                        const SizedBox(height: 8),
                        Text(
                          cell(
                            context,
                            key,
                            optionalObject(data['metrics'])[key],
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        PanelTrackingInsights(data: data),
        for (final entry in sections.entries) ...[
          const SizedBox(height: 16),
          Text(
            socialText(context, entry.value.$1, entry.value.$2),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (data[entry.key] is List && (data[entry.key] as List).isNotEmpty)
            PanelTrackingChart(kind: entry.key, rows: objects(data[entry.key])),
          if (data[entry.key] is List && (data[entry.key] as List).isEmpty)
            Text(
              socialText(context, 'داده‌ای ثبت نشده است.', 'No data recorded.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final key in entry.value.$3)
                    DataColumn(label: Text(label(context, key))),
                ],
                rows: [
                  for (final row
                      in data[entry.key] is List
                          ? objects(data[entry.key])
                          : [optionalObject(data[entry.key])])
                    DataRow(
                      cells: [
                        for (final key in entry.value.$3)
                          DataCell(
                            Text(
                              cell(
                                context,
                                key,
                                entry.key == 'forms' && key == 'completionRate'
                                    ? ((num.tryParse('${row['focuses']}') ??
                                                  0) >
                                              0
                                          ? ((num.tryParse(
                                                          '${row['submits']}',
                                                        ) ??
                                                        0) *
                                                    100 /
                                                    num.parse(
                                                      '${row['focuses']}',
                                                    ))
                                                .round()
                                          : null)
                                    : row[key],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        PanelTrackingRaw(data: optionalObject(data['raw'])),
      ],
    ),
  );
}

class PanelTrackingInsights extends StatelessWidget {
  const PanelTrackingInsights({super.key, required this.data});
  final Json data;
  @override
  Widget build(BuildContext context) {
    final metrics = optionalObject(data['metrics']);
    final popular = objects(data['popular'] ?? []).firstOrNull;
    final unpopular = objects(data['unpopular'] ?? []).firstOrNull;
    final feature = objects(data['features'] ?? []).firstOrNull;
    final sessions = num.tryParse('${metrics['sessions']}') ?? 0;
    final guests = num.tryParse('${metrics['guestSessions']}') ?? 0;
    final items = [
      ('صفحه محبوب', 'Popular page', popular?['label']),
      ('نیازمند بازبینی', 'Needs review', unpopular?['label']),
      ('امکان پرکاربرد', 'Popular feature', feature?['label']),
      (
        'اسکرول متوسط',
        'Average scroll',
        '${panelNumber(metrics['avgScroll'], fa: Localizations.localeOf(context).languageCode == 'fa')}%',
      ),
      (
        'سهم نشست مهمان',
        'Guest session share',
        '${panelNumber(sessions == 0 ? 0 : (guests * 100 / sessions).round(), fa: Localizations.localeOf(context).languageCode == 'fa')}%',
      ),
      ('رویداد در نشست', 'Events per session', metrics['eventsPerSession']),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          SizedBox(
            width: 170,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(socialText(context, item.$1, item.$2)),
                    const SizedBox(height: 8),
                    Text(
                      '${item.$3 ?? socialText(context, 'داده کافی نیست', 'Insufficient data')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PanelTrackingRaw extends StatefulWidget {
  const PanelTrackingRaw({super.key, required this.data});
  final Json data;
  @override
  State<PanelTrackingRaw> createState() => _PanelTrackingRawState();
}

class _PanelTrackingRawState extends State<PanelTrackingRaw> {
  static const tabs = {
    'sessions': ('نشست‌ها', 'Sessions'),
    'pageViews': ('بازدید صفحات', 'Page views'),
    'events': ('رویدادها', 'Events'),
    'engagements': ('تعامل محتوا', 'Content engagement'),
    'activities': ('بازه‌های فعالیت', 'Activity intervals'),
    'consents': ('رضایت‌نامه‌ها', 'Consents'),
    'batches': ('بسته‌های دریافت', 'Ingestion batches'),
  };
  String selected = 'sessions';
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final rows = objects(widget.data[selected] ?? []);
    final columns = rows.isEmpty ? <String>[] : rows.first.keys.toList();
    final pages = (rows.length / 10).ceil().clamp(1, 1000000);
    final current = page.clamp(1, pages);
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            socialText(
              context,
              'داده‌های فنی ثبت‌شده',
              'Recorded technical data',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: Theme.of(context).textTheme.labelLarge,
            onTap: (index) => setState(() {
              selected = tabs.keys.elementAt(index);
              page = 1;
            }),
            tabs: [
              for (final tab in tabs.values)
                Tab(text: socialText(context, tab.$1, tab.$2)),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                socialText(
                  context,
                  'داده‌ای در این بازه وجود ندارد.',
                  'No data in this period.',
                ),
              ),
            )
          else ...[
            // The website deliberately exposes source column names in this admin
            // diagnostic view, unlike ordinary user-facing record details.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final key in columns) DataColumn(label: Text(key)),
                ],
                rows: [
                  for (final row in rows.skip((current - 1) * 10).take(10))
                    DataRow(
                      cells: [
                        for (final key in columns)
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Tooltip(
                                message: row[key] is Map || row[key] is List
                                    ? jsonEncode(row[key])
                                    : '${row[key] ?? '—'}',
                                child: Text(
                                  row[key] is Map || row[key] is List
                                      ? jsonEncode(row[key])
                                      : '${row[key] ?? '—'}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: current > 1
                      ? () => setState(() => page = current - 1)
                      : null,
                  child: Text(socialText(context, 'قبلی', 'Previous')),
                ),
                Text('$current / $pages'),
                TextButton(
                  onPressed: current < pages
                      ? () => setState(() => page = current + 1)
                      : null,
                  child: Text(socialText(context, 'بعدی', 'Next')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PanelTrackingChart extends StatelessWidget {
  const PanelTrackingChart({super.key, required this.kind, required this.rows});
  final String kind;
  final List<Json> rows;
  static const measures = {
    'funnel': 'value',
    'sessionSegments': 'value',
    'devices': 'value',
    'browsers': 'value',
    'locales': 'value',
    'activity': 'seconds',
    'hourly': 'sessions',
    'weekdays': 'sessions',
  };
  @override
  Widget build(BuildContext context) {
    if (kind == 'trend') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AppLineChart(
          points: [
            for (final row in rows)
              AppChartPoint(
                PanelTracking.cell(context, 'day', row['day']),
                num.tryParse('${row['page_views']}')?.toDouble() ?? 0,
              ),
          ],
          formatValue: (value) =>
              PanelTracking.cell(context, 'page_views', value),
        ),
      );
    }
    final measure = measures[kind];
    if (measure == null) return const SizedBox();
    final maximum = rows
        .map((row) => num.tryParse('${row[measure]}') ?? 0)
        .fold<num>(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kind == 'weekdays'
                              ? PanelTracking.cell(
                                  context,
                                  'weekday',
                                  row['weekday'],
                                )
                              : '${row['label'] ?? row['hour'] ?? '—'}',
                        ),
                      ),
                      Text(PanelTracking.cell(context, measure, row[measure])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: maximum <= 0
                        ? 0
                        : ((num.tryParse('${row[measure]}') ?? 0) / maximum)
                              .clamp(0, 1)
                              .toDouble(),
                    borderRadius: appRadius(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
