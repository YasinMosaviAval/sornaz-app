import '../Social/social_api.dart';

class PanelNavigationUnavailable implements Exception {}

/// Internal website page groups, restricted to the server-authorized catalog.
Json panelSectionWithTabs(Json section, List<Json> sections) {
  final catalog = {
    for (final item in sections)
      if (item['hidden'] != true) '${item['key']}': item,
  };
  final key = '${section['key']}';
  Json readOnlyView(String viewKey, String rows, String fa, String en) => {
    ...section,
    'key': viewKey,
    'resourceKey': key,
    'rows': rows,
    'label': fa,
    'en': en,
    'actions': {'list': optionalObject(section['actions'])['list'] ?? {}},
    'filters': <Json>[],
    'optionActions': <String>[],
    'presentation': optionalObject(
      optionalObject(section['presentation'])['views'],
    )[rows],
  };
  if (key == 'my-lessons') {
    return {
      ...section,
      'pageTabs': [
        readOnlyView(
          'my-lesson-levels',
          'levels',
          'سطح درس‌ها',
          'Lesson levels',
        ),
        {...section, 'label': 'درس‌ها', 'en': 'Lessons'},
      ],
    };
  }
  if (key == 'my-points' && !catalog.containsKey('points')) {
    return {
      ...section,
      'pageTabs': [
        section,
        readOnlyView(
          'my-point-rules',
          'rules',
          'قوانین امتیازها',
          'Point rules',
        ),
      ],
    };
  }
  final personalLearning = !catalog.containsKey('members');
  final groups = [
    ['course-levels', 'lessons', 'courses'],
    ['members', 'users', 'member-schedules', 'employee-leaves'],
    ['branches', 'availabilities', 'scheduling-rules', 'organization-holidays'],
    ['terms', 'term-discounts'],
    ['classroom-types', 'classrooms'],
    if (personalLearning) ['dashboard', 'my-terms', 'my-classrooms'],
    ['my-points', 'points'],
  ];
  final group = groups.where((keys) => keys.contains(key)).firstOrNull;
  if (group == null) return section;
  const labels = {
    'course-levels': ('سطح درس‌ها', 'Lesson levels'),
    'lessons': ('درس‌ها', 'Lessons'),
    'courses': ('دوره‌ها', 'Courses'),
    'members': ('قراردادها', 'Contracts'),
    'users': ('نقش‌ها و دسترسی‌ها', 'Roles and permissions'),
    'member-schedules': ('برنامه زمانی اعضا', 'Member schedules'),
    'employee-leaves': ('مرخصی‌ها', 'Employee leaves'),
    'branches': ('مدیریت شعبه‌ها', 'Branch management'),
    'availabilities': ('برنامه زمانی سازمان', 'Organization availability'),
    'scheduling-rules': (
      'قوانین زمانبندی سازمان',
      'Organization scheduling rules',
    ),
    'organization-holidays': ('تعطیلات', 'Holidays'),
    'terms': ('مدیریت ترم‌ها', 'Manage terms'),
    'term-discounts': ('تخفیف‌ها', 'Discounts'),
    'classroom-types': ('انواع کلاس', 'Classroom types'),
    'classrooms': ('کلاس‌ها', 'Classrooms'),
    'dashboard': ('داشبورد من', 'My dashboard'),
    'my-terms': ('ترم‌های من', 'My terms'),
    'my-classrooms': ('کلاس‌های من', 'My classes'),
    'my-points': ('امتیازهای من', 'My points'),
    'points': ('قوانین امتیازها', 'Point rules'),
  };
  return {
    ...section,
    'pageTabs': [
      for (final target in group)
        if (catalog.containsKey(target))
          {
            ...(target == key ? section : catalog[target]!),
            if (target == 'dashboard' && personalLearning)
              'relatedSections': [
                for (final link in [
                  'my-classrooms',
                  'my-courses',
                  'my-terms',
                  'my-waiting',
                ])
                  if (catalog.containsKey(link)) {...catalog[link]!},
              ],
            'label': labels[target]!.$1,
            'en': labels[target]!.$2,
          },
    ],
  };
}

/// Hydrate only the website's authorized menu; the operation catalog is not a menu.
List<Json> websitePanelNavigation(Json response) {
  if (response['navigationVersion'] != 1 || response['navigation'] is! List) {
    throw PanelNavigationUnavailable();
  }
  final catalog = {
    for (final section in objects(response['sections']))
      '${section['key']}': section,
  };
  List<Json> resolve(List<Json> nodes) => [
    for (final node in nodes)
      if (node['section'] != 'my-settings' && node['destination'] != 'settings')
        if (node['children'] is List)
          {...node, 'children': resolve(objects(node['children']))}
        else if (['notation', 'website-example'].contains(node['destination']))
          {...node}
        else if (catalog.containsKey(node['section']))
          {
            ...panelSectionWithTabs(
              catalog[node['section']]!,
              catalog.values.toList(),
            ),
            if (node['links'] is List)
              'relatedSections': [
                for (final key in node['links'])
                  if (catalog.containsKey(key)) {...catalog[key]!},
              ],
            'navigationKey': node['key'],
            for (final key in ['label', 'en', 'where', 'initialParams'])
              if (node.containsKey(key)) key: node[key],
          }
        else
          throw PanelNavigationUnavailable(),
  ];
  return resolve(objects(response['navigation']));
}

/// Groups only sections authorized by the server; navigation never fetches data.
List<Json> panelNavigation(List<Json> sections) {
  final remaining = {
    for (final s in sections)
      if (![
        'account',
        'my-settings',
        'chat',
        'messages',
        'notifications',
        'points',
      ].contains(s['key']))
        '${s['key']}': Map<String, dynamic>.of(s),
  };
  Json? group(String key, String fa, String en, List<String> keys) {
    final children = [
      for (final k in keys)
        if (remaining.containsKey(k)) remaining.remove(k)!,
    ];
    if (children.isEmpty) return null;
    return {'key': key, 'label': fa, 'en': en, 'children': children};
  }

  final achievements = group(
    'achievements-menu',
    'سوابق و دستاوردها',
    'Background and achievements',
    [
      'awards',
      'badges',
      'experiences',
      'certificates',
      'educations',
      'events',
      'polls',
      'publications',
    ],
  );
  if (achievements != null)
    for (final s in objects(achievements['children'])) {
      if (s['key'] == 'awards') s['label'] = 'پاداش‌ها و جوایز';
    }
  final branches = group('branches-menu', 'شعبه‌ها', 'Branches', [
    'branches',
    'branch-types',
  ]);
  final roles = group(
    'access-menu',
    'نقش‌ها و دسترسی‌ها',
    'Roles and permissions',
    ['users', 'roles', 'permissions'],
  );
  final gallery = remaining.remove('gallery');
  final galleryMenu = gallery == null
      ? null
      : {
          'key': 'gallery-menu',
          'label': 'گالری',
          'en': 'Gallery',
          'children': [
            for (final entry in [
              ('cover', 'کاور', 'Cover'),
              ('logo', 'لوگو', 'Logo'),
              ('intro_video', 'ویدیو معرفی', 'Introduction video'),
              ('gallery', 'مجموعه عکس‌ها و ویدیوها', 'Photos and videos'),
            ])
              {
                ...gallery,
                'label': entry.$2,
                'en': entry.$3,
                'where': {'category': entry.$1},
                'initialParams': {'collection': entry.$1},
              },
          ],
        };
  final lessons = group('lessons-menu', 'درس‌ها', 'Lessons', [
    'lessons',
    'course-levels',
  ]);
  if (lessons != null)
    for (final child in objects(lessons['children'])) {
      child['label'] = child['key'] == 'lessons' ? 'درس‌ها' : 'سطح درس‌ها';
      child['en'] = child['key'] == 'lessons' ? 'Lessons' : 'Lesson levels';
    }
  final classes = group('classes-menu', 'کلاس‌ها', 'Classes', [
    'classrooms',
    'classroom-types',
    'classroom-categories',
  ]);
  final schedules = group('schedule-menu', 'برنامه زمانی', 'Schedule', [
    'scheduling-rules',
    'availabilities',
    'member-schedules',
    'availability-exceptions',
    'schedules',
  ]);
  final siteManagement = group(
    'site-management-menu',
    'مدیریت سایت',
    'Site management',
    ['pages', 'settings', 'site-settings', 'inline-translations', 'guides'],
  );
  // Match the website sidebar while retaining only server-authorized entries.
  List<Json> take(List<String> keys) => [
    for (final key in keys)
      if (remaining.containsKey(key)) remaining.remove(key)!,
  ];
  return [
    ...take([
      'tests',
      'posts',
      'post-categories',
      'media',
      'comments',
      'chart-gallery',
      'reports',
    ]),
    ...take([
      'dashboard',
      'waiting-approvals',
      'waiting-schedules',
      'my-waiting',
      'my-classrooms',
      'my-courses',
      'my-terms',
    ]),
    ?achievements,
    ...take(['tracking', 'national-holidays']),
    ?branches,
    ?roles,
    ?galleryMenu,
    ?lessons,
    // The mobile catalog calls the website's "teachers" section "members".
    ...take(['teachers', 'members']),
    ?classes,
    ...take(['courses', 'terms', 'students']),
    ?schedules,
    ...take(['finance']),
    ?siteManagement,
    // Keep app-only and future authorized sections available at the end.
    ...remaining.values,
  ];
}
