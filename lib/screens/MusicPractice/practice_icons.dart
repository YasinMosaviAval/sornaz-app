import 'package:flutter/material.dart';

/// Stable keys are shared with the catalog API, not platform font codepoints.
class PracticeIcons {
  static const choices = <String, (IconData, String, String)>{
    'music_note': (Icons.music_note_outlined, 'نت موسیقی', 'Music note'),
    'library_music': (
      Icons.library_music_outlined,
      'کتابخانهٔ موسیقی',
      'Music library',
    ),
    'piano': (Icons.piano_outlined, 'پیانو', 'Piano'),
    'queue_music': (Icons.queue_music, 'فهرست موسیقی', 'Music list'),
    'headphones': (Icons.headphones_outlined, 'هدفون', 'Headphones'),
    'mic': (Icons.mic_none, 'میکروفون', 'Microphone'),
    'hearing': (Icons.hearing_outlined, 'شنوایی', 'Hearing'),
    'graphic_eq': (Icons.graphic_eq, 'موج صدا', 'Sound wave'),
    'speed': (Icons.speed, 'سرعت', 'Tempo'),
    'album': (Icons.album_outlined, 'آلبوم', 'Album'),
    'school': (Icons.school_outlined, 'آموزش', 'Learning'),
    'star': (Icons.star_outline, 'ستاره', 'Star'),
    'tune': (Icons.tune, 'تنظیم صدا', 'Tuning'),
    'folder': (Icons.folder_outlined, 'پوشه', 'Folder'),
  };

  static IconData forNode(Map<String, dynamic> node, {bool expanded = false}) {
    final custom = choices[node['iconKey']]?.$1;
    if (custom != null) return expanded ? filled(custom) : custom;
    final slug = '${node['slug']}';
    if (slug.contains('iranian')) return Icons.music_note;
    if (slug.contains('western')) return Icons.piano;
    return node['depth'] == 1
        ? (expanded ? Icons.library_music : Icons.library_music_outlined)
        : (expanded ? Icons.folder : Icons.folder_outlined);
  }

  static IconData filled(IconData icon) => switch (icon) {
    Icons.music_note_outlined => Icons.music_note,
    Icons.library_music_outlined => Icons.library_music,
    Icons.piano_outlined => Icons.piano,
    Icons.headphones_outlined => Icons.headphones,
    Icons.mic_none => Icons.mic,
    Icons.hearing_outlined => Icons.hearing,
    Icons.album_outlined => Icons.album,
    Icons.school_outlined => Icons.school,
    Icons.star_outline => Icons.star,
    Icons.folder_outlined => Icons.folder,
    _ => icon,
  };
}
