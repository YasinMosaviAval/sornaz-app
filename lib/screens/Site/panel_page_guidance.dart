import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'panel_section_card.dart';

String panelGuideKey(String section) =>
    const {
      'members': 'teachers',
      'my-finance': 'finance',
      'my-lessons': 'lessons',
      'my-gallery': 'gallery',
      'my-schedule': 'member-schedules',
      'organization-holidays': 'availability-exceptions',
      'employee-leaves': 'availability-exceptions',
      'term-discounts': 'terms',
    }[section] ??
    section;

/// Reads the same translated database content as the website. Edit permission
/// comes from the authenticated catalog and is independently enforced by PHP.
class PanelPageGuidance extends StatefulWidget {
  const PanelPageGuidance({
    super.key,
    required this.api,
    required this.section,
    this.enabled = true,
    this.canEdit = false,
    this.horizontalInset = 0,
    this.defaults = const {},
  });
  final PanelApi api;
  final String section;
  final bool enabled, canEdit;
  final double horizontalInset;
  final Json defaults;
  @override
  State<PanelPageGuidance> createState() => _PanelPageGuidanceState();
}

class _PanelPageGuidanceState extends State<PanelPageGuidance> {
  Json guide = {};
  bool editable = false, failed = false;
  @override
  void initState() {
    super.initState();
    guide = widget.defaults;
    editable = widget.canEdit;
    load();
  }

  Future<void> load() async {
    if (!widget.enabled) {
      failed = true;
      return;
    }
    try {
      final content = await widget.api.get('/page-guidance/list');
      if (!mounted) return;
      setState(() {
        final saved = optionalObject(content[panelGuideKey(widget.section)]);
        guide = saved.isEmpty ? widget.defaults : saved;
        editable = widget.canEdit;
        failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> edit() async {
    await showDialog<PanelFormResult>(
      context: context,
      builder: (_) => PanelFormPage(
        dialog: true,
        title: socialText(context, 'توضیحات صفحه', 'Page guidance'),
        fields: [
          for (final language in ['fa', 'en'])
            {
              'key': language,
              'label': language == 'fa' ? 'فارسی' : 'English',
              'type': 'object',
              'options': [
                {'key': 'title', 'label': 'عنوان', 'en': 'Title'},
                {
                  'key': 'body',
                  'label': 'توضیحات',
                  'en': 'Description',
                  'type': 'multiline',
                },
              ],
            },
        ],
        data: const {},
        initial: {
          for (final language in ['fa', 'en'])
            language: {
              for (final field in ['title', 'body'])
                field: optionalObject(guide[field])[language] ?? '',
            },
        },
        onSubmit: (result) async {
          await widget.api.act(
            'page-guidance',
            'save',
            values: {
              ...result.values,
              'page': 'panel-${panelGuideKey(widget.section)}',
            },
          );
        },
      ),
    );
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    String text(String key) {
      final translations = optionalObject(guide[key]);
      final language = Localizations.localeOf(context).languageCode;
      for (final code in [language, 'fa', 'en']) {
        final value = '${translations[code] ?? ''}';
        if (value.trim().isNotEmpty) return value;
      }
      return '';
    }

    if (guide.isEmpty && !editable && !failed) return const SizedBox.shrink();
    return PanelSectionCard(
      horizontalInset: widget.horizontalInset,
      storageId: 'guidance-${widget.section}',
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
      icon: Icons.description_outlined,
      title: text('title').isEmpty
          ? socialText(context, 'توضیحات صفحه', 'Page guidance')
          : text('title'),
      children: [
        if (failed)
          TextButton.icon(
            onPressed: widget.enabled ? load : null,
            icon: const Icon(Icons.sync_problem_outlined),
            label: Text(
              socialText(
                context,
                widget.enabled
                    ? 'دریافت توضیحات صفحه؛ تلاش دوباره'
                    : 'برای توضیحات به‌روز و ویرایش آن، API وب باید به‌روز شود.',
                widget.enabled
                    ? 'Retry page guidance'
                    : 'Update the web API to load and edit current guidance.',
              ),
            ),
          ),
        if (editable)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: edit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                socialText(
                  context,
                  guide.isEmpty ? 'افزودن توضیحات صفحه' : 'ویرایش توضیحات صفحه',
                  guide.isEmpty ? 'Add page guidance' : 'Edit page guidance',
                ),
              ),
            ),
          ),
        if (text('title').isNotEmpty || text('body').isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(text('body')),
            ),
          ),
      ],
    );
  }
}
