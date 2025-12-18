import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> request() async {
    final mic = await Permission.microphone.request();
    final storage = await Permission.storage.request();
    return mic.isGranted && storage.isGranted;
  }
}
