import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';

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
    this.settingsCheckboxes = false,
  });
  final Future<void> Function(PanelFormResult result)? onSubmit;
  final bool settingsCheckboxes;
  final String title;
  final List<Json> fields;
  final Json data, initial;
  @override
  State<PanelFormPage> createState() => _PanelFormPageState();
}

class _PanelFormPageState extends State<PanelFormPage> {
  final form = GlobalKey<FormState>();
  bool submitting = false;
  late final Json values = {
    ...widget.initial,
    for (final field in widget.fields)
      if (field['initial'] != null && !widget.initial.containsKey(field['key']))
        '${field['key']}': panelValue(widget.initial, '${field['initial']}'),
  };
  final files = <String, PlatformFile>{};
  void change(Json field, dynamic value) {
    setState(() {
      values['${field['key']}'] = value;
      for (final child in widget.fields) {
        if (optionalObject(
          optionalObject(child['options'])['match'],
        ).values.contains(field['key'])) {
          values['${child['key']}'] = child['type'] == 'multi' ? [] : null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => ScrollAwareScaffold(
    appBar: AppTopBarDirection(
      child: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: socialText(context, 'ذخیره', 'Save'),
            icon: const Icon(Icons.save_outlined),
            onPressed: submitting
                ? null
                : () async {
                    for (final field in widget.fields) {
                      if (field['type'] == 'multi' &&
                          values[field['key']] is List) {
                        values[field['key']] = (values[field['key']] as List)
                            .map((item) => item is Map ? item['id'] : item)
                            .where((item) => item != null)
                            .toList();
                      }
                    }
                    if (form.currentState!.validate()) {
                      final result = PanelFormResult(
                        Map.of(values),
                        Map.of(files),
                      );
                      if (widget.onSubmit == null) {
                        Navigator.pop(context, result);
                        return;
                      }
                      setState(() => submitting = true);
                      try {
                        await widget.onSubmit!(result);
                        if (mounted) Navigator.pop(context, result);
                      } catch (e) {
                        if (mounted) socialError(context, e);
                      } finally {
                        if (mounted) setState(() => submitting = false);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
    body: AbsorbPointer(
      absorbing: submitting,
      child: Form(
        key: form,
        child: ListView(
          padding: widget.settingsCheckboxes
              ? EdgeInsets.zero
              : const EdgeInsets.all(16),
          children: [
            if (submitting) const LinearProgressIndicator(),
            for (final field in widget.fields)
              Padding(
                padding: EdgeInsets.only(
                  bottom: widget.settingsCheckboxes ? 0 : 16,
                ),
                child: PanelField(
                  field: {
                    ...field,
                    if (widget.settingsCheckboxes) 'type': 'settingsCheckbox',
                  },
                  value: values['${field['key']}'],
                  data: {...widget.data, '_form': values},
                  changed: (value) => change(field, value),
                  onFile: (file) {
                    files['${field['key']}'] = file;
                    setState(() => values['${field['key']}'] = file.name);
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
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
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final label = Localizations.localeOf(context).languageCode == 'fa'
        ? '${field['label']}'
        : '${field['en'] ?? field['key']}'
              .replaceAll('_', ' ')
              .replaceAllMapped(
                RegExp(r'([a-z])([A-Z])'),
                (m) => '${m[1]} ${m[2]}',
              );
    final type = '${field['type'] ?? 'text'}';
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
    if (type == 'file') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: Text(widget.value == null ? label : '$label: ${widget.value}'),
        onPressed: () async {
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
      final options = <String, String>{};
      if (source is List) {
        for (final item in source.whereType<Map>()) {
          if (item['read_only'] == true || item['writable'] == false) continue;
          if (!optionalObject(
            config['where'],
          ).entries.every((e) => item[e.key] == e.value)) {
            continue;
          }
          if (!optionalObject(config['match']).entries.every((e) {
            final current = panelValue(widget.data['_form'], '${e.value}');
            return current == null || '${item[e.key]}' == '$current';
          })) {
            continue;
          }
          final id = item[config['id'] ?? 'id'] ?? item['value'];
          if (id != null) {
            options['$id'] =
                '${item[config['label']] ?? item['title'] ?? item['label'] ?? panelTitle(optionalObject(item))}';
          }
        }
      }
      if (source == null && config['source'] == null) {
        for (final entry in config.entries) {
          options[entry.key] = '${entry.value}';
        }
      }
      if (type == 'multi') {
        final selected = (widget.value is List ? widget.value as List : [])
            .map((v) => v is Map ? '${v['id']}' : '$v')
            .toSet();
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
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
      return DropdownButtonFormField<String>(
        key: ValueKey('$label:$value:${options.length}'),
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: (v) => field['required'] == true && v == null
            ? socialText(context, 'یک گزینه انتخاب کنید.', 'Select an option.')
            : null,
        onChanged: (v) =>
            widget.changed(v == null ? null : int.tryParse(v) ?? v),
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
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              if (type == 'object')
                for (final child in fields)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: PanelField(
                      field: child,
                      value: optionalObject(widget.value)['${child['key']}'],
                      data: widget.data,
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
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        rows.removeAt(i);
                        widget.changed(rows);
                      },
                    ),
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<PanelFormResult>(
                            MaterialPageRoute(
                              builder: (_) => PanelFormPage(
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
                                initial: type == 'strings'
                                    ? {'value': rows[i]}
                                    : optionalObject(rows[i]),
                              ),
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
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<PanelFormResult>(
                          MaterialPageRoute(
                            builder: (_) => PanelFormPage(
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
                            ),
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
    final date = type == 'date', time = type == 'time';
    return TextFormField(
      controller: text,
      obscureText: type == 'password',
      minLines: type == 'multiline' ? 3 : 1,
      maxLines: type == 'multiline' ? 8 : 1,
      readOnly: date || time,
      keyboardType: type == 'number'
          ? TextInputType.number
          : type == 'email'
          ? TextInputType.emailAddress
          : type == 'phone'
          ? TextInputType.phone
          : TextInputType.text,
      inputFormatters: type == 'number'
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(text.text) ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (selected != null) {
                  value = selected.toIso8601String().substring(0, 10);
                }
              } else {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
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
