import '../Social/social_api.dart';
import 'panel_api.dart';

List<Json> _rows(dynamic value) => value is List
    ? value.whereType<Map>().map(optionalObject).toList()
    : <Json>[];

Json panelFormContext(List<Json> fields, Json values, Json data) => {
  ...data,
  '_form': values,
  '_root': data['_root'] ?? values,
  '_selected': {
    for (final field in fields)
      if (optionalObject(field['options'])['source'] is String)
        '${field['key']}': _rows(panelValue(data, '${field['options']['source']}'))
            .where(
              (item) =>
                  '${item[field['options']['id'] ?? 'id'] ?? item['value']}' ==
                  '${values[field['key']]}',
            )
            .firstOrNull,
  },
};

bool panelConditionsMatch(dynamic conditions, Json data) =>
    optionalObject(conditions).entries.every((entry) {
      final value = panelValue(data, entry.key);
      final rule = entry.value;
      if (rule is! Map) return '$value' == '$rule';
      if (rule.containsKey('in')) {
        return (rule['in'] as List).any((item) => '$item' == '$value');
      }
      if (rule.containsKey('not')) return '$value' != '${rule['not']}';
      if (rule.containsKey('underAge')) {
        final birth = DateTime.tryParse('$value');
        if (birth == null) return false;
        final now = DateTime.now();
        final birthday = DateTime(
          birth.year + (rule['underAge'] as num).toInt(),
          birth.month,
          birth.day,
        );
        return birth.isBefore(now) && birthday.isAfter(now);
      }
      return false;
    });

bool panelFieldVisible(Json field, Json data) =>
    panelConditionsMatch(field['visibleWhen'], data) &&
    !(field['hiddenWhen'] is Map &&
        panelConditionsMatch(field['hiddenWhen'], data));

bool panelFieldRequired(Json field, Json data) =>
    field['required'] == true ||
    field['requiredWhen'] is Map &&
        panelConditionsMatch(field['requiredWhen'], data);

Map<String, String> panelSelectOptions(Json field, Json data) {
  final config = optionalObject(field['options']);
  if (config['sources'] is List) {
    return {
      for (final source in _rows(config['sources']))
        ...panelSelectOptions({...field, 'options': source}, data),
    };
  }
  final source = config['source'] == null
      ? null
      : panelValue(data, '${config['source']}');
  final options = <String, String>{};
  final excluded = panelValue(data, '${config['excludeSource'] ?? ''}');
  final excludedIds = excluded is List
      ? excluded.map((id) => '$id').toSet()
      : excluded == null
      ? <String>{}
      : {'$excluded'};
  final allowedConfig = optionalObject(config['allowedIdsFrom']);
  Set<String>? allowed;
  if (allowedConfig.isNotEmpty) {
    allowed = {
      for (final item in _rows(panelValue(data, '${allowedConfig['source']}')))
        if (optionalObject(allowedConfig['match']).entries.every(
          (e) =>
              '${item[e.key]}' == '${panelValue(data['_form'], '${e.value}')}',
        ))
          for (final id in item[allowedConfig['field']] as List? ?? []) '$id',
    };
  }
  for (final raw in source is List ? source : const []) {
    if (raw is! Map) {
      options['$raw'] = '$raw';
      continue;
    }
    final item = optionalObject(raw);
    if (config['termRooms'] == true) {
      final selected = _rows(data['organizations'])
          .where(
            (o) =>
                '${o['user_id']}' ==
                '${optionalObject(data['_form'])['organizationUserId']}',
          )
          .firstOrNull;
      if (selected == null ||
          (selected['kind'] == 'branch'
              ? '${item['branchId']}' != '${selected['id']}'
              : '${item['academyId']}' != '${selected['id']}'))
        continue;
    }
    if (config['termPeople'] == true) {
      final room = optionalObject(panelValue(data, '_selected.classroomId'));
      final course = optionalObject(panelValue(data, '_selected.courseId'));
      final branch = room['branchId'] ?? 0;
      if ('${item['branchId'] ?? 0}' != '$branch' ||
          '$branch' == '0' &&
              '${item['academyId']}' != '${course['organizationId']}')
        continue;
    }
    if (config['includeReadOnly'] != true &&
        (item['read_only'] == true ||
            item['writable'] == false ||
            item['selectable'] == false))
      continue;
    if (!optionalObject(
      config['where'],
    ).entries.every((e) => '${item[e.key]}' == '${e.value}'))
      continue;
    if (!optionalObject(config['match']).entries.every((e) {
      final current = '${e.value}'.startsWith('_')
          ? panelValue(data, '${e.value}')
          : panelValue(data['_form'], '${e.value}');
      return current == null || '$current'.isEmpty
          ? config['requireMatch'] != true
          : '${item[e.key]}' == '$current';
    }))
      continue;
    if (config['staffRoles'] == true) {
      final form = optionalObject(data['_form']);
      final organizations = _rows(
        panelValue(data, 'staff_catalog.organizations'),
      );
      final organization = organizations
          .where((o) => '${o['user_id']}' == '${form['organizationUserId']}')
          .firstOrNull;
      final branch =
          organization?['branch_id'] != null &&
          '${organization?['branch_id']}' != '0';
      final name = '${item['name']}';
      if (branch
          ? !name.contains('branch')
          : !name.contains('academy') || name.contains('branch'))
        continue;
      final type = '${form['type']}';
      var needles = type == 'receptionist'
          ? ['receptionist', 'reception']
          : type == 'other'
          ? ['employee', 'staff', 'other']
          : [type];
      if (type == 'other' &&
          !_rows(source).any((role) {
            final name = '${role['name']}';
            final scoped = branch
                ? name.contains('branch')
                : name.contains('academy') && !name.contains('branch');
            return scoped && needles.any(name.contains);
          }))
        needles = <String>[];
      if (needles.isNotEmpty && !needles.any(name.contains)) continue;
    }
    final id = item[config['id'] ?? 'id'] ?? item['value'];
    if (id == null ||
        excludedIds.contains('$id') ||
        allowed != null && !allowed.contains('$id'))
      continue;
    options['${config['prefix'] ?? ''}$id'] =
        '${config['label'] == null ? item['title'] ?? item['label'] ?? panelTitle(item) : panelValue(item, '${config['label']}') ?? panelTitle(item)}';
  }
  if (config['source'] == null) {
    for (final entry in config.entries) options[entry.key] = '${entry.value}';
  }
  return options;
}

Json panelInitialValues(
  List<Json> fields,
  Json initial,
  Json data, {
  bool applyAliases = true,
  bool applyDefaults = true,
}) {
  final values = <String, dynamic>{...initial};
  for (final field in fields) {
    final key = '${field['key']}';
    final forced = optionalObject(field['valueWhen']);
    if (forced.isNotEmpty &&
        panelConditionsMatch(
          forced['when'],
          panelFormContext(fields, values, data),
        ))
      values[key] = forced['value'];
    if (applyAliases && field['initial'] != null) {
      final value = panelValue(initial, '${field['initial']}');
      if (value != null) values[key] = value;
    }
    final lookup = optionalObject(field['initialLookup']);
    if (applyAliases && lookup.isNotEmpty) {
      final item = _rows(panelValue(data, '${lookup['source']}'))
          .where(
            (item) =>
                '${item[lookup['id'] ?? 'id']}' == '${values[lookup['by']]}',
          )
          .firstOrNull;
      if (item?[lookup['field']] != null) values[key] = item![lookup['field']];
    }
    if (applyDefaults && values[key] == null && field['durationFrom'] is List) {
      final names = field['durationFrom'] as List;
      final start = '${values[names[0]] ?? ''}'.split(':');
      final end = '${values[names[1]] ?? ''}'.split(':');
      if (start.length >= 2 && end.length >= 2) {
        final minutes =
            (int.tryParse(end[0]) ?? 0) * 60 +
            (int.tryParse(end[1]) ?? 0) -
            (int.tryParse(start[0]) ?? 0) * 60 -
            (int.tryParse(start[1]) ?? 0);
        if (minutes > 0) values[key] = minutes;
      }
    }
    if (applyDefaults && values[key] == null && field.containsKey('default'))
      values[key] = field['default'];
    if (applyDefaults && values[key] == null && field['defaultToday'] == true)
      values[key] = DateTime.now().toIso8601String().substring(0, 10);
    if (applyDefaults &&
        values[key] == null &&
        field['defaultFirstOption'] == true) {
      final option = panelSelectOptions(field, {
        ...data,
        '_form': values,
      }).keys.firstOrNull;
      if (option != null) values[key] = int.tryParse(option) ?? option;
    }
    if (field['type'] == 'object') {
      values[key] = panelInitialValues(
        _rows(field['options']),
        optionalObject(values[key]),
        data,
        applyAliases: applyAliases,
        applyDefaults: applyDefaults,
      );
    }
    if (field['type'] == 'rows') {
      final rows = _rows(values[key]);
      var count =
          (num.tryParse('${values[field['rowsCountFrom']]}') ?? rows.length)
              .toInt()
              .clamp(0, 100);
      if (field['singleWhen'] is Map &&
          panelConditionsMatch(
            field['singleWhen'],
            panelFormContext(fields, values, data),
          ))
        count = 1;
      values[key] = [
        for (
          var i = 0;
          i < (field['rowsCountFrom'] == null ? rows.length : count);
          i++
        )
          panelInitialValues(
            _rows(field['options']),
            i < rows.length ? rows[i] : {},
            {...data, '_root': values},
            applyAliases: applyAliases,
            applyDefaults: i >= rows.length || applyDefaults,
          ),
      ];
    }
  }
  return values;
}

Json panelSubmittedValues(List<Json> fields, Json values, Json data) {
  final context = panelFormContext(fields, values, data);
  return {
    for (final field in fields)
      if (field['submit'] != false &&
          (panelFieldVisible(field, context) ||
              field['submitWhenHidden'] == true) &&
          values.containsKey(field['key']))
        '${field['key']}': field['type'] == 'object'
            ? panelSubmittedValues(
                _rows(field['options']),
                optionalObject(values[field['key']]),
                context,
              )
            : field['type'] == 'rows'
            ? [
                for (final row in _rows(values[field['key']]))
                  panelSubmittedValues(_rows(field['options']), row, context),
              ]
            : values[field['key']],
  };
}

/// Validate collections as well as scalar controls, including hidden-field rules.
String? panelInvalidField(List<Json> fields, Json values, Json data) {
  final context = panelFormContext(fields, values, data);
  for (final field in fields) {
    if (!panelFieldVisible(field, context)) continue;
    final key = '${field['key']}';
    final value = values[key];
    final empty =
        value == null ||
        value is String && value.trim().isEmpty ||
        value is List && value.isEmpty;
    if (panelFieldRequired(field, context) && empty) return key;
    if (empty) continue;
    final type = field['type'];
    if (type == 'select' &&
        !panelSelectOptions(field, context).containsKey('$value'))
      return key;
    if (type == 'number') {
      final number = num.tryParse('$value');
      if (number == null ||
          !number.isFinite ||
          field['min'] is num && number < field['min'] ||
          field['max'] is num && number > field['max'])
        return key;
      if (field['step'] is num && number % field['step'] != 0) return key;
    }
    if (field['maxLength'] is int && '$value'.length > field['maxLength'])
      return key;
    if (type == 'url') {
      final uri = Uri.tryParse('$value');
      if (uri == null ||
          !['https', 'http'].contains(uri.scheme) ||
          uri.host.isEmpty)
        return key;
    }
    if ((type == 'date' || type == 'datetime') &&
        DateTime.tryParse('$value') == null)
      return key;
    if (type == 'multi') {
      final options = panelSelectOptions(field, context);
      final max = num.tryParse(
        '${panelValue(context, '${field['maxItemsFrom'] ?? ''}')}',
      );
      if (max != null && (value as List).length > max) return key;
      if ((value as List).any(
        (item) => !options.containsKey('${item is Map ? item['id'] : item}'),
      ))
        return key;
    }
    if (type == 'object') {
      if (panelInvalidField(
            _rows(field['options']),
            optionalObject(value),
            context,
          ) !=
          null)
        return key;
    }
    if (type == 'rows') {
      if (field['maxItems'] is int &&
          (value as List).length > field['maxItems'])
        return key;
      for (final row in _rows(value)) {
        if (panelInvalidField(_rows(field['options']), row, context) != null)
          return key;
      }
    }
    if (type == 'strings' &&
        (value as List).any((item) => '$item'.trim().isEmpty))
      return key;
  }
  return null;
}

/// The same transport values computed by the website's form readers.
Json panelDialogPayload(
  String section,
  String operation,
  Json values,
  Json data,
) {
  final payload = <String, dynamic>{...values};
  if (section == 'availability-exceptions') {
    final target = '${values['targetValue'] ?? ''}'.split(':');
    if (target.length == 2) {
      payload['targetType'] = target.first;
      payload['membershipId'] = target.first == 'member'
          ? int.tryParse(target.last)
          : null;
    }
    payload.remove('targetValue');
    if (values['allDay'] == true) payload['ranges'] = [];
  }
  if (section == 'roles') payload['sortOrder'] = 0;
  if (section == 'permissions')
    payload['group'] = ['academy', 'branch'].contains(values['scope'])
        ? 'academy'
        : 'website';
  if (section == 'points') {
    final organization = _rows(
      data['organizations'],
    ).where((o) => '${o['id']}' == '${values['branchId']}').firstOrNull;
    payload['academyId'] = organization?['academyId'] ?? 0;
  }
  if (section == 'students') {
    payload['type'] = 'student';
    payload['parent'] = {
      for (final entry in {
        'name': 'parentName',
        'nationalId': 'parentNationalId',
        'fatherName': 'parentFatherName',
        'birthDate': 'parentBirthDate',
        'phone': 'parentPhone',
      }.entries)
        entry.key: values[entry.value] ?? '',
    };
    for (final key in [
      'parentName',
      'parentNationalId',
      'parentFatherName',
      'parentBirthDate',
      'parentPhone',
    ])
      payload[key] ??= '';
    payload['availabilities'] = [
      for (final row in _rows(payload['availabilities']))
        {...row, 'status': 'available'},
    ];
  }
  if (section == 'terms') {
    final organization = _rows(data['organizations'])
        .where((o) => '${o['user_id']}' == '${values['organizationUserId']}')
        .firstOrNull;
    if (organization != null) {
      payload['branchId'] =
          _rows(data['classrooms'])
              .where((room) => '${room['id']}' == '${values['classroomId']}')
              .firstOrNull?['branchId'] ??
          0;
      payload['academyId'] = organization['kind'] == 'academy'
          ? organization['id']
          : optionalObject(data['branchAcademies'])['${organization['id']}'];
    }
    final draft = operation == 'create' && values['status'] == 'open';
    payload['undatedTemplate'] = draft;
    payload['sessions'] = [
      for (final row in _rows(values['sessions']))
        {
          ...row,
          'date': draft ? '' : row['date'],
          if (row['startTime'] is String &&
              num.tryParse('${row['durationMinutes']}') != null)
            'endTime': _sessionEnd(
              '${row['startTime']}',
              (num.tryParse('${row['durationMinutes']}') ?? 0).toInt(),
            ),
        },
    ];
    if (['open', 'pending'].contains(values['status']))
      payload['students'] = [];
    payload['installments'] = [
      for (
        var i = 0;
        i < (num.tryParse('${values['installmentCount']}') ?? 1).clamp(1, 100);
        i++
      )
        {'amount': 1},
    ];
  }
  return payload;
}

String _sessionEnd(String start, int duration) {
  final parts = start.split(':');
  if (parts.length < 2) return '';
  final minutes =
      (int.tryParse(parts[0]) ?? 0) * 60 +
      (int.tryParse(parts[1]) ?? 0) +
      duration;
  return '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

/// The website loads term data and the course/organization catalog together.
/// Match by organization account ID, so two academies' branchId=0 never mix.
Json panelTermOptionData(Json data, Json courseData) {
  final organizations = _rows(courseData['organizations']);
  if (organizations.isEmpty) return data;
  dynamic owner(Json row) =>
      row['organizationUserId'] ??
      organizations
          .where(
            (o) => o['kind'] == 'branch'
                ? '${o['id']}' == '${row['branchId']}' &&
                      '${row['branchId']}' != '0'
                : '${row['branchId'] ?? 0}' == '0' &&
                      '${o['id']}' == '${row['academyId']}',
          )
          .firstOrNull?['user_id'];
  final courses = _rows(courseData['courses'])
      .map(
        (c) => {
          ...c,
          'lessonId': c['lesson_id'] ?? c['lessonId'],
          'organizationId':
              c['organizationId'] ??
              organizations
                  .where(
                    (o) => '${o['user_id']}' == '${c['organizationUserId']}',
                  )
                  .firstOrNull?['id'],
        },
      )
      .toList();
  return {
    ...data,
    'organizations': organizations,
    'courses': courses,
    for (final collection in ['members', 'classrooms'])
      collection: [
        for (final row in _rows(data[collection]))
          {...row, 'organizationUserId': owner(row)},
      ],
    'terms': [
      for (final row in _rows(data['terms']))
        {
          ...row,
          'organizationUserId': courses
              .where((c) => '${c['id']}' == '${row['courseId']}')
              .firstOrNull?['organizationUserId'],
        },
    ],
  };
}

List<Json> panelTermDialogFields(List<Json> fields) => [
  for (final original in fields)
    (() {
      final field = <String, dynamic>{...original};
      final key = field['key'];
      if (key == 'branchId') {
        field['key'] = 'organizationUserId';
        field['options'] = {'source': 'organizations', 'id': 'user_id'};
        field['initialLookup'] = {
          'source': 'courses',
          'by': 'courseId',
          'field': 'organizationUserId',
        };
      }
      final config = optionalObject(field['options']);
      final match = optionalObject(config['match']);
      if (match.containsKey('branchId')) {
        field['options'] = {
          ...config,
          'match': {
            for (final e in match.entries)
              (e.key == 'branchId' ? 'organizationUserId' : e.key):
                  e.value == 'branchId' ? 'organizationUserId' : e.value,
          },
        };
      }
      if (field['dependsOn'] is List)
        field['dependsOn'] = [
          for (final key in field['dependsOn'])
            key == 'branchId' ? 'organizationUserId' : key,
        ];
      if (key == 'classroomId')
        field['options'] = {'source': 'classrooms', 'termRooms': true};
      if (['teachers', 'students'].contains(key))
        field['options'] = {
          ...optionalObject(field['options']),
          'termPeople': true,
          'match': {
            for (final e in optionalObject(
              optionalObject(field['options'])['match'],
            ).entries)
              if (!['organizationUserId', 'branchId'].contains(e.key))
                e.key: e.value,
          },
        };
      return field;
    })(),
];
