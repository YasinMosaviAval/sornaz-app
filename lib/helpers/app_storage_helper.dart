import 'dart:io';

class StorageHelper {
  static Future<List<Directory>> getStorageRoots() async {
    final List<Directory> roots = [];

    // حافظه داخلی
    final internal = Directory('/storage/emulated/0');
    if (await internal.exists()) {
      roots.add(internal);
    }

    // بررسی SD Card ها
    final storageDir = Directory('/storage');
    if (await storageDir.exists()) {
      final children = storageDir.listSync();
      for (var c in children) {
        if (c is Directory &&
            !c.path.contains('emulated') &&
            !c.path.contains('self')) {
          roots.add(c);
        }
      }
    }

    return roots;
  }
}
