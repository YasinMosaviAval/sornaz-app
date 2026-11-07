import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/app_async_state.dart';
import '../../components/app_bar.dart';
import '../../components/charts/app_sample_chart.dart';
import '../../helpers/app_appearance.dart';
import '../../helpers/chart_export.dart';
import '../Social/social_widgets.dart';
import '../Social/social_api.dart';
import 'panel_parity.dart';
import 'panel_section_card.dart';
import 'panel_ui.dart';

class PanelChartGalleryPage extends StatefulWidget {
  const PanelChartGalleryPage({super.key, this.catalog});
  final Json? catalog;
  @override
  State<PanelChartGalleryPage> createState() => _PanelChartGalleryPageState();
}

class _PanelChartGalleryPageState extends State<PanelChartGalleryPage> {
  Json? data;
  bool failed = false;
  String search = '', family = '', type = '', variant = 'all';
  final localVariants = <String, String>{};
  String t(String fa, String en) => socialText(context, fa, en);
  bool get fa => Localizations.localeOf(context).languageCode == 'fa';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value =
          widget.catalog ??
          object(
            jsonDecode(
              await rootBundle.loadString('assets/panel/chart-gallery.json'),
            ),
          );
      if (value['version'] != 1 || objects(value['types']).length != 19) {
        throw const FormatException('Gallery contract changed');
      }
      if (mounted) {
        setState(() {
          data = value;
          failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  String label(Json item) => '${item[fa ? 'title' : 'en']}';
  String translated(String value) {
    if (fa) return panelDigits(value);
    final translated = '${optionalObject(data?['labels'])[value] ?? value}';
    return translated.replaceAllMapped(
      RegExp('[۰-۹]'),
      (m) => '${'۰۱۲۳۴۵۶۷۸۹'.indexOf(m[0]!)}',
    );
  }

  Widget select(
    String id,
    String title,
    String value,
    Map<String, String> options,
    ValueChanged<String> change, {
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey('chart-$id-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: title),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled
          ? (value) {
              if (value != null) change(value);
            }
          : null,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final families = objects(data?['families'] ?? []),
        types = objects(data?['types'] ?? []);
    final filtered = types.where((item) {
      final familyRow =
          families.where((f) => f['id'] == item['family']).firstOrNull ?? {};
      final text =
          '${item['title']} ${item['en']} ${item['description']} ${item['descriptionEn']} ${familyRow['fa']} ${familyRow['en']}'
              .toLowerCase();
      return (family.isEmpty || item['family'] == family) &&
          (type.isEmpty || item['id'] == type) &&
          text.contains(search.trim().toLowerCase());
    }).toList();
    return PanelScaffold(
      appBar: SornazAppBar(title: t('گالری نمودارها', 'Chart gallery')),
      body: failed
          ? AppErrorState(
              message: t(
                'دریافت نمونه‌های نمودار انجام نشد.',
                'Could not load the chart samples.',
              ),
              onRetry: load,
            )
          : data == null
          ? const AppLoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  t(
                    'این نمودارها نمونهٔ نمایشی هستند و اطلاعات حساب یا گزارش مالی شما نیستند.',
                    'These are demonstration charts, not your account or financial reports.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                PanelSectionCard(
                  title: t('فیلترها', 'Filters'),
                  horizontalInset: 0,
                  storageId: 'chart-gallery-filters',
                  children: [
                    TextField(
                      key: const ValueKey('chart-search'),
                      decoration: InputDecoration(
                        labelText: t(
                          'جستجوی نام یا کاربرد',
                          'Search name or purpose',
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    select(
                      'family',
                      t('خانوادهٔ نمودار', 'Chart family'),
                      family,
                      {
                        '': t('همه خانواده‌ها', 'All families'),
                        for (final f in families)
                          '${f['id']}': '${f[fa ? 'fa' : 'en']}',
                      },
                      (v) => setState(() => family = v),
                    ),
                    select('type', t('نوع نمودار', 'Chart type'), type, {
                      '': t('همه انواع نمودار', 'All chart types'),
                      for (final item in types) '${item['id']}': label(item),
                    }, (v) => setState(() => type = v)),
                    select('variant', t('پیاده‌سازی', 'Variant'), variant, {
                      'all': t('هر دو نمونه', 'Both samples'),
                      'basic': t('پایه', 'Basic'),
                      'advanced': t('پیشرفته', 'Advanced'),
                    }, (v) => setState(() => variant = v)),
                  ],
                ),
                Text(
                  '${panelNumber(filtered.length, fa: fa)} ${t('نوع نمودار قابل نمایش', 'chart types shown')}',
                ),
                if (filtered.isEmpty)
                  AppEmptyState(
                    message: t(
                      'نموداری با این فیلتر پیدا نشد.',
                      'No charts match these filters.',
                    ),
                  ),
                for (final item in filtered)
                  Card(
                    key: ValueKey('gallery-${item['id']}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: appRadius(context),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            label(item),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${item[fa ? 'description' : 'descriptionEn']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          select(
                            'local-${item['id']}',
                            t('نمایش نمونه‌ها', 'Sample display'),
                            localVariants[item['id']] ?? 'all',
                            {
                              'all': t('هر دو نمونه', 'Both samples'),
                              'basic': t('فقط پایه', 'Basic only'),
                              'advanced': t('فقط پیشرفته', 'Advanced only'),
                            },
                            (v) => setState(
                              () => localVariants['${item['id']}'] = v,
                            ),
                            enabled: variant == 'all',
                          ),
                          for (final choice
                              in (variant == 'all'
                                          ? localVariants[item['id']] ?? 'all'
                                          : variant) ==
                                      'all'
                                  ? ['basic', 'advanced']
                                  : [
                                      variant == 'all'
                                          ? localVariants[item['id']]!
                                          : variant,
                                    ])
                            _GallerySample(
                              key: ValueKey('${item['id']}-$choice'),
                              type: '${item['id']}',
                              option: optionalObject(item[choice]),
                              advanced: choice == 'advanced',
                              translate: translated,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _GallerySample extends StatefulWidget {
  const _GallerySample({
    super.key,
    required this.type,
    required this.option,
    required this.advanced,
    required this.translate,
  });
  final String type;
  final Json option;
  final bool advanced;
  final String Function(String) translate;
  @override
  State<_GallerySample> createState() => _GallerySampleState();
}

class _GallerySampleState extends State<_GallerySample> {
  final boundary = GlobalKey();
  bool exporting = false;
  String t(String fa, String en) => socialText(context, fa, en);
  Future<void> export() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      await saveChartPng(
        boundary,
        '${widget.type}-${widget.advanced ? 'advanced' : 'basic'}.png',
      );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              widget.advanced
                  ? t('پیاده‌سازی پیشرفته', 'Advanced sample')
                  : t('پیاده‌سازی پایه', 'Basic sample'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          IconButton(
            tooltip: t('ذخیره نمودار PNG', 'Save chart PNG'),
            icon: const Icon(Icons.download_outlined),
            onPressed: exporting ? null : export,
          ),
        ],
      ),
      RepaintBoundary(
        key: boundary,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: AppSampleChart(
            type: widget.type,
            option: widget.option,
            translate: widget.translate,
          ),
        ),
      ),
    ],
  );
}
