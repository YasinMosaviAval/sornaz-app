import 'package:sornaz/components/jalali_date_picker.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'panel_ui.dart';
import 'panel_caption.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sornaz/helpers/app_typography.dart';

import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form_contract.dart';
import 'branch_color_picker.dart';
export 'panel_form_contract.dart' show panelFieldVisible;
import '../Social/member_grid.dart';
import '../Social/media_picker.dart';
import 'package:provider/provider.dart';
import '../Authentication/providers/auth_session.dart';

class PanelFormResult {
  PanelFormResult(this.values, this.files);
  final Json values;
  final Map<String, PlatformFile> files;
}

class PanelFormPage extends StatefulWidget {
  const PanelFormPage({
    super.key,
    required this.title,
    required this.fields,
    required this.data,
    this.initial = const {},
    this.onSubmit,
    this.onRequestCode,
    this.loadBatchTimes,
    this.lookupMemberUser,
    this.previewStudentSchedule,
    this.loadOptions,
    this.settingsCheckboxes = false,
    this.dialog = false,
    this.declaredOnly = false,
    this.submitButtons = const [],
    this.suggestedTitle,
    this.bottomSubmitLabel,
  });
  final Future<void> Function(PanelFormResult result)? onSubmit;
  final Future<void> Function(PanelFormResult result)? onRequestCode;
  final Future<Json> Function(Json values)? loadBatchTimes;
  final Future<Json> Function(Json values, String query)? lookupMemberUser;
  final Future<Json> Function(Json values)? previewStudentSchedule;
  final Future<Json> Function()? loadOptions;
  final bool settingsCheckboxes, dialog;
  final bool declaredOnly;
  final List<Json> submitButtons;
  final String title;
  final String? bottomSubmitLabel;
  final String Function(Json values)? suggestedTitle;
  final List<Json> fields;
  final Json data, initial;
  @override
  State<PanelFormPage> createState() => _PanelFormPageState();
}

class _PanelFormPageState extends State<PanelFormPage> {
  Json? existingUser;
  bool lookupBusy = false, previewBusy = false;
  String userQuery = '';
  List<Json> foundUsers = [];
  List<String> scheduleIssues = [];
  List<Json> get effectiveFields => [
    for (final field in widget.fields)
      if (existingUser != null &&
          (optionalObject(existingUser!['fields'])[field['key']] == true ||
              ['registration', 'profileVisibility'].contains(field['key'])))
        {
          ...field,
          'required': false,
          'visibleWhen': {'_form._neverShowSavedIdentity': true},
        }
      else if (existingUser != null &&
          '${field['key']}'.startsWith('parent') &&
          optionalObject(existingUser!['fields'])['birthDate'] == true)
        {
          ...field,
          'visibleWhen': {'_form._existingUnder18': true},
        }
      else
        field,
  ];

  Future<void> lookupUser() async {
    if (lookupBusy || widget.lookupMemberUser == null) return;
    setState(() => lookupBusy = true);
    final organization = values['organizationUserId'];
    try {
      final result = await widget.lookupMemberUser!(
        Map.of(values),
        userQuery.trim(),
      );
      if (mounted && organization == values['organizationUserId'])
        setState(() => foundUsers = objects(result['users'] ?? []));
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => lookupBusy = false);
    }
  }

  Future<void> previewSchedule() async {
    if (previewBusy || widget.previewStudentSchedule == null) return;
    setState(() => previewBusy = true);
    final before = jsonEncode([values['termId'], values['studentSchedule']]);
    try {
      final response = await widget.previewStudentSchedule!(Map.of(values));
      if (mounted &&
          before == jsonEncode([values['termId'], values['studentSchedule']]))
        setState(() {
          scheduleIssues = [
            for (final session in objects(response['sessions'] ?? []))
              if ('${session['error'] ?? ''}'.isNotEmpty)
                '${session['date']}: ${session['error']}',
          ];
          values['studentSchedule'] = {
            ...optionalObject(values['studentSchedule']),
            'dates': [
              for (final session in objects(response['sessions'] ?? []))
                session['date'],
            ],
          };
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => previewBusy = false);
    }
  }

  late final Json liveData = Map.of(widget.data);
  Timer? optionsTimer;
  bool optionsLoading = false;
  final form = GlobalKey<FormState>();
  bool submitting = false, handedOff = false;
  String? validationError;
  late final Json values = panelInitialValues(
    effectiveFields,
    widget.initial,
    liveData,
  );
  final files = <String, PlatformFile>{};
  List<String> batchTimes = [];
  bool batchTimesLoading = false, batchTimesFailed = false;
  int batchTimesSequence = 0;
  @override
  void initState() {
    super.initState();
    if (widget.suggestedTitle != null && '${values['title'] ?? ''}'.isEmpty) {
      values['title'] = widget.suggestedTitle!(values);
    }
    if (widget.loadBatchTimes != null)
      WidgetsBinding.instance.addPostFrameCallback((_) => refreshBatchTimes());
    if (widget.loadOptions != null) {
      optionsTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => refreshOptions(),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(refreshOptions()),
      );
    }
  }

  Future<void> refreshOptions() async {
    if (!mounted ||
        submitting ||
        optionsLoading ||
        widget.loadOptions == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        ModalRoute.of(context)?.isCurrent == false)
      return;
    optionsLoading = true;
    try {
      final latest = await widget.loadOptions!();
      if (!mounted) return;
      setState(() {
        liveData.addAll(latest);
        // Keep user input; clear only a selection whose organization was removed.
        for (final field in effectiveFields) {
          if (field['type'] != 'select' ||
              !RegExp(
                r'organization|branch|academy',
                caseSensitive: false,
              ).hasMatch('${field['key']}'))
            continue;
          final available = panelSelectOptions(
            field,
            panelFormContext(effectiveFields, values, liveData),
          );
          final current = '${values[field['key']] ?? ''}';
          if (current.isNotEmpty && !available.containsKey(current))
            values[field['key']] = null;
        }
      });
    } catch (_) {
      // Keep the form and entered values when the network is unavailable.
    } finally {
      optionsLoading = false;
    }
  }

  Future<void> refreshBatchTimes() async {
    if (!mounted || widget.loadBatchTimes == null) return;
    final sequence = ++batchTimesSequence;
    setState(() {
      batchTimesLoading = true;
      batchTimesFailed = false;
    });
    try {
      final result = await widget.loadBatchTimes!(Map.of(values));
      if (!mounted || sequence != batchTimesSequence) return;
      setState(() {
        batchTimes = (result['times'] as List? ?? [])
            .map((time) => '$time')
            .toList();
        if ((num.tryParse('${result['timezoneId']}') ?? 0) > 0)
          values['timezoneId'] = result['timezoneId'];
        for (final key in ['rangeStart', 'rangeEnd']) {
          if (!batchRangeOptions(key).containsKey('${values[key]}'))
            values[key] = null;
        }
      });
    } catch (_) {
      if (mounted && sequence == batchTimesSequence)
        setState(() {
          batchTimes = [];
          batchTimesFailed = true;
        });
    } finally {
      if (mounted && sequence == batchTimesSequence)
        setState(() => batchTimesLoading = false);
    }
  }

  Map<String, String> batchRangeOptions(String key) {
    final options = <String, String>{};
    for (final time in batchTimes) {
      var value = time;
      if (key == 'rangeEnd') {
        final parts = time.split(':');
        final minute = int.parse(parts[0]) * 60 + int.parse(parts[1]) + 5;
        value =
            '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
      }
      options[value] = value;
    }
    return options;
  }

  @override
  void dispose() {
    optionsTimer?.cancel();
    if (!handedOff)
      for (final file in files.values) {
        unawaited(releasePickedMedia(file));
      }
    super.dispose();
  }

  void change(Json field, dynamic value) {
    setState(() {
      if (field['key'] == 'organizationUserId') {
        existingUser = null;
        foundUsers = [];
        values.remove('_existingUnder18');
      }
      if (field['key'] == 'termId') values.remove('studentSchedule');
      if (field['key'] == 'studentSchedule') {
        final previous = optionalObject(values['studentSchedule']);
        final next = optionalObject(value);
        if (previous['firstDate'] != next['firstDate'] ||
            previous['classroomId'] != next['classroomId']) {
          value = {...next}..remove('dates');
          scheduleIssues = [];
        }
      }
      final previousSuggestion = widget.suggestedTitle?.call(values);
      final updateTitle =
          previousSuggestion != null &&
          ('${values['title'] ?? ''}'.isEmpty ||
              values['title'] == previousSuggestion);
      values['${field['key']}'] = value;
      for (final child in effectiveFields) {
        if (optionalObject(
          optionalObject(child['options'])['match'],
        ).values.contains(field['key'])) {
          values['${child['key']}'] = child['type'] == 'multi' ? [] : null;
        }
        if ((child['dependsOn'] as List? ?? []).contains(field['key']) &&
            !(child['key'] == 'teachers' && field['key'] == 'classroomId')) {
          values['${child['key']}'] = child['type'] == 'multi' ? [] : null;
        }
      }
      final updated = panelInitialValues(
        effectiveFields,
        values,
        liveData,
        applyAliases: false,
        applyDefaults: false,
      );
      values.addAll(updated);
      if (updateTitle && field['key'] != 'title') {
        values['title'] = widget.suggestedTitle!(values);
      }
      if (field['key'] == 'classroomId' && values['teachers'] is List) {
        final teacher = effectiveFields
            .where((field) => field['key'] == 'teachers')
            .firstOrNull;
        if (teacher != null) {
          final allowed = panelSelectOptions(
            teacher,
            panelFormContext(effectiveFields, values, liveData),
          );
          values['teachers'] = (values['teachers'] as List)
              .where(
                (item) =>
                    allowed.containsKey('${item is Map ? item['id'] : item}'),
              )
              .toList();
        }
      }
    });
    if (widget.loadBatchTimes != null &&
        ['organizationUserId', 'classroomId', 'weekday'].contains(field['key']))
      unawaited(refreshBatchTimes());
  }

  Future<void> submit({
    Json overrides = const {},
    bool requestCode = false,
  }) async {
    if (submitting) return;
    if (!requestCode && scheduleIssues.isNotEmpty) {
      setState(
        () => validationError = socialText(
          context,
          'تداخل جلسه‌ها را اصلاح و دوباره تاریخ‌ها را بررسی کنید.',
          'Resolve session conflicts and preview the dates again.',
        ),
      );
      return;
    }
    if (widget.loadBatchTimes != null &&
        (batchTimesLoading || batchTimesFailed || batchTimes.isEmpty))
      return;
    if (widget.loadBatchTimes != null && panelBatchTermCount(values) == null) {
      setState(
        () => validationError = socialText(
          context,
          'بازه باید به جلسه‌های کامل تقسیم شود.',
          'The range must contain whole sessions.',
        ),
      );
      return;
    }
    if (widget.declaredOnly) {
      final invalid = panelInvalidField(effectiveFields, values, liveData);
      if (invalid != null) {
        final field = effectiveFields
            .where((field) => field['key'] == invalid)
            .first;
        setState(
          () => validationError =
              '${Localizations.localeOf(context).languageCode == 'fa' ? field['label'] : field['en'] ?? invalid}: ${socialText(context, 'اطلاعات این فیلد را بررسی کنید.', 'Check this field.')}',
        );
        form.currentState!.validate();
        return;
      }
    }
    setState(() => validationError = null);
    for (final field in effectiveFields) {
      if (field['type'] == 'multi' && values[field['key']] is List) {
        values[field['key']] = (values[field['key']] as List)
            .map((item) => item is Map ? item['id'] : item)
            .where((item) => item != null)
            .toList();
      }
    }
    if (form.currentState!.validate()) {
      final result = PanelFormResult({
        ...(widget.declaredOnly
            ? panelSubmittedValues(effectiveFields, values, liveData)
            : Map.of(values)),
        ...overrides,
      }, Map.of(files));
      if (existingUser != null)
        result.values['existingUserToken'] = existingUser!['token'];
      final schedule = optionalObject(values['studentSchedule']);
      if (schedule['dates'] is List)
        result.values['studentSchedule'] = schedule;
      if (widget.onSubmit == null) {
        handedOff = true;
        Navigator.pop(context, result);
        return;
      }
      setState(() => submitting = true);
      try {
        if (requestCode) {
          await widget.onRequestCode!(result);
          return;
        }
        await widget.onSubmit!(result);
        if (mounted) {
          handedOff = true;
          Navigator.pop(context, result);
        }
      } catch (e) {
        if (mounted) socialError(context, e);
      } finally {
        if (mounted) setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = AbsorbPointer(
      absorbing: submitting,
      child: Form(
        key: form,
        child: ListView(
          shrinkWrap: widget.dialog,
          physics: widget.dialog ? const NeverScrollableScrollPhysics() : null,
          padding: widget.settingsCheckboxes
              ? EdgeInsets.zero
              : const EdgeInsets.all(16),
          children: [
            if (widget.lookupMemberUser != null) ...[
              TextField(
                decoration: InputDecoration(
                  labelText: socialText(
                    context,
                    'نام کاربری یا شماره موبایل کامل',
                    'Exact username or mobile number',
                  ),
                ),
                onChanged: (value) => userQuery = value,
              ),
              TextButton(
                onPressed: lookupBusy ? null : lookupUser,
                child: Text(
                  socialText(
                    context,
                    'جستجوی کاربر موجود',
                    'Find existing user',
                  ),
                ),
              ),
              for (final user in foundUsers)
                ListTile(
                  title: Text('${user['name'] ?? user['username']}'),
                  onTap: () => setState(() {
                    existingUser = user;
                    values['_existingUnder18'] = user['under18'] == true;
                    foundUsers = [];
                  }),
                ),
              if (existingUser != null)
                ListTile(
                  title: Text(
                    '${existingUser!['name'] ?? existingUser!['username']}',
                  ),
                  subtitle: Text(
                    socialText(
                      context,
                      'اطلاعات ثبت‌شده از حساب انتخابی استفاده می‌شود.',
                      'Saved information from the selected account will be used.',
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      existingUser = null;
                      values.remove('_existingUnder18');
                    }),
                  ),
                ),
            ],
            if (widget.previewStudentSchedule != null &&
                effectiveFields.any(
                  (field) =>
                      field['key'] == 'studentSchedule' &&
                      panelFieldVisible(
                        field,
                        panelFormContext(effectiveFields, values, liveData),
                      ),
                )) ...[
              for (final issue in scheduleIssues)
                Text(
                  issue,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              TextButton(
                onPressed: previewBusy ? null : previewSchedule,
                child: Text(
                  socialText(
                    context,
                    'بررسی تاریخ جلسات',
                    'Preview session dates',
                  ),
                ),
              ),
              for (final entry
                  in (optionalObject(values['studentSchedule'])['dates']
                              as List? ??
                          [])
                      .indexed)
                PanelField(
                  key: ValueKey('preview-session-${entry.$1}'),
                  field: {
                    'key': 'sessionDate${entry.$1}',
                    'label': 'تاریخ جلسه ${entry.$1 + 1}',
                    'en': 'Session ${entry.$1 + 1} date',
                    'type': 'date',
                  },
                  value: entry.$2,
                  data: liveData,
                  changed: (value) => setState(() {
                    final schedule = optionalObject(values['studentSchedule']);
                    final dates = List<dynamic>.of(schedule['dates'] as List);
                    dates[entry.$1] = value;
                    values['studentSchedule'] = {...schedule, 'dates': dates};
                  }),
                  onFile: (_) {},
                ),
            ],
            if (widget.loadBatchTimes != null) ...[
              if (batchTimesLoading) const LinearProgressIndicator(),
              if (!batchTimesLoading && !batchTimesFailed && batchTimes.isEmpty)
                Text(
                  socialText(
                    context,
                    'سازمان و روز هفته را انتخاب کنید؛ بازه‌ها از ساعت‌های مجاز همان روز دریافت می‌شوند.',
                    'Select an organization and weekday to load its available hours.',
                  ),
                ),
              if (batchTimesFailed)
                TextButton(
                  onPressed: refreshBatchTimes,
                  child: Text(
                    socialText(
                      context,
                      'دریافت دوباره ساعت‌های مجاز',
                      'Retry available times',
                    ),
                  ),
                ),
              if (panelBatchTermCount(values) case final count?)
                Text(
                  socialText(
                    context,
                    '$count ترم مستقل ایجاد می‌شود.',
                    '$count separate terms will be created.',
                  ),
                )
              else
                Text(
                  socialText(
                    context,
                    'بازه و مدت جلسه را مشخص کنید.',
                    'Select a range and session duration.',
                  ),
                ),
            ],
            if (submitting) const LinearProgressIndicator(),
            if (validationError != null)
              Text(
                validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            for (final field in effectiveFields.where(
              (field) => panelFieldVisible(
                field,
                panelFormContext(effectiveFields, values, liveData),
              ),
            ))
              Padding(
                padding: EdgeInsets.only(
                  bottom: widget.settingsCheckboxes ? 0 : 16,
                ),
                child: PanelField(
                  key: ValueKey(field['key']),
                  field: {
                    ...field,
                    if (widget.loadBatchTimes != null &&
                        ['rangeStart', 'rangeEnd'].contains(field['key'])) ...{
                      'type': 'select',
                      'options': batchRangeOptions('${field['key']}'),
                    },
                    'required': panelFieldRequired(
                      field,
                      panelFormContext(effectiveFields, values, liveData),
                    ),
                    if (widget.settingsCheckboxes) 'type': 'settingsCheckbox',
                  },
                  value: values['${field['key']}'],
                  data: panelFormContext(effectiveFields, values, liveData),
                  changed: (value) => change(field, value),
                  onFile: (file) {
                    final previous = files['${field['key']}'];
                    if (previous != null)
                      unawaited(releasePickedMedia(previous));
                    files['${field['key']}'] = file;
                    setState(() => values['${field['key']}'] = file.name);
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.dialog)
      return PanelModal(
        title: widget.title,
        busy: submitting,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 12),
            if (widget.onRequestCode != null &&
                existingUser == null &&
                (values['type'] == null ||
                    ['manager', 'receptionist'].contains(values['type'])))
              OutlinedButton(
                onPressed: submitting ? null : () => submit(requestCode: true),
                child: Text(
                  socialText(
                    context,
                    'ارسال کد تأیید',
                    'Send verification code',
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    onPressed: submitting ? null : () => Navigator.pop(context),
                    child: Text(socialText(context, 'انصراف', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: submitting
                        ? null
                        : () => submit(
                            overrides: widget.submitButtons.isEmpty
                                ? {}
                                : optionalObject(
                                    widget.submitButtons.first['values'],
                                  ),
                          ),
                    child: Text(
                      widget.submitButtons.isEmpty
                          ? socialText(context, 'ذخیره تغییرات', 'Save changes')
                          : socialText(
                              context,
                              '${widget.submitButtons.first['label']}',
                              '${widget.submitButtons.first['en'] ?? widget.submitButtons.first['label']}',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            for (final button in widget.submitButtons.skip(1))
              TextButton(
                onPressed: submitting
                    ? null
                    : () => submit(overrides: optionalObject(button['values'])),
                child: Text(
                  socialText(
                    context,
                    '${button['label']}',
                    '${button['en'] ?? button['label']}',
                  ),
                ),
              ),
          ],
        ),
      );
    return PanelScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(widget.title),
          actions: [
            if (widget.bottomSubmitLabel == null)
              IconButton(
                tooltip: socialText(context, 'ذخیره', 'Save'),
                onPressed: submitting ? null : submit,
                icon: const Icon(Icons.save_outlined),
              ),
          ],
        ),
      ),
      body: widget.bottomSubmitLabel == null
          ? content
          : Column(
              children: [
                Expanded(child: content),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: appRadius(context),
                          ),
                        ),
                        onPressed: submitting ? null : submit,
                        child: Text(widget.bottomSubmitLabel!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class PanelField extends StatefulWidget {
  const PanelField({
    super.key,
    required this.field,
    this.value,
    required this.data,
    required this.changed,
    this.onFile,
  });
  final Json field, data;
  final dynamic value;
  final ValueChanged<dynamic> changed;
  final ValueChanged<PlatformFile>? onFile;
  @override
  State<PanelField> createState() => _PanelFieldState();
}

class _PanelFieldState extends State<PanelField> {
  late final text = TextEditingController(
    text: widget.value == null ? '' : '${widget.value}',
  );
  @override
  void didUpdateWidget(covariant PanelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        text.text != '${widget.value ?? ''}') {
      // A dependent field can change while the form is rebuilding. Notify its
      // TextFormField after that frame so FormState is not dirtied during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && text.text != '${widget.value ?? ''}') {
          text.text = '${widget.value ?? ''}';
        }
      });
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final label = panelCaption(context, field);
    final type = '${field['type'] ?? 'text'}';
    if (field['filter'] == true && type != 'select') {
      return PanelValueRow(
        title: label,
        value: widget.value == null || '${widget.value}'.isEmpty
            ? socialText(context, 'همه', 'All')
            : '${widget.value}',
        onTap: () async {
          final result = await showDialog<PanelFormResult>(
            context: context,
            builder: (_) => PanelFormPage(
              dialog: true,
              title: label,
              fields: [
                {...field, 'filter': false, 'required': false},
              ],
              data: widget.data,
              initial: {'${field['key']}': widget.value},
            ),
          );
          if (result != null && mounted)
            widget.changed(result.values['${field['key']}']);
        },
      );
    }
    if (type == 'settingsCheckbox') {
      return CheckboxListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 24, end: 16),
        visualDensity: VisualDensity.compact,
        title: Text(label, style: AppTypography.settingsItemTitle(context)),
        value: widget.value == true || widget.value == 1 || widget.value == '1',
        onChanged: (value) => widget.changed(value ?? false),
      );
    }
    if (type == 'bool') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: widget.value == true || widget.value == 1 || widget.value == '1',
        onChanged: widget.changed,
      );
    }
    if (type == 'color') {
      final hex = '${widget.value ?? '#4f46e5'}'.replaceFirst('#', '');
      return BranchColorPicker(
        key: ValueKey(hex),
        label: label,
        value: RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex) ? hex : '4f46e5',
        onChanged: (value) => widget.changed('#$value'),
      );
    }
    if (type == 'strings') {
      final value = (widget.value is List ? widget.value as List : [])
          .map((item) => item is Map ? '${item['label'] ?? ''}' : '$item')
          .join('\n');
      return TextFormField(
        key: ValueKey('${field['key']}:strings'),
        initialValue: value,
        minLines: 3,
        maxLines: 8,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: appRadius(context)),
        ),
        onChanged: (value) => widget.changed(
          value
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList(),
        ),
      );
    }
    if (type == 'file') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: Text(widget.value == null ? label : '$label: ${widget.value}'),
        onPressed: () async {
          if (field['mediaPicker'] == true) {
            final file = await pickGalleryMedia(
              context,
              imagesOnly: field['imagesOnly'] == true,
              crop: true,
            );
            if (file != null && mounted) widget.onFile?.call(file);
            return;
          }
          final result = await FilePicker.platform.pickFiles(withData: true);
          if (result != null && mounted) {
            widget.onFile?.call(result.files.single);
          }
        },
      );
    }
    if (type == 'select' || type == 'multi') {
      final config = optionalObject(field['options']);
      final dynamic source = config['source'] == null
          ? null
          : panelValue(widget.data, '${config['source']}');
      final options = panelSelectOptions(field, widget.data);
      if (type == 'multi') {
        final selected = (widget.value is List ? widget.value as List : [])
            .map((v) => v is Map ? '${v['id']}' : '$v')
            .toSet();
        if (field['key'] == 'userIds' && source is List) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 12),
              MemberGrid(
                users: objects(
                  source,
                ).where((u) => options.containsKey('${u['id']}')).toList(),
                selected: selected,
                token: context.read<AuthSession?>()?.token ?? '',
                shrinkWrap: true,
                onToggle: (id) {
                  if (!selected.remove(id)) selected.add(id);
                  widget.changed(
                    selected.map((v) => int.tryParse(v) ?? v).toList(),
                  );
                },
              ),
            ],
          );
        }
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: appRadius(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in options.entries)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  value: selected.contains(entry.key),
                  onChanged: (checked) {
                    checked == true
                        ? selected.add(entry.key)
                        : selected.remove(entry.key);
                    widget.changed(
                      selected.map((v) => int.tryParse(v) ?? v).toList(),
                    );
                  },
                ),
              if (options.isEmpty)
                Text(
                  socialText(
                    context,
                    'گزینه‌ای موجود نیست.',
                    'No options available.',
                  ),
                ),
            ],
          ),
        );
      }
      final value = widget.value == null ? '' : '${widget.value}';
      if (field['filter'] == true) {
        return PanelValueRow(
          title: label,
          value: options[value] ?? socialText(context, 'همه', 'All'),
          onTap: () async {
            final picked = await showDialog<String>(
              context: context,
              builder: (c) => PanelModal(
                title: label,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in {
                      '': socialText(context, 'همه', 'All'),
                      ...options,
                    }.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          entry.value,
                          style: Theme.of(c).textTheme.bodyMedium,
                        ),
                        trailing: value == entry.key
                            ? const Icon(Icons.check, size: 18)
                            : null,
                        onTap: () => Navigator.pop(c, entry.key),
                      ),
                  ],
                ),
              ),
            );
            if (picked != null && mounted)
              widget.changed(
                picked.isEmpty ? null : int.tryParse(picked) ?? picked,
              );
          },
        );
      }
      return DropdownButtonFormField<String>(
        key: ValueKey('$label:$value:${options.length}'),
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: appRadius(context)),
        ),
        items: [
          if (field['required'] != true)
            DropdownMenuItem(
              value: '',
              child: Text(socialText(context, 'بدون انتخاب', 'None')),
            ),
          for (final entry in options.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: (v) => field['required'] == true && (v == null || v.isEmpty)
            ? socialText(context, 'یک گزینه انتخاب کنید.', 'Select an option.')
            : null,
        onChanged: field['readOnly'] == true
            ? null
            : (v) => widget.changed(v == null ? null : int.tryParse(v) ?? v),
      );
    }
    if (type == 'rows' || type == 'object' || type == 'strings') {
      final rows = widget.value is List
          ? List<dynamic>.from(widget.value)
          : <dynamic>[];
      final fields = field['options'] is List
          ? objects(field['options'])
          : <Json>[];
      return Card(
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              if (type == 'object')
                for (final child in fields.where(
                  (child) => panelFieldVisible(
                    child,
                    panelFormContext(
                      fields,
                      optionalObject(widget.value),
                      widget.data,
                    ),
                  ),
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: PanelField(
                      key: ValueKey(child['key']),
                      field: {
                        ...child,
                        'required': panelFieldRequired(
                          child,
                          panelFormContext(
                            fields,
                            optionalObject(widget.value),
                            widget.data,
                          ),
                        ),
                      },
                      value: optionalObject(widget.value)['${child['key']}'],
                      data: panelFormContext(
                        fields,
                        optionalObject(widget.value),
                        widget.data,
                      ),
                      changed: (v) => widget.changed({
                        ...optionalObject(widget.value),
                        '${child['key']}': v,
                      }),
                    ),
                  ),
              if (type != 'object') ...[
                for (var i = 0; i < rows.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      rows[i] is Map
                          ? panelTitle(optionalObject(rows[i]))
                          : '${rows[i]}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        rows.removeAt(i);
                        widget.changed(rows);
                      },
                    ),
                    onTap: () async {
                      final result = await showDialog<PanelFormResult>(
                        context: context,
                        builder: (_) => PanelFormPage(
                          dialog: true,
                          title: label,
                          fields: type == 'strings'
                              ? [
                                  {
                                    'key': 'value',
                                    'label': label,
                                    'type': 'text',
                                  },
                                ]
                              : fields,
                          data: widget.data,
                          declaredOnly: true,
                          initial: type == 'strings'
                              ? {'value': rows[i]}
                              : optionalObject(rows[i]),
                        ),
                      );
                      if (result != null && mounted) {
                        rows[i] = type == 'strings'
                            ? result.values['value']
                            : result.values;
                        widget.changed(rows);
                      }
                    },
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(socialText(context, 'افزودن', 'Add')),
                  onPressed:
                      field['maxItems'] is int &&
                          rows.length >= field['maxItems']
                      ? null
                      : () async {
                          final result = await showDialog<PanelFormResult>(
                            context: context,
                            builder: (_) => PanelFormPage(
                              dialog: true,
                              title: label,
                              fields: type == 'strings'
                                  ? [
                                      {
                                        'key': 'value',
                                        'label': label,
                                        'type': 'text',
                                      },
                                    ]
                                  : fields,
                              data: widget.data,
                              declaredOnly: true,
                            ),
                          );
                          if (result != null && mounted) {
                            rows.add(
                              type == 'strings'
                                  ? result.values['value']
                                  : result.values,
                            );
                            widget.changed(rows);
                          }
                        },
                ),
              ],
            ],
          ),
        ),
      );
    }
    final date = type == 'date' || type == 'datetime', time = type == 'time';
    return TextFormField(
      controller: text,
      obscureText: type == 'password',
      maxLength: field['maxLength'] as int?,
      minLines: type == 'multiline' ? 3 : 1,
      maxLines: type == 'multiline' ? 8 : 1,
      readOnly: date || time || field['readOnly'] == true,
      enabled: field['readOnly'] != true,
      keyboardType: type == 'number'
          ? TextInputType.number
          : type == 'email'
          ? TextInputType.emailAddress
          : type == 'phone'
          ? TextInputType.phone
          : TextInputType.text,
      inputFormatters: type == 'number'
          ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: appRadius(context)),
        suffixIcon: date || time
            ? Icon(date ? Icons.calendar_today_outlined : Icons.schedule)
            : null,
      ),
      validator: (v) => field['required'] == true && (v ?? '').trim().isEmpty
          ? socialText(
              context,
              'این فیلد الزامی است.',
              'This field is required.',
            )
          : null,
      onChanged: (v) => widget.changed(type == 'number' ? num.tryParse(v) : v),
      onTap: date || time
          ? () async {
              String? value;
              if (date) {
                final selected = await showSornazDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(text.text) ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (selected != null) {
                  value = selected.toIso8601String().substring(0, 10);
                  if (type == 'datetime' && context.mounted) {
                    final initial = DateTime.tryParse(text.text);
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: initial == null
                          ? TimeOfDay.now()
                          : TimeOfDay.fromDateTime(initial),
                    );
                    if (selectedTime == null) return;
                    value =
                        '${value}T${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  }
                }
              } else {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: RegExp(r'^\d{2}:\d{2}').hasMatch(text.text)
                      ? TimeOfDay(
                          hour: int.parse(
                            text.text.substring(0, 2),
                          ).clamp(0, 23),
                          minute: int.parse(
                            text.text.substring(3, 5),
                          ).clamp(0, 59),
                        )
                      : TimeOfDay.now(),
                );
                if (selected != null) {
                  value =
                      '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                }
              }
              if (value != null && mounted) {
                text.text = value;
                widget.changed(value);
              }
            }
          : null,
    );
  }
}
