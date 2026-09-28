import '../Social/social_api.dart';

/// Groups only sections authorized by the server; navigation never fetches data.
List<Json> panelNavigation(List<Json> sections) {
  final remaining = {
    for (final s in sections)
      if (![
        'account',
        'chat',
        'settings',
        'site-settings',
        'pages',
        'guides',
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
    ...take(['dashboard', 'my-classrooms', 'my-courses', 'my-terms']),
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
    // Keep app-only and future authorized sections available at the end.
    ...remaining.values,
  ];
}
