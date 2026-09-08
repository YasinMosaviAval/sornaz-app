import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> request() async {
    final mic = await Permission.microphone.request();
    return mic.isGranted;
  }
}
