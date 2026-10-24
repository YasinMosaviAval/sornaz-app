import '../Social/social_api.dart';

double panelFiniteNumber(dynamic value) {
  final n = num.tryParse('$value');
  return n != null && n.isFinite ? n.toDouble() : 0;
}

class PanelDistribution {
  const PanelDistribution(
    this.values, {
    this.people = 0,
    this.negative = false,
  });
  final Map<String, double> values;
  final int people;
  final bool negative;
}

PanelDistribution panelPointDistribution(Json balance) {
  final raw = {
    for (final key in ['general', 'professional', 'specialized'])
      key: panelFiniteNumber(balance[key]),
  };
  return PanelDistribution(
    raw.map((key, value) => MapEntry(key, value < 0 ? 0 : value)),
    negative: raw.values.any((v) => v < 0),
  );
}

PanelDistribution panelContractDistribution(
  List<Json> rows, {
  String type = '',
}) {
  final groups = <String, Set<String>>{};
  final people = <String>{};
  for (final row in rows) {
    final id = row['user_id'] ?? row['userId'] ?? row['id'];
    if (id == null) continue;
    final contracts = objects(row['contracts'] ?? []);
    for (final contract in contracts.isEmpty ? [row] : contracts) {
      final kind = '${contract['type'] ?? ''}';
      if (panelFiniteNumber(
                contract['contractId'] ?? contract['member_contract_id'],
              ) <=
              0 ||
          ['', 'student', 'waiting'].contains(kind) ||
          (type.isNotEmpty && type != kind)) {
        continue;
      }
      groups.putIfAbsent(kind, () => {}).add('$id');
      people.add('$id');
    }
  }
  final keys = groups.keys.toList()..sort();
  return PanelDistribution({
    for (final key in keys) key: groups[key]!.length.toDouble(),
  }, people: people.length);
}

class PanelLessonGroup {
  PanelLessonGroup(this.name);
  final String name;
  final inPerson = <String>{}, online = <String>{};
}

class PanelLessonDistribution {
  const PanelLessonDistribution(this.groups, this.counted, this.unknown);
  final List<PanelLessonGroup> groups;
  final int counted, unknown;
}

PanelLessonDistribution panelLessonDistribution(
  String section,
  List<Json> rows,
  Json data, {
  String unknownLesson = 'Unknown lesson',
}) {
  final courses = {
    for (final c in objects(data['courses'] ?? [])) '${c['id']}': c,
  };
  final rooms = {
    for (final c in objects(data['classrooms'] ?? [])) '${c['id']}': c,
  };
  final groups = <String, PanelLessonGroup>{};
  final counted = <String>{}, unknown = <String>{}, seen = <String>{};
  for (final row in rows) {
    final id = section == 'students' ? row['user_id'] ?? row['id'] : row['id'];
    if (id == null) continue;
    final person = '$id';
    Json course = {};
    final modes = <String>{};
    if (section == 'terms') {
      if (objects(row['students'] ?? []).isEmpty || !seen.add(person)) continue;
      course = courses['${row['courseId']}'] ?? {};
      for (final session in objects(row['sessions'] ?? [])) {
        final room = rooms['${session['classroomId']}'] ?? {};
        final mode =
            session['deliveryMode'] ??
            session['delivery_mode'] ??
            room['deliveryMode'];
        if (['in_person', 'online'].contains(mode)) modes.add('$mode');
      }
      if (modes.isEmpty) {
        final room =
            rooms['${row['classroomId'] ?? optionalObject(row['scheduleDraft'])['classroomId']}'] ??
            {};
        if (['in_person', 'online'].contains(room['deliveryMode'])) {
          modes.add('${room['deliveryMode']}');
        }
      }
    } else {
      modes.addAll(
        (row['deliveryModes'] is List ? row['deliveryModes'] as List : const [])
            .where((m) => ['in_person', 'online'].contains(m))
            .map((m) => '$m'),
      );
    }
    if (modes.isEmpty) {
      unknown.add(person);
      continue;
    }
    final lesson = section == 'students'
        ? row['lessonId']
        : course['lessonId'] ?? course['lesson_id'];
    final label = section == 'students'
        ? row['lessonName']
        : course['instrument'] ?? course['lessonTitle'];
    final group = groups.putIfAbsent(
      '${lesson ?? 'unknown'}',
      () => PanelLessonGroup(
        label == null || label == '—' ? unknownLesson : '$label',
      ),
    );
    if (modes.contains('in_person')) group.inPerson.add(person);
    if (modes.contains('online')) group.online.add(person);
    counted.add(person);
  }
  final sorted = groups.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return PanelLessonDistribution(sorted, counted.length, unknown.length);
}

class PanelHeatmapData {
  PanelHeatmapData(this.cells, this.sessions, this.unknown);
  final List<List<int>> cells;
  final int sessions, unknown;
}

PanelHeatmapData panelHeatmapData(List<Json> rows) {
  final cells = List.generate(7, (_) => List.filled(24, 0));
  final seen = <String>{};
  var sessions = 0, unknown = 0;
  int? minutes(dynamic value) {
    final match = RegExp(r'^(\d{2}):(\d{2})(?::\d{2})?$').firstMatch('$value');
    if (match == null) return null;
    final h = int.parse(match[1]!), m = int.parse(match[2]!);
    return h <= 24 && m < 60 && (h < 24 || m == 0) ? h * 60 + m : null;
  }

  for (final row in rows) {
    if (row['id'] != null && !seen.add('${row['id']}')) continue;
    final date = DateTime.tryParse('${row['date']}');
    final start = minutes(row['startTime']), end = minutes(row['endTime']);
    final count = row['count'] == null
        ? 1
        : panelFiniteNumber(row['count']).toInt();
    if (date == null ||
        start == null ||
        end == null ||
        end <= start ||
        end > 1440 ||
        count <= 0) {
      unknown += count > 0 ? count : 1;
      continue;
    }
    sessions += count;
    final day = (date.weekday + 1) % 7;
    for (var hour = start ~/ 60; hour < (end / 60).ceil(); hour++) {
      cells[day][hour] += count;
    }
  }
  return PanelHeatmapData(cells, sessions, unknown);
}
